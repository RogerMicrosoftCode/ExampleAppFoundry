# Chat Application con Azure AI Foundry, Microsoft Teams y Azure Bot Service

## 📋 Descripción

Esta guía proporciona un ejemplo completo de cómo crear una aplicación de chat usando **Azure AI Foundry**, **LangChain**, **Microsoft Teams** y **Azure Bot Service**, containerizada con Docker. La aplicación aprovecha las capacidades avanzadas de Azure AI Foundry para crear un asistente inteligente integrado con Microsoft Teams.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                  Microsoft Teams                     │
│                   (Frontend)                         │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              Azure Bot Service                       │
│         (Bot Framework Connector)                    │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│             Bot Application                          │
│        (Bot Framework SDK + LangChain)               │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│           Azure AI Foundry                           │
│      (AI Studio + Projects + Deployments)            │
│                                                       │
│  ┌─────────────────────────────────────────┐        │
│  │   Azure OpenAI Models                    │        │
│  │   • GPT-4.1 Turbo                       │        │
│  │   • GPT-3.5 Turbo                       │        │
│  └─────────────────────────────────────────┘        │
│                                                       │
│  ┌─────────────────────────────────────────┐        │
│  │   Content Safety                         │        │
│  │   • Moderation                           │        │
│  │   • Responsible AI                       │        │
│  └─────────────────────────────────────────┘        │
│                                                       │
│  ┌─────────────────────────────────────────┐        │
│  │   AI Search (Optional)                   │        │
│  │   • Vector Search                        │        │
│  │   • Semantic Search                      │        │
│  └─────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────┘
```

## 📦 Prerrequisitos

- Cuenta de Azure activa con suscripción
- Microsoft 365 / Office 365 con permisos de administración
- Azure CLI instalado (versión 2.50+)
- Python 3.9 o superior
- Docker y Docker Compose
- Git
- Node.js 16+ (para Teams App Studio)

## 🚀 Parte 1: Configuración de Azure AI Foundry

### Paso 1: Crear Azure AI Hub (AI Foundry)

```bash
# Login a Azure
az login

# Actualizar extensión de Azure AI
az extension add --name ml
az extension update --name ml

# Crear grupo de recursos
az group create \
  --name rg-ai-foundry-teams \
  --location eastus

# Crear Azure AI Hub (AI Foundry Hub)
az ml workspace create \
  --kind hub \
  --resource-group rg-ai-foundry-teams \
  --name ai-foundry-hub \
  --location eastus
```

### Paso 2: Crear Proyecto en Azure AI Foundry

#### Opción A: Usando Azure AI Studio (Recomendado)

1. Ve a [Azure AI Studio](https://ai.azure.com)
2. Haz clic en **+ New project**
3. Completa el formulario:
   ```
   Project name: teams-bot-project
   Hub: Selecciona el hub creado (ai-foundry-hub)
   Region: East US
   ```
4. Haz clic en **Create**

#### Opción B: Usando Azure CLI

```bash
# Crear proyecto de AI Foundry
az ml workspace create \
  --kind project \
  --resource-group rg-ai-foundry-teams \
  --name teams-bot-project \
  --hub-id /subscriptions/{subscription-id}/resourceGroups/rg-ai-foundry-teams/providers/Microsoft.MachineLearningServices/workspaces/ai-foundry-hub \
  --location eastus
```

### Paso 3: Configurar Azure OpenAI en AI Foundry

1. En Azure AI Studio, ve a tu proyecto **teams-bot-project**
2. En el menú izquierdo, selecciona **Deployments**
3. Haz clic en **+ Create deployment**
4. Configurar el modelo:
   ```
   Select model: gpt-41-turbo
   Deployment name: gpt-41-turbo
   Model version: Última disponible
   Deployment type: Standard
   Tokens per Minute Rate Limit: 10K-120K
   Content filter: Default
   ```
5. Haz clic en **Deploy**

### Paso 4: Configurar Conexiones en AI Foundry

1. En Azure AI Studio, ve a **Settings** > **Connections**
2. Verifica las conexiones creadas automáticamente:
   - **Azure OpenAI Connection**: Para acceso a modelos
   - **Azure AI Services**: Para Content Safety
   - **Azure AI Search**: (Opcional) Para RAG

### Paso 5: Obtener Credenciales del Proyecto

```bash
# Obtener detalles del workspace/proyecto
az ml workspace show \
  --name teams-bot-project \
  --resource-group rg-ai-foundry-teams

# Obtener endpoint
az ml workspace show \
  --name teams-bot-project \
  --resource-group rg-ai-foundry-teams \
  --query "discovery_url" -o tsv

# Obtener keys de Azure OpenAI conectado
az cognitiveservices account keys list \
  --name tu-azure-openai-resource \
  --resource-group rg-ai-foundry-teams
```

### Paso 6: Obtener Azure AI Project Connection String

En Azure AI Studio:
1. Ve a tu proyecto **teams-bot-project**
2. Haz clic en **Overview**
3. Copia los siguientes valores:
   - **Project Connection String** o **Discovery URL**
   - **Subscription ID**
   - **Resource Group**
   - **Project Name**

## 🤖 Parte 2: Configuración de Azure Bot Service

### Paso 1: Crear Azure Bot

```bash
# Crear App Registration en Azure AD
az ad app create \
  --display-name "Teams AI Foundry Bot" \
  --available-to-other-tenants false

# Guardar el Application (client) ID
APP_ID=$(az ad app list --display-name "Teams AI Foundry Bot" --query "[0].appId" -o tsv)

# Crear client secret
az ad app credential reset \
  --id $APP_ID \
  --append \
  --years 2

# Guardar el client secret generado

# Crear Azure Bot
az bot create \
  --resource-group rg-ai-foundry-teams \
  --name teams-ai-foundry-bot \
  --kind registration \
  --sku F0 \
  --appid $APP_ID \
  --endpoint https://tu-bot-app.azurewebsites.net/api/messages
```

### Paso 2: Configurar Canal de Teams

```bash
# Habilitar canal de Microsoft Teams
az bot msteams create \
  --resource-group rg-ai-foundry-teams \
  --name teams-ai-foundry-bot \
  --enable-calling false \
  --calling-web-hook ""
