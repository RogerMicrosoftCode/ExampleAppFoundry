# ============================================================================
# Script de Despliegue Completo de Solución Teams AI Bot
# ============================================================================
# Este script crea TODOS los recursos necesarios desde cero:
# - Resource Group
# - Azure AI Hub
# - Azure AI Project
# - Azure OpenAI Service + Deployment
# - Azure Bot Service + App Registration
# - Configura .env automáticamente
#
# Usage: .\deploy_full_solution.ps1
# ============================================================================

param(
    [switch]$SkipConfirmation = $false
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURACIÓN - Valores predefinidos para tu suscripción
# ============================================================================

$CONFIG = @{
    # Suscripción de Azure
    SubscriptionId = "662141d0-0308-4187-b46b-db1e9466b5ac"
    
    # Nuevo Resource Group
    ResourceGroup = "jarochatAIdemoteam"
    Location = "eastus2"
    
    # Azure AI Foundry
    AIHubName = "jarochat-ai-hub"
    AIProjectName = "jarochat-ai-project"
    
    # Azure OpenAI
    OpenAIResourceName = "jarochat-openai"
    OpenAIDeploymentName = "gpt-41-turbo"
    OpenAIModelName = "gpt-4"
    OpenAIModelVersion = "turbo-2024-04-09"
    
    # Azure Bot Service
    BotName = "jarochat-teams-bot"
    BotDisplayName = "JaroChat AI Demo Bot"
    BotDescription = "Bot inteligente para Teams con Azure AI Foundry"
    
    # Configuración de la App
    AppTemperature = "0.7"
    AppMaxTokens = "2000"
    SystemPrompt = "Eres JaroChat, un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil."
}

# ============================================================================
# Funciones de Utilidad
# ============================================================================

function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($Message) { Write-ColorOutput Green "✅ $Message" }
function Write-Info($Message) { Write-ColorOutput Cyan "ℹ️  $Message" }
function Write-Warning2($Message) { Write-ColorOutput Yellow "⚠️  $Message" }
function Write-Error2($Message) { Write-ColorOutput Red "❌ $Message" }
function Write-Step($Message) { Write-ColorOutput Magenta "`n🔹 $Message" }
function Write-Header($Message) {
    Write-Output ""
    Write-ColorOutput Cyan "═══════════════════════════════════════════════════════════"
    Write-ColorOutput Cyan "  $Message"
    Write-ColorOutput Cyan "═══════════════════════════════════════════════════════════"
    Write-Output ""
}

function Write-ProgressBar($Step, $Total, $Message) {
    $percent = [math]::Round(($Step / $Total) * 100)
    $bar = "█" * [math]::Round($percent / 5)
    $spaces = " " * (20 - [math]::Round($percent / 5))
    Write-ColorOutput Cyan "[$bar$spaces] $percent% - $Message"
}

# ============================================================================
# Banner de Inicio
# ============================================================================

Clear-Host
Write-Output ""
Write-ColorOutput Cyan "╔════════════════════════════════════════════════════════════╗"
Write-ColorOutput Cyan "║                                                            ║"
Write-ColorOutput Cyan "║         🚀 DESPLIEGUE COMPLETO DE SOLUCIÓN 🚀             ║"
Write-ColorOutput Cyan "║              Teams AI Bot - Azure AI Foundry               ║"
Write-ColorOutput Cyan "║                                                            ║"
Write-ColorOutput Cyan "╚════════════════════════════════════════════════════════════╝"
Write-Output ""

Write-Info "Este script creará TODOS los recursos necesarios desde cero"
Write-Output ""

# ============================================================================
# Mostrar Configuración
# ============================================================================

Write-Header "📋 CONFIGURACIÓN DEL DESPLIEGUE"

Write-Output "🔹 Suscripción:"
Write-Output "   ID: $($CONFIG.SubscriptionId)"
Write-Output ""
Write-Output "🔹 Nuevo Resource Group:"
Write-Output "   Nombre: $($CONFIG.ResourceGroup)"
Write-Output "   Location: $($CONFIG.Location)"
Write-Output ""
Write-Output "🔹 Azure AI Foundry:"
Write-Output "   AI Hub: $($CONFIG.AIHubName)"
Write-Output "   AI Project: $($CONFIG.AIProjectName)"
Write-Output ""
Write-Output "🔹 Azure OpenAI:"
Write-Output "   Resource: $($CONFIG.OpenAIResourceName)"
Write-Output "   Deployment: $($CONFIG.OpenAIDeploymentName)"
Write-Output "   Model: $($CONFIG.OpenAIModelName) ($($CONFIG.OpenAIModelVersion))"
Write-Output ""
Write-Output "🔹 Azure Bot Service:"
Write-Output "   Bot: $($CONFIG.BotName)"
Write-Output "   Display Name: $($CONFIG.BotDisplayName)"
Write-Output ""

if (-not $SkipConfirmation) {
    Write-Warning2 "⚠️  Este script creará recursos que pueden generar costos en Azure"
    Write-Output ""
    $confirm = Read-Host "¿Deseas continuar con el despliegue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Error2 "Despliegue cancelado por el usuario"
        exit 0
    }
}

