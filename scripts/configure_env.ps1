# Script para configurar automáticamente el archivo .env
# con valores obtenidos desde Azure
# Usage: .\configure_env.ps1

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
Write-Output "🔧 Configurador de .env para Teams AI Bot"
Write-Output "========================================="
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
az login --output table

if ($LASTEXITCODE -ne 0) {
    Write-Error2 "❌ Error al iniciar sesión en Azure"
    exit 1
}

Write-Success "✅ Login exitoso"

# Obtener lista de suscripciones
Write-Output ""
Write-Info "📋 Obteniendo suscripciones disponibles..."
az account list --query "[].{Name:name, ID:id, Default:isDefault}" -o table

# Preguntar si desea cambiar de suscripción
Write-Output ""
$changeSubscription = Read-Host "¿Deseas usar una suscripción diferente? (y/n)"
if ($changeSubscription -eq "y" -or $changeSubscription -eq "Y") {
    $subId = Read-Host "Ingresa el ID de la suscripción"
    az account set --subscription $subId
    Write-Success "✅ Suscripción cambiada"
}

# Obtener Subscription ID actual
$SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Success "Usando suscripción: $SUBSCRIPTION_ID"

# Preguntar por Resource Group
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuración de Resource Group"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""
Write-Output "Grupos de recursos existentes:"
az group list --query "[].{Name:name, Location:location}" -o table

Write-Output ""
$useExistingRG = Read-Host "¿Deseas usar un Resource Group existente? (y/n)"
if ($useExistingRG -eq "y" -or $useExistingRG -eq "Y") {
    $RESOURCE_GROUP = Read-Host "Nombre del Resource Group"
} else {
    $rgInput = Read-Host "Nombre para el nuevo Resource Group [rg-ai-foundry-teams]"
    $RESOURCE_GROUP = if ([string]::IsNullOrWhiteSpace($rgInput)) { "rg-ai-foundry-teams" } else { $rgInput }
    
    $locInput = Read-Host "Location [eastus]"
    $LOCATION = if ([string]::IsNullOrWhiteSpace($locInput)) { "eastus" } else { $locInput }
    
    Write-Info "Creando Resource Group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
    Write-Success "✅ Resource Group creado"
}

# Preguntar por Azure AI Foundry Hub y Project
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuración de Azure AI Foundry"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""

# Instalar/actualizar extensión de ML
Write-Info "Actualizando extensión de Azure ML..."
az extension add --name ml --upgrade --yes 2>$null

# Listar workspaces existentes
Write-Output ""
Write-Output "Workspaces de Azure AI existentes:"
try {
    az ml workspace list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:kind}" -o table
} catch {
    Write-Output "No hay workspaces existentes"
}

Write-Output ""
$useExistingAI = Read-Host "¿Deseas usar un AI Hub/Project existente? (y/n)"
if ($useExistingAI -eq "y" -or $useExistingAI -eq "Y") {
    $AI_HUB_NAME = Read-Host "Nombre del AI Hub"
    $AI_PROJECT_NAME = Read-Host "Nombre del AI Project"
} else {
    $hubInput = Read-Host "Nombre para el AI Hub [ai-foundry-hub]"
    $AI_HUB_NAME = if ([string]::IsNullOrWhiteSpace($hubInput)) { "ai-foundry-hub" } else { $hubInput }
    
    $projInput = Read-Host "Nombre para el AI Project [teams-bot-project]"
    $AI_PROJECT_NAME = if ([string]::IsNullOrWhiteSpace($projInput)) { "teams-bot-project" } else { $projInput }
    
    if ([string]::IsNullOrWhiteSpace($LOCATION)) {
        $LOCATION = "eastus"
    }
    
    Write-Info "Creando Azure AI Hub..."
    az ml workspace create `
      --kind hub `
      --resource-group $RESOURCE_GROUP `
      --name $AI_HUB_NAME `
      --location $LOCATION
    
    Write-Success "✅ AI Hub creado"
    
    Write-Info "Creando Azure AI Project..."
    az ml workspace create `
      --kind project `
      --resource-group $RESOURCE_GROUP `
      --name $AI_PROJECT_NAME `
      --hub-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.MachineLearningServices/workspaces/$AI_HUB_NAME" `
      --location $LOCATION
    
    Write-Success "✅ AI Project creado"
}