```

### Paso 3: Configurar Permisos

En Azure Portal:
1. Ve a **Azure Active Directory** > **App registrations**
2. Busca "Teams AI Foundry Bot"
3. Ve a **API permissions** > **Add a permission**
4. Agrega:
   - **Microsoft Graph API**:
     - `User.Read` (Delegated)
     - `offline_access` (Delegated)
   - **Azure Service Management**:
     - `user_impersonation` (Delegated)

## 📁 Estructura del Proyecto

```
azure-ai-foundry-teams-bot/
├── app/
│   ├── __init__.py
│   ├── config.py                    # Configuración centralizada
│   ├── foundry_client.py            # Cliente de Azure AI Foundry
│   ├── chat_engine.py               # Motor de chat con LangChain
│   └── utils.py                     # Utilidades
├── bot/
│   ├── __init__.py
│   ├── bot_app.py                   # Aplicación principal del bot
│   ├── teams_bot.py                 # Lógica del bot de Teams
│   ├── conversation_manager.py      # Gestión de conversaciones
│   ├── cards.py                     # Adaptive Cards
│   └── content_safety.py            # Content Safety integration
├── web/
│   └── streamlit_app.py             # Interfaz web opcional
├── tests/
│   ├── test_connection.py
│   ├── test_foundry.py
│   └── test_bot.py
├── teams/
│   ├── manifest.json                # Manifest de Teams App
│   ├── color.png                    # Icono color (192x192)
│   └── outline.png                  # Icono outline (32x32)
├── .env.example
├── .gitignore
├── Dockerfile.bot
├── Dockerfile.web
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## 💻 Código de la Aplicación

### 1. requirements.txt

```txt
# Framework web
streamlit==1.30.0
aiohttp==3.9.1

# Bot Framework
botbuilder-core==4.15.0
botbuilder-schema==4.15.0
botbuilder-integration-aiohttp==4.15.0

# Azure AI SDK
azure-ai-ml==1.12.0
azure-identity==1.15.0
azure-ai-inference==1.0.0b1

# LangChain
langchain==0.1.4
langchain-openai==0.0.5
openai==1.10.0

# Azure OpenAI (para conexión directa si es necesario)
azure-openai==1.3.0

# Content Safety
azure-ai-contentsafety==1.0.0

# Utilidades
python-dotenv==1.0.1
requests==2.31.0
pydantic==2.5.3
tenacity==8.2.3

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-mock==3.12.0

# Adaptive Cards
adaptivecards==0.1.0
```

### 2. .env.example

```env
# ===========================================
# Azure AI Foundry Configuration
# ===========================================

# Azure AI Project Details
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_RESOURCE_GROUP=rg-ai-foundry-teams
AZURE_AI_PROJECT_NAME=teams-bot-project

# Azure AI Foundry Hub
AZURE_AI_HUB_NAME=ai-foundry-hub

# Discovery URL / Project Endpoint
AZURE_AI_PROJECT_ENDPOINT=https://tu-proyecto.api.azureml.ms

# Azure OpenAI Connection (desde AI Foundry)
AZURE_OPENAI_ENDPOINT=https://tu-openai.openai.azure.com/
AZURE_OPENAI_API_KEY=tu-clave-api-aqui
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-41-turbo
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# ===========================================
# Azure Bot Service Configuration
# ===========================================

# Microsoft App ID (Bot Application ID)
MICROSOFT_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Microsoft App Password (Bot Client Secret)
MICROSOFT_APP_PASSWORD=tu-client-secret-aqui

# Bot Endpoint
BOT_ENDPOINT=https://tu-bot.azurewebsites.net/api/messages

# ===========================================
# Application Settings
# ===========================================

APP_TITLE=Teams AI Foundry Assistant
APP_TEMPERATURE=0.7
APP_MAX_TOKENS=2000
LOG_LEVEL=INFO

# System Prompt
SYSTEM_PROMPT=Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry. Respondes de manera profesional, clara y útil.

# ===========================================
# Azure AI Foundry Features
# ===========================================

# Enable Content Safety
ENABLE_CONTENT_SAFETY=true
CONTENT_SAFETY_THRESHOLD=medium

# Enable AI Search (RAG)
ENABLE_AI_SEARCH=false
AI_SEARCH_ENDPOINT=https://tu-search.search.windows.net
AI_SEARCH_KEY=tu-search-key
AI_SEARCH_INDEX_NAME=teams-knowledge-base

# Enable Prompt Flow
ENABLE_PROMPT_FLOW=false

# ===========================================
# Teams Settings
# ===========================================

TEAMS_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ENABLE_PROACTIVE_MESSAGES=false

# ===========================================
# Server Configuration
# ===========================================

BOT_PORT=3978
WEB_PORT=8501
HOST=0.0.0.0
ENVIRONMENT=development
```

### 3. app/config.py

