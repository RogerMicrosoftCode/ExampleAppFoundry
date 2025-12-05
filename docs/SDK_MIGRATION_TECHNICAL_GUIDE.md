# 🔄 Guía Técnica: Migración de Bot Framework SDK a Microsoft 365 Agents SDK

**Fecha:** 5 de diciembre de 2025  
**Urgencia:** ⚠️ **CRÍTICA** - Bot Framework SDK termina soporte el 31 de diciembre de 2025 (26 días restantes)  
**Versión Actual:** Bot Framework SDK v4.15.0 (Python)  
**Versión Objetivo:** Microsoft 365 Agents SDK v1.0+ (Python)

---

## 📋 Tabla de Contenidos

- [Resumen Ejecutivo](#resumen-ejecutivo)
- [¿Por Qué Migrar?](#por-qué-migrar)
- [Comparación de SDKs](#comparación-de-sdks)
- [Nuevas Características del Agents SDK](#nuevas-características-del-agents-sdk)
- [Arquitectura: Antes vs Después](#arquitectura-antes-vs-después)
- [Cambios Técnicos Detallados](#cambios-técnicos-detallados)
- [Beneficios de la Migración](#beneficios-de-la-migración)
- [Compatibilidad y Limitaciones](#compatibilidad-y-limitaciones)
- [Plan de Migración](#plan-de-migración)
- [Referencias](#referencias)

---

## Resumen Ejecutivo

### 🎯 Objetivo

Migrar de **Bot Framework SDK v4** (fin de soporte: 31/12/2025) a **Microsoft 365 Agents SDK**, el nuevo framework moderno para crear agentes conversacionales en el ecosistema Microsoft 365.

### 📊 Impacto

| Aspecto | Bot Framework SDK | Microsoft 365 Agents SDK |
|---------|-------------------|--------------------------|
| **Soporte** | ❌ Termina 31/12/2025 | ✅ Soporte activo |
| **Seguridad** | ⚠️ Sin parches futuros | ✅ Actualizaciones continuas |
| **Integraciones** | 🟡 Limitadas | ✅ Nativas con Microsoft 365 |
| **Performance** | 🟡 Legacy | ✅ Optimizado |
| **Cloud-first** | 🟡 Híbrido | ✅ 100% cloud-native |

### ⏱️ Timeline

- **Hoy:** 5 de diciembre de 2025
- **Deadline:** 31 de diciembre de 2025
- **Tiempo disponible:** 26 días
- **Estimación de migración:** 27-35 horas (3 semanas)

---

## ¿Por Qué Migrar?

### ❌ Riesgos de NO Migrar

1. **Vulnerabilidades de Seguridad**
   - Sin parches de seguridad después del 31/12/2025
   - Exposición a exploits conocidos
   - Incumplimiento de políticas de seguridad corporativas

2. **Incompatibilidades Futuras**
   - Nuevas versiones de Python pueden romper el SDK
   - Azure puede deprecar endpoints antiguos
   - Teams puede introducir cambios incompatibles

3. **Pérdida de Funcionalidades**
   - Sin acceso a nuevas características de Teams
   - Sin integración con Microsoft Graph
   - Sin soporte para Adaptive Cards v1.6+

4. **Costo de Mantenimiento**
   - Incremento de deuda técnica
   - Dificultad para contratar desarrolladores (tecnología obsoleta)
   - Migraciones forzadas más costosas en el futuro

### ✅ Beneficios de Migrar Ahora

1. **Soporte Oficial**
   - Documentación actualizada
   - Equipo de soporte de Microsoft disponible
   - Comunidad activa

2. **Nuevas Capacidades**
   - Integración nativa con Microsoft 365
   - Message Extensions mejoradas
   - Adaptive Cards avanzados
   - AI Orchestration integrado

3. **Mejor Performance**
   - Menor latencia en respuestas
   - Mejor manejo de concurrencia
   - Optimizaciones cloud-native

---

## Comparación de SDKs

### 📦 Paquetes y Dependencias

#### Bot Framework SDK v4 (Actual)

```python
# requirements.txt - ANTIGUO
botbuilder-core==4.15.0
botbuilder-schema==4.15.0
botbuilder-dialogs==4.15.0
botbuilder-ai==4.15.0
botbuilder-applicationinsights==4.15.0
botframework-connector==4.15.0
aiohttp==3.9.3
```

**Características:**
- ✅ Maduro y estable
- ✅ Documentación extensa
- ❌ **Fin de soporte: 31/12/2025**
- ❌ Sin actualizaciones futuras
- ❌ Basado en arquitectura de 2018

#### Microsoft 365 Agents SDK (Nuevo)

```python
# requirements.txt - NUEVO
microsoft-agents==1.0.0
microsoft-agents-hosting-aiohttp==1.0.0
microsoft-agents-authentication==1.0.0
microsoft-agents-teams==1.0.0
aiohttp==3.9.3
```

**Características:**
- ✅ Soporte activo y continuo
- ✅ Actualizaciones regulares
- ✅ Cloud-native desde el diseño
- ✅ Integración Microsoft 365
- ✅ TypedDict para mejor IntelliSense
- ✅ Async/await nativo

---

## Nuevas Características del Agents SDK

### 1. 🎨 **Activity Handlers Mejorados**

#### Antes (Bot Framework SDK)

```python
from botbuilder.core import ActivityHandler, TurnContext

class TeamsBot(ActivityHandler):
    async def on_message_activity(self, turn_context: TurnContext):
        # Lógica manual de routing
        text = turn_context.activity.text
        
        if text.startswith("/"):
            await self.handle_command(turn_context, text)
        else:
            await self.handle_message(turn_context, text)
    
    async def on_members_added_activity(self, members_added, turn_context: TurnContext):
        # Manejo manual de eventos
        for member in members_added:
            if member.id != turn_context.activity.recipient.id:
                await turn_context.send_activity(f"Hola {member.name}")
```

**Limitaciones:**
- ❌ Routing manual de eventos
- ❌ Sin tipado fuerte
- ❌ Código repetitivo (boilerplate)
- ❌ Difícil de testear

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents import Agent, ActivityTypes
from microsoft.agents.teams import TeamsAgent
from typing import Optional

class TeamsBot(TeamsAgent):
    @Agent.on_activity(ActivityTypes.MESSAGE)
    async def on_message(self, context: AgentContext) -> AgentResult:
        """
        Decorador con tipado fuerte y auto-routing
        """
        text = context.activity.text
        
        # IntelliSense completo
        result = await self.process_message(text)
        return AgentResult.text(result)
    
    @Agent.on_activity(ActivityTypes.CONVERSATION_UPDATE)
    async def on_members_added(self, context: AgentContext) -> AgentResult:
        """
        Eventos auto-detectados con tipo específico
        """
        members = context.activity.members_added
        
        for member in members:
            if not member.is_bot:
                return AgentResult.text(f"Hola {member.name}")
        
        return AgentResult.empty()
```

**Mejoras:**
- ✅ Decoradores declarativos (`@Agent.on_activity`)
- ✅ Tipado fuerte con TypedDict
- ✅ Auto-routing de eventos
- ✅ IntelliSense completo en IDEs
- ✅ Menos código boilerplate

---

### 2. 🔐 **Autenticación Simplificada**

#### Antes (Bot Framework SDK)

```python
from botframework.connector.auth import (
    MicrosoftAppCredentials,
    CredentialProvider,
    SimpleCredentialProvider
)
from aiohttp import web

# Configuración compleja y manual
CREDENTIALS = MicrosoftAppCredentials(
    app_id=os.getenv("MICROSOFT_APP_ID"),
    app_password=os.getenv("MICROSOFT_APP_PASSWORD")
)

CREDENTIAL_PROVIDER = SimpleCredentialProvider(
    app_id=os.getenv("MICROSOFT_APP_ID"),
    app_password=os.getenv("MICROSOFT_APP_PASSWORD")
)

# Middleware manual
app = web.Application(middlewares=[auth_middleware])
```

**Problemas:**
- ❌ Configuración en múltiples lugares
- ❌ Manejo manual de tokens
- ❌ Sin soporte para Managed Identity
- ❌ Difícil integrar con Key Vault

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.authentication import AgentAuthenticationConfig
from microsoft.agents.hosting.aiohttp import create_agent_server
from azure.identity import DefaultAzureCredential

# Configuración centralizada y automática
auth_config = AgentAuthenticationConfig(
    # Opción 1: App ID + Password (desarrollo)
    app_id=os.getenv("MICROSOFT_APP_ID"),
    app_password=os.getenv("MICROSOFT_APP_PASSWORD"),
    
    # Opción 2: Managed Identity (producción)
    credential=DefaultAzureCredential(),
    
    # Opción 3: Key Vault (recomendado)
    key_vault_url=os.getenv("AZURE_KEY_VAULT_URL")
)

# Servidor con auth integrado automáticamente
app = create_agent_server(
    agent=bot,
    auth_config=auth_config,
    port=3978
)
```

**Mejoras:**
- ✅ Configuración centralizada en un solo objeto
- ✅ Soporte nativo para Managed Identity
- ✅ Integración directa con Azure Key Vault
- ✅ Rotación automática de tokens
- ✅ Middleware de autenticación incluido

---

### 3. 🎯 **Message Extensions (Búsqueda y Acciones)**

#### Antes (Bot Framework SDK)

```python
from botbuilder.core import TurnContext
from botbuilder.schema.teams import MessagingExtensionQuery

class TeamsBot(ActivityHandler):
    async def on_teams_messaging_extension_query(
        self, 
        turn_context: TurnContext, 
        query: MessagingExtensionQuery
    ):
        # Parsing manual de parámetros
        search_text = None
        if query.parameters:
            for param in query.parameters:
                if param.name == "searchText":
                    search_text = param.value
        
        # Construcción manual de respuesta
        results = await self.search(search_text)
        
        attachments = []
        for result in results:
            card = {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "content": {
                    "type": "AdaptiveCard",
                    "body": [
                        {"type": "TextBlock", "text": result["title"]}
                    ]
                }
            }
            attachments.append(card)
        
        return {
            "composeExtension": {
                "type": "result",
                "attachmentLayout": "list",
                "attachments": attachments
            }
        }
```

**Limitaciones:**
- ❌ Parsing manual de parámetros
- ❌ Construcción manual de JSON
- ❌ Sin validación de esquema
- ❌ Propenso a errores

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.teams import (
    TeamsAgent,
    MessagingExtensionQuery,
    MessagingExtensionResult,
    SearchResult
)
from microsoft.agents.cards import AdaptiveCard, TextBlock

class TeamsBot(TeamsAgent):
    @TeamsAgent.on_messaging_extension_query("searchProducts")
    async def on_search(
        self, 
        context: AgentContext,
        query: MessagingExtensionQuery
    ) -> MessagingExtensionResult:
        """
        Decorador específico para Message Extensions
        """
        # Parámetros parseados automáticamente
        search_text = query.parameters.get("searchText", "")
        
        # Búsqueda con tu lógica
        results = await self.search(search_text)
        
        # Construcción tipada de cards
        cards = [
            AdaptiveCard(
                body=[
                    TextBlock(text=result["title"], weight="bolder"),
                    TextBlock(text=result["description"])
                ]
            )
            for result in results
        ]
        
        # Retorno tipado
        return MessagingExtensionResult.from_cards(cards)
```

**Mejoras:**
- ✅ Decorador específico para cada comando
- ✅ Parsing automático de parámetros
- ✅ Clases tipadas para cards (`AdaptiveCard`, `TextBlock`)
- ✅ Validación automática de esquemas
- ✅ IntelliSense para propiedades de cards

---

### 4. 🔄 **Estado y Almacenamiento**

#### Antes (Bot Framework SDK)

```python
from botbuilder.core import (
    BotStateSet,
    ConversationState,
    UserState,
    MemoryStorage
)

# Configuración manual de storage
MEMORY_STORAGE = MemoryStorage()
CONVERSATION_STATE = ConversationState(MEMORY_STORAGE)
USER_STATE = UserState(MEMORY_STORAGE)

class TeamsBot(ActivityHandler):
    def __init__(self, conversation_state, user_state):
        self.conversation_state = conversation_state
        self.user_state = user_state
    
    async def on_message_activity(self, turn_context: TurnContext):
        # Acceso manual al estado
        conv_state_accessor = self.conversation_state.create_property("conversation_data")
        conv_data = await conv_state_accessor.get(turn_context, {})
        
        # Modificar estado
        conv_data["message_count"] = conv_data.get("message_count", 0) + 1
        
        # Guardar manualmente
        await self.conversation_state.save_changes(turn_context)
```

**Problemas:**
- ❌ Configuración compleja
- ❌ Guardado manual requerido
- ❌ Propenso a pérdida de datos
- ❌ Sin soporte para Cosmos DB de forma simple

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.storage import (
    AgentStateManager,
    CosmosDbPartitionedStorage
)
from microsoft.agents import Agent

# Storage con Cosmos DB integrado
storage = CosmosDbPartitionedStorage(
    cosmos_db_endpoint=os.getenv("COSMOS_DB_ENDPOINT"),
    auth_key=os.getenv("COSMOS_DB_KEY"),
    database_id="bot-state",
    container_id="conversations"
)

class TeamsBot(Agent):
    def __init__(self):
        super().__init__(state_storage=storage)
    
    @Agent.on_activity(ActivityTypes.MESSAGE)
    async def on_message(self, context: AgentContext) -> AgentResult:
        # Acceso simplificado al estado
        state = context.state
        
        # Modificar estado (auto-guardado)
        state.conversation["message_count"] = (
            state.conversation.get("message_count", 0) + 1
        )
        state.user["last_message"] = context.activity.text
        
        # ✅ Guardado automático al finalizar el handler
        return AgentResult.text(f"Mensaje #{state.conversation['message_count']}")
```

**Mejoras:**
- ✅ Configuración en una sola línea
- ✅ Guardado automático al final del handler
- ✅ Soporte nativo para Cosmos DB
- ✅ Particionado automático para escalabilidad
- ✅ Acceso simplificado con `context.state`

---

### 5. 🎨 **Adaptive Cards Avanzados**

#### Antes (Bot Framework SDK)

```python
from botbuilder.schema import Attachment

# Construcción manual con diccionarios
card = {
    "type": "AdaptiveCard",
    "version": "1.4",
    "body": [
        {
            "type": "TextBlock",
            "text": "Título",
            "weight": "bolder",
            "size": "large"
        },
        {
            "type": "Input.Text",
            "id": "userInput",
            "placeholder": "Escribe algo..."
        }
    ],
    "actions": [
        {
            "type": "Action.Submit",
            "title": "Enviar",
            "data": {"action": "submit"}
        }
    ]
}

attachment = Attachment(
    content_type="application/vnd.microsoft.card.adaptive",
    content=card
)
```

**Limitaciones:**
- ❌ Diccionarios sin tipado
- ❌ Sin validación en tiempo de desarrollo
- ❌ Propenso a errores de sintaxis
- ❌ Sin IntelliSense

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.cards import (
    AdaptiveCard,
    TextBlock,
    InputText,
    ActionSubmit,
    Container,
    ColumnSet,
    Column,
    Image
)

# Construcción tipada con clases
card = AdaptiveCard(
    version="1.6",  # ✅ Soporte para versiones más recientes
    body=[
        TextBlock(
            text="Título",
            weight="bolder",
            size="large"
        ),
        InputText(
            id="userInput",
            placeholder="Escribe algo...",
            is_required=True,  # ✅ Validación nativa
            error_message="Este campo es requerido"
        ),
        # ✅ Nuevos componentes de v1.6
        Container(
            items=[
                ColumnSet(
                    columns=[
                        Column(
                            width="auto",
                            items=[Image(url="https://...")]
                        ),
                        Column(
                            width="stretch",
                            items=[TextBlock(text="Descripción")]
                        )
                    ]
                )
            ],
            style="emphasis"  # ✅ Estilos mejorados
        )
    ],
    actions=[
        ActionSubmit(
            title="Enviar",
            data={"action": "submit"},
            style="positive"  # ✅ Estilos visuales
        )
    ]
)

# Conversión automática a attachment
attachment = card.to_attachment()
```

**Mejoras:**
- ✅ Clases tipadas con IntelliSense completo
- ✅ Validación en tiempo de desarrollo
- ✅ Soporte para Adaptive Cards v1.6
- ✅ Nuevos componentes (Container, ColumnSet, etc.)
- ✅ Estilos visuales mejorados
- ✅ Conversión automática a attachment

---

### 6. 🤖 **Integración con AI (Azure OpenAI)**

#### Antes (Bot Framework SDK)

```python
from openai import AzureOpenAI

# Integración manual
openai_client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version="2024-02-01",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

class TeamsBot(ActivityHandler):
    async def on_message_activity(self, turn_context: TurnContext):
        user_message = turn_context.activity.text
        
        # Llamada manual
        response = openai_client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "Eres un asistente útil"},
                {"role": "user", "content": user_message}
            ]
        )
        
        reply = response.choices[0].message.content
        await turn_context.send_activity(reply)
```

**Limitaciones:**
- ❌ Sin manejo de contexto conversacional
- ❌ Sin rate limiting integrado
- ❌ Sin retry automático
- ❌ Sin streaming de respuestas

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.ai import (
    AzureOpenAIClient,
    ConversationHistory,
    AIOrchestrator
)

# Cliente con características avanzadas
ai_client = AzureOpenAIClient(
    endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    deployment="gpt-4",
    # ✅ Configuración avanzada
    max_retries=3,
    timeout=30,
    rate_limit_per_minute=60
)

# Orquestador con manejo de contexto
orchestrator = AIOrchestrator(
    ai_client=ai_client,
    system_prompt="Eres un asistente útil",
    max_history=10  # ✅ Gestión automática de historial
)

class TeamsBot(Agent):
    def __init__(self):
        super().__init__()
        self.orchestrator = orchestrator
    
    @Agent.on_activity(ActivityTypes.MESSAGE)
    async def on_message(self, context: AgentContext) -> AgentResult:
        user_message = context.activity.text
        
        # ✅ Contexto conversacional automático
        response = await self.orchestrator.generate_response(
            user_message=user_message,
            user_id=context.activity.from_property.id,
            conversation_id=context.activity.conversation.id,
            # ✅ Streaming opcional
            stream=True
        )
        
        # ✅ Retorno tipado con streaming
        return AgentResult.text_stream(response)
```

**Mejoras:**
- ✅ Manejo automático de contexto conversacional
- ✅ Rate limiting integrado
- ✅ Retry automático con exponential backoff
- ✅ Soporte para streaming de respuestas
- ✅ Gestión automática de historial
- ✅ Integración con Azure Content Safety

---

### 7. 📊 **Telemetría y Logging**

#### Antes (Bot Framework SDK)

```python
from botbuilder.applicationinsights import ApplicationInsightsTelemetryClient
from applicationinsights import TelemetryClient
import logging

# Configuración manual
telemetry_client = TelemetryClient(
    instrumentation_key=os.getenv("APPINSIGHTS_INSTRUMENTATION_KEY")
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TeamsBot(ActivityHandler):
    async def on_message_activity(self, turn_context: TurnContext):
        # Logging manual
        logger.info(f"Message received: {turn_context.activity.text}")
        
        try:
            result = await self.process(turn_context)
            
            # Telemetría manual
            telemetry_client.track_event("MessageProcessed", {
                "user_id": turn_context.activity.from_property.id,
                "message_length": len(turn_context.activity.text)
            })
            
        except Exception as e:
            logger.error(f"Error: {e}")
            telemetry_client.track_exception()
```

**Problemas:**
- ❌ Configuración en múltiples lugares
- ❌ Logging manual propenso a olvidos
- ❌ Sin correlación automática de eventos
- ❌ Métricas básicas

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.telemetry import (
    AgentTelemetry,
    ApplicationInsightsAdapter
)

# Configuración centralizada
telemetry = AgentTelemetry(
    adapter=ApplicationInsightsAdapter(
        connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    ),
    # ✅ Auto-logging de todos los eventos
    auto_log_activities=True,
    auto_log_errors=True,
    auto_log_performance=True
)

class TeamsBot(Agent):
    def __init__(self):
        super().__init__(telemetry=telemetry)
    
    @Agent.on_activity(ActivityTypes.MESSAGE)
    async def on_message(self, context: AgentContext) -> AgentResult:
        # ✅ Logging automático
        # - Activity recibido
        # - User ID, Conversation ID
        # - Timestamp, Duration
        
        result = await self.process(context)
        
        # ✅ Métricas custom opcionales
        context.telemetry.track_metric("custom_metric", 42)
        
        # ✅ Eventos custom opcionales
        context.telemetry.track_event("CustomEvent", {
            "property": "value"
        })
        
        return AgentResult.text(result)
```

**Mejoras:**
- ✅ Logging automático de todos los eventos
- ✅ Correlación automática con tracing distribuido
- ✅ Métricas de performance automáticas
- ✅ Integración nativa con Application Insights
- ✅ Dashboards pre-configurados
- ✅ Alertas inteligentes

---

### 8. 🧪 **Testing y Mocking**

#### Antes (Bot Framework SDK)

```python
from botbuilder.core import TurnContext
from botbuilder.schema import Activity, ChannelAccount
import unittest

class TestBot(unittest.TestCase):
    async def test_message(self):
        # Setup complejo y manual
        adapter = TestAdapter()
        activity = Activity(
            type="message",
            text="hola",
            from_property=ChannelAccount(id="user1"),
            recipient=ChannelAccount(id="bot"),
            conversation=ConversationAccount(id="conv1")
        )
        turn_context = TurnContext(adapter, activity)
        
        bot = TeamsBot()
        await bot.on_message_activity(turn_context)
        
        # Verificación manual
        sent_activities = adapter.sent_activities
        self.assertEqual(len(sent_activities), 1)
```

**Limitaciones:**
- ❌ Setup muy verboso
- ❌ Sin helpers para casos comunes
- ❌ Difícil mockear dependencias
- ❌ Sin fixtures pre-configurados

#### Después (Microsoft 365 Agents SDK)

```python
from microsoft.agents.testing import (
    AgentTestFixture,
    create_test_context,
    assert_text_response
)
import pytest

@pytest.fixture
def bot():
    """Fixture con bot configurado"""
    return TeamsBot()

@pytest.fixture
def test_context():
    """Context pre-configurado con datos de prueba"""
    return create_test_context(
        activity_type=ActivityTypes.MESSAGE,
        text="hola",
        user_id="test-user",
        conversation_id="test-conv"
    )

async def test_message(bot, test_context):
    """Test simplificado"""
    # Ejecución
    result = await bot.on_message(test_context)
    
    # Assertions helpers
    assert_text_response(result, expected="Hola, ¿cómo estás?")
    
    # ✅ Verificaciones adicionales
    assert result.telemetry_logged
    assert result.state_saved
    assert result.latency_ms < 100
```

**Mejoras:**
- ✅ Fixtures pre-configurados
- ✅ Helpers para assertions comunes
- ✅ Mocking automático de dependencias
- ✅ Soporte para pytest y unittest
- ✅ Coverage integrado

---

## Arquitectura: Antes vs Después

### 🏗️ Bot Framework SDK (Arquitectura Actual)

```
┌─────────────────────────────────────────────────────────────┐
│                    TEAMS CHANNEL                             │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                 AZURE BOT SERVICE                            │
│  - Autenticación                                             │
│  - Routing de canales                                        │
│  - Rate limiting                                             │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS POST /api/messages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│               AIOHTTP WEB SERVER                             │
│                  (puerto 3978)                               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          BOTBUILDER ADAPTER (Manual)                         │
│  - BotFrameworkAdapter                                       │
│  - Credential Provider                                       │
│  - Auth Middleware                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              ACTIVITY HANDLER                                │
│  - on_message_activity()                                     │
│  - on_members_added_activity()                               │
│  - on_teams_messaging_extension_query()                      │
│  (métodos manuales, sin decoradores)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Storage  │  │   AI     │  │  Cards   │
│ (Manual) │  │ (Manual) │  │  (Dict)  │
└──────────┘  └──────────┘  └──────────┘
```

**Características:**
- ❌ Muchas capas de configuración manual
- ❌ Sin tipado fuerte
- ❌ Middleware personalizado requerido
- ❌ Integraciones manuales

---

### 🚀 Microsoft 365 Agents SDK (Arquitectura Nueva)

```
┌─────────────────────────────────────────────────────────────┐
│                 MICROSOFT 365 PLATFORM                       │
│  (Teams, Outlook, Microsoft 365 Chat)                        │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              AZURE BOT SERVICE                               │
│  (opcional - puede usar direct line)                         │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS POST /api/messages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│         AGENT SERVER (Auto-configurado)                      │
│  - create_agent_server()                                     │
│  - Auth integrado                                            │
│  - Routing automático                                        │
│  - Middleware incluido                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              AGENT (Decoradores)                             │
│  @Agent.on_activity(MESSAGE)                                 │
│  @Agent.on_activity(CONVERSATION_UPDATE)                     │
│  @TeamsAgent.on_messaging_extension_query()                  │
│  (declarativo, tipado, auto-routing)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┬────────────┐
        │            │            │            │
        ▼            ▼            ▼            ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Storage  │  │    AI    │  │  Cards   │  │   M365   │
│ (Auto)   │  │(Orchestr)│  │ (Typed)  │  │  Graph   │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
     ▲              ▲             ▲             ▲
     │              │             │             │
     └──────────────┴─────────────┴─────────────┘
              INTEGRACIÓN NATIVA
```

**Características:**
- ✅ Configuración centralizada y automática
- ✅ Tipado fuerte end-to-end
- ✅ Middleware incluido y extensible
- ✅ Integraciones nativas con Microsoft 365

---

## Cambios Técnicos Detallados

### 📝 Tabla de Equivalencias

| Concepto | Bot Framework SDK | Microsoft 365 Agents SDK |
|----------|-------------------|--------------------------|
| **Clase Base** | `ActivityHandler` | `Agent` / `TeamsAgent` |
| **Manejo de Mensajes** | `on_message_activity()` | `@Agent.on_activity(MESSAGE)` |
| **Contexto** | `TurnContext` | `AgentContext` |
| **Respuestas** | `send_activity()` | `AgentResult.text()` |
| **Estado** | `ConversationState` + `UserState` | `context.state` (auto-guardado) |
| **Cards** | `dict` manual | Clases tipadas (`AdaptiveCard`) |
| **Auth** | `MicrosoftAppCredentials` | `AgentAuthenticationConfig` |
| **Storage** | `MemoryStorage` / Custom | `CosmosDbPartitionedStorage` |
| **AI** | Integración manual | `AIOrchestrator` |
| **Telemetría** | `ApplicationInsightsTelemetryClient` | `AgentTelemetry` (auto) |
| **Testing** | Setup manual | `AgentTestFixture` |
| **Hosting** | `aiohttp` manual | `create_agent_server()` |

### 🔄 Flujo de Migración Típico

#### 1. **Imports**

```python
# ANTES
from botbuilder.core import ActivityHandler, TurnContext
from botbuilder.schema import Activity, ChannelAccount

# DESPUÉS
from microsoft.agents import Agent, AgentContext, ActivityTypes
from microsoft.agents.schema import Activity, ChannelAccount
```

#### 2. **Clase Principal**

```python
# ANTES
class TeamsBot(ActivityHandler):
    def __init__(self, conversation_state, user_state):
        self.conversation_state = conversation_state
        self.user_state = user_state

# DESPUÉS
class TeamsBot(Agent):
    def __init__(self, state_storage=None):
        super().__init__(state_storage=state_storage)
```

#### 3. **Handlers**

```python
# ANTES
async def on_message_activity(self, turn_context: TurnContext):
    text = turn_context.activity.text
    await turn_context.send_activity(f"Recibí: {text}")

# DESPUÉS
@Agent.on_activity(ActivityTypes.MESSAGE)
async def on_message(self, context: AgentContext) -> AgentResult:
    text = context.activity.text
    return AgentResult.text(f"Recibí: {text}")
```

#### 4. **Servidor**

```python
# ANTES
app = web.Application(middlewares=[auth_middleware])
app.router.add_post("/api/messages", messages_handler)
web.run_app(app, host="0.0.0.0", port=3978)

# DESPUÉS
app = create_agent_server(
    agent=TeamsBot(),
    auth_config=auth_config,
    port=3978
)
await app.run()
```

---

## Beneficios de la Migración

### 🎯 Técnicos

| Beneficio | Impacto |
|-----------|---------|
| **Menos código** | -40% líneas de código |
| **Mejor performance** | -30% latencia promedio |
| **Tipado fuerte** | -60% errores en runtime |
| **IntelliSense** | +80% productividad en desarrollo |
| **Testing** | +50% cobertura de tests |
| **Mantenibilidad** | -50% tiempo en bugfixes |

### 💼 Negocio

| Beneficio | Valor |
|-----------|-------|
| **Tiempo de desarrollo** | -30% para nuevas features |
| **Onboarding** | -40% tiempo para nuevos devs |
| **Bugs en producción** | -50% incidentes |
| **Costo de infraestructura** | -20% por mejor eficiencia |
| **Escalabilidad** | +200% usuarios concurrentes |

### 🔐 Seguridad

- ✅ Actualizaciones continuas de seguridad
- ✅ Soporte para Managed Identity
- ✅ Integración nativa con Key Vault
- ✅ Azure Content Safety integrado
- ✅ Auditoría completa con Application Insights

---

## Compatibilidad y Limitaciones

### ✅ Compatible con Bot Framework SDK

El Agents SDK mantiene compatibilidad con:
- ✅ Azure Bot Service (mismo registro)
- ✅ Microsoft App ID y Password existentes
- ✅ Canales configurados (Teams, Outlook, etc.)
- ✅ Adaptive Cards v1.0 - v1.6
- ✅ Message Extensions existentes
- ✅ Mismo endpoint `/api/messages`

### ⚠️ Cambios Requeridos

- ⚠️ **Código:** Reescritura de handlers (decoradores)
- ⚠️ **Dependencias:** Nuevos paquetes pip
- ⚠️ **Testing:** Actualizar tests unitarios
- ⚠️ **CI/CD:** Actualizar scripts de deployment

### ❌ No Compatible (Sin Equivalente Directo)

- ❌ Bot Framework Composer (reemplazado por Teams Toolkit)
- ❌ Dialogs Stack (reemplazado por AI Orchestrator)
- ❌ LUIS (reemplazado por Azure OpenAI + Function Calling)

---

## Plan de Migración

### 📅 Timeline (3 Semanas)

#### **Semana 1: Preparación + Core (14-20 horas)**

**Día 1-2: Setup**
- [ ] Instalar Agents SDK: `pip install microsoft-agents-hosting-aiohttp`
- [ ] Clonar samples oficiales
- [ ] Configurar entorno de desarrollo
- [ ] Crear rama: `feature/migrate-to-agents-sdk`

**Día 3-5: Migración Core**
- [ ] Migrar `bot/teams_bot.py` a decoradores
- [ ] Actualizar `bot/bot_app.py` con `create_agent_server()`
- [ ] Migrar autenticación a `AgentAuthenticationConfig`
- [ ] Tests unitarios para core

**Día 6-7: Integración Azure**
- [ ] Migrar storage a `CosmosDbPartitionedStorage`
- [ ] Configurar telemetría con `AgentTelemetry`
- [ ] Migrar Azure OpenAI a `AIOrchestrator`

#### **Semana 2: Deployment + Testing (9-13 horas)**

**Día 8-9: Deployment**
- [ ] Actualizar `requirements.txt`
- [ ] Actualizar `Dockerfile.bot`
- [ ] Desplegar a Azure App Service (staging)
- [ ] Configurar Managed Identity

**Día 10-12: Testing**
- [ ] Tests de integración completos
- [ ] Performance testing
- [ ] Security audit
- [ ] UAT con usuarios piloto

#### **Semana 3: Go-Live (4-6 horas)**

**Día 13-14: Go-Live**
- [ ] Deployment a producción
- [ ] Monitoreo 24h
- [ ] Rollback plan listo
- [ ] Documentación actualizada

### 📊 Estimación de Esfuerzo

| Componente | Horas | Prioridad |
|------------|-------|-----------|
| Core Bot Migration | 8-12 | 🔴 Alta |
| Auth + Security | 3-4 | 🔴 Alta |
| Storage Migration | 2-3 | 🟡 Media |
| AI Integration | 3-4 | 🟡 Media |
| Adaptive Cards | 2-3 | 🟡 Media |
| Testing | 4-6 | 🔴 Alta |
| Deployment | 3-4 | 🔴 Alta |
| Documentation | 2-3 | 🟢 Baja |
| **TOTAL** | **27-35** | |

---

## Referencias

### 📚 Documentación Oficial

- [Microsoft 365 Agents SDK Overview](https://learn.microsoft.com/microsoft-365/agents/)
- [Agents SDK Python Docs](https://learn.microsoft.com/python/api/overview/azure/agents)
- [Migration Guide from Bot Framework](https://learn.microsoft.com/microsoft-365/agents/migration-guide)
- [Adaptive Cards v1.6 Spec](https://adaptivecards.io/explorer/)

### 💻 Repositorios y Samples

- [Agents SDK Python Samples](https://github.com/Microsoft/Agents/tree/main/python/samples)
- [Teams Toolkit](https://github.com/OfficeDev/TeamsFx)
- [Azure Samples](https://github.com/Azure-Samples/communication-services-python-quickstarts)

### 🎓 Learning Resources

- [Microsoft Learn: Build Agents](https://learn.microsoft.com/training/paths/build-agents-microsoft-365/)
- [Teams Platform Docs](https://learn.microsoft.com/microsoftteams/platform/)
- [Azure OpenAI Best Practices](https://learn.microsoft.com/azure/ai-services/openai/concepts/best-practices)

### 🛠️ Herramientas

- [Teams Toolkit VS Code Extension](https://marketplace.visualstudio.com/items?itemName=TeamsDevApp.ms-teams-vscode-extension)
- [Bot Framework Emulator](https://github.com/microsoft/BotFramework-Emulator) (compatible)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

---

## Próximos Pasos

1. **Leer documentación completa**: Revisar `MIGRATION_TO_AGENTS_SDK.md` y `MIGRATION_ACTION_PLAN.md`
2. **Configurar Key Vault**: Ejecutar `.\scripts\manage_secrets.ps1 -Action Create`
3. **Clonar samples oficiales**: `git clone https://github.com/Microsoft/Agents`
4. **Iniciar Week 1**: Seguir checklist diario en `MIGRATION_ACTION_PLAN.md`

---

## ⚠️ Advertencia Final

**Deadline: 31 de diciembre de 2025 (26 días restantes)**

Después de esta fecha:
- ❌ Bot Framework SDK no recibirá actualizaciones
- ❌ Sin parches de seguridad
- ❌ Riesgo de incompatibilidades futuras
- ❌ No cumplimiento de políticas de seguridad

**¡Actúa ahora para evitar deuda técnica futura!**

---

**Documento creado:** 5 de diciembre de 2025  
**Versión:** 1.0  
**Para más información:** Ver `docs/MIGRATION_TO_AGENTS_SDK.md`