# 🚀 Quick Start - Configuración Automática

## Configuración del archivo .env en 1 comando

### Para Windows (PowerShell) - RECOMENDADO

```powershell
# 1. Habilitar ejecución de scripts (solo primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. Ejecutar el configurador
.\scripts\configure_env.ps1
```

### Para Linux/macOS (Bash)

```bash
# 1. Hacer ejecutable
chmod +x scripts/configure_env.sh

# 2. Ejecutar el configurador
./scripts/configure_env.sh
```

## ¿Qué hace el script?

El script automáticamente:

✅ Hace login en Azure  
✅ Crea/selecciona Resource Group  
✅ Crea/selecciona Azure AI Hub y Project  
✅ Crea/selecciona Azure OpenAI y obtiene credenciales  
✅ Crea/selecciona Azure Bot y genera secrets  
✅ Habilita canal de Microsoft Teams  
✅ Genera el archivo `.env` completo  

## Después de ejecutar el script

1. **Desplegar modelo en Azure AI Studio**:
   - Ve a https://ai.azure.com
   - Selecciona tu proyecto
   - Crea un deployment del modelo (ej: GPT-4)

2. **Verificar configuración**:
   ```bash
   python -c "from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate()"
   ```

3. **Ejecutar localmente**:
   ```bash
   python bot/bot_app.py
   ```

4. **Desplegar a Azure**:
   ```bash
   # Bash
   ./scripts/deploy.sh
   
   # PowerShell
   .\scripts\deploy.ps1
   ```

## 📚 Documentación Completa

- [Guía detallada del configurador](docs/CONFIGURE_ENV_GUIDE.md)
- [README del proyecto](README_PROJECT.md)
- [Documentación técnica completa](BotTeamsAFOIADemo.md)

## ⚡ Solución Rápida de Problemas

**Error: "Azure CLI not found"**
```bash
# Instalar Azure CLI desde:
# https://docs.microsoft.com/cli/azure/install-azure-cli
```

**Error: "Insufficient permissions"**
- Necesitas rol Contributor en la suscripción
- Necesitas permisos para crear App Registrations en Azure AD

**¿Ya tienes recursos creados?**
- El script te preguntará si quieres usar recursos existentes
- Simplemente responde "y" y selecciona el recurso

## 💡 Consejos

- Usa los valores por defecto presionando Enter si no estás seguro
- Puedes ejecutar el script múltiples veces
- Guarda el resumen que muestra al final
- El archivo `.env` se puede editar manualmente después

---

**¿Listo?** Ejecuta el script y en 5 minutos tendrás todo configurado! 🎉
