# ExampleAppFoundry
ExampleAppFoundry


# Chat Application con Azure AI Foundry, LangChain y Docker

## 📋 Descripción

Esta guía proporciona un ejemplo completo de cómo crear una aplicación de chat usando Azure AI Foundry (Azure OpenAI), LangChain y Python, containerizada con Docker para facilitar el despliegue.

## 🏗️ Arquitectura

```
┌─────────────────┐
│   Usuario       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Streamlit UI  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   LangChain     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Azure AI Foundry│
│   (OpenAI)      │
└─────────────────┘
```

## 📦 Prerrequisitos

- Cuenta de Azure activa
- Azure AI Foundry / Azure OpenAI Service configurado
- Python 3.9+
- Docker y Docker Compose
- Git

## 🚀 Configuración de Azure AI Foundry

### Paso 1: Crear Recurso de Azure OpenAI

1. Accede al [Portal de Azure](https://portal.azure.com)
2. Busca "Azure OpenAI" en el marketplace
3. Haz clic en **Crear**
4. Completa los detalles:
   - **Suscripción**: Selecciona tu suscripción
   - **Grupo de recursos**: Crea uno nuevo o usa existente
   - **Región**: Selecciona una región disponible (ej: East US, West Europe)
   - **Nombre**: Asigna un nombre único
   - **Plan de precios**: Selecciona el plan adecuado

### Paso 2: Desplegar un Modelo

1. Una vez creado el recurso, ve a **Azure AI Studio** o **Azure OpenAI Studio**
2. Navega a **Deployments** > **Create new deployment**
3. Selecciona un modelo:
   - **Modelo**: `gpt-4` o `gpt-35-turbo`
   - **Nombre del despliegue**: `chat-model` (este nombre lo usaremos en el código)
   - **Versión**: Última disponible
4. Configura las capacidades según necesites

### Paso 3: Obtener Credenciales

1. Ve a **Keys and Endpoint** en tu recurso de Azure OpenAI
2. Copia:
   - **Endpoint**: `https://tu-recurso.openai.azure.com/`
   - **Key**: Tu clave API
   - **Deployment Name**: El nombre que asignaste al modelo

## 📁 Estructura del Proyecto

```
azure-foundry-chat/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── chat_manager.py
│   └── config.py
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## 💻 Código de la Aplicación

### 1. requirements.txt

```txt
streamlit==1.29.0
langchain==0.1.0
langchain-openai==0.0.2
python-dotenv==1.0.0
openai==1.6.1
```

### 2. .env.example

```env
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://tu-recurso.openai.azure.com/
AZURE_OPENAI_API_KEY=tu-clave-api-aqui
AZURE_OPENAI_DEPLOYMENT_NAME=chat-model
AZURE_OPENAI_API_VERSION=2024-02-15-preview

# Application Configuration
APP_TITLE=Chat con Azure AI Foundry
APP_TEMPERATURE=0.7
APP_MAX_TOKENS=1000
```

### 3. app/config.py

```python
"""
Configuración de la aplicación
"""
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

class Config:
    """Clase de configuración para la aplicación"""
    
    # Azure OpenAI Configuration
    AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
    AZURE_OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY")
    AZURE_OPENAI_DEPLOYMENT_NAME = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
    AZURE_OPENAI_API_VERSION = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
    
    # Application Configuration
    APP_TITLE = os.getenv("APP_TITLE", "Chat con Azure AI Foundry")
    APP_TEMPERATURE = float(os.getenv("APP_TEMPERATURE", "0.7"))
    APP_MAX_TOKENS = int(os.getenv("APP_MAX_TOKENS", "1000"))
    
    @classmethod
    def validate(cls):
        """Valida que todas las configuraciones necesarias estén presentes"""
        required_vars = [
            "AZURE_OPENAI_ENDPOINT",
            "AZURE_OPENAI_API_KEY",
            "AZURE_OPENAI_DEPLOYMENT_NAME"
        ]
        
        missing_vars = [var for var in required_vars if not getattr(cls, var)]
        
        if missing_vars:
            raise ValueError(
                f"Faltan las siguientes variables de entorno: {', '.join(missing_vars)}"
            )
        
        return True
```

### 4. app/chat_manager.py

```python
"""
Gestor de chat usando LangChain y Azure OpenAI
"""
from langchain_openai import AzureChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain
from langchain.prompts import PromptTemplate
from app.config import Config

class ChatManager:
    """Clase para gestionar conversaciones con Azure OpenAI"""
    
    def __init__(self):
        """Inicializa el gestor de chat"""
        Config.validate()
        
        # Configurar el modelo de Azure OpenAI
        self.llm = AzureChatOpenAI(
            azure_endpoint=Config.AZURE_OPENAI_ENDPOINT,
            api_key=Config.AZURE_OPENAI_API_KEY,
            azure_deployment=Config.AZURE_OPENAI_DEPLOYMENT_NAME,
            api_version=Config.AZURE_OPENAI_API_VERSION,
            temperature=Config.APP_TEMPERATURE,
            max_tokens=Config.APP_MAX_TOKENS
        )
        
        # Configurar la memoria de conversación
        self.memory = ConversationBufferMemory(
            return_messages=True,
            memory_key="chat_history"
        )
        
        # Template del prompt
        template = """Eres un asistente útil y amigable. Responde de manera clara y concisa.

Historial de conversación:
{chat_history}

Usuario: {input}
Asistente:"""
        
        prompt = PromptTemplate(
            input_variables=["chat_history", "input"],
            template=template
        )
        
        # Crear la cadena de conversación
        self.conversation = ConversationChain(
            llm=self.llm,
            memory=self.memory,
            prompt=prompt,
            verbose=False
        )
    
    def send_message(self, message: str) -> str:
        """
        Envía un mensaje y obtiene la respuesta
        
        Args:
            message: Mensaje del usuario
            
        Returns:
            Respuesta del asistente
        """
        try:
            response = self.conversation.predict(input=message)
            return response
        except Exception as e:
            return f"Error al procesar el mensaje: {str(e)}"
    
    def clear_history(self):
        """Limpia el historial de conversación"""
        self.memory.clear()
    
    def get_history(self) -> list:
        """
        Obtiene el historial de conversación
        
        Returns:
            Lista de mensajes del historial
        """
        return self.memory.chat_memory.messages
```

### 5. app/main.py

```python
"""
Aplicación principal de Streamlit
"""
import streamlit as st
from app.chat_manager import ChatManager
from app.config import Config

# Configuración de la página
st.set_page_config(
    page_title=Config.APP_TITLE,
    page_icon="💬",
    layout="wide"
)

def initialize_session_state():
    """Inicializa el estado de la sesión"""
    if "chat_manager" not in st.session_state:
        try:
            st.session_state.chat_manager = ChatManager()
        except ValueError as e:
            st.error(f"Error de configuración: {e}")
            st.stop()
    
    if "messages" not in st.session_state:
        st.session_state.messages = []

def main():
    """Función principal de la aplicación"""
    
    # Inicializar estado de sesión
    initialize_session_state()
    
    # Título de la aplicación
    st.title(f"💬 {Config.APP_TITLE}")
    
    # Sidebar con información
    with st.sidebar:
        st.header("ℹ️ Información")
        st.info(
            "Esta aplicación usa Azure AI Foundry y LangChain "
            "para crear un chatbot inteligente."
        )
        
        st.header("⚙️ Configuración")
        st.write(f"**Modelo:** {Config.AZURE_OPENAI_DEPLOYMENT_NAME}")
        st.write(f"**Temperatura:** {Config.APP_TEMPERATURE}")
        st.write(f"**Max Tokens:** {Config.APP_MAX_TOKENS}")
        
        # Botón para limpiar conversación
        if st.button("🗑️ Limpiar Conversación", use_container_width=True):
            st.session_state.chat_manager.clear_history()
            st.session_state.messages = []
            st.rerun()
    
    # Contenedor principal del chat
    chat_container = st.container()
    
    # Mostrar mensajes existentes
    with chat_container:
        for message in st.session_state.messages:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])
    
    # Input del usuario
    if prompt := st.chat_input("Escribe tu mensaje aquí..."):
        # Agregar mensaje del usuario al historial
        st.session_state.messages.append({"role": "user", "content": prompt})
        
        # Mostrar mensaje del usuario
        with chat_container:
            with st.chat_message("user"):
                st.markdown(prompt)
        
        # Obtener respuesta del asistente
        with chat_container:
            with st.chat_message("assistant"):
                with st.spinner("Pensando..."):
                    response = st.session_state.chat_manager.send_message(prompt)
                    st.markdown(response)
        
        # Agregar respuesta al historial
        st.session_state.messages.append({"role": "assistant", "content": response})

