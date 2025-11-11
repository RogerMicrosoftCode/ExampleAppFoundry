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
