#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script para gestionar secretos en Azure Key Vault
    
.DESCRIPTION
    Permite crear, obtener y actualizar secretos del bot en Azure Key Vault
    
.EXAMPLE
    .\scripts\manage_secrets.ps1 -Action Create
    .\scripts\manage_secrets.ps1 -Action Get
    .\scripts\manage_secrets.ps1 -Action Rotate
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Create", "Get", "Set", "Rotate", "Delete")]
    [string]$Action = "Get",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "BotchatSoluEngMxRog755-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

# Colores
function Write-Title {
    param($Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param($Number, $Text)
    Write-Host ""
    Write-Host "[$Number]" -ForegroundColor Yellow -NoNewline
    Write-Host " $Text" -ForegroundColor White
}

function Write-Success {
    param($Text)
    Write-Host "    ✅ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param($Text)
    Write-Host "    ❌ $Text" -ForegroundColor Red
}

function Write-Info {
    param($Text)
    Write-Host "    ℹ️  $Text" -ForegroundColor Gray
}

function Write-Warning-Custom {
    param($Text)
    Write-Host "    ⚠️  $Text" -ForegroundColor Yellow
}

# Banner
Clear-Host
Write-Title "🔐 AZURE KEY VAULT - GESTIÓN DE SECRETOS"

# Cargar configuración
Write-Step "1" "Cargando configuración..."

try {
    $envPath = Join-Path $PSScriptRoot ".." ".env"
    if (Test-Path $envPath) {
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                Set-Item -Path "env:$key" -Value $value
            }
        }
    }
    
    # Determinar nombre del Key Vault si no se proporciona
    if ([string]::IsNullOrWhiteSpace($KeyVaultName)) {
        $KeyVaultName = "kv-botchat-$(Get-Random -Maximum 9999)"
        Write-Info "Nombre generado: $KeyVaultName"
    }
    
    Write-Success "Configuración cargada"
}
catch {
    Write-Error-Custom "Error cargando configuración: $_"
    exit 1
}

# Verificar Azure CLI
Write-Step "2" "Verificando Azure CLI..."

try {
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    Write-Success "Azure CLI instalado: v$($azVersion.'azure-cli')"
}
catch {
    Write-Error-Custom "Azure CLI no está instalado"
    Write-Info "Descarga desde: https://aka.ms/installazurecliwindows"
    exit 1
}

# Verificar autenticación
Write-Step "3" "Verificando autenticación..."

try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    Write-Success "Autenticado como: $($account.user.name)"
    
    # Establecer subscription
    if ($env:AZURE_SUBSCRIPTION_ID) {
        az account set --subscription $env:AZURE_SUBSCRIPTION_ID
        Write-Success "Subscription configurada"
    }
}
catch {
    Write-Warning-Custom "No autenticado, iniciando login..."
    az login
}