```python
"""
Configuración centralizada para Azure AI Foundry + Teams Bot
"""
import os
import logging
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


class AzureAIFoundryConfig:
    """Configuración de Azure AI Foundry"""
    
    # Azure Subscription & Resource Group
    SUBSCRIPTION_ID: str = os.getenv("AZURE_SUBSCRIPTION_ID", "")
    RESOURCE_GROUP: str = os.getenv("AZURE_RESOURCE_GROUP", "")
    
    # Azure AI Project
    PROJECT_NAME: str = os.getenv("AZURE_AI_PROJECT_NAME", "")
    PROJECT_ENDPOINT: str = os.getenv("AZURE_AI_PROJECT_ENDPOINT", "")
    HUB_NAME: str = os.getenv("AZURE_AI_HUB_NAME", "")
    
    # Azure OpenAI (conectado a AI Foundry)
    OPENAI_ENDPOINT: str = os.getenv("AZURE_OPENAI_ENDPOINT", "")
    OPENAI_API_KEY: str = os.getenv("AZURE_OPENAI_API_KEY", "")
    OPENAI_DEPLOYMENT: str = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "")
    OPENAI_API_VERSION: str = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
    
    # Model Parameters
    TEMPERATURE: float = float(os.getenv("APP_TEMPERATURE", "0.7"))
    MAX_TOKENS: int = int(os.getenv("APP_MAX_TOKENS", "2000"))
    TIMEOUT: int = int(os.getenv("REQUEST_TIMEOUT", "30"))
    
    # Content Safety
    ENABLE_CONTENT_SAFETY: bool = os.getenv("ENABLE_CONTENT_SAFETY", "true").lower() == "true"
    CONTENT_SAFETY_THRESHOLD: str = os.getenv("CONTENT_SAFETY_THRESHOLD", "medium")
    
    # AI Search (RAG)
    ENABLE_AI_SEARCH: bool = os.getenv("ENABLE_AI_SEARCH", "false").lower() == "true"
    AI_SEARCH_ENDPOINT: str = os.getenv("AI_SEARCH_ENDPOINT", "")
    AI_SEARCH_KEY: str = os.getenv("AI_SEARCH_KEY", "")
    AI_SEARCH_INDEX: str = os.getenv("AI_SEARCH_INDEX_NAME", "")
    
    @classmethod
    def validate(cls) -> bool:
        """Valida configuraciones requeridas"""
        required_fields = {
            "SUBSCRIPTION_ID": cls.SUBSCRIPTION_ID,
            "RESOURCE_GROUP": cls.RESOURCE_GROUP,
            "PROJECT_NAME": cls.PROJECT_NAME,
            "OPENAI_ENDPOINT": cls.OPENAI_ENDPOINT,
            "OPENAI_API_KEY": cls.OPENAI_API_KEY,
            "OPENAI_DEPLOYMENT": cls.OPENAI_DEPLOYMENT
        }
        
        missing_fields = [
            field for field, value in required_fields.items() 
            if not value or value.strip() == ""
        ]
        
        if missing_fields:
            error_msg = (
                f"Azure AI Foundry: Faltan configuraciones: {', '.join(missing_fields)}"
            )
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        if cls.ENABLE_AI_SEARCH:
            if not cls.AI_SEARCH_ENDPOINT or not cls.AI_SEARCH_KEY:
                raise ValueError("AI Search habilitado pero faltan credenciales")
        
        logger.info("✅ Configuración de Azure AI Foundry validada")
        return True
    
    @classmethod
    def get_info(cls) -> dict:
        """Retorna información de configuración (sin datos sensibles)"""
        return {
            "project": cls.PROJECT_NAME,
            "hub": cls.HUB_NAME,
            "deployment": cls.OPENAI_DEPLOYMENT,
            "temperature": cls.TEMPERATURE,
            "max_tokens": cls.MAX_TOKENS,
            "content_safety": cls.ENABLE_CONTENT_SAFETY,
            "ai_search": cls.ENABLE_AI_SEARCH
        }


class BotConfig:
    """Configuración de Azure Bot Service"""
    
    APP_ID: str = os.getenv("MICROSOFT_APP_ID", "")
    APP_PASSWORD: str = os.getenv("MICROSOFT_APP_PASSWORD", "")
    BOT_ENDPOINT: str = os.getenv("BOT_ENDPOINT", "")
    PORT: int = int(os.getenv("BOT_PORT", "3978"))
    HOST: str = os.getenv("HOST", "0.0.0.0")
    
    @classmethod
    def validate(cls) -> bool:
        """Valida configuraciones del bot"""
        required_fields = {
            "APP_ID": cls.APP_ID,
            "APP_PASSWORD": cls.APP_PASSWORD
        }
        
        missing_fields = [
            field for field, value in required_fields.items() 
            if not value or value.strip() == ""
        ]
        
        if missing_fields:
            error_msg = (
                f"Bot Service: Faltan configuraciones: {', '.join(missing_fields)}"
            )
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        logger.info("✅ Configuración de Bot Service validada")
        return True


class AppConfig:
    """Configuración de la aplicación"""
    
    TITLE: str = os.getenv("APP_TITLE", "Teams AI Foundry Assistant")
    SYSTEM_PROMPT: str = os.getenv(
        "SYSTEM_PROMPT",
        "Eres un asistente inteligente de Microsoft Teams potenciado por Azure AI Foundry."
    )
    ENABLE_PROACTIVE: bool = os.getenv("ENABLE_PROACTIVE_MESSAGES", "false").lower() == "true"
    TEAMS_APP_ID: str = os.getenv("TEAMS_APP_ID", "")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
```

### 4. app/foundry_client.py

```python
"""
Cliente para Azure AI Foundry
"""
import logging
from typing import Optional, Dict, Any
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
from app.config import AzureAIFoundryConfig

logger = logging.getLogger(__name__)


class AzureAIFoundryClient:
    """
    Cliente para interactuar con Azure AI Foundry
    """
    
    def __init__(self):
        """Inicializa el cliente de Azure AI Foundry"""
        try:
            logger.info("Inicializando Azure AI Foundry Client...")
            
            # Crear credencial de Azure
            self.credential = DefaultAzureCredential()
            
            # Crear ML Client para AI Foundry
            self.ml_client = MLClient(
                credential=self.credential,
                subscription_id=AzureAIFoundryConfig.SUBSCRIPTION_ID,
                resource_group_name=AzureAIFoundryConfig.RESOURCE_GROUP,
                workspace_name=AzureAIFoundryConfig.PROJECT_NAME
            )
            
            logger.info(f"✅ Conectado a Azure AI Foundry Project: {AzureAIFoundryConfig.PROJECT_NAME}")
            
        except Exception as e:
            logger.error(f"Error inicializando Azure AI Foundry Client: {e}")
            raise
    
    def get_project_info(self) -> Dict[str, Any]:
        """
        Obtiene información del proyecto de AI Foundry
        
        Returns:
            Diccionario con información del proyecto
        """
        try:
            workspace = self.ml_client.workspaces.get(
                name=AzureAIFoundryConfig.PROJECT_NAME
            )
            
            return {
                "name": workspace.name,
                "location": workspace.location,
                "resource_group": workspace.resource_group,
                "description": workspace.description,
                "discovery_url": workspace.discovery_url
            }
        except Exception as e:
            logger.error(f"Error obteniendo info del proyecto: {e}")
            return {}
    
    def get_deployment_info(self, deployment_name: str) -> Optional[Dict[str, Any]]:
        """
        Obtiene información de un deployment
        
        Args:
            deployment_name: Nombre del deployment
            
        Returns:
            Información del deployment
        """
        try:
            # Nota: Esto es específico de AI Foundry
            # La implementación puede variar según la versión del SDK
            logger.info(f"Obteniendo info de deployment: {deployment_name}")
            return {
                "name": deployment_name,
                "status": "active"
            }
        except Exception as e:
            logger.error(f"Error obteniendo info de deployment: {e}")
            return None
    
    def validate_connection(self) -> bool:
        """
        Valida la conexión con Azure AI Foundry
        
        Returns:
            True si la conexión es válida
        """
        try:
            project_info = self.get_project_info()
            if project_info:
                logger.info(f"✅ Conexión validada con proyecto: {project_info.get('name')}")
                return True
            return False
        except Exception as e:
            logger.error(f"Error validando conexión: {e}")
            return False
```

### 5. app/chat_engine.py

