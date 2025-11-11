# Guía de Contribución

¡Gracias por tu interés en contribuir al proyecto Teams AI Foundry Bot! 🎉

## Código de Conducta

Este proyecto y todos sus participantes están sujetos al [Código de Conducta](CODE_OF_CONDUCT.md). Al participar, se espera que mantengas este código.

## ¿Cómo puedo contribuir?

### Reportar Bugs

Si encuentras un bug:

1. **Verifica** que no exista ya un issue reportado
2. **Crea un nuevo issue** con:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Comportamiento esperado vs. actual
   - Versión de Python, sistema operativo, etc.
   - Logs relevantes (sin datos sensibles)

### Sugerir Mejoras

Para sugerir nuevas características:

1. **Verifica** que no exista una sugerencia similar
2. **Crea un issue** describiendo:
   - El problema que resolvería
   - La solución propuesta
   - Alternativas consideradas
   - Contexto adicional

### Pull Requests

#### Proceso

1. **Fork** el repositorio
2. **Crea una rama** desde `main`:
   ```bash
   git checkout -b feature/mi-nueva-caracteristica
   ```
3. **Desarrolla** tu cambio siguiendo las guías de estilo
4. **Añade tests** si es aplicable
5. **Ejecuta los tests** localmente:
   ```bash
   make test
   make lint
   ```
6. **Commit** tus cambios:
   ```bash
   git commit -m "feat: añade nueva característica"
   ```
7. **Push** a tu fork:
   ```bash
   git push origin feature/mi-nueva-caracteristica
   ```
8. **Abre un Pull Request** desde GitHub

#### Guías de Estilo

**Python:**
- Sigue [PEP 8](https://pep8.org/)
- Usa [Black](https://black.readthedocs.io/) para formateo
- Máximo 100 caracteres por línea
- Docstrings en formato Google

**Commits:**
- Usa [Conventional Commits](https://www.conventionalcommits.org/)
- Formato: `tipo(scope): descripción`
- Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Ejemplos:
```
feat(chat): añade soporte para imágenes
fix(bot): corrige error en manejo de comandos
docs(readme): actualiza instrucciones de instalación
```

**Documentación:**
- Documenta todas las funciones públicas
- Actualiza README si cambias funcionalidad
- Añade comentarios para lógica compleja

#### Tests

- Escribe tests para nuevas características
- Mantén coverage > 80%
- Tests deben ser independientes
- Usa fixtures de pytest cuando sea apropiado

```python
def test_mi_funcion():
    """Test que verifica mi_funcion funciona correctamente"""
    resultado = mi_funcion(parametro="test")
    assert resultado == "esperado"
```

#### Checklist de PR

Antes de enviar tu PR, verifica:

- [ ] El código sigue las guías de estilo
- [ ] Los tests pasan localmente
- [ ] Añadiste tests para nuevas características
- [ ] Actualizaste la documentación si es necesario
- [ ] El commit message sigue el formato convencional
- [ ] No hay merge conflicts con `main`
- [ ] Removiste código comentado o de debug

## Estructura del Proyecto

```
ExampleAppFoundry/
├── app/              # Lógica de aplicación
├── bot/              # Lógica del bot de Teams
├── tests/            # Tests unitarios
├── scripts/          # Scripts de deployment
└── docs/             # Documentación adicional
```

## Entorno de Desarrollo

### Setup

```bash
# Clonar
git clone https://github.com/tu-usuario/ExampleAppFoundry.git
cd ExampleAppFoundry

# Entorno virtual
python -m venv venv
source venv/bin/activate

# Instalar dependencias
make install-dev

# Configurar .env
cp .env.example .env
# Editar .env con tus credenciales
```

### Comandos Útiles

```bash
make help           # Ver todos los comandos
make test           # Ejecutar tests
make lint           # Ejecutar linting
make format         # Formatear código
make docker-build   # Construir imagen
make validate-config # Validar configuración
```

## Preguntas

Si tienes preguntas:

1. Revisa la [documentación](README_PROJECT.md)
2. Busca en los [issues existentes](https://github.com/tu-usuario/ExampleAppFoundry/issues)
3. Abre un [nuevo issue](https://github.com/tu-usuario/ExampleAppFoundry/issues/new) con la etiqueta `question`

## Agradecimientos

¡Gracias por contribuir! Cada contribución, grande o pequeña, es valiosa. 🙏