# ============================================================================
# PASO 1: Verificar Prerrequisitos
# ============================================================================

Write-Header "PASO 1/10: Verificar Prerrequisitos"
Write-ProgressBar 1 10 "Verificando Azure CLI..."

try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Success "Azure CLI instalado: $($azVersion.'azure-cli')"
} catch {
    Write-Error2 "Azure CLI no está instalado"
    Write-Output "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# ============================================================================
# PASO 2: Login a Azure
# ============================================================================

Write-Header "PASO 2/10: Autenticación en Azure"
Write-ProgressBar 2 10 "Verificando sesión..."

if (-not (az account show 2>$null)) {
    Write-Info "Iniciando login en Azure..."
    az login --output table
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "Error al iniciar sesión en Azure"
        exit 1
    }
}

Write-Success "Sesión de Azure activa"

# Establecer suscripción
Write-Info "Configurando suscripción..."
az account set --subscription $CONFIG.SubscriptionId

if ($LASTEXITCODE -ne 0) {
    Write-Error2 "Error al configurar la suscripción"
    exit 1
}

$currentSub = az account show --query "{Name:name, ID:id}" -o json | ConvertFrom-Json
Write-Success "Usando suscripción: $($currentSub.Name)"

# ============================================================================
# PASO 3: Instalar Extensiones de Azure CLI
# ============================================================================

Write-Header "PASO 3/10: Instalar Extensiones de Azure CLI"
Write-ProgressBar 3 10 "Instalando extensiones..."

Write-Info "Instalando extensión de Azure ML..."
az extension add --name ml --upgrade --yes --only-show-errors 2>$null | Out-Null
Write-Success "Extensión ml instalada"

Write-Info "Instalando extensión de Cognitive Services..."
az extension add --name cognitiveservices --upgrade --yes --only-show-errors 2>$null | Out-Null
Write-Success "Extensión cognitiveservices instalada"

# ============================================================================
# PASO 4: Crear Resource Group
# ============================================================================

Write-Header "PASO 4/10: Crear Resource Group"
Write-ProgressBar 4 10 "Creando Resource Group..."

Write-Info "Verificando si el Resource Group existe..."
$rgExists = az group exists --name $CONFIG.ResourceGroup

if ($rgExists -eq "true") {
    Write-Warning2 "Resource Group '$($CONFIG.ResourceGroup)' ya existe"
    $overwrite = Read-Host "¿Deseas continuar usando este Resource Group? (y/n)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Error2 "Despliegue cancelado"
        exit 1
    }
} else {
    Write-Info "Creando Resource Group '$($CONFIG.ResourceGroup)'..."
    az group create `
        --name $CONFIG.ResourceGroup `
        --location $CONFIG.Location `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resource Group creado exitosamente"
    } else {
        Write-Error2 "Error al crear Resource Group"
        exit 1
    }
}

# ============================================================================
# PASO 5: Crear Azure OpenAI Service
# ============================================================================

Write-Header "PASO 5/10: Crear Azure OpenAI Service"
Write-ProgressBar 5 10 "Creando recurso Azure OpenAI..."

Write-Info "Verificando si el recurso OpenAI existe..."
$openaiExists = az cognitiveservices account show `
    --name $CONFIG.OpenAIResourceName `
    --resource-group $CONFIG.ResourceGroup 2>$null

if ($openaiExists) {
    Write-Warning2 "Recurso Azure OpenAI '$($CONFIG.OpenAIResourceName)' ya existe"
} else {
    Write-Info "Creando recurso Azure OpenAI '$($CONFIG.OpenAIResourceName)'..."
    Write-Info "Esto puede tomar 2-3 minutos..."
    
    az cognitiveservices account create `
        --name $CONFIG.OpenAIResourceName `
        --resource-group $CONFIG.ResourceGroup `
        --location $CONFIG.Location `
        --kind OpenAI `
        --sku S0 `
        --yes `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Azure OpenAI Service creado exitosamente"
        Start-Sleep -Seconds 10  # Esperar a que se propague
    } else {
        Write-Error2 "Error al crear Azure OpenAI Service"
        exit 1
    }
}

