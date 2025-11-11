# 🔧 Guía de Uso del Configurador Automático de .env

Este documento explica cómo usar los scripts `configure_env.sh` (Bash) y `configure_env.ps1` (PowerShell) para configurar automáticamente tu archivo `.env`.

## 📋 ¿Qué hace el script?

El script configurador automatiza completamente la configuración de tu entorno, realizando las siguientes tareas:

1. **Autenticación en Azure**: Hace login en tu cuenta de Azure
2. **Selección de Suscripción**: Te permite elegir la suscripción a usar
3. **Gestión de Resource Group**: Crea o selecciona un Resource Group existente
4. **Configuración de Azure AI Foundry**: 
   - Crea o selecciona un AI Hub
   - Crea o selecciona un AI Project
   - Obtiene el endpoint del proyecto
5. **Configuración de Azure OpenAI**:
   - Crea o selecciona un recurso de Azure OpenAI
   - Obtiene automáticamente el endpoint y API key
   - Configura el nombre del deployment del modelo
6. **Configuración del Bot Service**:
   - Crea o selecciona un Azure Bot
   - Crea App Registration automáticamente
   - Genera y obtiene Client Secret
   - Habilita el canal de Microsoft Teams
7. **Configuraciones Adicionales**:
   - Content Safety
   - Parámetros del modelo (temperatura, max tokens)
   - System prompt personalizado
8. **Generación del .env**: Crea automáticamente el archivo `.env` con todos los valores

## 🚀 Uso

### Para Linux/macOS (Bash)

```bash
# Hacer el script ejecutable
chmod +x scripts/configure_env.sh

# Ejecutar el script
./scripts/configure_env.sh
```

### Para Windows (PowerShell)

```powershell
# Habilitar ejecución de scripts (solo primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ejecutar el script
.\scripts\configure_env.ps1
```

## 📝 Proceso Interactivo

El script te guiará paso a paso. Aquí hay un ejemplo de lo que verás:

### 1. Login en Azure

```
========================================
🔧 Configurador de .env para Teams AI Bot
========================================

✅ Azure CLI encontrado

📝 Iniciando sesión en Azure...
```

Se abrirá tu navegador para autenticarte.

### 2. Selección de Suscripción

```
📋 Obteniendo suscripciones disponibles...

Name                    ID                                      Default
----------------------  --------------------------------------  ---------
Mi Suscripción          xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx    true

¿Deseas usar una suscripción diferente? (y/n): n
```

### 3. Resource Group

```
════════════════════════════════════════
  Configuración de Resource Group
════════════════════════════════════════

Grupos de recursos existentes:
Name                      Location
------------------------  ----------
existing-rg               eastus

¿Deseas usar un Resource Group existente? (y/n): n
Nombre para el nuevo Resource Group [rg-ai-foundry-teams]: 
Location [eastus]: 
```

### 4. Azure AI Foundry

```
════════════════════════════════════════
  Configuración de Azure AI Foundry
════════════════════════════════════════

Workspaces de Azure AI existentes:
Name                Type
------------------  --------

¿Deseas usar un AI Hub/Project existente? (y/n): n
Nombre para el AI Hub [ai-foundry-hub]: 
Nombre para el AI Project [teams-bot-project]: 

Creando Azure AI Hub...
✅ AI Hub creado

Creando Azure AI Project...
✅ AI Project creado
```

### 5. Azure OpenAI

```
════════════════════════════════════════
  Configuración de Azure OpenAI
════════════════════════════════════════

Recursos de Azure OpenAI existentes:
(vacío si no hay ninguno)

¿Deseas usar un recurso OpenAI existente? (y/n): n
Nombre para el recurso Azure OpenAI [openai-teams-bot-project]: 

Creando recurso Azure OpenAI...
✅ Recurso OpenAI creado

Obteniendo credenciales de Azure OpenAI...

Nombre del deployment de modelo OpenAI [gpt-41-turbo]: 
```

### 6. Azure Bot Service

```
════════════════════════════════════════
  Configuración de Azure Bot Service
════════════════════════════════════════

Bots existentes:
No hay bots existentes

¿Deseas usar un bot existente? (y/n): n
Nombre para el bot [teams-ai-foundry-bot]: 

Creando App Registration...
✅ App Registration creada: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Creando client secret...
✅ Client Secret creado

Creando Azure Bot...
✅ Azure Bot creado

Habilitando canal de Microsoft Teams...
✅ Canal de Teams habilitado
```

### 7. Configuraciones Adicionales

```
════════════════════════════════════════
  Configuraciones Adicionales
════════════════════════════════════════

Habilitar Content Safety? (y/n) [y]: y
Temperatura del modelo [0.7]: 
Máximo de tokens [2000]: 
System Prompt [Eres un asistente inteligente...]: 
```

### 8. Resultado Final

