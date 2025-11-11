#!/bin/bash

# Script para desplegar el bot en Azure Container Apps
# Usage: ./deploy.sh

set -e

echo "========================================="
echo "Deployment de Teams AI Foundry Bot"
echo "========================================="

# Verificar que .env existe
if [ ! -f .env ]; then
    echo "❌ Archivo .env no encontrado"
    echo "Copia .env.example a .env y configura las variables"
    exit 1
fi

# Cargar variables de entorno
source .env

# Variables de deployment
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-rg-ai-foundry-teams}"
LOCATION="${AZURE_LOCATION:-eastus}"
ACR_NAME="${ACR_NAME:-myaifoundryregistry}"
BOT_APP_NAME="${BOT_APP_NAME:-teams-ai-foundry-bot}"
CONTAINER_APP_ENV="${CONTAINER_APP_ENV:-ai-foundry-env}"

echo ""
echo "Configuración de deployment:"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - ACR Name: $ACR_NAME"
echo "  - Bot Name: $BOT_APP_NAME"
echo ""

# Login a Azure
echo "📝 Verificando sesión de Azure..."
az account show > /dev/null 2>&1 || az login

# Crear Container Registry si no existe
echo "📦 Configurando Container Registry..."
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "  - Creando ACR: $ACR_NAME"
    az acr create \
      --resource-group $RESOURCE_GROUP \
      --name $ACR_NAME \
      --sku Basic
else
    echo "  - ACR ya existe: $ACR_NAME"
fi

# Build y push de imagen
echo "🔨 Construyendo y subiendo imagen Docker..."
az acr build \
  --registry $ACR_NAME \
  --image teams-ai-foundry-bot:latest \
  --file Dockerfile.bot .

echo "✅ Imagen construida y subida"

# Crear Container Apps Environment si no existe
echo "🌐 Configurando Container Apps Environment..."
if ! az containerapp env show --name $CONTAINER_APP_ENV --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo "  - Creando environment: $CONTAINER_APP_ENV"
    az containerapp env create \
      --name $CONTAINER_APP_ENV \
      --resource-group $RESOURCE_GROUP \
      --location $LOCATION
else
    echo "  - Environment ya existe: $CONTAINER_APP_ENV"
fi

# Desplegar Container App
echo "🚀 Desplegando Container App..."
az containerapp create \
  --name $BOT_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINER_APP_ENV \
  --image $ACR_NAME.azurecr.io/teams-ai-foundry-bot:latest \
  --target-port 3978 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 1.0 \
  --memory 2.0Gi \
  --secrets \
    openai-key="$AZURE_OPENAI_API_KEY" \
    bot-password="$MICROSOFT_APP_PASSWORD" \
  --env-vars \
    AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID" \
    AZURE_RESOURCE_GROUP="$RESOURCE_GROUP" \
    AZURE_AI_PROJECT_NAME="$AZURE_AI_PROJECT_NAME" \
    AZURE_AI_HUB_NAME="$AZURE_AI_HUB_NAME" \
    AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
    AZURE_OPENAI_API_KEY=secretref:openai-key \
    AZURE_OPENAI_DEPLOYMENT_NAME="$AZURE_OPENAI_DEPLOYMENT_NAME" \
    AZURE_OPENAI_API_VERSION="$AZURE_OPENAI_API_VERSION" \
    MICROSOFT_APP_ID="$MICROSOFT_APP_ID" \
    MICROSOFT_APP_PASSWORD=secretref:bot-password \
    ENABLE_CONTENT_SAFETY="$ENABLE_CONTENT_SAFETY" \
    APP_TEMPERATURE="$APP_TEMPERATURE" \
    APP_MAX_TOKENS="$APP_MAX_TOKENS" \
    LOG_LEVEL="$LOG_LEVEL" \
  --registry-server $ACR_NAME.azurecr.io

# Obtener URL del bot
echo "🔍 Obteniendo URL del bot..."
BOT_URL=$(az containerapp show \
  --name $BOT_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  -o tsv)

BOT_ENDPOINT="https://$BOT_URL/api/messages"

echo "✅ Bot desplegado en: $BOT_ENDPOINT"

# Actualizar endpoint en Azure Bot
echo "🔄 Actualizando endpoint en Azure Bot Service..."
az bot update \
  --resource-group $RESOURCE_GROUP \
  --name ${BOT_NAME:-teams-ai-foundry-bot} \
  --endpoint "$BOT_ENDPOINT"

echo ""
echo "========================================="
echo "✅ Deployment completado exitosamente!"
echo "========================================="
echo ""
echo "URL del bot: $BOT_ENDPOINT"
echo "Health check: https://$BOT_URL/health"
echo ""
echo "Próximos pasos:"
echo "1. Verifica el health check del bot"
echo "2. Configura la Teams App en el portal de Teams"
echo "3. Instala el bot en tu tenant de Teams"
echo ""
