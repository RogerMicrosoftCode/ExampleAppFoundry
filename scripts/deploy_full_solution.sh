#!/bin/bash
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
# Usage: ./deploy_full_solution.sh
# ============================================================================

set -e

# ============================================================================
# CONFIGURACIÓN - Valores predefinidos
# ============================================================================

SUBSCRIPTION_ID="662141d0-0308-4187-b46b-db1e9466b5ac"
RESOURCE_GROUP="jarochatAIdemoteam"
LOCATION="eastus2"

AI_HUB_NAME="jarochat-ai-hub"
AI_PROJECT_NAME="jarochat-ai-project"

OPENAI_RESOURCE_NAME="jarochat-openai"
OPENAI_DEPLOYMENT_NAME="gpt-41-turbo"
OPENAI_MODEL_NAME="gpt-4"
OPENAI_MODEL_VERSION="turbo-2024-04-09"

BOT_NAME="jarochat-teams-bot"
BOT_DISPLAY_NAME="JaroChat AI Demo Bot"

APP_TEMPERATURE="0.7"
APP_MAX_TOKENS="2000"
SYSTEM_PROMPT="Eres JaroChat, un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil."

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================================================
# Banner de Inicio
# ============================================================================

clear
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║         🚀 DESPLIEGUE COMPLETO DE SOLUCIÓN 🚀             ║${NC}"
echo -e "${CYAN}║              Teams AI Bot - Azure AI Foundry               ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}ℹ️  Este script creará TODOS los recursos necesarios desde cero${NC}"
echo ""