```
📝 Generando archivo .env...
✅ Archivo .env generado exitosamente

=========================================
✅ Configuración Completada
=========================================

📋 Resumen de la configuración:

  Azure Subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Resource Group: rg-ai-foundry-teams
  AI Hub: ai-foundry-hub
  AI Project: teams-bot-project
  OpenAI Resource: openai-teams-bot-project
  OpenAI Deployment: gpt-41-turbo
  Bot Name: teams-ai-foundry-bot
  Bot App ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

⚠️  IMPORTANTE - Próximos pasos:

1. Ve a Azure AI Studio: https://ai.azure.com
   - Despliega el modelo GPT-4.1 'gpt-41-turbo' si aún no existe

2. Verifica tu archivo .env:
   cat .env

3. Prueba la configuración:
   make validate-config

4. Ejecuta el bot localmente:
   python bot/bot_app.py

5. Despliega a Azure:
   bash scripts/deploy.sh

¡Configuración exitosa! 🎉
```

## 🔄 Usar Recursos Existentes

Si ya tienes recursos creados en Azure, el script te permite seleccionarlos:

1. El script lista todos los recursos existentes en cada paso
2. Responde `y` cuando pregunte si deseas usar recursos existentes
3. Ingresa el nombre del recurso que deseas usar
4. El script obtendrá automáticamente las credenciales

## 🔐 Seguridad

- ✅ Las credenciales se obtienen directamente desde Azure
- ✅ El Client Secret se genera automáticamente
- ✅ El archivo `.env` se crea localmente y no se sube a git (está en `.gitignore`)
- ✅ Solo necesitas tener permisos en tu suscripción de Azure

## 🛠️ Requisitos Previos

Antes de ejecutar el script, asegúrate de tener:

1. **Azure CLI instalado**: 
   - Linux/macOS: `curl -L https://aka.ms/InstallAzureCli | bash`
   - Windows: Descarga desde https://aka.ms/installazurecliwindows

2. **Permisos en Azure**:
   - Contributor o superior en la suscripción
   - Permisos para crear App Registrations en Azure AD

3. **Python 3.9+** (para validar después)

## ❓ Preguntas Frecuentes

### ¿Puedo ejecutar el script múltiples veces?

Sí, puedes ejecutarlo tantas veces como quieras. El script te permite elegir entre usar recursos existentes o crear nuevos.

### ¿Qué pasa si ya tengo un .env?

El script sobrescribirá el archivo `.env` existente. Haz un backup si necesitas conservar valores personalizados.

### ¿El script crea recursos que cuestan dinero?

Sí, algunos recursos tienen costos:
- Azure OpenAI (S0): Costo por uso
- Azure AI Hub/Project: Costo por recursos consumidos
- Azure Bot Service (F0): Gratis

Revisa la [calculadora de precios de Azure](https://azure.microsoft.com/pricing/calculator/) para más información.

### ¿Puedo personalizar los valores después?

Sí, puedes editar manualmente el archivo `.env` generado para ajustar cualquier valor.

### ¿El script despliega el modelo de OpenAI?

No, el script NO despliega el modelo automáticamente. Debes:
1. Ir a Azure AI Studio (https://ai.azure.com)
2. Navegar a tu proyecto
3. Ir a "Deployments"
4. Crear un deployment del modelo GPT-4.1 con el nombre que especificaste (ej: `gpt-41-turbo`)

## 🐛 Solución de Problemas

### Error: "Azure CLI not found"

```bash
# Instalar Azure CLI
# Linux/macOS:
curl -L https://aka.ms/InstallAzureCli | bash

# Windows (PowerShell como Admin):
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait
```

### Error: "Insufficient permissions"

Asegúrate de tener rol de Contributor o superior en la suscripción.

### Error al crear App Registration

Necesitas permisos de "Application Administrator" o "Global Administrator" en Azure AD.

### El script se congela en login

Verifica que tu navegador no esté bloqueando ventanas emergentes.

## 📚 Próximos Pasos

Después de ejecutar el script:

1. **Desplegar modelo en AI Studio**
2. **Validar configuración**: `python -c "from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()"`
3. **Ejecutar bot localmente**: `python bot/bot_app.py`
4. **Desplegar a Azure**: `./scripts/deploy.sh` o `.\scripts\deploy.ps1`

## 💡 Consejos

- **Nombres descriptivos**: Usa nombres que identifiquen el propósito (ej: `rg-chatbot-prod`)
- **Organización**: Agrupa recursos relacionados en el mismo Resource Group
- **Locations**: Elige una location cercana a tus usuarios para mejor latencia
- **Backup**: Guarda una copia del resumen final que muestra el script

---

¿Necesitas ayuda? Revisa la [documentación completa](README_PROJECT.md) o crea un [issue en GitHub](https://github.com/tu-usuario/ExampleAppFoundry/issues).