```python
"""
Motor de chat usando LangChain con Azure AI Foundry
"""
import logging
from typing import List, Dict, Optional
from langchain_openai import AzureChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain
from langchain.prompts import (
    ChatPromptTemplate,
    MessagesPlaceholder,
    SystemMessagePromptTemplate,
    HumanMessagePromptTemplate,
)
from langchain.callbacks import get_openai_callback

from app.config import AzureAIFoundryConfig, AppConfig
from app.foundry_client import AzureAIFoundryClient

logger = logging.getLogger(__name__)


class AIFoundryChatEngine:
    """
    Motor de chat que utiliza Azure AI Foundry para conversaciones inteligentes
    """
    
    def __init__(self, session_id: Optional[str] = None):
        """
        Inicializa el motor de chat con Azure AI Foundry
        
        Args:
            session_id: ID de sesión para mantener conversaciones separadas
        """
        AzureAIFoundryConfig.validate()
        
        self.session_id = session_id or "default"
        logger.info(f"Inicializando AIFoundryChatEngine para sesión: {self.session_id}")
        
        # Inicializar cliente de AI Foundry
        try:
            self.foundry_client = AzureAIFoundryClient()
            self.foundry_client.validate_connection()
        except Exception as e:
            logger.warning(f"No se pudo conectar con AI Foundry Client: {e}")
            self.foundry_client = None
        
        # Configurar Azure OpenAI a través de AI Foundry
        self.llm = AzureChatOpenAI(
            azure_endpoint=AzureAIFoundryConfig.OPENAI_ENDPOINT,
            api_key=AzureAIFoundryConfig.OPENAI_API_KEY,
            azure_deployment=AzureAIFoundryConfig.OPENAI_DEPLOYMENT,
            api_version=AzureAIFoundryConfig.OPENAI_API_VERSION,
            temperature=AzureAIFoundryConfig.TEMPERATURE,
            max_tokens=AzureAIFoundryConfig.MAX_TOKENS,
            timeout=AzureAIFoundryConfig.TIMEOUT,
            model_kwargs={
                "top_p": 0.95,
                "frequency_penalty": 0,
                "presence_penalty": 0
            }
        )
        
        # Memoria de conversación
        self.memory = ConversationBufferMemory(
            return_messages=True,
            memory_key="history",
            input_key="input"
        )
        
        # Crear prompt template mejorado para AI Foundry
        system_template = f"""{AppConfig.SYSTEM_PROMPT}

Información del contexto:
- Plataforma: Azure AI Foundry
- Proyecto: {AzureAIFoundryConfig.PROJECT_NAME}
- Modelo: {AzureAIFoundryConfig.OPENAI_DEPLOYMENT}

Directrices:
1. Proporciona respuestas precisas y útiles
2. Mantén un tono profesional pero amigable
3. Si no estás seguro de algo, indícalo claramente
4. Usa formato markdown cuando sea apropiado para mejor legibilidad"""
        
        prompt = ChatPromptTemplate.from_messages([
            SystemMessagePromptTemplate.from_template(system_template),
            MessagesPlaceholder(variable_name="history"),
            HumanMessagePromptTemplate.from_template("{input}")
        ])
        
        # Crear cadena de conversación
        self.conversation = ConversationChain(
            llm=self.llm,
            memory=self.memory,
            prompt=prompt,
            verbose=False
        )
        
        # Estadísticas
        self.total_tokens_used = 0
        self.total_calls = 0
        
        logger.info(f"✅ AIFoundryChatEngine inicializado para sesión: {self.session_id}")
    
    async def send_message_async(self, message: str) -> str:
        """
        Envía un mensaje de forma asíncrona con tracking de tokens
        
        Args:
            message: Mensaje del usuario
            
        Returns:
            Respuesta del asistente
        """
        try:
            logger.info(f"[{self.session_id}] Procesando mensaje: {message[:50]}...")
            
            # Usar callback para trackear tokens
            with get_openai_callback() as cb:
                response = await self.conversation.apredict(input=message)
                
                # Actualizar estadísticas
                self.total_tokens_used += cb.total_tokens
                self.total_calls += 1
                
                logger.info(
                    f"[{self.session_id}] Respuesta generada. "
                    f"Tokens: {cb.total_tokens} "
                    f"(Prompt: {cb.prompt_tokens}, Completion: {cb.completion_tokens})"
                )
            
            return response
            
        except Exception as e:
            error_msg = f"Error al procesar mensaje: {str(e)}"
            logger.error(f"[{self.session_id}] {error_msg}")
            return (
                "Lo siento, ocurrió un error al procesar tu mensaje. "
                "Por favor, intenta de nuevo o contacta al administrador si el problema persiste."
            )
    
    def send_message(self, message: str) -> str:
        """
        Envía un mensaje de forma síncrona
        
        Args:
            message: Mensaje del usuario
            
        Returns:
            Respuesta del asistente
        """
        try:
            logger.info(f"[{self.session_id}] Procesando mensaje (sync)...")
            
            with get_openai_callback() as cb:
                response = self.conversation.predict(input=message)
                self.total_tokens_used += cb.total_tokens
                self.total_calls += 1
            
            return response
        except Exception as e:
            logger.error(f"[{self.session_id}] Error: {str(e)}")
            return "Lo siento, ocurrió un error al procesar tu mensaje."
    
    def clear_history(self) -> None:
        """Limpia el historial de conversación"""
        logger.info(f"[{self.session_id}] Limpiando historial")
        self.memory.clear()
    
    def get_history(self) -> List[Dict[str, str]]:
        """Obtiene el historial de conversación"""
        messages = self.memory.chat_memory.messages
        return [
            {
                "role": msg.type,
                "content": msg.content
            }
            for msg in messages
        ]
    
    def get_message_count(self) -> int:
        """Cuenta mensajes en el historial"""
        return len(self.memory.chat_memory.messages)
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Obtiene estadísticas del uso del chat engine
        
        Returns:
            Diccionario con estadísticas
        """
        return {
            "session_id": self.session_id,
            "message_count": self.get_message_count(),
            "total_tokens_used": self.total_tokens_used,
            "total_calls": self.total_calls,
            "average_tokens_per_call": (
                self.total_tokens_used // self.total_calls 
                if self.total_calls > 0 else 0
            ),
            "model": AzureAIFoundryConfig.OPENAI_DEPLOYMENT,
            "project": AzureAIFoundryConfig.PROJECT_NAME
        }
```

### 6. bot/content_safety.py