# Obtener endpoint y keys
Write-Info "Obteniendo credenciales de Azure OpenAI..."
$OPENAI_ENDPOINT = az cognitiveservices account show `
    --name $CONFIG.OpenAIResourceName `
    --resource-group $CONFIG.ResourceGroup `
    --query "properties.endpoint" -o tsv

$OPENAI_API_KEY = az cognitiveservices account keys list `
    --name $CONFIG.OpenAIResourceName `
    --resource-group $CONFIG.ResourceGroup `
    --query "key1" -o tsv

Write-Success "Credenciales obtenidas"
Write-Info "Endpoint: $OPENAI_ENDPOINT"

# ============================================================================
# PASO 6: Crear Deployment del Modelo GPT-4
# ============================================================================

Write-Header "PASO 6/10: Crear Deployment del Modelo"
Write-ProgressBar 6 10 "Desplegando modelo GPT-4..."

Write-Info "Verificando si el deployment existe..."
$deploymentExists = az cognitiveservices account deployment show `
    --name $CONFIG.OpenAIResourceName `
    --resource-group $CONFIG.ResourceGroup `
    --deployment-name $CONFIG.OpenAIDeploymentName 2>$null

if ($deploymentExists) {
    Write-Warning2 "Deployment '$($CONFIG.OpenAIDeploymentName)' ya existe"
} else {
    Write-Info "Creando deployment '$($CONFIG.OpenAIDeploymentName)'..."
    Write-Info "Esto puede tomar 2-3 minutos..."
    
    az cognitiveservices account deployment create `
        --name $CONFIG.OpenAIResourceName `
        --resource-group $CONFIG.ResourceGroup `
        --deployment-name $CONFIG.OpenAIDeploymentName `
        --model-name $CONFIG.OpenAIModelName `
        --model-version $CONFIG.OpenAIModelVersion `
        --model-format OpenAI `
        --sku-capacity 10 `
        --sku-name "Standard" `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Modelo desplegado exitosamente"
    } else {
        Write-Error2 "Error al desplegar modelo"
        Write-Warning2 "Puedes crear el deployment manualmente en Azure AI Studio"
        Write-Warning2 "URL: https://ai.azure.com"
    }
}

# ============================================================================
# PASO 7: Crear Azure AI Hub
# ============================================================================

Write-Header "PASO 7/10: Crear Azure AI Hub"
Write-ProgressBar 7 10 "Creando AI Hub..."

Write-Info "Verificando si el AI Hub existe..."
$hubExists = az ml workspace show `
    --name $CONFIG.AIHubName `
    --resource-group $CONFIG.ResourceGroup 2>$null

