#!/bin/bash
# Script para configurar automáticamente el archivo .env
# con valores preestablecidos para BotprojectTeam
# Usage: ./configure_env_preset.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Valores preestablecidos
SUBSCRIPTION_ID="662141d0-0308-4187-b46b-db1e9466b5ac"
RESOURCE_GROUP="AIBOTSTEAM"
AI_HUB_NAME="BotprojectTeam"
AI_PROJECT_NAME="BotprojectTeam"
OPENAI_RESOURCE_NAME="aiappsseroger"
OPENAI_DEPLOYMENT="gpt-4.1"
LOCATION="eastus2"

echo ""
echo "========================================="
echo "🔧 Configurador Automático .env"
echo "    BotprojectTeam - Azure AI Foundry"
echo "========================================="
echo ""

echo -e "${CYAN}📋 Configuración preestablecida:${NC}"
echo ""
echo "  Suscripción: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  AI Hub: $AI_HUB_NAME"
echo "  AI Project: $AI_PROJECT_NAME"
echo "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
echo "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
echo ""

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI no está instalado${NC}"
    echo "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv 2>/dev/null)
echo -e "${GREEN}✅ Azure CLI encontrado: $AZ_VERSION${NC}"

# Login a Azure
echo ""
echo -e "${CYAN}📝 Iniciando sesión en Azure...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${CYAN}No hay sesión activa. Iniciando login...${NC}"
    az login --output table
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al iniciar sesión en Azure${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Login exitoso${NC}"

# Establecer la suscripción correcta
echo -e "${CYAN}🔄 Configurando suscripción...${NC}"
az account set --subscription "$SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al configurar la suscripción${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Suscripción configurada${NC}"

# Instalar/actualizar extensión de ML
echo -e "${CYAN}🔧 Verificando extensión de Azure ML...${NC}"
az extension add --name ml --upgrade --yes --only-show-errors 2>/dev/null || true
echo -e "${GREEN}✅ Extensión Azure ML lista${NC}"

# Verificar que el Resource Group existe
echo -e "${CYAN}🔍 Verificando Resource Group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")
if [ "$RG_EXISTS" = "true" ]; then
    echo -e "${GREEN}✅ Resource Group encontrado: $RESOURCE_GROUP${NC}"
else
    echo -e "${RED}❌ Resource Group '$RESOURCE_GROUP' no existe${NC}"
    read -p "¿Deseas crearlo? (y/n): " CREATE_RG
    if [ "$CREATE_RG" = "y" ] || [ "$CREATE_RG" = "Y" ]; then
        echo -e "${CYAN}Creando Resource Group...${NC}"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        echo -e "${GREEN}✅ Resource Group creado${NC}"
    else
        echo -e "${RED}Cancelando configuración...${NC}"
        exit 1
    fi
fi

# Verificar AI Project
echo -e "${CYAN}🔍 Verificando AI Project...${NC}"
if az ml workspace show --name "$AI_PROJECT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}✅ AI Project encontrado: $AI_PROJECT_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  AI Project '$AI_PROJECT_NAME' no encontrado${NC}"
    echo -e "${CYAN}Por favor, créalo en Azure AI Studio: https://ai.azure.com${NC}"
    read -p "¿Continuar de todas formas? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 1
    fi
fi

# Obtener Project Endpoint
echo -e "${CYAN}📡 Obteniendo información del proyecto...${NC}"
PROJECT_ENDPOINT=$(az ml workspace show \
  --name "$AI_PROJECT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "discovery_url" -o tsv 2>/dev/null || echo "https://ai.azure.com")

# Verificar recurso Azure OpenAI
echo -e "${CYAN}🔍 Verificando recurso Azure OpenAI...${NC}"
if az cognitiveservices account show \
  --name "$OPENAI_RESOURCE_NAME" \
  --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}✅ Recurso OpenAI encontrado: $OPENAI_RESOURCE_NAME${NC}"
