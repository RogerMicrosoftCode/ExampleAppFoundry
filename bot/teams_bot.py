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
