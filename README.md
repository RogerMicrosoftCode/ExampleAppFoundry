# Chat Application con Azure AI Foundry, Microsoft Teams y Azure Bot Service

## 📋 Descripción

Esta aplicación es un bot de chat inteligente para Microsoft Teams potenciado por **Azure AI Foundry**, **LangChain** y **Azure Bot Service**. Utiliza modelos de OpenAI desplegados en Azure AI Foundry para proporcionar asistencia conversacional avanzada con características de seguridad empresarial.

## 🏗️ Arquitectura

```
Microsoft Teams (Frontend)
           ↓
Azure Bot Service (Bot Framework Connector)
           ↓
Bot Application (Bot Framework SDK + LangChain)
           ↓
Azure AI Foundry (AI Studio + Projects + Deployments)
    ├── Azure OpenAI Models (GPT-4.1)
    ├── Content Safety (Moderation)
    └── AI Search (Optional RAG)
```

## 📦 Estructura del Proyecto

```
ExampleAppFoundry/
├── app/                          # Módulo de aplicación principal
│   ├── __init__.py              # Inicializador del módulo
│   ├── config.py                # Configuración centralizada
│   ├── foundry_client.py        # Cliente de Azure AI Foundry
│   ├── chat_engine.py           # Motor de chat con LangChain
│   └── utils.py                 # Utilidades generales
├── bot/                         # Módulo del bot
│   ├── __init__.py              # Inicializador del módulo
│   ├── bot_app.py               # Aplicación principal del bot
│   ├── teams_bot.py             # Lógica del bot de Teams
│   ├── conversation_manager.py  # Gestor de conversaciones
│   ├── cards.py                 # Adaptive Cards
│   └── content_safety.py        # Integración Content Safety
├── scripts/                     # Scripts de deployment
│   ├── configure_env.sh         # 🆕 Configurador automático de .env (Bash)
│   ├── configure_env.ps1        # 🆕 Configurador automático de .env (PowerShell)
│   ├── setup_azure.sh           # Setup de recursos Azure
│   ├── deploy.sh                # Script de deployment
│   └── local_test.sh            # Test local
├── .env.example                 # Plantilla de variables de entorno
├── .gitignore                   # Archivos a ignorar en git
├── requirements.txt             # Dependencias Python
├── Dockerfile.bot               # Dockerfile para el bot
├── docker-compose.yml           # Configuración Docker Compose
└── README.md                    # Este archivo
```

## 🚀 Prerrequisitos

- **Azure**: Cuenta con suscripción activa
- **Microsoft 365**: Con permisos de administración
- **Python**: 3.9 o superior
- **Azure CLI**: Versión 2.50+
- **Docker**: Para containerización
- **Git**: Para control de versiones

## ⚙️ Instalación Local

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/ExampleAppFoundry.git
cd ExampleAppFoundry
```

### 2. Crear entorno virtual

```bash
# Linux/macOS
python -m venv venv
source venv/bin/activate

# Windows
py -m venv venv
venv\Scripts\activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

> **⚠️ Nota sobre azure-ai-ml:** Este paquete está comentado en `requirements.txt` debido a problemas de compatibilidad. 
> No es necesario para ejecutar el bot. Si necesitas gestionar recursos de Azure AI Foundry programáticamente, 
> consulta [`docs/AZURE_AI_ML_SETUP.md`](docs/AZURE_AI_ML_SETUP.md) para alternativas recomendadas.

### 4. Configurar variables de entorno

#### Opción A: Configuración Automática (Recomendado) 🆕

**Para Linux/macOS:**
```bash
chmod +x scripts/configure_env.sh
./scripts/configure_env.sh
```

**Para Windows (PowerShell):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\configure_env.ps1
```

Este script interactivo:
- ✅ Hace login en tu suscripción de Azure
- ✅ Crea o selecciona recursos existentes (Resource Group, AI Hub, AI Project, Bot)
- ✅ Obtiene automáticamente todas las credenciales necesarias
- ✅ Genera el archivo `.env` completamente configurado

#### Opción B: Configuración Manual

```bash
cp .env.example .env
nano .env  # Editar con tus credenciales
```

### 5. Ejecutar el bot localmente

```bash
py bot/bot_app.py
```

El bot estará disponible en `http://localhost:3978`

## 🐳 Instalación con Docker

### 1. Construir imagen

```bash
docker build -f Dockerfile.bot -t teams-ai-foundry-bot .
```

