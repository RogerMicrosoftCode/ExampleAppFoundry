# 🚀 Script de Despliegue Completo - JaroChat AI Demo

Este script automatiza la creación de **TODOS los recursos necesarios** para desplegar la solución Teams AI Bot con Azure AI Foundry desde cero.

## 📦 ¿Qué Crea Este Script?

El script `deploy_full_solution.ps1` crea automáticamente:

### ✅ Infraestructura de Azure
- **Resource Group**: `jarochatAIdemoteam` en `eastus2`
- **Azure AI Hub**: `jarochat-ai-hub`
- **Azure AI Project**: `jarochat-ai-project`
- **Azure OpenAI Service**: `jarochat-openai`
  - **Deployment del modelo**: `gpt-41-turbo` (GPT-4 Turbo)
- **Azure Bot Service**: `jarochat-teams-bot`
  - App Registration con Client Secret
  - Canal de Microsoft Teams habilitado

### ✅ Configuración
- Archivo `.env` con todas las credenciales
- Endpoints y API Keys configurados automáticamente
- System Prompt personalizado para JaroChat

## 🎯 Ventajas de Este Script

| Característica | Script Completo | Scripts Previos |
|----------------|-----------------|-----------------|
| Crea Resource Group | ✅ Sí | ❌ Usa existente |
| Crea OpenAI Service | ✅ Sí | ❌ Usa existente |
| Despliega Modelo GPT-4 | ✅ Sí | ❌ Manual |
| Crea AI Hub | ✅ Sí | ❌ Usa existente |
| Crea AI Project | ✅ Sí | ❌ Usa existente |
| Crea Bot Service | ✅ Sí | ✅ Sí |
| Genera .env | ✅ Sí | ✅ Sí |
| **Tiempo estimado** | ⏱️ 10-15 min | ⏱️ 5 min |
| **Interacción requerida** | 🔄 Mínima | 🔄 Media |

## 🔧 Requisitos Previos

### Software Necesario

#### Windows:
```powershell
# Azure CLI
winget install Microsoft.AzureCLI

# PowerShell 5.1+ (ya incluido en Windows)
```

#### Linux/Mac:
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# o usando Homebrew (Mac)
brew install azure-cli
```

### Permisos en Azure

Necesitas los siguientes permisos en la suscripción `662141d0-0308-4187-b46b-db1e9466b5ac`:

- ✅ **Contributor** (para crear recursos)
- ✅ **User Access Administrator** (para crear App Registrations)
- ✅ **Cognitive Services Contributor** (para Azure OpenAI)

## 🚀 Uso

### Windows (PowerShell):

```powershell
# Navegar al directorio de scripts
cd scripts

# Ejecutar el script
.\deploy_full_solution.ps1
```

### Linux/Mac (Bash):

```bash
# Dar permisos de ejecución
chmod +x scripts/deploy_full_solution.sh

# Ejecutar el script
./scripts/deploy_full_solution.sh
```

### Modo No Interactivo:

```powershell
# Sin confirmación (para CI/CD)
.\deploy_full_solution.ps1 -SkipConfirmation
```

## 📋 Proceso de Despliegue

El script sigue estos pasos automáticamente:

### Paso 1: Verificar Prerrequisitos
- ✅ Verifica instalación de Azure CLI
- ✅ Valida versión compatible

### Paso 2: Autenticación
- 🔐 Login a Azure (si es necesario)
- 🎯 Configura la suscripción correcta

### Paso 3: Extensiones
- 📦 Instala extensión `ml` para Azure AI
- 📦 Instala extensión `cognitiveservices`

### Paso 4: Resource Group
- 📁 Crea `jarochatAIdemoteam` en `eastus2`
- ⚠️ Si existe, pregunta si continuar

### Paso 5: Azure OpenAI Service
- 🤖 Crea recurso `jarochat-openai`
- 🔑 Obtiene endpoint y API key
- ⏱️ Tiempo: 2-3 minutos

### Paso 6: Deployment del Modelo
- 🚀 Despliega GPT-4 Turbo como `gpt-41-turbo`
- 📊 Capacidad: 10 TPM (Tokens Por Minuto)
- ⏱️ Tiempo: 2-3 minutos

### Paso 7: Azure AI Hub
- 🏢 Crea `jarochat-ai-hub`
- 🔗 Conecta con Azure OpenAI
- ⏱️ Tiempo: 3-5 minutos

### Paso 8: Azure AI Project
- 📂 Crea `jarochat-ai-project`
- 🔗 Vincula al Hub
- ⏱️ Tiempo: 2-3 minutos

### Paso 9: Azure Bot Service
- 🤖 Crea App Registration
- 🔐 Genera Client Secret (¡guárdalo!)
- 📱 Habilita canal de Teams
- ⏱️ Tiempo: 1-2 minutos

### Paso 10: Generar .env
- 📝 Crea archivo `.env` con todas las credenciales
- ✅ Listo para usar

## ⏱️ Tiempo Total Estimado

- **Primera ejecución**: 10-15 minutos
- **Con recursos existentes**: 3-5 minutos

## 📊 Ejemplo de Ejecución

```powershell
PS> .\deploy_full_solution.ps1

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║         🚀 DESPLIEGUE COMPLETO DE SOLUCIÓN 🚀             ║
║              Teams AI Bot - Azure AI Foundry               ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

