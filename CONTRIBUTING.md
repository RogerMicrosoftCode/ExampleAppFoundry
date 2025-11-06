# Contributing to ExampleAppFoundry

Thank you for your interest in contributing to ExampleAppFoundry! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/ExampleAppFoundry.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Install dependencies: `npm install`

## Development Workflow

1. Make your changes
2. Write or update tests as needed
3. Run tests: `npm test`
4. Run linter: `npm run lint`
5. Build the project: `npm run build`
6. Ensure all checks pass

## Code Quality Standards

- **TypeScript**: Use proper TypeScript types and interfaces
- **Testing**: Maintain or improve test coverage
- **Linting**: Code must pass ESLint checks
- **Code Style**: Follow the existing code style in the project

## Commit Messages

Write clear, concise commit messages that describe what changes you made and why.

Example:
```
Add user deletion endpoint

- Implement DELETE /api/users/:id route
- Add deleteUser method to UserService
- Include tests for deletion functionality
```

## Pull Request Process

1. Ensure your code passes all tests and linting
2. Update documentation if needed
3. Submit your pull request with a clear description
4. Wait for review and address any feedback

## Testing

- Write unit tests for new features
- Ensure existing tests still pass
- Aim for high test coverage

## Questions?

Feel free to open an issue for any questions or concerns.