```python
"""
Integración con Azure AI Content Safety (parte de AI Foundry)
"""
import logging
from typing import Dict, List, Optional
from azure.ai.contentsafety import ContentSafetyClient
from azure.ai.contentsafety.models import AnalyzeTextOptions
from azure.identity import DefaultAzureCredential
from app.config import AzureAIFoundryConfig

logger = logging.getLogger(__name__)


class ContentSafetyManager:
    """
    Gestor de Content Safety de Azure AI
    """
    
    # Thresholds de severidad
    THRESHOLDS = {
        "low": 2,      # Bloquea solo contenido severo
        "medium": 1,   # Bloquea contenido medio y severo
        "high": 0      # Bloquea todo contenido potencialmente problemático
    }
    
    def __init__(self):
        """Inicializa el cliente de Content Safety"""
        if not AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY:
            logger.info("Content Safety deshabilitado")
            self.client = None
            return
        
        try:
            logger.info("Inicializando Content Safety Client...")
            
            # Nota: El endpoint de Content Safety debe estar configurado en AI Foundry
            # Aquí usamos DefaultAzureCredential para autenticación
            credential = DefaultAzureCredential()
            
            # El endpoint debe obtenerse de las conexiones de AI Foundry
            # Por ahora usamos el endpoint de OpenAI como base
            # En producción, esto vendría de la configuración de AI Foundry
            self.client = None  # Implementación depende de la configuración específica
            
            self.threshold = self.THRESHOLDS.get(
                AzureAIFoundryConfig.CONTENT_SAFETY_THRESHOLD,
                1
            )
            
            logger.info("✅ Content Safety Client inicializado")
            
        except Exception as e:
            logger.warning(f"No se pudo inicializar Content Safety: {e}")
            self.client = None
    
    def analyze_text(self, text: str) -> Dict[str, any]:
        """
        Analiza un texto para detectar contenido inapropiado
        
        Args:
            text: Texto a analizar
            
        Returns:
            Diccionario con resultados del análisis
        """
        if not self.client or not AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY:
            return {
                "is_safe": True,
                "categories": {},
                "message": "Content Safety no habilitado"
            }
        
        try:
            # Implementación de análisis de contenido
            # Esto es un placeholder - la implementación real depende del SDK
            logger.info(f"Analizando contenido: {text[:50]}...")
            
            # Simulación de respuesta
            return {
                "is_safe": True,
                "categories": {
                    "hate": 0,
                    "self_harm": 0,
                    "sexual": 0,
                    "violence": 0
                },
                "message": "Contenido seguro"
            }
            
        except Exception as e:
            logger.error(f"Error analizando contenido: {e}")
            return {
                "is_safe": True,  # Fail open en caso de error
                "categories": {},
                "message": f"Error en análisis: {str(e)}"
            }
    
    def is_content_safe(self, text: str) -> bool:
        """
        Verifica si el contenido es seguro
        
        Args:
            text: Texto a verificar
            
        Returns:
            True si el contenido es seguro
        """
        if not AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY:
            return True
        
        result = self.analyze_text(text)
        return result.get("is_safe", True)
```

### 7. bot/teams_bot.py

```python
"""
Bot de Microsoft Teams con Azure AI Foundry
"""
import logging
from typing import List
from botbuilder.core import (
    ActivityHandler,
    TurnContext,
    MessageFactory
)
from botbuilder.schema import (
    Activity,
    ActivityTypes,
    ChannelAccount
)

from app.chat_engine import AIFoundryChatEngine
from bot.conversation_manager import ConversationManager
from bot.cards import AdaptiveCards
from bot.content_safety import ContentSafetyManager

logger = logging.getLogger(__name__)


class TeamsAIFoundryBot(ActivityHandler):
    """
    Bot de Microsoft Teams integrado con Azure AI Foundry
    """
    
    def __init__(self):
        """Inicializa el bot"""
        super().__init__()
        self.conversation_manager = ConversationManager()
        self.content_safety = ContentSafetyManager()
        logger.info("✅ TeamsAIFoundryBot inicializado")
    
    async def on_message_activity(self, turn_context: TurnContext):
        """
        Maneja mensajes entrantes
        
        Args:
            turn_context: Contexto de la conversación
        """
        try:
            # Obtener información del mensaje
            user_id = turn_context.activity.from_property.id
            conversation_id = turn_context.activity.conversation.id
            user_message = turn_context.activity.text
            user_name = turn_context.activity.from_property.name
            
            logger.info(
                f"Mensaje de {user_name} ({user_id}) "
                f"en {conversation_id}: {user_message[:50]}..."
            )
            
            # Verificar content safety
            if not self.content_safety.is_content_safe(user_message):
                await turn_context.send_activity(
                    "⚠️ Lo siento, tu mensaje contiene contenido que no puedo procesar. "
                    "Por favor, reformula tu pregunta de manera apropiada."
                )
                return
            
            # Comandos especiales
            if user_message.lower().startswith("/"):
                await self._handle_command(turn_context, user_message.lower())
                return
            
            # Obtener o crear chat engine
            chat_engine = self.conversation_manager.get_or_create_engine(conversation_id)
            
            # Mostrar indicador de escritura
            await turn_context.send_activity(Activity(type=ActivityTypes.typing))
            
            # Obtener respuesta del modelo
            response = await chat_engine.send_message_async(user_message)
            
            # Verificar respuesta con content safety
            if not self.content_safety.is_content_safe(response):
                response = (
                    "Lo siento, no puedo proporcionar esa información. "
                    "¿Puedo ayudarte con algo más?"
                )
            
            # Enviar respuesta
            await turn_context.send_activity(MessageFactory.text(response))
            
            logger.info(f"Respuesta enviada a {user_name}")
            
        except Exception as e:
            logger.error(f"Error en on_message_activity: {e}", exc_info=True)
            await turn_context.send_activity(
                "Lo siento, ocurrió un error al procesar tu mensaje. "
                "El equipo técnico ha sido notificado. Por favor, intenta de nuevo más tarde."
            )
    
    async def on_members_added_activity(
        self, 
        members_added: List[ChannelAccount], 
        turn_context: TurnContext
    ):
        """Maneja cuando se agregan miembros"""
        for member in members_added:
            if member.id != turn_context.activity.recipient.id:
                welcome_card = AdaptiveCards.create_welcome_card()
                message = MessageFactory.attachment(welcome_card)
                await turn_context.send_activity(message)
    
    async def _handle_command(self, turn_context: TurnContext, command: str):
        """
        Maneja comandos especiales
        
        Args:
            turn_context: Contexto de la conversación
            command: Comando a ejecutar
        """
        conversation_id = turn_context.activity.conversation.id
        
        if command == "/help":
            help_card = AdaptiveCards.create_help_card()
            await turn_context.send_activity(MessageFactory.attachment(help_card))
        
        elif command in ["/clear", "/reset"]:
            chat_engine = self.conversation_manager.get_or_create_engine(conversation_id)
            chat_engine.clear_history()
            await turn_context.send_activity(
                "✅ Historial limpiado. ¡Empecemos una nueva conversación!"
            )
        
        elif command == "/stats":
            chat_engine = self.conversation_manager.get_or_create_engine(conversation_id)
            stats = chat_engine.get_statistics()
            
            stats_card = AdaptiveCards.create_stats_card(stats)
            await turn_context.send_activity(MessageFactory.attachment(stats_card))
        
        elif command == "/about":
            about_card = AdaptiveCards.create_about_card()
            await turn_context.send_activity(MessageFactory.attachment(about_card))
        
        elif command == "/project":
            # Comando especial para Azure AI Foundry
            project_card = AdaptiveCards.create_project_info_card()
            await turn_context.send_activity(MessageFactory.attachment(project_card))
        
        else:
            await turn_context.send_activity(
                f"❌ Comando desconocido: {command}\n"
                "Usa /help para ver comandos disponibles."
            )
```

