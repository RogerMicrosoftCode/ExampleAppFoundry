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
