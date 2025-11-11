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