# Ejecutar acción
switch ($Action) {
    "Create" {
        Write-Step "4" "Creando Azure Key Vault..."
        
        # Verificar si ya existe
        $exists = az keyvault show --name $KeyVaultName --resource-group $ResourceGroup 2>$null
        
        if ($exists) {
            Write-Warning-Custom "Key Vault '$KeyVaultName' ya existe"
        }
        else {
            Write-Info "Creando Key Vault: $KeyVaultName"
            az keyvault create `
                --name $KeyVaultName `
                --resource-group $ResourceGroup `
                --location $Location `
                --enable-rbac-authorization false `
                --output none
            
            Write-Success "Key Vault creado: $KeyVaultName"
        }
        
        # Obtener usuario actual para dar permisos
        Write-Step "5" "Configurando permisos..."
        
        $currentUser = az ad signed-in-user show --query id -o tsv
        
        az keyvault set-policy `
            --name $KeyVaultName `
            --object-id $currentUser `
            --secret-permissions get list set delete `
            --output none
        
        Write-Success "Permisos configurados para el usuario actual"
        
        # Crear secretos
        Write-Step "6" "Creando secretos..."
        
        Write-Host ""
        Write-Host "    Ingresa los valores para los secretos:" -ForegroundColor Cyan
        Write-Host ""
        
        # Microsoft App ID
        $appId = Read-Host "    Microsoft App ID"
        if (-not [string]::IsNullOrWhiteSpace($appId)) {
            az keyvault secret set `
                --vault-name $KeyVaultName `
                --name "bot-app-id" `
                --value $appId `
                --output none
            Write-Success "Secreto 'bot-app-id' creado"
        }
        
        # Microsoft App Password
        $appPassword = Read-Host "    Microsoft App Password" -AsSecureString
        $appPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword)
        )
        if (-not [string]::IsNullOrWhiteSpace($appPasswordPlain)) {
            az keyvault secret set `
                --vault-name $KeyVaultName `
                --name "bot-app-password" `
                --value $appPasswordPlain `
                --output none
            Write-Success "Secreto 'bot-app-password' creado"
        }
        
        # Azure OpenAI Key
        $openaiKey = Read-Host "    Azure OpenAI API Key" -AsSecureString
        $openaiKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($openaiKey)
        )
        if (-not [string]::IsNullOrWhiteSpace($openaiKeyPlain)) {
            az keyvault secret set `
                --vault-name $KeyVaultName `
                --name "azure-openai-api-key" `
                --value $openaiKeyPlain `
                --output none
            Write-Success "Secreto 'azure-openai-api-key' creado"
        }
        
        Write-Host ""
        Write-Success "Key Vault configurado: $KeyVaultName"
        Write-Info "Guarda este nombre para futuras operaciones"
    }
    
    "Get" {
        Write-Step "4" "Obteniendo secretos de Key Vault..."
        
        if ([string]::IsNullOrWhiteSpace($KeyVaultName)) {
            Write-Error-Custom "Debes proporcionar -KeyVaultName"
            exit 1
        }
        
        try {
            Write-Host ""
            Write-Info "Key Vault: $KeyVaultName"
            Write-Host ""
            
            # Obtener secretos
            $appId = az keyvault secret show `
                --vault-name $KeyVaultName `
                --name "bot-app-id" `
                --query value -o tsv 2>$null
            
            $appPassword = az keyvault secret show `
                --vault-name $KeyVaultName `
                --name "bot-app-password" `
                --query value -o tsv 2>$null
            
            $openaiKey = az keyvault secret show `
                --vault-name $KeyVaultName `
                --name "azure-openai-api-key" `
                --query value -o tsv 2>$null
            
            # Mostrar resultados (parcialmente ocultos)
            if ($appId) {
                Write-Success "bot-app-id: $($appId.Substring(0, 20))..."
            }
            if ($appPassword) {
                Write-Success "bot-app-password: ***********"
            }
            if ($openaiKey) {
                Write-Success "azure-openai-api-key: ***********"
            }
            
            Write-Host ""
            Write-Info "Secretos obtenidos exitosamente"
            
            # Opción para actualizar .env local
            Write-Host ""
            $updateEnv = Read-Host "    ¿Actualizar archivo .env local? (S/N)"
            
            if ($updateEnv -eq "S" -or $updateEnv -eq "s") {
                $envContent = @"
# Azure Bot Service Configuration (desde Key Vault)
MICROSOFT_APP_ID=$appId
MICROSOFT_APP_PASSWORD=$appPassword

# Azure OpenAI Configuration (desde Key Vault)
AZURE_OPENAI_API_KEY=$openaiKey

# Key Vault Configuration
AZURE_KEY_VAULT_NAME=$KeyVaultName
"@
                $envPath = Join-Path $PSScriptRoot ".." ".env"
                $envContent | Out-File -FilePath $envPath -Encoding UTF8
                Write-Success "Archivo .env actualizado"
            }
        }
        catch {
            Write-Error-Custom "Error obteniendo secretos: $_"
            exit 1
        }
    }
    
    "Set" {
        Write-Step "4" "Actualizando secreto en Key Vault..."
        
        if ([string]::IsNullOrWhiteSpace($KeyVaultName)) {
            Write-Error-Custom "Debes proporcionar -KeyVaultName"
            exit 1
        }
        
        Write-Host ""
        Write-Host "    Secretos disponibles:" -ForegroundColor Cyan
        Write-Host "    1. bot-app-id" -ForegroundColor White
        Write-Host "    2. bot-app-password" -ForegroundColor White
        Write-Host "    3. azure-openai-api-key" -ForegroundColor White
        Write-Host ""
        
        $secretName = Read-Host "    Nombre del secreto"
        $secretValue = Read-Host "    Nuevo valor" -AsSecureString
        $secretValuePlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretValue)
        )
        
        az keyvault secret set `
            --vault-name $KeyVaultName `
            --name $secretName `
            --value $secretValuePlain `
            --output none
        
        Write-Success "Secreto '$secretName' actualizado"
    }
    
    "Rotate" {
        Write-Step "4" "Rotando secretos..."
        
        if ([string]::IsNullOrWhiteSpace($KeyVaultName)) {
            Write-Error-Custom "Debes proporcionar -KeyVaultName"
            exit 1
        }
        
        Write-Warning-Custom "Esta operación regenerará el App Password en Azure AD"
        Write-Host ""
        $confirm = Read-Host "    ¿Continuar? (S/N)"
        
        if ($confirm -ne "S" -and $confirm -ne "s") {
            Write-Info "Operación cancelada"
            exit 0
        }
        
        # Obtener App ID actual
        $appId = az keyvault secret show `
            --vault-name $KeyVaultName `
            --name "bot-app-id" `
            --query value -o tsv
        
        Write-Info "Regenerando credencial para App ID: $appId"
        
        # Regenerar credencial
        $newCred = az ad app credential reset `
            --id $appId `
            --append `
            --output json | ConvertFrom-Json
        
        # Actualizar en Key Vault
        az keyvault secret set `
            --vault-name $KeyVaultName `
            --name "bot-app-password" `
            --value $newCred.password `
            --output none
        
        Write-Success "Credencial rotada exitosamente"
        Write-Info "Expira: $($newCred.endDateTime)"
        
        Write-Host ""
        Write-Warning-Custom "Actualiza la configuración en:"
        Write-Info "• Azure App Service (si ya está desplegado)"
        Write-Info "• Variables de entorno locales"
    }
    
    "Delete" {
        Write-Step "4" "Eliminando secreto de Key Vault..."
        
        if ([string]::IsNullOrWhiteSpace($KeyVaultName)) {
            Write-Error-Custom "Debes proporcionar -KeyVaultName"
            exit 1
        }
        
        Write-Host ""
        $secretName = Read-Host "    Nombre del secreto a eliminar"
        
        Write-Warning-Custom "Esta operación eliminará el secreto"
        $confirm = Read-Host "    ¿Continuar? (S/N)"
        
        if ($confirm -eq "S" -or $confirm -eq "s") {
            az keyvault secret delete `
                --vault-name $KeyVaultName `
                --name $secretName `
                --output none
            
            Write-Success "Secreto '$secretName' eliminado"
        }
        else {
            Write-Info "Operación cancelada"
        }
    }
}

Write-Host ""
Write-Title "✅ OPERACIÓN COMPLETADA"
Write-Host ""
