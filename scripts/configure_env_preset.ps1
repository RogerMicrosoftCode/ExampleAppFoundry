# Script para configurar automáticamente el archivo .env
# con valores preestablecidos para BotprojectTeam
# Usage: .\configure_env_preset.ps1

param(
    [switch]$NonInteractive = $false
)

$ErrorActionPreference = "Stop"

# Colores
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($Message) { Write-ColorOutput Green $Message }
function Write-Info($Message) { Write-ColorOutput Cyan $Message }
function Write-Warning2($Message) { Write-ColorOutput Yellow $Message }
function Write-Error2($Message) { Write-ColorOutput Red $Message }

Write-Output ""
Write-Output "========================================="
Write-Output "🔧 Configurador Automático .env"
Write-Output "    BotprojectTeam - Azure AI Foundry"
Write-Output "========================================="
Write-Output ""

# Valores preestablecidos
$SUBSCRIPTION_ID = "662141d0-0308-4187-b46b-db1e9466b5ac"
$RESOURCE_GROUP = "AIBOTSTEAM"
$AI_HUB_NAME = "BotprojectTeam"
$AI_PROJECT_NAME = "BotprojectTeam"
$OPENAI_RESOURCE_NAME = "aiappsseroger"
$OPENAI_DEPLOYMENT = "gpt-4.1"
$LOCATION = "eastus2"

Write-Info "📋 Configuración preestablecida:"
Write-Output ""
Write-Output "  Suscripción: $SUBSCRIPTION_ID"
Write-Output "  Resource Group: $RESOURCE_GROUP"
Write-Output "  Location: $LOCATION"
Write-Output "  AI Hub: $AI_HUB_NAME"
Write-Output "  AI Project: $AI_PROJECT_NAME"
Write-Output "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
Write-Output "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
Write-Output ""

# Verificar que Azure CLI está instalado
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Success "✅ Azure CLI encontrado: $($azVersion.'azure-cli')"
} catch {
    Write-Error2 "❌ Azure CLI no está instalado"
    Write-Output "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Login a Azure
Write-Output ""
Write-Info "📝 Iniciando sesión en Azure..."
$loginResult = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Info "No hay sesión activa. Iniciando login..."
    az login --output table
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "❌ Error al iniciar sesión en Azure"
        exit 1
    }
}

Write-Success "✅ Login exitoso"

# Establecer la suscripción correcta
Write-Info "🔄 Configurando suscripción..."
az account set --subscription $SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    Write-Error2 "❌ Error al configurar la suscripción"
    exit 1
}
Write-Success "✅ Suscripción configurada"

# Instalar/actualizar extensión de ML
Write-Info "🔧 Verificando extensión de Azure ML..."
try {
    az extension add --name ml --upgrade --yes --only-show-errors 2>$null | Out-Null
    Write-Success "✅ Extensión Azure ML lista"
} catch {
    Write-Warning2 "⚠️  Advertencia: No se pudo actualizar la extensión ML"
}

# Verificar que el Resource Group existe
Write-Info "🔍 Verificando Resource Group..."
$rgExists = az group exists --name $RESOURCE_GROUP
if ($rgExists -eq "true") {
    Write-Success "✅ Resource Group encontrado: $RESOURCE_GROUP"
} else {
    Write-Error2 "❌ Resource Group '$RESOURCE_GROUP' no existe"
    $createRG = Read-Host "¿Deseas crearlo? (y/n)"
    if ($createRG -eq "y" -or $createRG -eq "Y") {
        Write-Info "Creando Resource Group..."
        az group create --name $RESOURCE_GROUP --location $LOCATION
        Write-Success "✅ Resource Group creado"
    } else {
        Write-Error2 "Cancelando configuración..."
        exit 1
    }
}

# Verificar AI Project
Write-Info "🔍 Verificando AI Project..."
$projectExists = $false
try {
    $projectInfo = az ml workspace show `
      --name $AI_PROJECT_NAME `
      --resource-group $RESOURCE_GROUP 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        $projectExists = $true
        Write-Success "✅ AI Project encontrado: $AI_PROJECT_NAME"
    }
} catch {
    $projectExists = $false
}

