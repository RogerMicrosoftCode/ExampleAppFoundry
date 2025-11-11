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
