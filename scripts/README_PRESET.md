# 🚀 Scripts de Configuración Preestablecida

Este directorio contiene scripts automatizados para configurar rápidamente el archivo `.env` con valores preestablecidos para el proyecto **BotprojectTeam**.

## 📋 Scripts Disponibles

### 1️⃣ Script con Valores Preestablecidos (Recomendado)

Estos scripts usan valores predefinidos para acelerar la configuración:

#### Windows (PowerShell):
```powershell
.\scripts\configure_env_preset.ps1
```

#### Linux/Mac (Bash):
```bash
chmod +x scripts/configure_env_preset.sh
./scripts/configure_env_preset.sh
```

**Valores Preestablecidos:**
- **Suscripción**: `662141d0-0308-4187-b46b-db1e9466b5ac`
- **Resource Group**: `AIBOTSTEAM`
- **Location**: `eastus2`
- **AI Hub**: `BotprojectTeam`
- **AI Project**: `BotprojectTeam`
- **OpenAI Resource**: `aiappsseroger`
- **OpenAI Deployment**: `gpt-4.1`

### 2️⃣ Script Interactivo Completo

Para configuraciones personalizadas o nuevos proyectos:

#### Windows (PowerShell):
```powershell
.\scripts\configure_env.ps1
```

#### Linux/Mac (Bash):
```bash
chmod +x scripts/configure_env.sh
./scripts/configure_env.sh
```

## 🔍 ¿Qué Hace el Script Preset?

1. **Verifica Azure CLI** - Comprueba que esté instalado
2. **Login a Azure** - Inicia sesión (si es necesario)
3. **Configura Suscripción** - Establece la suscripción correcta
4. **Verifica Recursos** - Comprueba que existan:
   - Resource Group `AIBOTSTEAM`
   - AI Project `BotprojectTeam`
   - Azure OpenAI `aiappsseroger`
5. **Obtiene Credenciales** - Extrae endpoints y API keys automáticamente
6. **Configura Bot** (Opcional) - Permite configurar Azure Bot Service
7. **Genera .env** - Crea el archivo con todos los valores

## 📝 Requisitos Previos