ℹ️  Este script creará TODOS los recursos necesarios desde cero

═══════════════════════════════════════════════════════════
  📋 CONFIGURACIÓN DEL DESPLIEGUE
═══════════════════════════════════════════════════════════

🔹 Suscripción:
   ID: 662141d0-0308-4187-b46b-db1e9466b5ac

🔹 Nuevo Resource Group:
   Nombre: jarochatAIdemoteam
   Location: eastus2

🔹 Azure AI Foundry:
   AI Hub: jarochat-ai-hub
   AI Project: jarochat-ai-project

🔹 Azure OpenAI:
   Resource: jarochat-openai
   Deployment: gpt-41-turbo
   Model: gpt-4 (turbo-2024-04-09)

🔹 Azure Bot Service:
   Bot: jarochat-teams-bot
   Display Name: JaroChat AI Demo Bot

⚠️  Este script creará recursos que pueden generar costos en Azure

¿Deseas continuar con el despliegue? (yes/no): yes

═══════════════════════════════════════════════════════════
  PASO 1/10: Verificar Prerrequisitos
═══════════════════════════════════════════════════════════

[████████████████████] 10% - Verificando Azure CLI...
✅ Azure CLI instalado: 2.65.0

═══════════════════════════════════════════════════════════
  PASO 2/10: Autenticación en Azure
═══════════════════════════════════════════════════════════

[████████████████████] 20% - Verificando sesión...
✅ Sesión de Azure activa
ℹ️  Configurando suscripción...
✅ Usando suscripción: Microsoft Azure Sponsorship

... (proceso continúa) ...

════════════════════════════════════════════════════════════
⚠️  IMPORTANTE: Guarda este Client Secret de forma segura
    No se mostrará de nuevo después de este despliegue
════════════════════════════════════════════════════════════

    Client Secret: AbCdEfGh1234567890~XyZ...

════════════════════════════════════════════════════════════

Presiona Enter después de guardar el Client Secret...

... (proceso continúa) ...

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              ✅ DESPLIEGUE COMPLETADO ✅                   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════
  📊 RESUMEN DEL DESPLIEGUE
═══════════════════════════════════════════════════════════

🔹 Resource Group: jarochatAIdemoteam
🔹 AI Hub: jarochat-ai-hub
🔹 AI Project: jarochat-ai-project
🔹 OpenAI Resource: jarochat-openai
🔹 Bot: jarochat-teams-bot
🔹 Bot App ID: 12345678-abcd-1234-abcd-123456789abc

🎉 ¡Despliegue completado exitosamente!
🤖 Tu bot JaroChat está listo para usar
```

## 🔍 Verificación Post-Despliegue

### 1. Verificar Recursos en Azure Portal

```powershell
# Abrir Azure Portal
Start-Process "https://portal.azure.com/#view/HubsExtension/BrowseResourceGroup/resourceGroup/jarochatAIdemoteam"
```

Deberías ver:
- ✅ 1 Resource Group: `jarochatAIdemoteam`
- ✅ 1 Azure OpenAI: `jarochat-openai`
- ✅ 1 AI Hub: `jarochat-ai-hub`
- ✅ 1 AI Project: `jarochat-ai-project`
- ✅ 1 Bot Service: `jarochat-teams-bot`

### 2. Verificar AI Project en Azure AI Studio

```powershell
# Abrir Azure AI Studio
Start-Process "https://ai.azure.com"
```

- Ve a "Projects"
- Busca `jarochat-ai-project`
- Verifica el deployment `gpt-41-turbo`

### 3. Verificar archivo .env

```powershell
# Ver el contenido
Get-Content .env

# Verificar que tiene todas las variables
Select-String -Path .env -Pattern "AZURE_|MICROSOFT_|BOT_"
```

### 4. Probar la Configuración

```powershell
# Validar configuración de Python
python -c "from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()"
```

Si todo está bien, deberías ver:
```
✅ Azure AI Foundry config is valid
✅ Bot config is valid
```

## 🎯 Próximos Pasos

### 1. Instalar Dependencias

```powershell
pip install -r requirements.txt
```

### 2. Ejecutar el Bot Localmente

```powershell
python bot/bot_app.py
```

### 3. Configurar en Microsoft Teams

1. Ve a [Teams Developer Portal](https://dev.teams.microsoft.com/apps)
2. Crea una nueva app
3. Ve a "App features" → "Bot"
4. Configura:
   - **Bot ID**: (copia desde `.env` → `MICROSOFT_APP_ID`)
   - **Messaging endpoint**: `https://jarochat-teams-bot.azurewebsites.net/api/messages`