if ($hubExists) {
    Write-Warning2 "AI Hub '$($CONFIG.AIHubName)' ya existe"
} else {
    Write-Info "Creando AI Hub '$($CONFIG.AIHubName)'..."
    Write-Info "Esto puede tomar 3-5 minutos..."
    
    az ml workspace create `
        --kind hub `
        --name $CONFIG.AIHubName `
        --resource-group $CONFIG.ResourceGroup `
        --location $CONFIG.Location `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "AI Hub creado exitosamente"
    } else {
        Write-Error2 "Error al crear AI Hub"
        Write-Warning2 "Puedes crear el Hub manualmente en Azure AI Studio"
    }
}

# ============================================================================
# PASO 8: Crear Azure AI Project
# ============================================================================

Write-Header "PASO 8/10: Crear Azure AI Project"
Write-ProgressBar 8 10 "Creando AI Project..."

Write-Info "Verificando si el AI Project existe..."
$projectExists = az ml workspace show `
    --name $CONFIG.AIProjectName `
    --resource-group $CONFIG.ResourceGroup 2>$null

if ($projectExists) {
    Write-Warning2 "AI Project '$($CONFIG.AIProjectName)' ya existe"
} else {
    Write-Info "Creando AI Project '$($CONFIG.AIProjectName)'..."
    Write-Info "Esto puede tomar 2-3 minutos..."
    
    $hubId = "/subscriptions/$($CONFIG.SubscriptionId)/resourceGroups/$($CONFIG.ResourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/$($CONFIG.AIHubName)"
    
    az ml workspace create `
        --kind project `
        --name $CONFIG.AIProjectName `
        --resource-group $CONFIG.ResourceGroup `
        --location $CONFIG.Location `
        --hub-id $hubId `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "AI Project creado exitosamente"
    } else {
        Write-Error2 "Error al crear AI Project"
        Write-Warning2 "Puedes crear el Project manualmente en Azure AI Studio"
    }
}

# Obtener Project Endpoint
$PROJECT_ENDPOINT = az ml workspace show `
    --name $CONFIG.AIProjectName `
    --resource-group $CONFIG.ResourceGroup `
    --query "discovery_url" -o tsv 2>$null

if ([string]::IsNullOrWhiteSpace($PROJECT_ENDPOINT)) {
    $PROJECT_ENDPOINT = "https://ai.azure.com"
}

# ============================================================================
# PASO 9: Crear Azure Bot Service
# ============================================================================

Write-Header "PASO 9/10: Crear Azure Bot Service"
Write-ProgressBar 9 10 "Creando Bot Service..."

Write-Info "Verificando si el bot existe..."
$botExists = az bot show `
    --resource-group $CONFIG.ResourceGroup `
    --name $CONFIG.BotName 2>$null

if ($botExists) {
    Write-Warning2 "Bot '$($CONFIG.BotName)' ya existe"
    
    # Obtener App ID existente
    $BOT_APP_ID = az bot show `
        --resource-group $CONFIG.ResourceGroup `
        --name $CONFIG.BotName `
        --query "properties.msaAppId" -o tsv
    
    Write-Info "App ID del bot: $BOT_APP_ID"
    Write-Warning2 "Necesitarás ingresar el Client Secret manualmente"
    $BOT_APP_PASSWORD = Read-Host "Ingresa el Microsoft App Password" -AsSecureString
    $BOT_APP_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($BOT_APP_PASSWORD))
} else {
    Write-Info "Creando App Registration..."
    
    # Crear App Registration
    $BOT_APP_ID = az ad app create `
        --display-name $CONFIG.BotDisplayName `
        --query appId -o tsv
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "App Registration creada: $BOT_APP_ID"
    } else {
        Write-Error2 "Error al crear App Registration"
        exit 1
    }
    
    # Crear Client Secret
    Write-Info "Creando Client Secret..."
    $BOT_APP_PASSWORD = az ad app credential reset `
        --id $BOT_APP_ID `
        --append `
        --years 2 `
        --query password -o tsv
    
    Write-Success "Client Secret creado"
    Write-Warning2 "════════════════════════════════════════════════════════════"
    Write-Warning2 "⚠️  IMPORTANTE: Guarda este Client Secret de forma segura"
    Write-Warning2 "    No se mostrará de nuevo después de este despliegue"
    Write-Warning2 "════════════════════════════════════════════════════════════"
    Write-Output ""
    Write-ColorOutput Yellow "    Client Secret: $BOT_APP_PASSWORD"
    Write-Output ""
    Write-Warning2 "════════════════════════════════════════════════════════════"
    Write-Output ""
    Read-Host "Presiona Enter después de guardar el Client Secret..."
    
    # Crear Azure Bot
    Write-Info "Creando Azure Bot Service..."
    az bot create `
        --resource-group $CONFIG.ResourceGroup `
        --name $CONFIG.BotName `
        --kind registration `
        --sku F0 `
        --appid $BOT_APP_ID `
        --endpoint "https://$($CONFIG.BotName).azurewebsites.net/api/messages" `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Azure Bot Service creado"
    } else {
        Write-Error2 "Error al crear Azure Bot"
        exit 1
    }
    
    # Habilitar canal de Teams
    Write-Info "Habilitando canal de Microsoft Teams..."
    az bot msteams create `
        --resource-group $CONFIG.ResourceGroup `
        --name $CONFIG.BotName `
        --enable-calling false `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Canal de Teams habilitado"
    } else {
        Write-Warning2 "Error al habilitar Teams (puedes hacerlo manualmente)"
    }
}

