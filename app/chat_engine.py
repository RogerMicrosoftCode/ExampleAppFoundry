"""
Motor de chat usando LangChain con Azure AI Foundry
"""
import logging
from typing import List, Dict, Optional, Any
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