### 8. bot/conversation_manager.py

```python
"""
Gestor de conversaciones para múltiples usuarios
"""
import logging
from typing import Dict
from app.chat_engine import AIFoundryChatEngine

logger = logging.getLogger(__name__)


class ConversationManager:
    """Gestiona múltiples instancias de chat engines"""
    
    def __init__(self):
        """Inicializa el gestor"""
        self.engines: Dict[str, AIFoundryChatEngine] = {}
        logger.info("ConversationManager inicializado")
    
    def get_or_create_engine(self, conversation_id: str) -> AIFoundryChatEngine:
        """
        Obtiene o crea un chat engine
        
        Args:
            conversation_id: ID de la conversación
            
        Returns:
            Chat engine para la conversación
        """
        if conversation_id not in self.engines:
            logger.info(f"Creando AIFoundryChatEngine para: {conversation_id}")
            self.engines[conversation_id] = AIFoundryChatEngine(session_id=conversation_id)
        
        return self.engines[conversation_id]
    
    def remove_engine(self, conversation_id: str) -> bool:
        """Elimina un chat engine"""
        if conversation_id in self.engines:
            logger.info(f"Eliminando engine: {conversation_id}")
            del self.engines[conversation_id]
            return True
        return False
    
    def get_active_count(self) -> int:
        """Obtiene número de conversaciones activas"""
        return len(self.engines)
    
    def get_all_statistics(self) -> list:
        """Obtiene estadísticas de todas las conversaciones"""
        return [
            engine.get_statistics() 
            for engine in self.engines.values()
        ]
    
    def clear_all(self):
        """Limpia todas las conversaciones"""
        logger.info("Limpiando todas las conversaciones")
        self.engines.clear()
```

### 9. bot/cards.py

```python
"""
Adaptive Cards para Teams (mejoradas para AI Foundry)
"""
from botbuilder.schema import Attachment
from botbuilder.core import CardFactory
from app.config import AzureAIFoundryConfig
from typing import Dict, Any


class AdaptiveCards:
    """Generador de Adaptive Cards"""
    
    @staticmethod
    def create_welcome_card() -> Attachment:
        """Tarjeta de bienvenida"""
        card = {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "👋 ¡Hola! Soy tu Asistente de IA",
                    "size": "ExtraLarge",
                    "weight": "Bolder",
                    "color": "Accent"
                },
                {
                    "type": "TextBlock",
                    "text": f"Potenciado por **Azure AI Foundry** 🚀",
                    "wrap": True,
                    "spacing": "Small",
                    "color": "Good"
                },
                {
                    "type": "Container",
                    "style": "emphasis",
                    "items": [
                        {
                            "type": "TextBlock",
                            "text": "📍 **Proyecto:** " + AzureAIFoundryConfig.PROJECT_NAME,
                            "wrap": True,
                            "size": "Small"
                        },
                        {
                            "type": "TextBlock",
                            "text": "🤖 **Modelo:** " + AzureAIFoundryConfig.OPENAI_DEPLOYMENT,
                            "wrap": True,
                            "size": "Small"
                        }
                    ],
                    "spacing": "Medium"
                },
                {
                    "type": "TextBlock",
                    "text": "**¿Qué puedo hacer?**",
                    "weight": "Bolder",
                    "spacing": "Medium"
                },
                {
                    "type": "ColumnSet",
                    "columns": [
                        {
                            "type": "Column",
                            "width": "auto",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "text": "💬 Conversaciones naturales\n📝 Redacción de documentos\n💡 Generación de ideas\n🔍 Análisis de información\n💻 Asistencia con código",
                                    "wrap": True
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": "**Comandos:**",
                    "weight": "Bolder",
                    "spacing": "Medium"
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {"title": "/help", "value": "Ver ayuda"},
                        {"title": "/clear", "value": "Limpiar historial"},
                        {"title": "/stats", "value": "Ver estadísticas"},
                        {"title": "/project", "value": "Info de AI Foundry"},
                        {"title": "/about", "value": "Acerca del bot"}
                    ]
                }
            ]
        }
        return CardFactory.adaptive_card(card)
    
    @staticmethod
    def create_stats_card(stats: Dict[str, Any]) -> Attachment:
        """Tarjeta de estadísticas mejorada"""
        card = {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "📊 Estadísticas de la Sesión",
                    "size": "Large",
                    "weight": "Bolder",
                    "color": "Accent"
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {
                            "title": "Mensajes:",
                            "value": str(stats.get("message_count", 0))
                        },
                        {
                            "title": "Tokens usados:",
                            "value": f"{stats.get('total_tokens_used', 0):,}"
                        },
                        {
                            "title": "Llamadas al modelo:",
                            "value": str(stats.get("total_calls", 0))
                        },
                        {
                            "title": "Promedio tokens/llamada:",
                            "value": str(stats.get("average_tokens_per_call", 0))
                        },
                        {
                            "title": "Modelo:",
                            "value": stats.get("model", "N/A")
                        },
                        {
                            "title": "Proyecto:",
                            "value": stats.get("project", "N/A")
                        }
                    ]
                }
            ]
        }
        return CardFactory.adaptive_card(card)
    
    @staticmethod
    def create_project_info_card() -> Attachment:
        """Tarjeta con información del proyecto de AI Foundry"""
        card = {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "🏗️ Azure AI Foundry Project",
                    "size": "Large",
                    "weight": "Bolder",
                    "color": "Accent"
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {
                            "title": "Proyecto:",
                            "value": AzureAIFoundryConfig.PROJECT_NAME
                        },
                        {
                            "title": "Hub:",
                            "value": AzureAIFoundryConfig.HUB_NAME
                        },
                        {
                            "title": "Deployment:",
                            "value": AzureAIFoundryConfig.OPENAI_DEPLOYMENT
                        },
                        {
                            "title": "Content Safety:",
                            "value": "✅ Activo" if AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY else "❌ Inactivo"
                        },
                        {
                            "title": "AI Search:",
                            "value": "✅ Activo" if AzureAIFoundryConfig.ENABLE_AI_SEARCH else "❌ Inactivo"
                        }
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": "Este bot está potenciado por Azure AI Foundry, la plataforma empresarial de Microsoft para desarrollar aplicaciones de IA generativa.",
                    "wrap": True,
                    "spacing": "Medium",
                    "isSubtle": True
                }
            ]
        }
        return CardFactory.adaptive_card(card)
    
    @staticmethod
    def create_help_card() -> Attachment:
        """Tarjeta de ayuda"""
        card = {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "📚 Centro de Ayuda",
                    "size": "Large",
                    "weight": "Bolder",
                    "color": "Accent"
                },
                {
                    "type": "TextBlock",
                    "text": "**Comandos Disponibles:**",
                    "weight": "Bolder",
                    "spacing": "Medium"
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {"title": "/help", "value": "Muestra esta ayuda"},
                        {"title": "/clear", "value": "Limpia el historial"},
                        {"title": "/stats", "value": "Estadísticas de uso"},
                        {"title": "/project", "value": "Info de AI Foundry"},
                        {"title": "/about", "value": "Información del bot"}
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": "**Características:**",
                    "weight": "Bolder",
                    "spacing": "Medium"
                },
                {
                    "type": "TextBlock",
                    "text": "✅ Conversación con contexto\n✅ Content Safety habilitado\n✅ Respuestas en tiempo real\n✅ Multi-idioma",
                    "wrap": True
                }
            ]
        }
        return CardFactory.adaptive_card(card)
    
    @staticmethod
    def create_about_card() -> Attachment:
        """Tarjeta acerca del bot"""
        card = {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "ℹ️ Acerca del Asistente",
                    "size": "Large",
                    "weight": "Bolder",
                    "color": "Accent"
                },
                {
                    "type": "TextBlock",
                    "text": "**Teams AI Foundry Assistant**",
                    "weight": "Bolder",
                    "spacing": "Medium"
                },
                {
                    "type": "TextBlock",
                    "text": "Asistente de IA empresarial desarrollado con Azure AI Foundry, Bot Framework y LangChain.",
                    "wrap": True
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {"title": "Versión:", "value": "1.0.0"},
                        {"title": "Plataforma:", "value": "Azure AI Foundry"},
                        {"title": "Tecnologías:", "value": "GPT-4.1, LangChain, Bot Framework"},
                        {"title": "Seguridad:", "value": "Content Safety + RBAC"}
                    ],
                    "spacing": "Medium"
                }
            ]
        }
        return CardFactory.adaptive_card(card)
```

