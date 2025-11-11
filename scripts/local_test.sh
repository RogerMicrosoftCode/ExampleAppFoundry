#!/bin/bash

# Script para probar el bot localmente
# Usage: ./local_test.sh

set -e

echo "========================================="
echo "Test Local - Teams AI Foundry Bot"
echo "========================================="

# Verificar Python
if ! command -v python &> /dev/null; then
    echo "❌ Python no está instalado"
    exit 1
fi

echo "✅ Python version: $(python --version)"

# Verificar que .env existe
if [ ! -f .env ]; then
    echo "❌ Archivo .env no encontrado"
    echo "Copia .env.example a .env y configura las variables"
    exit 1
fi

echo "✅ Archivo .env encontrado"

# Verificar venv
if [ ! -d "venv" ]; then
    echo "📦 Creando entorno virtual..."
    python -m venv venv
fi

# Activar venv
echo "🔌 Activando entorno virtual..."
source venv/bin/activate

# Instalar dependencias
echo "📥 Instalando dependencias..."
pip install -q -r requirements.txt

echo "✅ Dependencias instaladas"

# Test de importación
echo "🧪 Verificando importaciones..."
python -c "
from app.config import AzureAIFoundryConfig, BotConfig
from app.foundry_client import AzureAIFoundryClient
from app.chat_engine import AIFoundryChatEngine
from bot.teams_bot import TeamsAIFoundryBot
print('✅ Todas las importaciones exitosas')
"

# Test de configuración
echo "🧪 Validando configuración..."
python -c "
from app.config import AzureAIFoundryConfig, BotConfig
try:
    AzureAIFoundryConfig.validate()
    BotConfig.validate()
    print('✅ Configuración válida')
except Exception as e:
    print(f'❌ Error en configuración: {e}')
    exit(1)
"

# Ejecutar bot
echo ""
echo "========================================="
echo "🚀 Iniciando bot localmente..."
echo "========================================="
echo ""
echo "El bot estará disponible en: http://localhost:3978"
echo "Health check: http://localhost:3978/health"
echo ""
echo "Presiona Ctrl+C para detener"
echo ""

python bot/bot_app.py
