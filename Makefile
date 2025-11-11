# Makefile para el proyecto Teams AI Foundry Bot

.PHONY: help install test lint format clean docker-build docker-run deploy

# Variables
PYTHON := python
PIP := pip
PYTEST := pytest
DOCKER := docker
DOCKER_COMPOSE := docker-compose

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Instala las dependencias
	$(PIP) install -r requirements.txt

install-dev: ## Instala dependencias de desarrollo
	$(PIP) install -r requirements.txt
	$(PIP) install pytest pytest-asyncio pytest-mock black flake8 mypy

test: ## Ejecuta los tests
	$(PYTEST) tests/ -v

test-coverage: ## Ejecuta tests con coverage
	$(PYTEST) tests/ -v --cov=app --cov=bot --cov-report=html

lint: ## Ejecuta linting
	flake8 app/ bot/ --max-line-length=100

format: ## Formatea el código con black
	black app/ bot/ tests/

type-check: ## Verifica tipos con mypy
	mypy app/ bot/

clean: ## Limpia archivos temporales
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache
	rm -rf htmlcov
	rm -rf .coverage

docker-build: ## Construye la imagen Docker
	$(DOCKER) build -f Dockerfile.bot -t teams-ai-foundry-bot:latest .

docker-run: ## Ejecuta el bot con Docker Compose
	$(DOCKER_COMPOSE) up -d

docker-stop: ## Detiene los contenedores
	$(DOCKER_COMPOSE) down

docker-logs: ## Muestra los logs
	$(DOCKER_COMPOSE) logs -f

run-local: ## Ejecuta el bot localmente
	$(PYTHON) bot/bot_app.py

setup-azure: ## Configura recursos en Azure
	bash scripts/setup_azure.sh

deploy: ## Despliega en Azure
	bash scripts/deploy.sh

check-env: ## Verifica que .env esté configurado
	@test -f .env || (echo "❌ .env no encontrado. Copia .env.example" && exit 1)
	@echo "✅ .env encontrado"

validate-config: check-env ## Valida la configuración
	@$(PYTHON) -c "from app.config import AzureAIFoundryConfig, BotConfig; AzureAIFoundryConfig.validate(); BotConfig.validate(); print('✅ Configuración válida')"

health-check: ## Verifica el health del bot
	@curl -f http://localhost:3978/health || echo "❌ Bot no responde"

all: install lint test ## Ejecuta install, lint y test