### ✅ Software Necesario:
- **Azure CLI** instalado
  - Windows: `winget install Microsoft.AzureCLI`
  - Mac: `brew install azure-cli`
  - Linux: [Instrucciones oficiales](https://learn.microsoft.com/cli/azure/install-azure-cli-linux)
- **PowerShell 5.1+** (Windows) o **Bash** (Linux/Mac)
- **Permisos en Azure**:
  - Lector en la suscripción
  - Colaborador en el Resource Group
  - Acceso al recurso Azure OpenAI

### ⚠️ Recursos que Deben Existir:
- ✅ **Suscripción**: `662141d0-0308-4187-b46b-db1e9466b5ac`
- ✅ **Resource Group**: `AIBOTSTEAM` (en `eastus2`)
- ✅ **AI Project**: `BotprojectTeam`
- ✅ **Azure OpenAI**: `aiappsseroger`
- ⚠️ **Deployment del Modelo**: `gpt-4.1` (debe crearse manualmente en AI Studio)

## 🎯 Uso Rápido

### Opción A: Solo Obtener Credenciales (Sin configurar Bot)

```powershell
# Ejecutar el script
.\scripts\configure_env_preset.ps1

# Cuando pregunte por el Bot, responder "n"
¿Deseas configurar el Bot ahora? (y/n): n
```

Esto generará el `.env` con placeholders para el Bot. Podrás configurarlo manualmente después.

### Opción B: Configuración Completa (Con Bot)

```powershell
# Ejecutar el script
.\scripts\configure_env_preset.ps1

# Cuando pregunte por el Bot, responder "y"
¿Deseas configurar el Bot ahora? (y/n): y

# Si el bot ya existe:
# - Te pedirá el App Password (Client Secret)

# Si el bot NO existe:
# - Creará automáticamente:
#   ✅ App Registration
#   ✅ Client Secret (¡guárdalo!)
#   ✅ Azure Bot Service
#   ✅ Canal de Teams
```

## 📊 Ejemplo de Ejecución

```powershell
PS> .\scripts\configure_env_preset.ps1

=========================================
🔧 Configurador Automático .env
    BotprojectTeam - Azure AI Foundry
=========================================

📋 Configuración preestablecida:

  Suscripción: 662141d0-0308-4187-b46b-db1e9466b5ac
  Resource Group: AIBOTSTEAM
  Location: eastus2
  AI Hub: BotprojectTeam
  AI Project: BotprojectTeam
  OpenAI Resource: aiappsseroger
  OpenAI Deployment: gpt-4.1

✅ Azure CLI encontrado: 2.65.0
📝 Iniciando sesión en Azure...
✅ Login exitoso
🔄 Configurando suscripción...
✅ Suscripción configurada
🔧 Verificando extensión de Azure ML...
✅ Extensión Azure ML lista
🔍 Verificando Resource Group...
✅ Resource Group encontrado: AIBOTSTEAM
🔍 Verificando AI Project...
✅ AI Project encontrado: BotprojectTeam
📡 Obteniendo información del proyecto...
🔍 Verificando recurso Azure OpenAI...
✅ Recurso OpenAI encontrado: aiappsseroger
🔑 Obteniendo credenciales de Azure OpenAI...
✅ Credenciales obtenidas
🔍 Verificando deployment del modelo 'gpt-4.1'...
⚠️  Asegúrate de que el deployment 'gpt-4.1' existe en Azure AI Studio
    URL: https://ai.azure.com

════════════════════════════════════════
  Configuración de Azure Bot Service
════════════════════════════════════════

¿Deseas configurar el Bot ahora? (y/n): y
Nombre para el bot [teams-ai-foundry-bot]: teams-botproject-bot
Creando nuevo bot...
Creando App Registration...
✅ App Registration creada: 12345678-abcd-1234-abcd-123456789abc
Creando client secret...
✅ Client Secret creado
⚠️  IMPORTANTE: Guarda este password, no se mostrará de nuevo:
    AbCdEfGh1234567890~XyZ...
Presiona Enter para continuar...
Creando Azure Bot...
✅ Azure Bot creado
Habilitando canal de Microsoft Teams...
✅ Canal de Teams habilitado

════════════════════════════════════════
  Configuraciones Adicionales
════════════════════════════════════════

Habilitar Content Safety? (y/n) [y]: y
Temperatura del modelo [0.7]: 0.7
Máximo de tokens [2000]: 2000
System Prompt personalizado? (Enter para usar el predeterminado): 

📝 Generando archivo .env...
✅ Archivo .env generado exitosamente en:
   C:\...\ExampleAppFoundry\.env

=========================================
✅ Configuración Completada
=========================================

📋 Resumen de la configuración:

  Suscripción: 662141d0-0308-4187-b46b-db1e9466b5ac
  Resource Group: AIBOTSTEAM
  Location: eastus2
  AI Hub: BotprojectTeam
  AI Project: BotprojectTeam
  OpenAI Resource: aiappsseroger
  OpenAI Endpoint: https://aiappsseroger.openai.azure.com/
  OpenAI Deployment: gpt-4.1
  Bot Name: teams-botproject-bot
  Bot App ID: 12345678-abcd-1234-abcd-123456789abc

⚠️  IMPORTANTE - Próximos pasos:

1. Verifica que el deployment del modelo existe:
   - Ve a https://ai.azure.com
   - Selecciona el proyecto 'BotprojectTeam'
   - Ve a 'Deployments' y verifica que existe 'gpt-4.1'

2. Revisa tu archivo .env:
   Get-Content .env

3. Prueba la configuración:
   python -c "from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()"

4. Instala las dependencias:
   pip install -r requirements.txt

5. Ejecuta el bot localmente:
   python bot/bot_app.py

¡Configuración exitosa! 🎉
```

## 🔧 Troubleshooting

### Error: "Azure CLI no está instalado"
```powershell
# Windows
winget install Microsoft.AzureCLI

# Reinicia el terminal después de instalar
```

### Error: "Resource Group 'AIBOTSTEAM' no existe"
El script ofrecerá crearlo automáticamente. Responde `y` para continuar.

### Error: "AI Project 'BotprojectTeam' no encontrado"
Debes crear el proyecto manualmente en [Azure AI Studio](https://ai.azure.com):
1. Ve a https://ai.azure.com
2. Selecciona "Create new project"
3. Nombre: `BotprojectTeam`
4. Resource Group: `AIBOTSTEAM`
5. Location: `East US 2`

### Error: "Deployment 'gpt-4.1' no existe"
El deployment debe crearse manualmente:
1. Ve a https://ai.azure.com
2. Selecciona el proyecto `BotprojectTeam`
3. Ve a "Deployments" → "Create"
4. Selecciona modelo GPT-4.1
5. Nombre del deployment: `gpt-4.1`

### Error: "Extension 'ml' failed to install"
Este es un warning que puede ignorarse. El script continúa normalmente.

## 📚 Archivos Generados

### `.env` (en la raíz del proyecto)
Contiene todas las configuraciones necesarias:
- Credenciales de Azure
- Configuración de AI Foundry
- Endpoints y API Keys
- Configuración del Bot
- Parámetros de la aplicación

**⚠️ IMPORTANTE**: El archivo `.env` contiene información sensible. NUNCA lo subas a Git.

## 🔄 Diferencias Entre Scripts

| Característica | `configure_env_preset.ps1` | `configure_env.ps1` |
|----------------|----------------------------|---------------------|
| Valores predefinidos | ✅ Sí | ❌ No |
| Interactivo | Parcial (solo Bot y extras) | ✅ Completo |
| Velocidad | ⚡ Rápido | 🐢 Más lento |
| Flexibilidad | 🔒 Proyecto específico | 🔓 Cualquier proyecto |
| Uso recomendado | BotprojectTeam | Nuevos proyectos |

## 🎓 Siguientes Pasos

Después de ejecutar el script:

1. **Verificar el .env**:
   ```powershell
   Get-Content .env
   ```

2. **Crear el deployment del modelo** (si no existe):
   - Ve a https://ai.azure.com
   - Proyecto `BotprojectTeam`
   - Deployments → Create → `gpt-4.1`

3. **Instalar dependencias**:
   ```powershell
   pip install -r requirements.txt
   ```

4. **Probar localmente**:
   ```powershell
   python bot/bot_app.py
   ```

5. **Configurar en Teams**:
   - Ve a https://dev.teams.microsoft.com/apps
   - Crea una nueva app
   - Configura el Bot con el App ID generado

6. **Desplegar a Azure**:
   ```powershell
   .\scripts\deploy.ps1
   ```

## 📞 Soporte

Si tienes problemas:
1. Verifica que tengas los permisos necesarios en Azure
2. Revisa que todos los recursos existan
3. Consulta la documentación oficial de [Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)
4. Revisa los logs del script para identificar errores específicos

---

**Desarrollado para el proyecto BotprojectTeam** 🤖✨
