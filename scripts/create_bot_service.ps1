#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Crea un nuevo Azure Bot Service usando Azure CLI
    
.DESCRIPTION
    Este script crea un Azure Bot Service con la configuración predefinida
    usando el App Registration existente (JaroChat AI Demo Bot)
    
.EXAMPLE
    .\scripts\create_bot_service.ps1
#>

# Configuración
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
Write-Title "🤖 CREAR AZURE BOT SERVICE"

# Cargar configuración del .env
Write-Step "1" "Cargando configuración..."

try {
    $envPath = Join-Path $PSScriptRoot ".." ".env"
    if (-not (Test-Path $envPath)) {
        Write-Error-Custom "Archivo .env no encontrado"
        exit 1
    }

    # Leer variables del .env
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$key" -Value $value
        }
    }

    # Función helper para obtener valores seguros con prioridad Key Vault
    function Get-SecureValue {
        param(
            [string]$KeyVaultSecretName,
            [string]$EnvVarName,
            [string]$GitConfigKey,
            [string]$DefaultValue = ""
        )
        
        $value = ""
        
        # 1. Intentar Key Vault (si está configurado)
        if ($env:AZURE_KEY_VAULT_NAME -and -not [string]::IsNullOrWhiteSpace($KeyVaultSecretName)) {
            try {
                $value = az keyvault secret show `
                    --vault-name $env:AZURE_KEY_VAULT_NAME `
                    --name $KeyVaultSecretName `
                    --query value -o tsv 2>$null
                
                if ($value) {
                    Write-Info "Secreto '$KeyVaultSecretName' obtenido de Key Vault"
                    return $value
                }
            }
            catch {
                # Silencioso, intentar siguiente método
            }
        }
        
        # 2. Variable de entorno
        if ([string]::IsNullOrWhiteSpace($value) -and $env:$EnvVarName) {
            $value = $env:$EnvVarName
            Write-Info "Usando variable de entorno: $EnvVarName"
        }
        
        # 3. Git config local
        if ([string]::IsNullOrWhiteSpace($value)) {
            $value = git config --local $GitConfigKey 2>$null
            if ($value) {
                Write-Info "Usando git config local: $GitConfigKey"
            }
        }
        
        # 4. Valor por defecto
        if ([string]::IsNullOrWhiteSpace($value)) {
            $value = $DefaultValue
        }
        
        return $value
    }

    # Obtener credenciales con prioridad Key Vault > .env > git config > default
    $appId = Get-SecureValue `
        -KeyVaultSecretName "bot-app-id" `
        -EnvVarName "MICROSOFT_APP_ID" `
        -GitConfigKey "user.app.id" `
        -DefaultValue "4c0b49fc-cd97-4772-b859-3e1f6cff69cb"
    
    $appPassword = Get-SecureValue `
        -KeyVaultSecretName "bot-app-password" `
        -EnvVarName "MICROSOFT_APP_PASSWORD" `
        -GitConfigKey "user.app.password" `
        -DefaultValue ""
    
    $subscription = if ($env:AZURE_SUBSCRIPTION_ID) { 
        $env:AZURE_SUBSCRIPTION_ID 
    } else { 
        "662141d0-0308-4187-b46b-db1e9466b5ac" 
    }
    
    $resourceGroup = if ($env:AZURE_RESOURCE_GROUP) { 
        $env:AZURE_RESOURCE_GROUP 
    } else { 
        "BotchatSoluEngMxRog755-rg" 
    }

    Write-Success "Configuración cargada"
    Write-Info "App ID: $($appId.Substring(0,20))..."
    Write-Info "Subscription: $($subscription.Substring(0,20))..."
    Write-Info "Resource Group: $resourceGroup"
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

# Login a Azure
Write-Step "3" "Verificando autenticación de Azure..."

try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    Write-Success "Autenticado como: $($account.user.name)"
    Write-Info "Subscription activa: $($account.name)"
}
catch {
    Write-Warning-Custom "No autenticado, iniciando login..."
    az login
    $account = az account show --output json | ConvertFrom-Json
    Write-Success "Autenticado correctamente"
}

# Establecer la subscripción correcta
Write-Step "4" "Configurando subscription..."

try {
    az account set --subscription $subscription
    Write-Success "Subscription configurada: $subscription"
}
catch {
    Write-Error-Custom "Error configurando subscription: $_"
    exit 1
}

# Solicitar nombre del bot
Write-Step "5" "Configuración del Bot Service..."
Write-Host ""
Write-Host "    Ingresa el nombre para el Bot Service" -ForegroundColor Cyan
Write-Host "    (debe ser único en Azure, solo letras, números y guiones)" -ForegroundColor Gray
Write-Host ""
$botName = Read-Host "    Nombre del bot (ejemplo: jarochat-ai-demo-bot)"

if ([string]::IsNullOrWhiteSpace($botName)) {
    Write-Error-Custom "Nombre del bot no puede estar vacío"
    exit 1
}

# Configuración del bot
$location = "eastus2"
$sku = "F0"  # Free tier
$description = "JaroChat AI Demo Bot con Azure AI Foundry"

Write-Host ""
Write-Info "Nombre: $botName"
Write-Info "Location: $location"
Write-Info "SKU: $sku (Free - 10,000 mensajes/mes)"
Write-Info "Resource Group: $resourceGroup"
Write-Host ""

# Confirmación
Write-Host "    ¿Crear el Bot Service con esta configuración? (S/N): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host

if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Warning-Custom "Operación cancelada"
    exit 0
}

# Crear el Bot Service
Write-Step "6" "Creando Bot Service..."
Write-Info "Esto puede tardar 1-2 minutos..."
Write-Host ""

try {
    $result = az bot create `
        --resource-group $resourceGroup `
        --name $botName `
        --kind azurebot `
        --location $location `
        --sku $sku `
        --appid $appId `
        --password $appPassword `
        --description $description `
        --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw $result
    }

    Write-Success "Bot Service creado exitosamente: $botName"
}
catch {
    Write-Error-Custom "Error creando Bot Service:"
    Write-Host "    $_" -ForegroundColor Red
    Write-Host ""
    Write-Warning-Custom "Posibles causas:"
    Write-Info "• El nombre ya está en uso (intenta otro nombre)"
    Write-Info "• Permisos insuficientes en la subscription"
    Write-Info "• El App ID ya está asociado a otro bot"
    exit 1
}

# Obtener URL de ngrok si está disponible
Write-Step "7" "Configurando Messaging Endpoint..."

$ngrokUrl = ""
try {
    # Intentar obtener URL de ngrok desde su API local
    $ngrokApi = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction SilentlyContinue
    $ngrokUrl = $ngrokApi.tunnels[0].public_url
    
    if ($ngrokUrl) {
        $endpoint = "$ngrokUrl/api/messages"
        
        Write-Info "URL de ngrok detectada: $ngrokUrl"
        Write-Host ""
        Write-Host "    ¿Configurar este endpoint ahora? (S/N): " -ForegroundColor Yellow -NoNewline
        $confirmEndpoint = Read-Host
        
        if ($confirmEndpoint -eq "S" -or $confirmEndpoint -eq "s") {
            az bot update `
                --resource-group $resourceGroup `
                --name $botName `
                --endpoint $endpoint `
                --output none
            
            Write-Success "Messaging endpoint configurado: $endpoint"
        }
        else {
            Write-Warning-Custom "Endpoint no configurado. Hazlo manualmente desde el portal"
        }
    }
}
catch {
    Write-Warning-Custom "ngrok no está activo o no se pudo detectar"
    Write-Info "Configura el endpoint manualmente en el portal:"
    Write-Info "https://portal.azure.com → Bot Service → Configuration"
}

# Habilitar canal de Teams
Write-Step "8" "Habilitando canal de Microsoft Teams..."

try {
    az bot msteams create `
        --resource-group $resourceGroup `
        --name $botName `
        --output none
    
    Write-Success "Canal de Teams habilitado"
}
catch {
    Write-Warning-Custom "No se pudo habilitar Teams automáticamente"
    Write-Info "Habilítalo manualmente: Portal → Channels → Microsoft Teams"
}

# Resumen final
Write-Host ""
Write-Title "✅ BOT SERVICE CREADO EXITOSAMENTE"

Write-Host "    📋 Información del Bot:" -ForegroundColor Cyan
Write-Host ""
Write-Success "Nombre: $botName"
Write-Success "Resource Group: $resourceGroup"
Write-Success "App ID: $appId"
Write-Success "Location: $location"
Write-Success "SKU: $sku"
if ($ngrokUrl) {
    Write-Success "Endpoint: $ngrokUrl/api/messages"
}
Write-Host ""

Write-Host "    🔗 Enlaces útiles:" -ForegroundColor Cyan
Write-Host ""
Write-Info "Portal de Azure:"
Write-Host "    https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.BotService/botServices/$botName" -ForegroundColor White
Write-Host ""
Write-Info "Test en Web Chat:"
Write-Host "    Portal → $botName → Test in Web Chat" -ForegroundColor White
Write-Host ""

Write-Host "    📝 Próximos pasos:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    1. Si no configuraste el endpoint, ve al portal y actualízalo:" -ForegroundColor White
Write-Host "       https://TU-URL-NGROK.ngrok-free.app/api/messages" -ForegroundColor Gray
Write-Host ""
Write-Host "    2. Abre el bot en Teams:" -ForegroundColor White
Write-Host "       Portal → $botName → Channels → Microsoft Teams → Open in Teams" -ForegroundColor Gray
Write-Host ""
Write-Host "    3. Envía un mensaje de prueba" -ForegroundColor White
Write-Host ""

Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