# Obtener Project Endpoint
Write-Info "Obteniendo información del proyecto..."
try {
    $PROJECT_ENDPOINT = az ml workspace show `
      --name $AI_PROJECT_NAME `
      --resource-group $RESOURCE_GROUP `
      --query "discovery_url" -o tsv
} catch {
    $PROJECT_ENDPOINT = ""
}

# Preguntar por Azure OpenAI
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuración de Azure OpenAI"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""

Write-Output "Recursos de Azure OpenAI existentes:"
try {
    az cognitiveservices account list `
      --resource-group $RESOURCE_GROUP `
      --query "[?kind=='OpenAI'].{Name:name, Location:location, Endpoint:properties.endpoint}" -o table
} catch {
    Write-Output "No hay recursos OpenAI existentes"
}

Write-Output ""
$useExistingOpenAI = Read-Host "¿Deseas usar un recurso OpenAI existente? (y/n)"
if ($useExistingOpenAI -eq "y" -or $useExistingOpenAI -eq "Y") {
    $OPENAI_RESOURCE_NAME = Read-Host "Nombre del recurso Azure OpenAI"
} else {
    $openaiInput = Read-Host "Nombre para el recurso Azure OpenAI [openai-$AI_PROJECT_NAME]"
    $OPENAI_RESOURCE_NAME = if ([string]::IsNullOrWhiteSpace($openaiInput)) { "openai-$AI_PROJECT_NAME" } else { $openaiInput }
    
    Write-Info "Creando recurso Azure OpenAI..."
    az cognitiveservices account create `
      --name $OPENAI_RESOURCE_NAME `
      --resource-group $RESOURCE_GROUP `
      --kind OpenAI `
      --sku S0 `
      --location $LOCATION `
      --yes
    
    Write-Success "✅ Recurso OpenAI creado"
}

# Obtener endpoint y key de OpenAI
Write-Info "Obteniendo credenciales de Azure OpenAI..."
$OPENAI_ENDPOINT = az cognitiveservices account show `
  --name $OPENAI_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "properties.endpoint" -o tsv

$OPENAI_API_KEY = az cognitiveservices account keys list `
  --name $OPENAI_RESOURCE_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "key1" -o tsv

# Preguntar por deployment de modelo
Write-Output ""
$deployInput = Read-Host "Nombre del deployment de modelo OpenAI [gpt-41-turbo]"
$OPENAI_DEPLOYMENT = if ([string]::IsNullOrWhiteSpace($deployInput)) { "gpt-41-turbo" } else { $deployInput }

Write-Warning2 "Nota: Asegúrate de crear el deployment '$OPENAI_DEPLOYMENT' en Azure AI Studio"
Write-Warning2 "URL: https://ai.azure.com"

# Preguntar por Azure Bot Service
Write-Output ""
Write-Warning2 "════════════════════════════════════════"
Write-Warning2 "  Configuración de Azure Bot Service"
Write-Warning2 "════════════════════════════════════════"
Write-Output ""

Write-Output "Bots existentes:"
try {
    az bot show --resource-group $RESOURCE_GROUP --name teams-ai-foundry-bot --query "{Name:name, Endpoint:properties.endpoint}" -o table
} catch {
    Write-Output "No hay bots existentes"
}

Write-Output ""
$useExistingBot = Read-Host "¿Deseas usar un bot existente? (y/n)"
if ($useExistingBot -eq "y" -or $useExistingBot -eq "Y") {
    $BOT_NAME = Read-Host "Nombre del bot"
    
    # Intentar obtener App ID del bot existente
    try {
        $BOT_APP_ID = az bot show `
          --resource-group $RESOURCE_GROUP `
          --name $BOT_NAME `
          --query "properties.msaAppId" -o tsv
    } catch {
        $BOT_APP_ID = ""
    }
    
    if ([string]::IsNullOrWhiteSpace($BOT_APP_ID)) {
        $BOT_APP_ID = Read-Host "Ingresa el Microsoft App ID del bot"
    }
    
    $BOT_APP_PASSWORD = Read-Host "Ingresa el Microsoft App Password (Client Secret)" -AsSecureString
    $BOT_APP_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($BOT_APP_PASSWORD))
} else {
    $botInput = Read-Host "Nombre para el bot [teams-ai-foundry-bot]"
    $BOT_NAME = if ([string]::IsNullOrWhiteSpace($botInput)) { "teams-ai-foundry-bot" } else { $botInput }
    
    Write-Info "Creando App Registration..."
    
    # Crear App Registration
    $APP_DISPLAY_NAME = $BOT_NAME
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

$promptInput = Read-Host "System Prompt [Eres un asistente inteligente...]"
$SYSTEM_PROMPT = if ([string]::IsNullOrWhiteSpace($promptInput)) { 
    "Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil." 
} else { 
    $promptInput 
}

# Generar archivo .env
Write-Output ""
Write-Info "📝 Generando archivo .env..."

$ENV_FILE = ".env"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$envContent = @"
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $timestamp

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

APP_TITLE=Teams AI Foundry Assistant
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

$envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8

Write-Success "✅ Archivo .env generado exitosamente"

# Resumen
Write-Output ""
Write-Success "========================================="
Write-Success "✅ Configuración Completada"
Write-Success "========================================="
Write-Output ""
Write-Info "📋 Resumen de la configuración:"
Write-Output ""
Write-Output "  Azure Subscription: $SUBSCRIPTION_ID"
Write-Output "  Resource Group: $RESOURCE_GROUP"
Write-Output "  AI Hub: $AI_HUB_NAME"
Write-Output "  AI Project: $AI_PROJECT_NAME"
Write-Output "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
Write-Output "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
Write-Output "  Bot Name: $BOT_NAME"
Write-Output "  Bot App ID: $BOT_APP_ID"
Write-Output ""
Write-Warning2 "⚠️  IMPORTANTE - Próximos pasos:"
Write-Output ""
Write-Output "1. Ve a Azure AI Studio: https://ai.azure.com"
Write-Output "   - Despliega el modelo '$OPENAI_DEPLOYMENT' si aún no existe"
Write-Output ""
Write-Output "2. Verifica tu archivo .env:"
Write-Info "   Get-Content .env"
Write-Output ""
Write-Output "3. Prueba la configuración:"
Write-Info "   python -c `"from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()`""
Write-Output ""
Write-Output "4. Ejecuta el bot localmente:"
Write-Info "   python bot/bot_app.py"
Write-Output ""
Write-Output "5. Despliega a Azure:"
Write-Info "   .\scripts\deploy.ps1"
Write-Output ""
Write-Success "¡Configuración exitosa! 🎉"
Write-Output ""