if __name__ == "__main__":
    main()
```

### 6. app/__init__.py

```python
"""
Paquete de la aplicación de chat
"""
__version__ = "1.0.0"
```

## 🐳 Containerización con Docker

### 1. Dockerfile

```dockerfile
# Usar imagen base de Python
FROM python:3.11-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de requisitos
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY app/ ./app/

# Exponer el puerto de Streamlit
EXPOSE 8501

# Variables de entorno para Streamlit
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_ADDRESS=0.0.0.0

# Healthcheck
HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

# Comando para ejecutar la aplicación
CMD ["streamlit", "run", "app/main.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

### 2. docker-compose.yml

```yaml
version: '3.8'

services:
  chat-app:
    build: .
    container_name: azure-foundry-chat
    ports:
      - "8501:8501"
    environment:
      - AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}
      - AZURE_OPENAI_API_KEY=${AZURE_OPENAI_API_KEY}
      - AZURE_OPENAI_DEPLOYMENT_NAME=${AZURE_OPENAI_DEPLOYMENT_NAME}
      - AZURE_OPENAI_API_VERSION=${AZURE_OPENAI_API_VERSION}
      - APP_TITLE=${APP_TITLE}
      - APP_TEMPERATURE=${APP_TEMPERATURE}
      - APP_MAX_TOKENS=${APP_MAX_TOKENS}
    restart: unless-stopped
    volumes:
      - ./app:/app/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8501/_stcore/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 3. .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Environment variables
.env

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Docker
docker-compose.override.yml
```

## 🚀 Instalación y Ejecución

### Opción 1: Ejecución Local sin Docker

#### Paso 1: Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd azure-foundry-chat
```

#### Paso 2: Crear Entorno Virtual

```bash
python -m venv venv

# En Windows
venv\Scripts\activate

# En Linux/Mac
source venv/bin/activate
```

#### Paso 3: Instalar Dependencias

```bash
pip install -r requirements.txt
```

#### Paso 4: Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Editar .env con tus credenciales de Azure
nano .env  # o usa tu editor preferido
```

#### Paso 5: Ejecutar la Aplicación

```bash
streamlit run app/main.py
```

La aplicación estará disponible en `http://localhost:8501`

### Opción 2: Ejecución con Docker

#### Paso 1: Preparar Entorno

```bash
# Clonar repositorio
git clone <url-del-repositorio>
cd azure-foundry-chat

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales
```

#### Paso 2: Construir y Ejecutar

```bash
# Construir la imagen
docker-compose build

# Ejecutar el contenedor
docker-compose up -d

# Ver logs
docker-compose logs -f
```

#### Paso 3: Acceder a la Aplicación

Abre tu navegador en `http://localhost:8501`

#### Comandos Útiles de Docker

```bash
# Detener la aplicación
docker-compose down

# Reconstruir después de cambios
docker-compose up -d --build

# Ver estado de contenedores
docker-compose ps

# Reiniciar servicio
docker-compose restart
```

## 🧪 Pruebas

### Probar la Conexión con Azure

Crea un archivo `test_connection.py`:

```python
from app.config import Config
from app.chat_manager import ChatManager

def test_connection():
    try:
        Config.validate()
        print("✅ Configuración válida")
        
        chat = ChatManager()
        print("✅ Conexión establecida con Azure OpenAI")
        
        response = chat.send_message("Hola, ¿puedes confirmar que estás funcionando?")
        print(f"✅ Respuesta recibida: {response[:100]}...")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_connection()
```

Ejecutar:
```bash
python test_connection.py
```

## 📊 Monitoreo y Logs

### Ver Logs en Tiempo Real

```bash
# Con Docker
docker-compose logs -f chat-app

# Sin Docker
# Los logs aparecerán en la terminal donde ejecutaste streamlit
```

### Monitoreo en Azure

1. Ve a tu recurso de Azure OpenAI en el portal
2. Navega a **Monitoring** > **Metrics**
3. Puedes ver:
   - Número de llamadas
   - Latencia
   - Tokens utilizados
   - Errores

## 🔧 Solución de Problemas

### Error: "Missing environment variables"

**Solución**: Asegúrate de que el archivo `.env` existe y contiene todas las variables necesarias.

```bash
# Verificar variables
cat .env

# Verificar que el archivo .env se está cargando
python -c "from dotenv import load_dotenv; load_dotenv(); import os; print(os.getenv('AZURE_OPENAI_ENDPOINT'))"
```

### Error: "Authentication failed"

**Solución**: Verifica que tu API Key sea correcta y que el recurso esté activo.

1. Ve al portal de Azure
2. Confirma que el recurso de Azure OpenAI está en estado "Succeeded"
3. Regenera la clave si es necesario

### Error: "Deployment not found"

**Solución**: Verifica que el nombre del deployment coincida exactamente.

```bash
# El nombre debe coincidir con el que configuraste en Azure OpenAI Studio
AZURE_OPENAI_DEPLOYMENT_NAME=chat-model
```

### Contenedor no inicia

```bash
# Ver logs detallados
docker-compose logs chat-app

# Verificar configuración
docker-compose config

# Reconstruir desde cero
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

## 🔐 Mejores Prácticas de Seguridad

1. **Nunca commits tu archivo `.env`**: Está incluido en `.gitignore`
2. **Usa Azure Key Vault**: Para producción, almacena secretos en Azure Key Vault
3. **Rotar claves regularmente**: Cambia tus API keys periódicamente
4. **Limita permisos**: Usa roles de Azure RBAC apropiados
5. **Monitorea uso**: Configura alertas para uso inusual

## 📈 Extensiones y Mejoras

### 1. Agregar Memoria Persistente

Modifica `chat_manager.py` para usar Redis:

```python
from langchain.memory import RedisChatMessageHistory

def __init__(self):
    self.memory = ConversationBufferMemory(
        chat_memory=RedisChatMessageHistory(
            url="redis://localhost:6379",
            session_id="user_session"
        )
    )
```

### 2. Agregar Autenticación

Instala `streamlit-authenticator`:

```bash
pip install streamlit-authenticator
```

### 3. Implementar RAG (Retrieval Augmented Generation)

```python
from langchain.vectorstores import FAISS
from langchain.embeddings import AzureOpenAIEmbeddings

# Crear embeddings
embeddings = AzureOpenAIEmbeddings(
    azure_endpoint=Config.AZURE_OPENAI_ENDPOINT,
    api_key=Config.AZURE_OPENAI_API_KEY
)

# Crear vector store
vectorstore = FAISS.from_documents(documents, embeddings)
```

### 4. Desplegar en Azure Container Apps

```bash
# Login a Azure
az login

# Crear Container Registry
az acr create --resource-group myResourceGroup \
  --name myregistry --sku Basic

# Construir y push
az acr build --registry myregistry \
  --image azure-foundry-chat:latest .

# Desplegar en Container Apps
az containerapp create \
  --name azure-foundry-chat \
  --resource-group myResourceGroup \
  --image myregistry.azurecr.io/azure-foundry-chat:latest
```

## 📚 Recursos Adicionales

- [Documentación de Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/)
- [LangChain Documentation](https://python.langchain.com/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Azure AI Foundry](https://azure.microsoft.com/products/ai-studio/)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## ✉️ Contacto

Para preguntas o sugerencias, abre un issue en el repositorio.

## 🎉 Agradecimientos

- Azure AI Foundry team
- LangChain community
- Streamlit community

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub!**
