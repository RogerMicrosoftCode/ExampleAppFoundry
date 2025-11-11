"""
Utilidades generales para la aplicación
"""
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def format_message(message: str, max_length: int = 100) -> str:
    """
    Formatea un mensaje para logging
    
    Args:
        message: Mensaje a formatear
        max_length: Longitud máxima
        
    Returns:
        Mensaje formateado
    """
    if len(message) <= max_length:
        return message
    return message[:max_length] + "..."


def sanitize_user_input(text: str) -> str:
    """
    Sanitiza entrada del usuario
    
    Args:
        text: Texto a sanitizar
        
    Returns:
        Texto sanitizado
    """
    # Eliminar caracteres potencialmente peligrosos
    return text.strip()
