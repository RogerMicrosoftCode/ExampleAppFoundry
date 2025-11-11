#!/bin/bash

# Script para configurar automáticamente el archivo .env
# con valores obtenidos desde Azure
# Usage: ./configure_env.sh

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "========================================="
echo "🔧 Configurador de .env para Teams AI Bot"
echo "========================================="
echo ""

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI no está instalado${NC}"
    echo "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

echo -e "${GREEN}✅ Azure CLI encontrado${NC}"

# Login a Azure
echo ""
echo -e "${BLUE}📝 Iniciando sesión en Azure...${NC}"
az login --output table

# Verificar si el login fue exitoso
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al iniciar sesión en Azure${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Login exitoso${NC}"

# Obtener lista de suscripciones
echo ""
echo -e "${BLUE}📋 Obteniendo suscripciones disponibles...${NC}"
SUBSCRIPTIONS=$(az account list --query "[].{Name:name, ID:id, Default:isDefault}" -o table)
echo "$SUBSCRIPTIONS"

# Preguntar si desea cambiar de suscripción
echo ""
read -p "¿Deseas usar una suscripción diferente? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Ingresa el ID de la suscripción: " SUB_ID
    az account set --subscription "$SUB_ID"
    echo -e "${GREEN}✅ Suscripción cambiada${NC}"
fi

# Obtener Subscription ID actual
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Usando suscripción: $SUBSCRIPTION_ID${NC}"

# Preguntar por Resource Group
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuración de Resource Group${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""
echo "Grupos de recursos existentes:"
az group list --query "[].{Name:name, Location:location}" -o table

echo ""
read -p "¿Deseas usar un Resource Group existente? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Nombre del Resource Group: " RESOURCE_GROUP
else
    read -p "Nombre para el nuevo Resource Group [rg-ai-foundry-teams]: " RESOURCE_GROUP
    RESOURCE_GROUP=${RESOURCE_GROUP:-rg-ai-foundry-teams}
    
    read -p "Location [eastus]: " LOCATION
    LOCATION=${LOCATION:-eastus}
    
    echo -e "${BLUE}Creando Resource Group...${NC}"
    az group create --name $RESOURCE_GROUP --location $LOCATION
    echo -e "${GREEN}✅ Resource Group creado${NC}"
fi

# Preguntar por Azure AI Foundry Hub y Project
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuración de Azure AI Foundry${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

# Instalar/actualizar extensión de ML
echo -e "${BLUE}Actualizando extensión de Azure ML...${NC}"
az extension add --name ml --upgrade --yes 2>/dev/null

# Listar workspaces existentes
echo ""
echo "Workspaces de Azure AI existentes:"
az ml workspace list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:kind}" -o table 2>/dev/null || echo "No hay workspaces existentes"

echo ""
read -p "¿Deseas usar un AI Hub/Project existente? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Nombre del AI Hub: " AI_HUB_NAME
    read -p "Nombre del AI Project: " AI_PROJECT_NAME
else
    read -p "Nombre para el AI Hub [ai-foundry-hub]: " AI_HUB_NAME
    AI_HUB_NAME=${AI_HUB_NAME:-ai-foundry-hub}
    
    read -p "Nombre para el AI Project [teams-bot-project]: " AI_PROJECT_NAME
    AI_PROJECT_NAME=${AI_PROJECT_NAME:-teams-bot-project}
    
    LOCATION=${LOCATION:-eastus}
    
    echo -e "${BLUE}Creando Azure AI Hub...${NC}"
    az ml workspace create \
      --kind hub \
      --resource-group $RESOURCE_GROUP \
      --name $AI_HUB_NAME \
      --location $LOCATION
    
    echo -e "${GREEN}✅ AI Hub creado${NC}"
    
    echo -e "${BLUE}Creando Azure AI Project...${NC}"
    az ml workspace create \
      --kind project \
      --resource-group $RESOURCE_GROUP \
      --name $AI_PROJECT_NAME \
      --hub-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.MachineLearningServices/workspaces/$AI_HUB_NAME" \
      --location $LOCATION
    
    echo -e "${GREEN}✅ AI Project creado${NC}"
fi

# Obtener Project Endpoint
echo -e "${BLUE}Obteniendo información del proyecto...${NC}"
PROJECT_ENDPOINT=$(az ml workspace show \
  --name $AI_PROJECT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "discovery_url" -o tsv 2>/dev/null || echo "")

# Preguntar por Azure OpenAI
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuración de Azure OpenAI${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

echo "Recursos de Azure OpenAI existentes:"
az cognitiveservices account list \
  --resource-group $RESOURCE_GROUP \
  --query "[?kind=='OpenAI'].{Name:name, Location:location, Endpoint:properties.endpoint}" -o table 2>/dev/null || echo "No hay recursos OpenAI existentes"

echo ""
read -p "¿Deseas usar un recurso OpenAI existente? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Nombre del recurso Azure OpenAI: " OPENAI_RESOURCE_NAME
else
    read -p "Nombre para el recurso Azure OpenAI [openai-$AI_PROJECT_NAME]: " OPENAI_RESOURCE_NAME
    OPENAI_RESOURCE_NAME=${OPENAI_RESOURCE_NAME:-openai-$AI_PROJECT_NAME}
    
    echo -e "${BLUE}Creando recurso Azure OpenAI...${NC}"
    az cognitiveservices account create \
      --name $OPENAI_RESOURCE_NAME \
      --resource-group $RESOURCE_GROUP \
      --kind OpenAI \
      --sku S0 \
      --location ${LOCATION:-eastus} \
      --yes
    
    echo -e "${GREEN}✅ Recurso OpenAI creado${NC}"
fi

# Obtener endpoint y key de OpenAI
echo -e "${BLUE}Obteniendo credenciales de Azure OpenAI...${NC}"
OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name $OPENAI_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "properties.endpoint" -o tsv)

OPENAI_API_KEY=$(az cognitiveservices account keys list \
  --name $OPENAI_RESOURCE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "key1" -o tsv)

# Preguntar por deployment de modelo
echo ""
read -p "Nombre del deployment de modelo OpenAI [gpt-4-teams-foundry]: " OPENAI_DEPLOYMENT
OPENAI_DEPLOYMENT=${OPENAI_DEPLOYMENT:-gpt-4-teams-foundry}

echo -e "${YELLOW}Nota: Asegúrate de crear el deployment '$OPENAI_DEPLOYMENT' en Azure AI Studio${NC}"
echo -e "${YELLOW}URL: https://ai.azure.com${NC}"

# Preguntar por Azure Bot Service
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuración de Azure Bot Service${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

echo "Bots existentes:"
az bot show --resource-group $RESOURCE_GROUP --name teams-ai-foundry-bot --query "{Name:name, Endpoint:properties.endpoint}" -o table 2>/dev/null || echo "No hay bots existentes"

echo ""
read -p "¿Deseas usar un bot existente? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Nombre del bot: " BOT_NAME
    
    # Intentar obtener App ID del bot existente
    BOT_APP_ID=$(az bot show \
      --resource-group $RESOURCE_GROUP \
      --name $BOT_NAME \
      --query "properties.msaAppId" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$BOT_APP_ID" ]; then
        read -p "Ingresa el Microsoft App ID del bot: " BOT_APP_ID
    fi
    
    read -p "Ingresa el Microsoft App Password (Client Secret): " -s BOT_APP_PASSWORD
    echo ""
else
    read -p "Nombre para el bot [teams-ai-foundry-bot]: " BOT_NAME
    BOT_NAME=${BOT_NAME:-teams-ai-foundry-bot}
    
    echo -e "${BLUE}Creando App Registration...${NC}"
    
    # Crear App Registration
    APP_DISPLAY_NAME="$BOT_NAME"
    BOT_APP_ID=$(az ad app create \
      --display-name "$APP_DISPLAY_NAME" \
      --available-to-other-tenants false \
      --query appId -o tsv)
    
    echo -e "${GREEN}✅ App Registration creada: $BOT_APP_ID${NC}"
    
    # Crear client secret
    echo -e "${BLUE}Creando client secret...${NC}"
    BOT_APP_PASSWORD=$(az ad app credential reset \
      --id $BOT_APP_ID \
      --append \
      --years 2 \
      --query password -o tsv)
    
    echo -e "${GREEN}✅ Client Secret creado${NC}"
    
    # Crear Azure Bot
    echo -e "${BLUE}Creando Azure Bot...${NC}"
    az bot create \
      --resource-group $RESOURCE_GROUP \
      --name $BOT_NAME \
      --kind registration \
      --sku F0 \
      --appid $BOT_APP_ID \
      --endpoint "https://placeholder.azurewebsites.net/api/messages"
    
    echo -e "${GREEN}✅ Azure Bot creado${NC}"
    
    # Habilitar canal de Teams
    echo -e "${BLUE}Habilitando canal de Microsoft Teams...${NC}"
    az bot msteams create \
      --resource-group $RESOURCE_GROUP \
      --name $BOT_NAME \
      --enable-calling false
    
    echo -e "${GREEN}✅ Canal de Teams habilitado${NC}"
fi

# Configuraciones adicionales
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuraciones Adicionales${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

read -p "Habilitar Content Safety? (y/n) [y]: " -n 1 -r
echo
ENABLE_CONTENT_SAFETY="true"
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    ENABLE_CONTENT_SAFETY="false"
fi

read -p "Temperatura del modelo [0.7]: " APP_TEMPERATURE
APP_TEMPERATURE=${APP_TEMPERATURE:-0.7}

read -p "Máximo de tokens [2000]: " APP_MAX_TOKENS
APP_MAX_TOKENS=${APP_MAX_TOKENS:-2000}

read -p "System Prompt [Eres un asistente inteligente...]: " SYSTEM_PROMPT
SYSTEM_PROMPT=${SYSTEM_PROMPT:-"Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil."}

# Generar archivo .env
echo ""
echo -e "${BLUE}📝 Generando archivo .env...${NC}"

ENV_FILE=".env"

cat > $ENV_FILE << EOF
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $(date)

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
EOF

echo -e "${GREEN}✅ Archivo .env generado exitosamente${NC}"

# Resumen
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✅ Configuración Completada${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${BLUE}📋 Resumen de la configuración:${NC}"
echo ""
echo "  Azure Subscription: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AI Hub: $AI_HUB_NAME"
echo "  AI Project: $AI_PROJECT_NAME"
echo "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
echo "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
echo "  Bot Name: $BOT_NAME"
echo "  Bot App ID: $BOT_APP_ID"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE - Próximos pasos:${NC}"
echo ""
echo "1. Ve a Azure AI Studio: ${BLUE}https://ai.azure.com${NC}"
echo "   - Despliega el modelo '$OPENAI_DEPLOYMENT' si aún no existe"
echo ""
echo "2. Verifica tu archivo .env:"
echo "   ${GREEN}cat .env${NC}"
echo ""
echo "3. Prueba la configuración:"
echo "   ${GREEN}make validate-config${NC}"
echo "   o"
echo "   ${GREEN}python -c \"from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()\"${NC}"
echo ""
echo "4. Ejecuta el bot localmente:"
echo "   ${GREEN}python bot/bot_app.py${NC}"
echo ""
echo "5. Despliega a Azure:"
echo "   ${GREEN}bash scripts/deploy.sh${NC}"
echo ""
echo -e "${GREEN}¡Configuración exitosa! 🎉${NC}"
echo ""