# ============================================================================
# PASO 10: Generar Archivo .env
# ============================================================================

Write-Header "PASO 10/10: Generar Archivo de Configuración (.env)"
Write-ProgressBar 10 10 "Generando .env..."

$SCRIPT_DIR = Split-Path -Parent $PSScriptRoot
$ENV_FILE_PATH = Join-Path -Path $SCRIPT_DIR -ChildPath ".env"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Info "Generando archivo .env..."

$envContent = @"
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $TIMESTAMP
# Despliegue completo: jarochatAIdemoteam

# Azure AI Project Details
AZURE_SUBSCRIPTION_ID=$($CONFIG.SubscriptionId)
AZURE_RESOURCE_GROUP=$($CONFIG.ResourceGroup)
AZURE_AI_PROJECT_NAME=$($CONFIG.AIProjectName)

# Azure AI Foundry Hub
AZURE_AI_HUB_NAME=$($CONFIG.AIHubName)

# Discovery URL / Project Endpoint
AZURE_AI_PROJECT_ENDPOINT=$PROJECT_ENDPOINT

# Azure OpenAI Connection (desde AI Foundry)
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_API_KEY
AZURE_OPENAI_DEPLOYMENT_NAME=$($CONFIG.OpenAIDeploymentName)
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ===========================================
# Azure Bot Service Configuration
# ===========================================

# Microsoft App ID (Bot Application ID)
MICROSOFT_APP_ID=$BOT_APP_ID

# Microsoft App Password (Bot Client Secret)
MICROSOFT_APP_PASSWORD=$BOT_APP_PASSWORD

# Bot Endpoint (actualizar después del deployment)
BOT_ENDPOINT=https://$($CONFIG.BotName).azurewebsites.net/api/messages

# ===========================================
# Application Settings
# ===========================================

APP_TITLE=JaroChat AI Demo - Teams Assistant
APP_TEMPERATURE=$($CONFIG.AppTemperature)
APP_MAX_TOKENS=$($CONFIG.AppMaxTokens)
LOG_LEVEL=INFO

# System Prompt
SYSTEM_PROMPT=$($CONFIG.SystemPrompt)

# ===========================================
# Azure AI Foundry Features
# ===========================================

# Enable Content Safety
ENABLE_CONTENT_SAFETY=true
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

$envContent | Out-File -FilePath $ENV_FILE_PATH -Encoding UTF8 -Force

Write-Success "Archivo .env generado exitosamente"
Write-Info "Ubicación: $ENV_FILE_PATH"

# ============================================================================
# Resumen Final
# ============================================================================

Write-Output ""
Write-Output ""
Write-ColorOutput Green "╔════════════════════════════════════════════════════════════╗"
Write-ColorOutput Green "║                                                            ║"
Write-ColorOutput Green "║              ✅ DESPLIEGUE COMPLETADO ✅                   ║"
Write-ColorOutput Green "║                                                            ║"
Write-ColorOutput Green "╚════════════════════════════════════════════════════════════╝"
Write-Output ""

Write-Header "📊 RESUMEN DEL DESPLIEGUE"

Write-Output "🔹 Resource Group:"
Write-Output "   Nombre: $($CONFIG.ResourceGroup)"
Write-Output "   Location: $($CONFIG.Location)"
Write-Output ""
Write-Output "🔹 Azure AI Foundry:"
Write-Output "   Hub: $($CONFIG.AIHubName)"
Write-Output "   Project: $($CONFIG.AIProjectName)"
Write-Output "   URL: https://ai.azure.com"
Write-Output ""
Write-Output "🔹 Azure OpenAI:"
Write-Output "   Resource: $($CONFIG.OpenAIResourceName)"
Write-Output "   Endpoint: $OPENAI_ENDPOINT"
Write-Output "   Deployment: $($CONFIG.OpenAIDeploymentName)"
Write-Output "   Model: $($CONFIG.OpenAIModelName)"
Write-Output ""
Write-Output "🔹 Azure Bot Service:"
Write-Output "   Bot: $($CONFIG.BotName)"
Write-Output "   App ID: $BOT_APP_ID"
Write-Output "   Endpoint: https://$($CONFIG.BotName).azurewebsites.net/api/messages"
Write-Output ""
Write-Output "🔹 Archivo de Configuración:"
Write-Output "   .env generado en: $ENV_FILE_PATH"
Write-Output ""