# ============================================================================
# Mostrar Configuración
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📋 CONFIGURACIÓN DEL DESPLIEGUE${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "🔹 Suscripción:"
echo "   ID: $SUBSCRIPTION_ID"
echo ""
echo "🔹 Nuevo Resource Group:"
echo "   Nombre: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo ""
echo "🔹 Azure AI Foundry:"
echo "   AI Hub: $AI_HUB_NAME"
echo "   AI Project: $AI_PROJECT_NAME"
echo ""
echo "🔹 Azure OpenAI:"
echo "   Resource: $OPENAI_RESOURCE_NAME"
echo "   Deployment: $OPENAI_DEPLOYMENT_NAME"
echo "   Model: $OPENAI_MODEL_NAME ($OPENAI_MODEL_VERSION)"
echo ""
echo "🔹 Azure Bot Service:"
echo "   Bot: $BOT_NAME"
echo "   Display Name: $BOT_DISPLAY_NAME"
echo ""

echo -e "${YELLOW}⚠️  Este script creará recursos que pueden generar costos en Azure${NC}"
echo ""
read -p "¿Deseas continuar con el despliegue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}❌ Despliegue cancelado por el usuario${NC}"
    exit 0
fi

# ============================================================================
# PASO 1: Verificar Prerrequisitos
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 1/10: Verificar Prerrequisitos${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI no está instalado${NC}"
    echo "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null)
echo -e "${GREEN}✅ Azure CLI instalado: $AZ_VERSION${NC}"

# ============================================================================
# PASO 2: Login a Azure
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 2/10: Autenticación en Azure${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if ! az account show &> /dev/null; then
    echo -e "${CYAN}ℹ️  Iniciando login en Azure...${NC}"
    az login --output table
fi

echo -e "${GREEN}✅ Sesión de Azure activa${NC}"

echo -e "${CYAN}ℹ️  Configurando suscripción...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"
echo -e "${GREEN}✅ Suscripción configurada${NC}"

# ============================================================================
# PASO 3: Instalar Extensiones
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 3/10: Instalar Extensiones de Azure CLI${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}ℹ️  Instalando extensión de Azure ML...${NC}"
az extension add --name ml --upgrade --yes --only-show-errors 2>/dev/null || true
echo -e "${GREEN}✅ Extensión ml instalada${NC}"

# ============================================================================
# PASO 4: Crear Resource Group
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 4/10: Crear Resource Group${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")
if [ "$RG_EXISTS" = "true" ]; then
    echo -e "${YELLOW}⚠️  Resource Group '$RESOURCE_GROUP' ya existe${NC}"
    read -p "¿Deseas continuar usando este Resource Group? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo -e "${RED}❌ Despliegue cancelado${NC}"
        exit 1
    fi
else
    echo -e "${CYAN}ℹ️  Creando Resource Group '$RESOURCE_GROUP'...${NC}"
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    echo -e "${GREEN}✅ Resource Group creado exitosamente${NC}"
fi

# ============================================================================
# PASO 5: Crear Azure OpenAI Service
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 5/10: Crear Azure OpenAI Service${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if az cognitiveservices account show \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Recurso Azure OpenAI '$OPENAI_RESOURCE_NAME' ya existe${NC}"
else
    echo -e "${CYAN}ℹ️  Creando recurso Azure OpenAI '$OPENAI_RESOURCE_NAME'...${NC}"
    echo -e "${CYAN}ℹ️  Esto puede tomar 2-3 minutos...${NC}"
    
    az cognitiveservices account create \
        --name "$OPENAI_RESOURCE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --kind OpenAI \
        --sku S0 \
        --yes \
        --output none
    
    echo -e "${GREEN}✅ Azure OpenAI Service creado exitosamente${NC}"
    sleep 10
fi

echo -e "${CYAN}ℹ️  Obteniendo credenciales de Azure OpenAI...${NC}"
OPENAI_ENDPOINT=$(az cognitiveservices account show \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.endpoint" -o tsv)

OPENAI_API_KEY=$(az cognitiveservices account keys list \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "key1" -o tsv)

echo -e "${GREEN}✅ Credenciales obtenidas${NC}"
echo -e "${CYAN}ℹ️  Endpoint: $OPENAI_ENDPOINT${NC}"

# ============================================================================
# PASO 6: Crear Deployment del Modelo
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 6/10: Crear Deployment del Modelo${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if az cognitiveservices account deployment show \
    --name "$OPENAI_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --deployment-name "$OPENAI_DEPLOYMENT_NAME" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Deployment '$OPENAI_DEPLOYMENT_NAME' ya existe${NC}"
else
    echo -e "${CYAN}ℹ️  Creando deployment '$OPENAI_DEPLOYMENT_NAME'...${NC}"
    echo -e "${CYAN}ℹ️  Esto puede tomar 2-3 minutos...${NC}"
    
    az cognitiveservices account deployment create \
        --name "$OPENAI_RESOURCE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --deployment-name "$OPENAI_DEPLOYMENT_NAME" \
        --model-name "$OPENAI_MODEL_NAME" \
        --model-version "$OPENAI_MODEL_VERSION" \
        --model-format OpenAI \
        --sku-capacity 10 \
        --sku-name "Standard" \
        --output none && echo -e "${GREEN}✅ Modelo desplegado exitosamente${NC}" || \
        echo -e "${YELLOW}⚠️  Error al desplegar modelo (puedes crearlo manualmente en Azure AI Studio)${NC}"
fi

# ============================================================================
# PASO 7: Crear Azure AI Hub
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 7/10: Crear Azure AI Hub${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if az ml workspace show \
    --name "$AI_HUB_NAME" \
    --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  AI Hub '$AI_HUB_NAME' ya existe${NC}"
else
    echo -e "${CYAN}ℹ️  Creando AI Hub '$AI_HUB_NAME'...${NC}"
    echo -e "${CYAN}ℹ️  Esto puede tomar 3-5 minutos...${NC}"
    
    az ml workspace create \
        --kind hub \
        --name "$AI_HUB_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none && echo -e "${GREEN}✅ AI Hub creado exitosamente${NC}" || \
        echo -e "${YELLOW}⚠️  Error al crear AI Hub${NC}"
fi

# ============================================================================
# PASO 8: Crear Azure AI Project
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 8/10: Crear Azure AI Project${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if az ml workspace show \
    --name "$AI_PROJECT_NAME" \
    --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  AI Project '$AI_PROJECT_NAME' ya existe${NC}"
else
    echo -e "${CYAN}ℹ️  Creando AI Project '$AI_PROJECT_NAME'...${NC}"
    echo -e "${CYAN}ℹ️  Esto puede tomar 2-3 minutos...${NC}"
    
    HUB_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.MachineLearningServices/workspaces/$AI_HUB_NAME"
    
    az ml workspace create \
        --kind project \
        --name "$AI_PROJECT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --hub-id "$HUB_ID" \
        --output none && echo -e "${GREEN}✅ AI Project creado exitosamente${NC}" || \
        echo -e "${YELLOW}⚠️  Error al crear AI Project${NC}"
fi

PROJECT_ENDPOINT=$(az ml workspace show \
    --name "$AI_PROJECT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "discovery_url" -o tsv 2>/dev/null || echo "https://ai.azure.com")

# ============================================================================
# PASO 9: Crear Azure Bot Service
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 9/10: Crear Azure Bot Service${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if az bot show --resource-group "$RESOURCE_GROUP" --name "$BOT_NAME" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Bot '$BOT_NAME' ya existe${NC}"
    BOT_APP_ID=$(az bot show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BOT_NAME" \
        --query "properties.msaAppId" -o tsv)
    echo -e "${CYAN}ℹ️  App ID del bot: $BOT_APP_ID${NC}"
    read -sp "Ingresa el Microsoft App Password: " BOT_APP_PASSWORD
    echo ""
else
    echo -e "${CYAN}ℹ️  Creando App Registration...${NC}"
    BOT_APP_ID=$(az ad app create \
        --display-name "$BOT_DISPLAY_NAME" \
        --query appId -o tsv)
    echo -e "${GREEN}✅ App Registration creada: $BOT_APP_ID${NC}"
    
    echo -e "${CYAN}ℹ️  Creando Client Secret...${NC}"
    BOT_APP_PASSWORD=$(az ad app credential reset \
        --id "$BOT_APP_ID" \
        --append \
        --years 2 \
        --query password -o tsv)
    
    echo -e "${GREEN}✅ Client Secret creado${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTE: Guarda este Client Secret${NC}"
    echo -e "${YELLOW}    Client Secret: $BOT_APP_PASSWORD${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    read -p "Presiona Enter después de guardar el Client Secret..."
    
    echo -e "${CYAN}ℹ️  Creando Azure Bot Service...${NC}"
    az bot create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BOT_NAME" \
        --kind registration \
        --sku F0 \
        --appid "$BOT_APP_ID" \
        --endpoint "https://${BOT_NAME}.azurewebsites.net/api/messages" \
        --output none
    echo -e "${GREEN}✅ Azure Bot Service creado${NC}"
    
    echo -e "${CYAN}ℹ️  Habilitando canal de Microsoft Teams...${NC}"
    az bot msteams create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BOT_NAME" \
        --enable-calling false \
        --output none && echo -e "${GREEN}✅ Canal de Teams habilitado${NC}" || \
        echo -e "${YELLOW}⚠️  Error al habilitar Teams${NC}"
fi

# ============================================================================
# PASO 10: Generar Archivo .env
# ============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  PASO 10/10: Generar Archivo de Configuración (.env)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH="$SCRIPT_DIR/../.env"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

cat > "$ENV_FILE_PATH" << EOF
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $TIMESTAMP
# Despliegue completo: jarochatAIdemoteam

# Azure AI Project Details
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_AI_PROJECT_NAME=$AI_PROJECT_NAME

# Azure AI Foundry Hub
AZURE_AI_HUB_NAME=$AI_HUB_NAME

# Discovery URL / Project Endpoint
AZURE_AI_PROJECT_ENDPOINT=$PROJECT_ENDPOINT

# Azure OpenAI Connection
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_API_KEY
AZURE_OPENAI_DEPLOYMENT_NAME=$OPENAI_DEPLOYMENT_NAME
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ===========================================
# Azure Bot Service Configuration
# ===========================================

MICROSOFT_APP_ID=$BOT_APP_ID
MICROSOFT_APP_PASSWORD=$BOT_APP_PASSWORD
BOT_ENDPOINT=https://${BOT_NAME}.azurewebsites.net/api/messages

# ===========================================
# Application Settings
# ===========================================

APP_TITLE=JaroChat AI Demo - Teams Assistant
APP_TEMPERATURE=$APP_TEMPERATURE
APP_MAX_TOKENS=$APP_MAX_TOKENS
LOG_LEVEL=INFO

SYSTEM_PROMPT=$SYSTEM_PROMPT

# ===========================================
# Azure AI Foundry Features
# ===========================================

ENABLE_CONTENT_SAFETY=true
CONTENT_SAFETY_THRESHOLD=medium

ENABLE_AI_SEARCH=false
AI_SEARCH_ENDPOINT=
AI_SEARCH_KEY=
AI_SEARCH_INDEX_NAME=

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
EOF

echo -e "${GREEN}✅ Archivo .env generado exitosamente${NC}"
echo -e "${CYAN}ℹ️  Ubicación: $ENV_FILE_PATH${NC}"

# ============================================================================
# Resumen Final
# ============================================================================

echo ""
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              ✅ DESPLIEGUE COMPLETADO ✅                   ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📊 RESUMEN DEL DESPLIEGUE${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "🔹 Resource Group: $RESOURCE_GROUP"
echo "🔹 AI Hub: $AI_HUB_NAME"
echo "🔹 AI Project: $AI_PROJECT_NAME"
echo "🔹 OpenAI Resource: $OPENAI_RESOURCE_NAME"
echo "🔹 Bot: $BOT_NAME"
echo "🔹 Bot App ID: $BOT_APP_ID"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🎯 PRÓXIMOS PASOS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "1️⃣  Verificar Azure AI Studio: https://ai.azure.com"
echo "2️⃣  Revisar .env: cat .env"
echo "3️⃣  Instalar dependencias: pip install -r requirements.txt"
echo "4️⃣  Probar configuración: python -c 'from app.config import AzureAIFoundryConfig; AzureAIFoundryConfig.validate()'"
echo "5️⃣  Ejecutar bot: python bot/bot_app.py"
echo "6️⃣  Configurar en Teams: https://dev.teams.microsoft.com/apps"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 ¡Despliegue completado exitosamente!${NC}"
echo -e "${GREEN}🤖 Tu bot JaroChat está listo para usar${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
