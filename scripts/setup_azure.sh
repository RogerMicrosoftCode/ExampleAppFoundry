#!/bin/bash

# Script para configurar recursos de Azure AI Foundry y Bot Service
# Usage: ./setup_azure.sh

set -e

echo "========================================="
echo "Setup de Azure AI Foundry + Bot Service"
echo "========================================="

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI no está instalado"
    echo "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Login a Azure
echo "📝 Iniciando sesión en Azure..."
az login

# Variables de configuración
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-rg-ai-foundry-teams}"
LOCATION="${AZURE_LOCATION:-eastus}"
AI_HUB_NAME="${AZURE_AI_HUB_NAME:-ai-foundry-hub}"
AI_PROJECT_NAME="${AZURE_AI_PROJECT_NAME:-teams-bot-project}"
BOT_NAME="${BOT_NAME:-teams-ai-foundry-bot}"

echo ""
echo "Configuración:"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - Location: $LOCATION"
echo "  - AI Hub: $AI_HUB_NAME"
echo "  - AI Project: $AI_PROJECT_NAME"
echo "  - Bot Name: $BOT_NAME"
echo ""

read -p "¿Continuar con esta configuración? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Actualizar extensión de Azure AI
echo "📦 Actualizando extensiones de Azure..."
az extension add --name ml --upgrade --yes

# Crear grupo de recursos
echo "📁 Creando grupo de recursos..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Crear Azure AI Hub
echo "🏗️ Creando Azure AI Hub..."
az ml workspace create \
  --kind hub \
  --resource-group $RESOURCE_GROUP \
  --name $AI_HUB_NAME \
  --location $LOCATION

echo "✅ Azure AI Hub creado"

# Obtener subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Crear Azure AI Project
echo "📊 Creando Azure AI Project..."
az ml workspace create \
  --kind project \
  --resource-group $RESOURCE_GROUP \
  --name $AI_PROJECT_NAME \
  --hub-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.MachineLearningServices/workspaces/$AI_HUB_NAME" \
  --location $LOCATION

echo "✅ Azure AI Project creado"

# Crear App Registration para el bot
echo "🤖 Creando App Registration..."
APP_ID=$(az ad app create \
  --display-name "$BOT_NAME" \
  --available-to-other-tenants false \
  --query appId -o tsv)

echo "  - App ID: $APP_ID"

# Crear client secret
echo "🔑 Creando client secret..."
SECRET_OUTPUT=$(az ad app credential reset \
  --id $APP_ID \
  --append \
  --years 2 \
  --query password -o tsv)

echo "  - Client Secret: $SECRET_OUTPUT"

# Crear Azure Bot
echo "💬 Creando Azure Bot..."
az bot create \
  --resource-group $RESOURCE_GROUP \
  --name $BOT_NAME \
  --kind registration \
  --sku F0 \
  --appid $APP_ID \
  --endpoint "https://placeholder.azurewebsites.net/api/messages"

# Habilitar canal de Teams
echo "📱 Habilitando canal de Microsoft Teams..."
az bot msteams create \
  --resource-group $RESOURCE_GROUP \
  --name $BOT_NAME \
  --enable-calling false

echo ""
echo "========================================="
echo "✅ Setup completado exitosamente!"
echo "========================================="
echo ""
echo "Guarda esta información:"
echo "  - AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "  - AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "  - AZURE_AI_HUB_NAME: $AI_HUB_NAME"
echo "  - AZURE_AI_PROJECT_NAME: $AI_PROJECT_NAME"
echo "  - MICROSOFT_APP_ID: $APP_ID"
echo "  - MICROSOFT_APP_PASSWORD: $SECRET_OUTPUT"
echo ""
echo "Próximos pasos:"
echo "1. Ve a Azure AI Studio (https://ai.azure.com)"
echo "2. Despliega un modelo de Azure OpenAI en tu proyecto"
echo "3. Actualiza el archivo .env con estas credenciales"
echo "4. Ejecuta ./deploy.sh para desplegar el bot"
echo ""