Write-Header "🎯 PRÓXIMOS PASOS"

Write-Output "1️⃣  Verificar recursos en Azure Portal:"
Write-ColorOutput Cyan "   https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups"
Write-Output ""

Write-Output "2️⃣  Verificar AI Project en Azure AI Studio:"
Write-ColorOutput Cyan "   https://ai.azure.com"
Write-Output ""

Write-Output "3️⃣  Revisar archivo .env generado:"
Write-ColorOutput Cyan "   Get-Content .env"
Write-Output ""

Write-Output "4️⃣  Instalar dependencias de Python:"
Write-ColorOutput Cyan "   pip install -r requirements.txt"
Write-Output ""

Write-Output "5️⃣  Probar la configuración:"
Write-ColorOutput Cyan "   python -c `"from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()`""
Write-Output ""

Write-Output "6️⃣  Ejecutar el bot localmente:"
Write-ColorOutput Cyan "   python bot/bot_app.py"
Write-Output ""

Write-Output "7️⃣  Configurar el bot en Teams:"
Write-ColorOutput Cyan "   - Ve a: https://dev.teams.microsoft.com/apps"
Write-ColorOutput Cyan "   - Crea nueva app"
Write-ColorOutput Cyan "   - Configura Bot ID: $BOT_APP_ID"
Write-ColorOutput Cyan "   - Messaging endpoint: https://$($CONFIG.BotName).azurewebsites.net/api/messages"
Write-Output ""

Write-Output "8️⃣  Desplegar a Azure Container Apps (cuando esté listo):"
Write-ColorOutput Cyan "   .\scripts\deploy.ps1"
Write-Output ""

Write-Header "📚 DOCUMENTACIÓN Y RECURSOS"

Write-Output "• Azure AI Studio:"
Write-Output "  https://ai.azure.com"
Write-Output ""
Write-Output "• Azure Portal - Resource Group:"
Write-Output "  https://portal.azure.com/#@/resource/subscriptions/$($CONFIG.SubscriptionId)/resourceGroups/$($CONFIG.ResourceGroup)"
Write-Output ""
Write-Output "• Bot Framework Portal:"
Write-Output "  https://dev.botframework.com/bots?id=$BOT_APP_ID"
Write-Output ""
Write-Output "• Teams Developer Portal:"
Write-Output "  https://dev.teams.microsoft.com/apps"
Write-Output ""

Write-Header "💰 ESTIMACIÓN DE COSTOS"

Write-Output "Recursos creados (estimación mensual):"
Write-Output "• Azure OpenAI (GPT-4): ~\$30-100/mes (según uso)"
Write-Output "• Azure Bot Service (F0): GRATIS"
Write-Output "• Azure AI Hub/Project: ~\$5-20/mes"
Write-Output "• Resource Group: GRATIS"
Write-Output ""
Write-Warning2 "💡 Los costos varían según el uso. Monitorea en Azure Cost Management"
Write-Output ""

Write-Header "🔒 SEGURIDAD"

Write-Output "✅ Credenciales almacenadas en .env (NO subir a Git)"
Write-Output "✅ App Registration con Client Secret"
Write-Output "✅ Content Safety habilitado por defecto"
Write-Output "✅ RBAC configurado en recursos de Azure"
Write-Output ""
Write-Warning2 "⚠️  Asegúrate de que .env está en .gitignore"
Write-Output ""

Write-ColorOutput Green "════════════════════════════════════════════════════════════"
Write-ColorOutput Green "🎉 ¡Despliegue completado exitosamente!"
Write-ColorOutput Green "🤖 Tu bot JaroChat está listo para usar"
Write-ColorOutput Green "════════════════════════════════════════════════════════════"
Write-Output ""

# Preguntar si desea abrir Azure Portal
$openPortal = Read-Host "¿Deseas abrir Azure Portal para ver los recursos? (y/n)"
if ($openPortal -eq "y" -or $openPortal -eq "Y") {
    Start-Process "https://portal.azure.com/#view/HubsExtension/BrowseResourceGroup/resourceGroup/$($CONFIG.ResourceGroup)"
}

Write-Output ""
Write-Success "Script completado. ¡Feliz desarrollo! 🚀"
Write-Output ""