if (-not $projectExists) {
    Write-Warning2 "⚠️  AI Project '$AI_PROJECT_NAME' no encontrado"
    Write-Info "Por favor, créalo en Azure AI Studio: https://ai.azure.com"
    $continue = Read-Host "¿Continuar de todas formas? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Obtener Project Endpoint
Write-Info "📡 Obteniendo información del proyecto..."
$PROJECT_ENDPOINT = ""
try {
    $PROJECT_ENDPOINT = az ml workspace show `
      --name $AI_PROJECT_NAME `
      --resource-group $RESOURCE_GROUP `
      --query "discovery_url" -o tsv 2>$null
    
    if ([string]::IsNullOrWhiteSpace($PROJECT_ENDPOINT)) {
        $PROJECT_ENDPOINT = "https://ai.azure.com"
    }
} catch {
    $PROJECT_ENDPOINT = "https://ai.azure.com"
}

# Verificar recurso Azure OpenAI
Write-Info "🔍 Verificando recurso Azure OpenAI..."
$openaiExists = $false
try {
    $openaiInfo = az cognitiveservices account show `
      --name $OPENAI_RESOURCE_NAME `
      --resource-group $RESOURCE_GROUP 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        $openaiExists = $true
        Write-Success "✅ Recurso OpenAI encontrado: $OPENAI_RESOURCE_NAME"
    }
} catch {
    $openaiExists = $false
}

if (-not $openaiExists) {
    Write-Error2 "❌ Recurso Azure OpenAI '$OPENAI_RESOURCE_NAME' no encontrado"
    $createOpenAI = Read-Host "¿Deseas crearlo? (y/n)"
    if ($createOpenAI -eq "y" -or $createOpenAI -eq "Y") {
        Write-Info "Creando recurso Azure OpenAI..."
        az cognitiveservices account create `
          --name $OPENAI_RESOURCE_NAME `
          --resource-group $RESOURCE_GROUP `
          --kind OpenAI `
          --sku S0 `
          --location $LOCATION `
          --yes
        
        Write-Success "✅ Recurso OpenAI creado"
    } else {
        Write-Error2 "No se puede continuar sin el recurso OpenAI"
        exit 1
    }
}

# Obtener endpoint y key de OpenAI
Write-Info "🔑 Obteniendo credenciales de Azure OpenAI..."
$OPENAI_ENDPOINT = az cognitiveservices account show `
  --name $OPENAI_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "properties.endpoint" -o tsv

$OPENAI_API_KEY = az cognitiveservices account keys list `
  --name $OPENAI_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "key1" -o tsv

Write-Success "✅ Credenciales obtenidas"

# Verificar deployment del modelo
Write-Info "🔍 Verificando deployment del modelo '$OPENAI_DEPLOYMENT'..."
Write-Warning2 "⚠️  Asegúrate de que el deployment '$OPENAI_DEPLOYMENT' existe en Azure AI Studio"
Write-Warning2 "    URL: https://ai.azure.com"

# Configuración del Bot
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuración de Azure Bot Service"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""

$configureBotNow = Read-Host "¿Deseas configurar el Bot ahora? (y/n)"
if ($configureBotNow -eq "y" -or $configureBotNow -eq "Y") {
    $botInput = Read-Host "Nombre para el bot [teams-ai-foundry-bot]"
    $BOT_NAME = if ([string]::IsNullOrWhiteSpace($botInput)) { "teams-ai-foundry-bot" } else { $botInput }
    
    # Verificar si el bot existe
    $botExists = $false
    try {
        $botInfo = az bot show --resource-group $RESOURCE_GROUP --name $BOT_NAME 2>$null
        if ($LASTEXITCODE -eq 0) {
            $botExists = $true
            Write-Success "✅ Bot encontrado: $BOT_NAME"
            
            # Obtener App ID del bot existente
            $BOT_APP_ID = az bot show `
              --resource-group $RESOURCE_GROUP `
              --name $BOT_NAME `
              --query "properties.msaAppId" -o tsv
            
            Write-Info "App ID del bot: $BOT_APP_ID"
            $BOT_APP_PASSWORD = Read-Host "Ingresa el Microsoft App Password (Client Secret)" -AsSecureString
            $BOT_APP_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($BOT_APP_PASSWORD))
        }
    } catch {
        $botExists = $false
    }
    
    if (-not $botExists) {
        Write-Info "Creando nuevo bot..."
        
        # Crear App Registration
        $APP_DISPLAY_NAME = $BOT_NAME
        Write-Info "Creando App Registration..."
        $BOT_APP_ID = az ad app create `
          --display-name $APP_DISPLAY_NAME `
          --query appId -o tsv
        
        Write-Success "✅ App Registration creada: $BOT_APP_ID"
        
        # Crear client secret
        Write-Info "Creando client secret..."
        $BOT_APP_PASSWORD = az ad app credential reset `
          --id $BOT_APP_ID `
          --append `
          --years 2 `
          --query password -o tsv
        
        Write-Success "✅ Client Secret creado"
        Write-Warning2 "⚠️  IMPORTANTE: Guarda este password, no se mostrará de nuevo:"
        Write-Output "    $BOT_APP_PASSWORD"
        Write-Output ""
        Read-Host "Presiona Enter para continuar..."
        
        # Crear Azure Bot
        Write-Info "Creando Azure Bot..."
        az bot create `
          --resource-group $RESOURCE_GROUP `
          --name $BOT_NAME `
          --kind registration `
          --sku F0 `
          --appid $BOT_APP_ID `
          --endpoint "https://placeholder.azurewebsites.net/api/messages"
        
        Write-Success "✅ Azure Bot creado"
        
        # Habilitar canal de Teams
        Write-Info "Habilitando canal de Microsoft Teams..."
        az bot msteams create `
          --resource-group $RESOURCE_GROUP `
          --name $BOT_NAME `
          --enable-calling false
        
        Write-Success "✅ Canal de Teams habilitado"
    }
} else {
    Write-Warning2 "⚠️  Configuración del Bot omitida"
    Write-Output "   Deberás agregar manualmente MICROSOFT_APP_ID y MICROSOFT_APP_PASSWORD al .env"
    $BOT_APP_ID = "TU_MICROSOFT_APP_ID_AQUI"
    $BOT_APP_PASSWORD = "TU_MICROSOFT_APP_PASSWORD_AQUI"
    $BOT_NAME = "teams-ai-foundry-bot"
}

# Configuraciones adicionales
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuraciones Adicionales"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""

$contentSafetyInput = Read-Host "Habilitar Content Safety? (y/n) [y]"
$ENABLE_CONTENT_SAFETY = if ($contentSafetyInput -eq "n" -or $contentSafetyInput -eq "N") { "false" } else { "true" }

$tempInput = Read-Host "Temperatura del modelo [0.7]"
$APP_TEMPERATURE = if ([string]::IsNullOrWhiteSpace($tempInput)) { "0.7" } else { $tempInput }

$tokensInput = Read-Host "Máximo de tokens [2000]"
$APP_MAX_TOKENS = if ([string]::IsNullOrWhiteSpace($tokensInput)) { "2000" } else { $tokensInput }

$promptInput = Read-Host "System Prompt personalizado? (Enter para usar el predeterminado)"
$SYSTEM_PROMPT = if ([string]::IsNullOrWhiteSpace($promptInput)) { 
    "Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil." 
} else { 
    $promptInput 
}

# Generar archivo .env
Write-Output ""
Write-Info "📝 Generando archivo .env..."

$ENV_FILE_PATH = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath ".env"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$envContent = @"
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $timestamp
# Configuración: BotprojectTeam

# Azure AI Project Details
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_AI_PROJECT_NAME=$AI_PROJECT_NAME

# Azure AI Foundry Hub
AZURE_AI_HUB_NAME=$AI_HUB_NAME

# Discovery URL / Project Endpoint
AZURE_AI_PROJECT_ENDPOINT=$PROJECT_ENDPOINT

# Azure OpenAI Connection (desde AI Foundry)
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_API_KEY
AZURE_OPENAI_DEPLOYMENT_NAME=$OPENAI_DEPLOYMENT
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ===========================================
# Azure Bot Service Configuration
# ===========================================

# Microsoft App ID (Bot Application ID)
MICROSOFT_APP_ID=$BOT_APP_ID

# Microsoft App Password (Bot Client Secret)
MICROSOFT_APP_PASSWORD=$BOT_APP_PASSWORD

# Bot Endpoint (actualizar después del deployment)
BOT_ENDPOINT=https://tu-bot.azurewebsites.net/api/messages

# ===========================================
# Application Settings
# ===========================================

APP_TITLE=Teams AI Foundry Assistant - BotprojectTeam
APP_TEMPERATURE=$APP_TEMPERATURE
APP_MAX_TOKENS=$APP_MAX_TOKENS
LOG_LEVEL=INFO

# System Prompt
SYSTEM_PROMPT=$SYSTEM_PROMPT

# ===========================================
# Azure AI Foundry Features
# ===========================================

# Enable Content Safety
ENABLE_CONTENT_SAFETY=$ENABLE_CONTENT_SAFETY
CONTENT_SAFETY_THRESHOLD=medium

# Enable AI Search (RAG)
ENABLE_AI_SEARCH=false
AI_SEARCH_ENDPOINT=
AI_SEARCH_KEY=
AI_SEARCH_INDEX_NAME=

# Enable Prompt Flow
ENABLE_PROMPT_FLOW=false

# ===========================================
# Teams Settings
# ===========================================

TEAMS_APP_ID=
ENABLE_PROACTIVE_MESSAGES=false

# ===========================================
# Server Configuration
# ===========================================

BOT_PORT=3978
WEB_PORT=8501
HOST=0.0.0.0
ENVIRONMENT=development
"@

$envContent | Out-File -FilePath $ENV_FILE_PATH -Encoding UTF8

Write-Success "✅ Archivo .env generado exitosamente en:"
Write-Info "   $ENV_FILE_PATH"

# Resumen
Write-Output ""
Write-Success "========================================="
Write-Success "✅ Configuración Completada"
Write-Success "========================================="
Write-Output ""
Write-Info "📋 Resumen de la configuración:"
Write-Output ""
Write-Output "  Suscripción: $SUBSCRIPTION_ID"
Write-Output "  Resource Group: $RESOURCE_GROUP"
Write-Output "  Location: $LOCATION"
Write-Output "  AI Hub: $AI_HUB_NAME"
Write-Output "  AI Project: $AI_PROJECT_NAME"
Write-Output "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
Write-Output "  OpenAI Endpoint: $OPENAI_ENDPOINT"
Write-Output "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
Write-Output "  Bot Name: $BOT_NAME"
Write-Output "  Bot App ID: $BOT_APP_ID"
Write-Output ""
Write-Warning2 "⚠️  IMPORTANTE - Próximos pasos:"
Write-Output ""
Write-Output "1. Verifica que el deployment del modelo existe:"
Write-Info "   - Ve a https://ai.azure.com"
Write-Info "   - Selecciona el proyecto 'BotprojectTeam'"
Write-Info "   - Ve a 'Deployments' y verifica que existe '$OPENAI_DEPLOYMENT'"
Write-Output ""
Write-Output "2. Revisa tu archivo .env:"
Write-Info "   Get-Content .env"
Write-Output ""
Write-Output "3. Prueba la configuración:"
Write-Info "   python -c `"from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()`""
Write-Output ""
Write-Output "4. Instala las dependencias:"
Write-Info "   pip install -r requirements.txt"
Write-Output ""
Write-Output "5. Ejecuta el bot localmente:"
Write-Info "   python bot/bot_app.py"
Write-Output ""
Write-Output "6. Prueba el bot en Teams:"
Write-Info "   - Ve a https://dev.teams.microsoft.com/apps"
Write-Info "   - Configura tu app manifest con el Bot App ID: $BOT_APP_ID"
Write-Output ""
Write-Output "7. Despliega a Azure (cuando esté listo):"
Write-Info "   .\scripts\deploy.ps1"
Write-Output ""
Write-Success "¡Configuración exitosa! 🎉"
Write-Output ""
Write-Info "Archivo generado: $ENV_FILE_PATH"
Write-Output ""
