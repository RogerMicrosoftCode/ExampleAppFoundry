# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2024-11-10

### Añadido
- Implementación inicial del bot de Teams con Azure AI Foundry
- Integración con Azure OpenAI a través de AI Foundry
- Sistema de gestión de conversaciones con LangChain
- Adaptive Cards personalizadas para Teams
- Content Safety integration para moderación de contenido
- Sistema de comandos (`/help`, `/clear`, `/stats`, `/project`, `/about`)
- Configuración modular con variables de entorno
- Docker y Docker Compose para containerización
- Scripts de deployment automatizados para Azure
- Tests básicos con pytest
- Documentación completa

### Características
- ✅ Chat conversacional con contexto
- ✅ Múltiples sesiones de conversación simultáneas
- ✅ Content Safety habilitado
- ✅ Estadísticas de uso de tokens
- ✅ Health checks y monitoreo
- ✅ Deployment en Azure Container Apps
- ✅ Integración completa con Microsoft Teams

### Seguridad
- Implementación de Content Safety de Azure AI
- Autenticación con Azure AD
- Manejo seguro de secrets con variables de entorno
- Usuario no-root en contenedores Docker

## [Unreleased]

### Por Implementar
- [ ] AI Search integration para RAG
- [ ] Prompt Flow integration
- [ ] Telemetría avanzada con Application Insights
- [ ] Tests end-to-end
- [ ] CI/CD con GitHub Actions
- [ ] Soporte multi-idioma mejorado
- [ ] Panel de administración web
- [ ] Métricas y dashboards en tiempo real