else
    echo -e "${RED}❌ Recurso Azure OpenAI '$OPENAI_RESOURCE_NAME' no encontrado${NC}"
    read -p "¿Deseas crearlo? (y/n): " CREATE_OPENAI
    if [ "$CREATE_OPENAI" = "y" ] || [ "$CREATE_OPENAI" = "Y" ]; then
        echo -e "${CYAN}Creando recurso Azure OpenAI...${NC}"
        az cognitiveservices account create \
          --name "$OPENAI_RESOURCE_NAME" \
          --resource-group "$RESOURCE_GROUP" \
          --kind OpenAI \
          --sku S0 \
          --location "$LOCATION" \
          --yes
        
        echo -e "${GREEN}✅ Recurso OpenAI creado${NC}"
    else
        echo -e "${RED}No se puede continuar sin el recurso OpenAI${NC}"
        exit 1
    fi
fi

# Obtener endpoint y key de OpenAI
echo -e "${CYAN}🔑 Obteniendo credenciales de Azure OpenAI...${NC}"
OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name "$OPENAI_RESOURCE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.endpoint" -o tsv)

OPENAI_API_KEY=$(az cognitiveservices account keys list \
  --name "$OPENAI_RESOURCE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "key1" -o tsv)

echo -e "${GREEN}✅ Credenciales obtenidas${NC}"

# Verificar deployment del modelo
echo -e "${CYAN}🔍 Verificando deployment del modelo '$OPENAI_DEPLOYMENT'...${NC}"
echo -e "${YELLOW}⚠️  Asegúrate de que el deployment '$OPENAI_DEPLOYMENT' existe en Azure AI Studio${NC}"
echo -e "${YELLOW}    URL: https://ai.azure.com${NC}"

# Configuración del Bot
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuración de Azure Bot Service${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

read -p "¿Deseas configurar el Bot ahora? (y/n): " CONFIGURE_BOT
if [ "$CONFIGURE_BOT" = "y" ] || [ "$CONFIGURE_BOT" = "Y" ]; then
    read -p "Nombre para el bot [teams-ai-foundry-bot]: " BOT_INPUT
    BOT_NAME=${BOT_INPUT:-teams-ai-foundry-bot}
    
    # Verificar si el bot existe
    if az bot show --resource-group "$RESOURCE_GROUP" --name "$BOT_NAME" &> /dev/null; then
        echo -e "${GREEN}✅ Bot encontrado: $BOT_NAME${NC}"
        
        # Obtener App ID del bot existente
        BOT_APP_ID=$(az bot show \
          --resource-group "$RESOURCE_GROUP" \
          --name "$BOT_NAME" \
          --query "properties.msaAppId" -o tsv)
        
        echo -e "${CYAN}App ID del bot: $BOT_APP_ID${NC}"
        read -sp "Ingresa el Microsoft App Password (Client Secret): " BOT_APP_PASSWORD
        echo ""
    else
        echo -e "${CYAN}Creando nuevo bot...${NC}"
        
        # Crear App Registration
        echo -e "${CYAN}Creando App Registration...${NC}"
        BOT_APP_ID=$(az ad app create \
          --display-name "$BOT_NAME" \
          --query appId -o tsv)
        
        echo -e "${GREEN}✅ App Registration creada: $BOT_APP_ID${NC}"
        
        # Crear client secret
        echo -e "${CYAN}Creando client secret...${NC}"
        BOT_APP_PASSWORD=$(az ad app credential reset \
          --id "$BOT_APP_ID" \
          --append \
          --years 2 \
          --query password -o tsv)
        
        echo -e "${GREEN}✅ Client Secret creado${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANTE: Guarda este password, no se mostrará de nuevo:${NC}"
        echo "    $BOT_APP_PASSWORD"
        echo ""
        read -p "Presiona Enter para continuar..."
        
        # Crear Azure Bot
        echo -e "${CYAN}Creando Azure Bot...${NC}"
        az bot create \
          --resource-group "$RESOURCE_GROUP" \
          --name "$BOT_NAME" \
          --kind registration \
          --sku F0 \
          --appid "$BOT_APP_ID" \
          --endpoint "https://placeholder.azurewebsites.net/api/messages"
        
        echo -e "${GREEN}✅ Azure Bot creado${NC}"
        
        # Habilitar canal de Teams
        echo -e "${CYAN}Habilitando canal de Microsoft Teams...${NC}"
        az bot msteams create \
          --resource-group "$RESOURCE_GROUP" \
          --name "$BOT_NAME" \
          --enable-calling false
        
        echo -e "${GREEN}✅ Canal de Teams habilitado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Configuración del Bot omitida${NC}"
    echo "   Deberás agregar manualmente MICROSOFT_APP_ID y MICROSOFT_APP_PASSWORD al .env"
    BOT_APP_ID="TU_MICROSOFT_APP_ID_AQUI"
    BOT_APP_PASSWORD="TU_MICROSOFT_APP_PASSWORD_AQUI"
    BOT_NAME="teams-ai-foundry-bot"
fi

# Configuraciones adicionales
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configuraciones Adicionales${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

read -p "Habilitar Content Safety? (y/n) [y]: " CONTENT_SAFETY_INPUT
ENABLE_CONTENT_SAFETY=${CONTENT_SAFETY_INPUT:-y}
if [ "$ENABLE_CONTENT_SAFETY" = "n" ] || [ "$ENABLE_CONTENT_SAFETY" = "N" ]; then
    ENABLE_CONTENT_SAFETY="false"
else
    ENABLE_CONTENT_SAFETY="true"
fi

read -p "Temperatura del modelo [0.7]: " TEMP_INPUT
APP_TEMPERATURE=${TEMP_INPUT:-0.7}

read -p "Máximo de tokens [2000]: " TOKENS_INPUT
APP_MAX_TOKENS=${TOKENS_INPUT:-2000}

read -p "System Prompt personalizado? (Enter para usar el predeterminado): " PROMPT_INPUT
if [ -z "$PROMPT_INPUT" ]; then
    SYSTEM_PROMPT="Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil."
else
    SYSTEM_PROMPT="$PROMPT_INPUT"
fi

# Generar archivo .env
echo ""
echo -e "${CYAN}📝 Generando archivo .env...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH="$SCRIPT_DIR/../.env"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

cat > "$ENV_FILE_PATH" << EOF
# ===========================================
# Azure AI Foundry Configuration
# ===========================================
# Generado automáticamente el $TIMESTAMP
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
EOF

echo -e "${GREEN}✅ Archivo .env generado exitosamente en:${NC}"
echo -e "${CYAN}   $ENV_FILE_PATH${NC}"

# Resumen
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✅ Configuración Completada${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${CYAN}📋 Resumen de la configuración:${NC}"
echo ""
echo "  Suscripción: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  AI Hub: $AI_HUB_NAME"
echo "  AI Project: $AI_PROJECT_NAME"
echo "  OpenAI Resource: $OPENAI_RESOURCE_NAME"
echo "  OpenAI Endpoint: $OPENAI_ENDPOINT"
echo "  OpenAI Deployment: $OPENAI_DEPLOYMENT"
echo "  Bot Name: $BOT_NAME"
echo "  Bot App ID: $BOT_APP_ID"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE - Próximos pasos:${NC}"
echo ""
echo "1. Verifica que el deployment del modelo existe:"
echo -e "${CYAN}   - Ve a https://ai.azure.com${NC}"
echo -e "${CYAN}   - Selecciona el proyecto 'BotprojectTeam'${NC}"
echo -e "${CYAN}   - Ve a 'Deployments' y verifica que existe '$OPENAI_DEPLOYMENT'${NC}"
echo ""
echo "2. Revisa tu archivo .env:"
echo -e "${CYAN}   cat .env${NC}"
echo ""
echo "3. Prueba la configuración:"
echo -e "${CYAN}   python -c \"from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()\"${NC}"
echo ""
echo "4. Instala las dependencias:"
echo -e "${CYAN}   pip install -r requirements.txt${NC}"
echo ""
echo "5. Ejecuta el bot localmente:"
echo -e "${CYAN}   python bot/bot_app.py${NC}"
echo ""
echo "6. Prueba el bot en Teams:"
echo -e "${CYAN}   - Ve a https://dev.teams.microsoft.com/apps${NC}"
echo -e "${CYAN}   - Configura tu app manifest con el Bot App ID: $BOT_APP_ID${NC}"
echo ""
echo "7. Despliega a Azure (cuando esté listo):"
echo -e "${CYAN}   ./scripts/deploy.sh${NC}"
echo ""
echo -e "${GREEN}¡Configuración exitosa! 🎉${NC}"
echo ""
echo -e "${CYAN}Archivo generado: $ENV_FILE_PATH${NC}"
echo ""
