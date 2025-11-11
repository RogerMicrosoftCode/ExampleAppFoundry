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