5. Instala la app en Teams

### 4. Desplegar a Azure

```powershell
# Desplegar a Azure Container Apps
.\scripts\deploy.ps1
```

## 💰 Estimación de Costos

Recursos creados y costos mensuales aproximados:

| Recurso | SKU | Costo Mensual Estimado |
|---------|-----|------------------------|
| Azure OpenAI (GPT-4) | S0 | ~$30-100 (según uso) |
| Azure Bot Service | F0 (Free) | **GRATIS** |
| Azure AI Hub | Standard | ~$5-20 |
| Azure AI Project | Standard | ~$5-10 |
| **TOTAL** | | **~$40-130/mes** |

### 💡 Consejos para Reducir Costos:

1. **Usa el Free Tier** donde sea posible
2. **Monitorea el uso** en Azure Cost Management
3. **Elimina recursos** cuando no los uses:
   ```powershell
   az group delete --name jarochatAIdemoteam --yes --no-wait
   ```
4. **Configura alertas** de costos en Azure Portal

## 🔒 Seguridad

### ✅ Mejores Prácticas Implementadas:

1. **Credenciales en .env**
   - ✅ Archivo `.env` en `.gitignore`
   - ✅ NUNCA subir a Git
   - ✅ Client Secret mostrado solo una vez

2. **RBAC en Azure**
   - ✅ Permisos mínimos necesarios
   - ✅ App Registration con Secret
   - ✅ Managed Identities cuando sea posible

3. **Content Safety**
   - ✅ Habilitado por defecto
   - ✅ Threshold: medium

### ⚠️ Recomendaciones Adicionales:

```powershell
# Rotar Client Secret cada 6 meses
az ad app credential reset --id $MICROSOFT_APP_ID

# Habilitar Azure Key Vault (opcional)
# Para almacenar secretos de forma más segura
```

## 🐛 Troubleshooting

### Error: "Azure CLI no está instalado"

```powershell
# Windows
winget install Microsoft.AzureCLI

# Reiniciar terminal
```

### Error: "Insufficient permissions"

Necesitas permisos de **Contributor** en la suscripción.

```powershell
# Verificar permisos
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Error: "Resource Group already exists"

El script preguntará si deseas continuar. Si eliges "y", usará el RG existente.

### Error: "Deployment failed for model"

El deployment del modelo puede fallar por cuotas. Opciones:

1. **Crear manualmente en Azure AI Studio**:
   - Ve a https://ai.azure.com
   - Proyecto: `jarochat-ai-project`
   - Deployments → Create → Selecciona GPT-4

2. **Solicitar aumento de cuota**:
   ```powershell
   # Abrir portal de cuotas
   Start-Process "https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade"
   ```

### Error: "Extension 'ml' failed to install"

Este warning puede ignorarse. El script continúa normalmente.

## 🔄 Actualizar o Re-ejecutar

Si necesitas actualizar o re-crear recursos:

```powershell
# Eliminar Resource Group completo
az group delete --name jarochatAIdemoteam --yes --no-wait

# Esperar a que se elimine (5-10 minutos)
# Luego ejecutar el script de nuevo
.\deploy_full_solution.ps1
```

## 📚 Recursos Adicionales

- [Azure AI Studio](https://ai.azure.com)
- [Azure Portal](https://portal.azure.com)
- [Teams Developer Portal](https://dev.teams.microsoft.com)
- [Bot Framework Documentation](https://docs.microsoft.com/azure/bot-service/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/cognitive-services/openai/)

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs del script
2. Verifica permisos en Azure
3. Consulta la [documentación oficial](https://learn.microsoft.com/azure/ai-studio/)
4. Abre un issue en el repositorio

---

## 📝 Notas Importantes

### ⚠️ Client Secret

El **Client Secret** se muestra **SOLO UNA VEZ** durante la ejecución. Asegúrate de guardarlo en un lugar seguro.

### 🔐 Archivo .env

El archivo `.env` contiene información sensible. **NUNCA** lo subas a Git.

```bash
# Verificar que está en .gitignore
cat .gitignore | grep .env
```

### 💾 Backup

Considera hacer backup del archivo `.env`:

```powershell
# Crear backup encriptado (opcional)
Copy-Item .env .env.backup
```

---

**Desarrollado para JaroChat AI Demo Team** 🚀✨

**Resource Group**: `jarochatAIdemoteam`  
**Suscripción**: `662141d0-0308-4187-b46b-db1e9466b5ac`