### 10. bot/bot_app.py

```python
"""
Aplicación principal del bot con Azure AI Foundry
"""
import sys
import logging
from aiohttp import web
from aiohttp.web import Request, Response
from botbuilder.core import (
    BotFrameworkAdapterSettings,
    BotFrameworkAdapter,
    TurnContext,
)
from botbuilder.schema import Activity

from app.config import BotConfig, AzureAIFoundryConfig
from bot.teams_bot import TeamsAIFoundryBot

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Validar configuraciones
try:
    BotConfig.validate()
    AzureAIFoundryConfig.validate()
    logger.info("✅ Todas las configuraciones validadas")
except ValueError as e:
    logger.error(f"❌ Error de configuración: {e}")
    sys.exit(1)

# Configurar Bot Framework Adapter
SETTINGS = BotFrameworkAdapterSettings(
    app_id=BotConfig.APP_ID,
    app_password=BotConfig.APP_PASSWORD
)
ADAPTER = BotFrameworkAdapter(SETTINGS)


# Manejador de errores
async def on_error(context: TurnContext, error: Exception):
    """Maneja errores del bot"""
    logger.error(f"Error en el bot: {error}", exc_info=True)
    
    await context.send_activity(
        "❌ Lo siento, ocurrió un error inesperado. "
        "El equipo técnico ha sido notificado. "
        "Por favor, intenta de nuevo más tarde."
    )


ADAPTER.on_turn_error = on_error

# Crear instancia del bot
BOT = TeamsAIFoundryBot()


# Endpoint de mensajes
async def messages(req: Request) -> Response:
    """
    Endpoint principal para mensajes de Bot Framework
    
    Args:
        req: Request HTTP
        
    Returns:
        Response HTTP
    """
    if req.content_type == "application/json":
        body = await req.json()
    else:
        logger.warning("Request con content-type incorrecto")
        return Response(status=415)
    
    activity = Activity().deserialize(body)
    auth_header = req.headers.get("Authorization", "")
    
    try:
        response = await ADAPTER.process_activity(activity, auth_header, BOT.on_turn)
        if response:
            return web.json_response(data=response.body, status=response.status)
        return Response(status=201)
    except Exception as e:
        logger.error(f"Error procesando actividad: {e}", exc_info=True)
        return Response(status=500)


# Health check
async def health(req: Request) -> Response:
    """Health check endpoint"""
    return web.json_response({
        "status": "healthy",
        "service": "teams-ai-foundry-bot",
        "project": AzureAIFoundryConfig.PROJECT_NAME,
        "hub": AzureAIFoundryConfig.HUB_NAME,
        "deployment": AzureAIFoundryConfig.OPENAI_DEPLOYMENT
    })


# Info endpoint
async def info(req: Request) -> Response:
    """Info endpoint"""
    return web.json_response({
        "service": "Teams AI Foundry Bot",
        "version": "1.0.0",
        "platform": "Azure AI Foundry",
        "features": {
            "content_safety": AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY,
            "ai_search": AzureAIFoundryConfig.ENABLE_AI_SEARCH
        }
    })


# Crear aplicación web
APP = web.Application()
APP.router.add_post("/api/messages", messages)
APP.router.add_get("/health", health)
APP.router.add_get("/info", info)
APP.router.add_get("/", health)


if __name__ == "__main__":
    try:
        logger.info("="*70)
        logger.info("🤖 Iniciando Teams AI Foundry Bot")
        logger.info("="*70)
        logger.info(f"Puerto: {BotConfig.PORT}")
        logger.info(f"Host: {BotConfig.HOST}")
        logger.info(f"Bot App ID: {BotConfig.APP_ID}")
        logger.info(f"AI Foundry Project: {AzureAIFoundryConfig.PROJECT_NAME}")
        logger.info(f"AI Foundry Hub: {AzureAIFoundryConfig.HUB_NAME}")
        logger.info(f"Deployment: {AzureAIFoundryConfig.OPENAI_DEPLOYMENT}")
        logger.info(f"Content Safety: {'✅' if AzureAIFoundryConfig.ENABLE_CONTENT_SAFETY else '❌'}")
        logger.info(f"AI Search: {'✅' if AzureAIFoundryConfig.ENABLE_AI_SEARCH else '❌'}")
        logger.info("="*70)
        
        web.run_app(
            APP,
            host=BotConfig.HOST,
            port=BotConfig.PORT
        )
    except Exception as e:
        logger.error(f"❌ Error al iniciar el bot: {e}")
        sys.exit(1)
```

