# Configuración de Azure AI ML SDK

## ⚠️ Problema de Compatibilidad Conocido

El paquete `azure-ai-ml` actualmente (Nov 2025) tiene problemas de compatibilidad con `marshmallow` en Python 3.13. Este paquete **NO es necesario** para ejecutar el bot, solo para gestionar recursos de Azure AI Foundry programáticamente.

## ¿Cuándo Necesitas azure-ai-ml?

Necesitas `azure-ai-ml` si quieres:

1. **Crear proyectos de Azure AI Foundry programáticamente**
   ```python
   from azure.ai.ml import MLClient
   from azure.identity import DefaultAzureCredential
   from azure.ai.ml.entities import Project
   
   ml_client = MLClient(
       credential=DefaultAzureCredential(),
       subscription_id="tu-subscription-id",
       resource_group_name="tu-resource-group"
   )
   
   # Crear un proyecto
   project = Project(
       name="mi-proyecto",
       description="Proyecto de AI Foundry"
   )
   ml_client.projects.begin_create(project).result()
   ```

2. **Registrar modelos personalizados**
   ```python
   from azure.ai.ml.entities import Model
   
   model = Model(
       name="mi-modelo",
       path="./model",
       description="Modelo personalizado"
   )
   ml_client.models.create_or_update(model)
   ```

3. **Ejecutar pipelines de ML**
   ```python
   from azure.ai.ml import command, Input
   
   job = command(
       code="./src",
       command="python train.py",
       environment="AzureML-sklearn-1.0-ubuntu20.04-py38-cpu:1",
       compute="cpu-cluster"
   )
   ml_client.jobs.create_or_update(job)
   ```

4. **Gestionar datasets**
   ```python
   from azure.ai.ml.entities import Data
   from azure.ai.ml.constants import AssetTypes
   
   data = Data(
       path="./data",
       type=AssetTypes.URI_FOLDER,
       description="Dataset de entrenamiento"
   )
   ml_client.data.create_or_update(data)
   ```

## ¿Cuándo NO Necesitas azure-ai-ml?

**NO necesitas** `azure-ai-ml` si solo quieres:

- ✅ Ejecutar el bot de Teams
- ✅ Llamar a Azure OpenAI (usa `openai` SDK)
- ✅ Autenticarte con Azure (usa `azure-identity`)
- ✅ Llamar modelos desplegados en AI Foundry (usa `azure-ai-inference`)
- ✅ Gestionar recursos manualmente en Azure Portal
- ✅ Desplegar recursos con Azure CLI

## Alternativas Recomendadas

### 1. Azure CLI (Recomendado para CI/CD)

```bash
# Crear proyecto AI Foundry
az ml workspace create \
  --name mi-proyecto \
  --resource-group mi-rg \
  --location eastus2

# Registrar modelo
az ml model create \
  --name mi-modelo \
  --path ./model \
  --workspace-name mi-proyecto \
  --resource-group mi-rg

# Ejecutar job
az ml job create \
  --file job.yml \
  --workspace-name mi-proyecto \
  --resource-group mi-rg
```

**Instalación Azure CLI:**
```bash
# Windows
winget install Microsoft.AzureCLI

# Linux/macOS
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Extensión de ML
az extension add -n ml
```

### 2. Azure Portal (Gestión Manual)

1. Visita https://ai.azure.com
2. Navega a tu proyecto de AI Foundry
3. Gestiona recursos desde la interfaz web

### 3. REST API Directa

```python
import requests
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
token = credential.get_token("https://management.azure.com/.default")

headers = {
    "Authorization": f"Bearer {token.token}",
    "Content-Type": "application/json"
}

# Ejemplo: Listar proyectos
url = "https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.MachineLearningServices/workspaces?api-version=2023-10-01"
response = requests.get(url, headers=headers)
projects = response.json()
```

### 4. PowerShell (Windows)

```powershell
# Instalar módulo
Install-Module -Name Az.MachineLearningServices

# Crear proyecto
New-AzMLWorkspace `
  -Name "mi-proyecto" `
  -ResourceGroupName "mi-rg" `
  -Location "eastus2"
```

## Instalación de azure-ai-ml (Si es Absolutamente Necesario)

### Opción 1: Entorno Virtual Separado con Python 3.11

```bash
# Crear entorno con Python 3.11 (más compatible)
conda create -n azure-ml python=3.11
conda activate azure-ml

# Instalar con versiones específicas
pip install azure-ai-ml==1.12.0 "marshmallow>=3.5,<3.19"
```

### Opción 2: Usar Contenedor Docker

```dockerfile
FROM python:3.11-slim

RUN pip install azure-ai-ml==1.12.0 "marshmallow>=3.5,<3.19"

WORKDIR /app
COPY manage_ai_resources.py .

CMD ["python", "manage_ai_resources.py"]
```

### Opción 3: Esperar a Corrección del Bug

Monitorea el repositorio oficial:
- https://github.com/Azure/azure-sdk-for-python/issues

## Ejemplo Completo de Gestión sin azure-ai-ml

```python
"""
Gestión de recursos de Azure AI usando Azure CLI desde Python
No requiere azure-ai-ml
"""
import subprocess
import json

def create_ai_project(name: str, resource_group: str, location: str):
    """Crea un proyecto de AI Foundry usando Azure CLI"""
    cmd = [
        "az", "ml", "workspace", "create",
        "--name", name,
        "--resource-group", resource_group,
        "--location", location,
        "--output", "json"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return json.loads(result.stdout)
    else:
        raise Exception(f"Error: {result.stderr}")

def get_project_details(name: str, resource_group: str):
    """Obtiene detalles de un proyecto"""
    cmd = [
        "az", "ml", "workspace", "show",
        "--name", name,
        "--resource-group", resource_group,
        "--output", "json"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return json.loads(result.stdout)
    else:
        raise Exception(f"Error: {result.stderr}")

# Uso
if __name__ == "__main__":
    project = create_ai_project(
        name="mi-proyecto-ai",
        resource_group="mi-rg",
        location="eastus2"
    )
    print(f"Proyecto creado: {project['name']}")
    
    details = get_project_details(
        name="mi-proyecto-ai",
        resource_group="mi-rg"
    )
    print(f"Workspace ID: {details['id']}")
```

## Scripts de Despliegue Alternativos

Este proyecto incluye scripts PowerShell que **NO requieren azure-ai-ml**:

1. **`scripts/configure_env.ps1`**
   - Configura variables de entorno automáticamente
   - Usa Azure CLI en lugar de SDK

2. **`scripts/deploy_full_solution.ps1`**
   - Despliega toda la infraestructura
   - Usa comandos nativos de Azure CLI

3. **`scripts/configure_env_preset.ps1`**
   - Configuración rápida con valores preestablecidos

## Conclusión

Para el **99% de los casos de uso** de este bot, **NO necesitas azure-ai-ml**. Usa las alternativas mencionadas arriba que son más estables y fáciles de mantener.

Solo instala `azure-ai-ml` si:
- Necesitas automatización avanzada de pipelines ML
- Tienes código legacy que depende de él
- Puedes usar Python 3.11 en un entorno aislado
- Estás dispuesto a lidiar con problemas de compatibilidad

---

**Última actualización:** Noviembre 2025  
**Estado del bug:** Abierto - Conflicto con marshmallow 4.x  
**Alternativa recomendada:** Azure CLI + Scripts PowerShell
