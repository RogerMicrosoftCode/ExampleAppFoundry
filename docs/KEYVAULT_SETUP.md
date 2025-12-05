# 🔐 Azure Key Vault - Guía de Configuración

Esta guía te ayudará a configurar Azure Key Vault para gestionar de forma segura los secretos de tu bot.

## 📋 Tabla de Contenidos

- [¿Por qué Key Vault?](#por-qué-key-vault)
- [Configuración Rápida](#configuración-rápida)
- [Uso en Scripts](#uso-en-scripts)
- [Integración con Azure App Service](#integración-con-azure-app-service)
- [Rotación de Secretos](#rotación-de-secretos)
- [Troubleshooting](#troubleshooting)

---

## ¿Por qué Key Vault?

### ✅ Ventajas sobre otros métodos

| Método | Desarrollo Local | Producción | Auditoría | Rotación | Costo |
|--------|------------------|------------|-----------|----------|-------|
| **Key Vault** ⭐ | ✅ | ✅ | ✅ | ✅ Automática | ~$0.03/mes |
| Variables de Entorno | ✅ | ⚠️ | ❌ | 🟡 Manual | Gratis |
| Git Config | ✅ | ❌ | ❌ | 🟡 Manual | Gratis |

### 🎯 Casos de Uso Ideales

- ✅ Equipos con múltiples desarrolladores
- ✅ Aplicaciones en producción
- ✅ Cumplimiento de auditoría requerido
- ✅ Rotación frecuente de credenciales
- ✅ Múltiples entornos (dev, staging, prod)

---

## Configuración Rápida

### Paso 1: Crear Key Vault

Ejecuta el script de gestión:

```powershell
.\scripts\manage_secrets.ps1 -Action Create -KeyVaultName "kv-botchat-prod"
```

El script automáticamente:
- ✅ Crea el Key Vault en tu Resource Group
- ✅ Configura permisos para tu usuario
- ✅ Te solicita los valores de los secretos
- ✅ Almacena los secretos de forma segura

**Salida esperada:**
```
🔐 AZURE KEY VAULT - GESTIÓN DE SECRETOS
======================================================================

[1] Cargando configuración...
    ℹ️  Nombre generado: kv-botchat-9234
    ✅ Configuración cargada

[2] Verificando Azure CLI...
    ✅ Azure CLI instalado: v2.55.0

[3] Verificando autenticación...
    ✅ Autenticado como: usuario@dominio.com

[4] Creando Azure Key Vault...
    ℹ️  Creando Key Vault: kv-botchat-9234
    ✅ Key Vault creado: kv-botchat-9234

[5] Configurando permisos...
    ✅ Permisos configurados para el usuario actual

[6] Creando secretos...
    
    Ingresa los valores para los secretos:
    
    Microsoft App ID: 4c0b49fc-cd97-4772-b859-3e1f6cff69cb
    ✅ Secreto 'bot-app-id' creado
    
    Microsoft App Password: ****
    ✅ Secreto 'bot-app-password' creado
    
    Azure OpenAI API Key: ****
    ✅ Secreto 'azure-openai-api-key' creado

    ✅ Key Vault configurado: kv-botchat-9234
    ℹ️  Guarda este nombre para futuras operaciones
```

### Paso 2: Configurar Variable de Entorno

Agrega el nombre del Key Vault a tu archivo `.env`:

```bash
# Key Vault Configuration
AZURE_KEY_VAULT_NAME=kv-botchat-9234
```

### Paso 3: Verificar Configuración

```powershell
.\scripts\manage_secrets.ps1 -Action Get -KeyVaultName "kv-botchat-9234"
```

**¡Listo!** Tus secretos ahora están en Key Vault y los scripts los usarán automáticamente.

---

## Uso en Scripts

### Jerarquía de Prioridad Automática

Todos los scripts del proyecto buscan secretos en este orden:

1. **Azure Key Vault** (si `AZURE_KEY_VAULT_NAME` está configurado)
2. Variables de entorno (`.env`)
3. Git config local (`.git/config`)
4. Valores por defecto

### Ejemplo: Crear Bot Service

```powershell
# El script automáticamente lee de Key Vault
.\scripts\create_bot_service.ps1
```

**Salida esperada:**
```
[1] Cargando configuración...
    ℹ️  Secreto 'bot-app-id' obtenido de Key Vault
    ℹ️  Secreto 'bot-app-password' obtenido de Key Vault
    ✅ Configuración cargada
    ℹ️  App ID: 4c0b49fc-cd97-4772-...
```

### Forzar Uso de Key Vault

Si quieres asegurarte de que **solo** se use Key Vault:

```powershell
# Eliminar fallbacks
Remove-Item Env:\MICROSOFT_APP_ID
Remove-Item Env:\MICROSOFT_APP_PASSWORD
git config --local --unset user.app.id
git config --local --unset user.app.password

# Ejecutar script (solo funcionará con Key Vault)
.\scripts\create_bot_service.ps1
```

---

## Integración con Azure App Service

### Opción 1: Managed Identity (Recomendado)

Permite que tu App Service lea directamente de Key Vault sin credenciales:

```powershell
# 1. Habilitar Managed Identity en el App Service
az webapp identity assign `
    --name "tu-app-service" `
    --resource-group "BotchatSoluEngMxRog755-rg"

# 2. Obtener el Principal ID
$principalId = az webapp identity show `
    --name "tu-app-service" `
    --resource-group "BotchatSoluEngMxRog755-rg" `
    --query principalId -o tsv

Write-Host "Principal ID: $principalId"

# 3. Dar permisos al App Service en Key Vault
az keyvault set-policy `
    --name "kv-botchat-prod" `
    --object-id $principalId `
    --secret-permissions get list

# 4. Configurar App Settings para leer de Key Vault
az webapp config appsettings set `
    --name "tu-app-service" `
    --resource-group "BotchatSoluEngMxRog755-rg" `
    --settings `
    MICROSOFT_APP_ID="@Microsoft.KeyVault(SecretUri=https://kv-botchat-prod.vault.azure.net/secrets/bot-app-id/)" `
    MICROSOFT_APP_PASSWORD="@Microsoft.KeyVault(SecretUri=https://kv-botchat-prod.vault.azure.net/secrets/bot-app-password/)" `
    AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=https://kv-botchat-prod.vault.azure.net/secrets/azure-openai-api-key/)"
```

### Opción 2: Connection String (Alternativa)

Si no puedes usar Managed Identity:

```powershell
# Obtener la clave de acceso del Key Vault
# (menos seguro, no recomendado)
az webapp config appsettings set `
    --name "tu-app-service" `
    --resource-group "BotchatSoluEngMxRog755-rg" `
    --settings `
    AZURE_KEY_VAULT_NAME="kv-botchat-prod"
```

---

## Rotación de Secretos

### Rotar App Password Automáticamente

El script incluye un comando para regenerar credenciales:

```powershell
.\scripts\manage_secrets.ps1 -Action Rotate -KeyVaultName "kv-botchat-prod"
```

**¿Qué hace este comando?**
1. ✅ Regenera la credencial en Azure AD (App Registration)
2. ✅ Actualiza automáticamente el secreto en Key Vault
3. ✅ Muestra la fecha de expiración de la nueva credencial
4. ⚠️ **Importante:** La credencial anterior sigue funcionando (se agrega, no se reemplaza)

**Salida esperada:**
```
[4] Rotando secretos...
    ⚠️  Esta operación regenerará el App Password en Azure AD
    
    ¿Continuar? (S/N): S
    
    ℹ️  Regenerando credencial para App ID: 4c0b49fc-cd97-4772-b859-3e1f6cff69cb
    ✅ Credencial rotada exitosamente
    ℹ️  Expira: 2027-12-05T10:30:00Z
    
    ⚠️  Actualiza la configuración en:
    ℹ️  • Azure App Service (si ya está desplegado)
    ℹ️  • Variables de entorno locales
```

### Actualizar Secreto Manualmente

Si necesitas cambiar solo un secreto específico:

```powershell
.\scripts\manage_secrets.ps1 -Action Set -KeyVaultName "kv-botchat-prod"
```

Te pedirá:
- Nombre del secreto (ejemplo: `azure-openai-api-key`)
- Nuevo valor (input oculto con `-AsSecureString`)

---

## Comandos Adicionales

### Ver Todos los Secretos

```powershell
.\scripts\manage_secrets.ps1 -Action Get -KeyVaultName "kv-botchat-prod"
```

**Opciones:**
- Muestra los secretos (parcialmente ocultos)
- Te permite actualizar tu `.env` local con los valores

### Eliminar un Secreto

```powershell
.\scripts\manage_secrets.ps1 -Action Delete -KeyVaultName "kv-botchat-prod"
```

**⚠️ Cuidado:** Esta operación es **destructiva**. El secreto se moverá a "soft delete" por 90 días.

### Recuperar Secreto Eliminado

Si eliminaste un secreto por error:

```powershell
az keyvault secret recover `
    --vault-name "kv-botchat-prod" `
    --name "bot-app-password"
```

---

## Permisos y Seguridad

### Dar Acceso a Otros Usuarios

#### Por UPN (email):
```powershell
az keyvault set-policy `
    --name "kv-botchat-prod" `
    --upn "developer@dominio.com" `
    --secret-permissions get list
```

#### Por Service Principal:
```powershell
az keyvault set-policy `
    --name "kv-botchat-prod" `
    --object-id "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    --secret-permissions get list set
```

### Niveles de Permisos Recomendados

| Rol | Permisos | Uso |
|-----|----------|-----|
| **Desarrollador** | `get`, `list` | Solo lectura de secretos |
| **DevOps** | `get`, `list`, `set` | Actualizar secretos |
| **Admin** | `all` | Gestión completa |
| **App Service** | `get` | Solo obtener valores |

### Habilitar Auditoría

```powershell
# Crear Log Analytics Workspace (si no existe)
az monitor log-analytics workspace create `
    --resource-group "BotchatSoluEngMxRog755-rg" `
    --workspace-name "logs-botchat"

# Obtener el Workspace ID
$workspaceId = az monitor log-analytics workspace show `
    --resource-group "BotchatSoluEngMxRog755-rg" `
    --workspace-name "logs-botchat" `
    --query id -o tsv

# Habilitar diagnostic settings
az monitor diagnostic-settings create `
    --name "keyvault-logs" `
    --resource "/subscriptions/662141d0-0308-4187-b46b-db1e9466b5ac/resourceGroups/BotchatSoluEngMxRog755-rg/providers/Microsoft.KeyVault/vaults/kv-botchat-prod" `
    --workspace $workspaceId `
    --logs '[{"category":"AuditEvent","enabled":true}]'
```

---

## Troubleshooting

### Error: "Vault not found"

**Causa:** El Key Vault no existe o el nombre es incorrecto.

**Solución:**
```powershell
# Listar todos los Key Vaults en tu subscription
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
```

### Error: "Access denied"

**Causa:** No tienes permisos suficientes.

**Solución:**
```powershell
# Ver políticas de acceso actuales
az keyvault show --name "kv-botchat-prod" --query "properties.accessPolicies"

# Pedir al admin que te dé permisos
az keyvault set-policy `
    --name "kv-botchat-prod" `
    --upn "tu-email@dominio.com" `
    --secret-permissions get list
```

### Error: "Authentication failed"

**Causa:** Sesión de Azure CLI expirada.

**Solución:**
```powershell
az logout
az login
az account set --subscription "662141d0-0308-4187-b46b-db1e9466b5ac"
```

### Script usa credenciales antiguas

**Causa:** Prioridad incorrecta o cache.

**Solución:**
```powershell
# Verificar que AZURE_KEY_VAULT_NAME está configurado
$env:AZURE_KEY_VAULT_NAME

# Si no está, agregarlo a .env
Add-Content -Path ".env" -Value "AZURE_KEY_VAULT_NAME=kv-botchat-prod"

# Reiniciar PowerShell
exit
```

### Error: "Secret already exists"

**Causa:** Intentas crear un secreto que ya existe.

**Solución:**
```powershell
# Usar 'Set' en lugar de 'Create'
.\scripts\manage_secrets.ps1 -Action Set -KeyVaultName "kv-botchat-prod"
```

---

## Costos

### Tier Gratuito

Azure Key Vault incluye:
- ✅ 10,000 operaciones por mes **GRATIS**
- ✅ Almacenamiento ilimitado de secretos

### Operaciones Típicas

Para este proyecto:
- Script de creación de bot: ~2 operaciones
- Desarrollo local (10 ejecuciones/día): ~600 operaciones/mes
- App Service en producción: ~1,000 operaciones/mes

**Total estimado:** ~1,600 operaciones/mes = **$0.00** (dentro del tier gratuito)

### Costos Adicionales

Solo pagas si excedes 10,000 operaciones:
- $0.03 por 10,000 operaciones adicionales

---

## Checklist de Implementación

### Desarrollo Local
- [ ] Key Vault creado con `manage_secrets.ps1 -Action Create`
- [ ] Variable `AZURE_KEY_VAULT_NAME` en `.env`
- [ ] Secretos almacenados: `bot-app-id`, `bot-app-password`, `azure-openai-api-key`
- [ ] Verificado con `manage_secrets.ps1 -Action Get`
- [ ] Scripts funcionan correctamente (`create_bot_service.ps1`)

### Producción
- [ ] Managed Identity habilitada en App Service
- [ ] Permisos configurados en Key Vault
- [ ] App Settings con referencias Key Vault (`@Microsoft.KeyVault(...)`)
- [ ] Variables de entorno eliminadas de App Service
- [ ] Auditoría habilitada (opcional)
- [ ] Plan de rotación de secretos (cada 90 días)

### Seguridad
- [ ] No hay secretos en código fuente
- [ ] `.env` está en `.gitignore`
- [ ] Permisos de acceso revisados
- [ ] Logs de auditoría habilitados
- [ ] Backup de secretos críticos (fuera de Key Vault)

---

## Referencias

- [Azure Key Vault Documentation](https://learn.microsoft.com/azure/key-vault/)
- [Best Practices for Key Vault](https://learn.microsoft.com/azure/key-vault/general/best-practices)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Key Vault Pricing](https://azure.microsoft.com/pricing/details/key-vault/)

---

## Próximos Pasos

1. **Crear tu Key Vault**: `.\scripts\manage_secrets.ps1 -Action Create`
2. **Configurar .env**: Agregar `AZURE_KEY_VAULT_NAME`
3. **Verificar integración**: Ejecutar `create_bot_service.ps1`
4. **Desplegar a producción**: Configurar Managed Identity

**¿Preguntas?** Revisa la sección de [Troubleshooting](#troubleshooting) o consulta la [documentación oficial](https://learn.microsoft.com/azure/key-vault/).

---

**Última actualización:** 2025-12-05  
**Versión:** 1.0