### 2. Ejecutar con Docker Compose

```bash
docker-compose up -d
```

### 3. Ver logs

```bash
docker-compose logs -f teams-ai-foundry-bot
```

### 4. Detener

```bash
docker-compose down
```

## ☁️ Deployment en Azure

### Opción 1: Usar script automatizado

```bash
chmod +x scripts/setup_azure.sh
chmod +x scripts/deploy.sh

# Configurar recursos en Azure
./scripts/setup_azure.sh

# Deploy del bot
./scripts/deploy.sh
```

### Opción 2: Deployment manual

Ver la documentación completa en `BotTeamsAFOIADemo.md`

## 📝 Configuración

### Variables de Entorno Principales

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | ID de suscripción de Azure | `xxxxxxxx-xxxx-xxxx...` |
| `AZURE_RESOURCE_GROUP` | Grupo de recursos | `rg-ai-foundry-teams` |
| `AZURE_AI_PROJECT_NAME` | Nombre del proyecto AI Foundry | `teams-bot-project` |
| `AZURE_OPENAI_ENDPOINT` | Endpoint de Azure OpenAI | `https://....openai.azure.com/` |
| `AZURE_OPENAI_API_KEY` | API Key de OpenAI | `tu-clave-api` |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Nombre del deployment | `gpt-41-turbo` |
| `MICROSOFT_APP_ID` | Bot Application ID | `xxxxxxxx-xxxx-xxxx...` |
| `MICROSOFT_APP_PASSWORD` | Bot Client Secret | `tu-client-secret` |

Ver `.env.example` para la lista completa de variables.

## 🤖 Comandos del Bot

El bot soporta los siguientes comandos en Teams:

- `/help` - Muestra la ayuda
- `/clear` - Limpia el historial de conversación
- `/stats` - Muestra estadísticas de uso
- `/project` - Información del proyecto AI Foundry
- `/about` - Información sobre el bot

## 🔧 Desarrollo

### Agregar nuevas funcionalidades

1. **Nuevos comandos**: Editar `bot/teams_bot.py` método `_handle_command()`
2. **Nuevas cards**: Agregar métodos en `bot/cards.py`
3. **Configuración**: Actualizar `app/config.py`
4. **Chat engine**: Modificar `app/chat_engine.py`

### Testing

```bash
# Instalar dependencias de testing
pip install pytest pytest-asyncio pytest-mock

# Ejecutar tests
pytest tests/
```

## 📊 Monitoreo

### Health Check

```bash
curl http://localhost:3978/health
```

### Ver información del servicio

```bash
curl http://localhost:3978/info
```

### Logs en Docker

```bash
docker logs teams-ai-foundry-bot -f
```

## 🔒 Seguridad

- ✅ Content Safety integrado para moderación de contenido
- ✅ Autenticación OAuth con Azure AD
- ✅ Secrets manejados con variables de entorno
- ✅ Usuario no-root en Docker
- ✅ HTTPS en producción

## 🐛 Solución de Problemas

### Error: "AI Foundry project not found"

```bash
az ml workspace show \
  --name teams-bot-project \
  --resource-group rg-ai-foundry-teams
```

### Error: "Deployment not found"

Verifica en Azure AI Studio que el deployment existe y está activo.

### Bot no responde

1. Verificar logs: `docker-compose logs -f`
2. Verificar health: `curl http://localhost:3978/health`
3. Verificar configuración en `.env`

## 📚 Recursos
## 📚 Documentación Adicional

- **[Configuración de Azure AI ML SDK](docs/AZURE_AI_ML_SETUP.md)** - Alternativas para gestionar Azure AI Foundry sin azure-ai-ml
- **[Configuración Preset](README_PRESET.md)** - Uso del script de configuración rápida con valores preestablecidos
- **[Despliegue Completo](README_DEPLOY_FULL.md)** - Guía para desplegar toda la infraestructura desde cero

## 🔗 Referencias

- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)
- [Bot Framework](https://docs.microsoft.com/bot-framework/)
- [Teams Development](https://docs.microsoft.com/microsoftteams/platform/)
- [LangChain](https://python.langchain.com/)

## 📄 Licencia

MIT License

## 👥 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Para soporte y preguntas:
- Crea un issue en GitHub
- Consulta la documentación completa en `BotTeamsAFOIADemo.md`

---

**⭐ Desarrollado con Azure AI Foundry + Teams ⭐**