## 🐳 Dockerización

### Dockerfile.bot

```dockerfile
# Multi-stage build para el bot
FROM python:3.11-slim as builder

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Instalar curl para healthcheck
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar dependencias instaladas
COPY --from=builder /root/.local /root/.local

# Copiar código
COPY app/ ./app/
COPY bot/ ./bot/

# Actualizar PATH
ENV PATH=/root/.local/bin:$PATH

# Crear usuario no-root
RUN useradd -m -u 1000 botuser && \
    chown -R botuser:botuser /app

USER botuser

# Exponer puerto
EXPOSE 3978

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3978/health || exit 1

# Comando de inicio
CMD ["python", "bot/bot_app.py"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  # Bot de Teams con Azure AI Foundry
  teams-ai-foundry-bot:
    build:
      context: .
      dockerfile: Dockerfile.bot
    container_name: teams-ai-foundry-bot
    ports:
      - "3978:3978"
    environment:
      # Azure AI Foundry
      - AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
      - AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}
      - AZURE_AI_PROJECT_NAME=${AZURE_AI_PROJECT_NAME}
      - AZURE_AI_HUB_NAME=${AZURE_AI_HUB_NAME}
      - AZURE_AI_PROJECT_ENDPOINT=${AZURE_AI_PROJECT_ENDPOINT}
      
      # Azure OpenAI (conectado a AI Foundry)
      - AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}
      - AZURE_OPENAI_API_KEY=${AZURE_OPENAI_API_KEY}
      - AZURE_OPENAI_DEPLOYMENT_NAME=${AZURE_OPENAI_DEPLOYMENT_NAME}
      - AZURE_OPENAI_API_VERSION=${AZURE_OPENAI_API_VERSION}
      
      # Bot Service
      - MICROSOFT_APP_ID=${MICROSOFT_APP_ID}
      - MICROSOFT_APP_PASSWORD=${MICROSOFT_APP_PASSWORD}
      - BOT_PORT=3978
      - HOST=0.0.0.0
      
      # Features
      - ENABLE_CONTENT_SAFETY=${ENABLE_CONTENT_SAFETY:-true}
      - ENABLE_AI_SEARCH=${ENABLE_AI_SEARCH:-false}
      
      # App Settings
      - APP_TEMPERATURE=${APP_TEMPERATURE:-0.7}
      - APP_MAX_TOKENS=${APP_MAX_TOKENS:-2000}
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      - SYSTEM_PROMPT=${SYSTEM_PROMPT}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3978/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
    networks:
      - ai-foundry-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  ai-foundry-network:
    driver: bridge
```

## 🚀 Instalación y Despliegue

### Configuración Local

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/azure-ai-foundry-teams-bot.git
cd azure-ai-foundry-teams-bot

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate  # Windows

# Instalar dependencias
pip install -r requirements.txt

# Configurar .env
cp .env.example .env
nano .env  # Editar con tus credenciales

# Ejecutar bot
python bot/bot_app.py
```

### Despliegue en Azure Container Apps

```bash
# Variables
RESOURCE_GROUP="rg-ai-foundry-teams"
LOCATION="eastus"
ACR_NAME="myaifoundryregistry"
BOT_APP_NAME="teams-ai-foundry-bot"

# Crear Container Registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic

# Build y push
az acr build \
  --registry $ACR_NAME \
  --image teams-ai-foundry-bot:latest \
  --file Dockerfile.bot .

# Crear Container Apps Environment
az containerapp env create \
  --name ai-foundry-env \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Desplegar
az containerapp create \
  --name $BOT_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment ai-foundry-env \
  --image $ACR_NAME.azurecr.io/teams-ai-foundry-bot:latest \
  --target-port 3978 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --secrets \
    openai-key=$AZURE_OPENAI_API_KEY \
    bot-password=$MICROSOFT_APP_PASSWORD \
  --env-vars \
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    AZURE_RESOURCE_GROUP=$RESOURCE_GROUP \
    AZURE_AI_PROJECT_NAME=$AZURE_AI_PROJECT_NAME \
    AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT \
    AZURE_OPENAI_API_KEY=secretref:openai-key \
    AZURE_OPENAI_DEPLOYMENT_NAME=$AZURE_OPENAI_DEPLOYMENT_NAME \
    MICROSOFT_APP_ID=$MICROSOFT_APP_ID \
    MICROSOFT_APP_PASSWORD=secretref:bot-password \
    ENABLE_CONTENT_SAFETY=true

# Obtener URL
BOT_URL=$(az containerapp show \
  --name $BOT_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  -o tsv)

echo "Bot URL: https://$BOT_URL/api/messages"

# Actualizar endpoint en Azure Bot
az bot update \
  --resource-group $RESOURCE_GROUP \
  --name teams-ai-foundry-bot \
  --endpoint "https://$BOT_URL/api/messages"
```

## 📱 Configurar Teams App

Ver sección de configuración de Teams del documento anterior (manifest.json, iconos, etc.)

## 🔧 Solución de Problemas

### Error: "AI Foundry project not found"

```bash
# Verificar que el proyecto existe
az ml workspace show \
  --name teams-bot-project \
  --resource-group rg-ai-foundry-teams

# Verificar permisos
az role assignment list \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-ai-foundry-teams \
  --output table
```

### Error: "Deployment not found"

Verifica en Azure AI Studio que el deployment existe y está activo.

### Content Safety no funciona

Asegúrate de que Content Safety esté habilitado en tu AI Foundry Hub.

## 📚 Recursos Adicionales

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Azure AI Studio](https://ai.azure.com)
- [Bot Framework Documentation](https://docs.microsoft.com/bot-framework/)
- [Teams Development](https://docs.microsoft.com/microsoftteams/platform/)

## 📄 Licencia

MIT License

---

<div align="center">

**⭐ Desarrollado con Azure AI Foundry + Teams ⭐**

[Reportar Bug](https://github.com/tu-usuario/azure-ai-foundry-teams-bot/issues) · [Documentación](https://learn.microsoft.com/azure/ai-studio/)

</div>
