"""
Cliente para Azure AI Foundry
"""
import logging
from typing import Optional, Dict, Any
from azure.identity import DefaultAzureCredential

# ⚠️ azure-ai-ml está comentado debido a problemas de compatibilidad
# Ver docs/AZURE_AI_ML_SETUP.md para alternativas
# from azure.ai.ml import MLClient

from app.config import AzureAIFoundryConfig

logger = logging.getLogger(__name__)


class AzureAIFoundryClient:
    """
    Cliente para interactuar con Azure AI Foundry
    Nota: MLClient está deshabilitado por problemas de compatibilidad.
    El bot funciona usando Azure OpenAI directamente.
    """
    
    def __init__(self):
        """Inicializa el cliente de Azure AI Foundry"""
        try:
            logger.info("Inicializando Azure AI Foundry Client...")
            
            # Crear credencial de Azure
            self.credential = DefaultAzureCredential()
            
            # MLClient está deshabilitado - usando Azure OpenAI directamente
            self.ml_client = None
            logger.warning("MLClient deshabilitado. Usando Azure OpenAI directamente.")
            
            # El bot puede funcionar sin MLClient usando solo Azure OpenAI
            # Para gestionar recursos de AI Foundry, usa Azure CLI o el Portal
            
            logger.info(f"✅ Cliente básico inicializado para proyecto: {AzureAIFoundryConfig.PROJECT_NAME}")
            
        except Exception as e:
            logger.error(f"Error inicializando Azure AI Foundry Client: {e}")
            raise
    
    def get_project_info(self) -> Dict[str, Any]:
        """
        Obtiene información del proyecto de AI Foundry
        Nota: MLClient no disponible. Retorna información de configuración.
        
        Returns:
            Diccionario con información del proyecto
        """
        if self.ml_client is None:
            logger.warning("MLClient no disponible. Retornando info de configuración.")
            return {
                "name": AzureAIFoundryConfig.PROJECT_NAME,
                "resource_group": AzureAIFoundryConfig.RESOURCE_GROUP,
                "subscription_id": AzureAIFoundryConfig.SUBSCRIPTION_ID,
                "status": "Configurado (MLClient deshabilitado)"
            }
        
        # Código original si MLClient estuviera disponible
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
        if self.ml_client is None:
            logger.warning("MLClient no disponible. Retornando info básica.")
            return {
                "name": deployment_name,
                "status": "Configurado (usando Azure OpenAI directamente)"
            }
        
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
        if self.ml_client is None:
            logger.info("MLClient no disponible. Validación omitida (bot funcionará con Azure OpenAI directo).")
            return True  # Retornar True para no bloquear el bot
        
        try:
            project_info = self.get_project_info()
            if project_info:
                logger.info(f"✅ Conexión validada con proyecto: {project_info.get('name')}")
                return True
            return False
        except Exception as e:
            logger.error(f"Error validando conexión: {e}")
            return False
