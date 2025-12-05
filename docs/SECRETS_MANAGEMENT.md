# Gestión de Secretos

## 🔐 Configuración de Credenciales Seguras

Este proyecto utiliza credenciales de Azure que **NO deben estar en el código ni en git**.

## Métodos de Configuración

### Opción 1: Configuración Git Local (Recomendado para desarrollo)

Las credenciales se guardan en `.git/config` (ignorado por git):

```powershell
# Configurar App ID
git config --local user.app.id "TU_APP_ID"

# Configurar App Password  
git config --local user.app.password "TU_APP_PASSWORD"

# Configurar Subscription ID
git config --local user.subscription.id "TU_SUBSCRIPTION_ID"

# Configurar Resource Group
git config --local user.resource.group "TU_RESOURCE_GROUP"
```

### Opción 2: Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto (ya está en `.gitignore`):

```bash
MICROSOFT_APP_ID=tu-app-id
MICROSOFT_APP_PASSWORD=tu-app-password
AZURE_SUBSCRIPTION_ID=tu-subscription-id
AZURE_RESOURCE_GROUP=tu-resource-group
```

### Opción 3: Azure Key Vault (Recomendado para producción)

```powershell
# Obtener secretos desde Key Vault
az keyvault secret show --name "bot-app-id" --vault-name "tu-keyvault" --query value -o tsv
```

## Verificar Configuración

```powershell
# Ver configuración local de git
git config --local --list | Select-String "user.app"

# Verificar .env
Get-Content .env | Select-String "MICROSOFT_APP"
```

## Rotar Credenciales

Si un secreto fue expuesto:

1. **Regenerar en Azure Portal:**
   - Azure Active Directory → App registrations
   - Buscar tu app → Certificates & secrets
   - New client secret

2. **Actualizar configuración local:**
   ```powershell
   git config --local user.app.password "NUEVO_PASSWORD"
   ```

3. **Actualizar en producción:**
   - Azure Portal → App Service → Configuration
   - Actualizar `MICROSOFT_APP_PASSWORD`

## Seguridad

- ❌ **NUNCA** commitear secretos en git
- ❌ **NUNCA** compartir secretos en chat/email
- ✅ Usar variables de entorno o Azure Key Vault
- ✅ Rotar secretos regularmente
- ✅ Usar diferentes secretos para dev/prod

## Scripts Actualizados

Los siguientes scripts ahora leen credenciales de forma segura:

- `scripts/create_bot_service.ps1`
- `scripts/configure_env.ps1`

Prioridad de lectura:
1. Variables de entorno (.env)
2. Git config local
3. Valores por defecto (solo IDs no sensibles)
