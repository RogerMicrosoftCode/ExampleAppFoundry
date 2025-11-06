# ExampleAppFoundry

A modern, well-structured foundational example application built with TypeScript, Express, and Jest. This project demonstrates best practices for building scalable Node.js applications with proper testing, linting, and type safety.

## Features

- **TypeScript**: Full type safety and modern ES features
- **Express**: Fast, minimalist web framework for Node.js
- **RESTful API**: Example API endpoints demonstrating CRUD operations
- **Testing**: Comprehensive test suite using Jest
- **Linting**: ESLint configuration for code quality
- **Modular Architecture**: Clean separation of concerns with controllers, services, and models

## Project Structure

```
ExampleAppFoundry/
├── src/
│   ├── controllers/      # Request handlers
│   ├── services/         # Business logic
│   ├── models/           # Data models
│   ├── utils/            # Utility functions
│   ├── app.ts            # Express app configuration
│   └── index.ts          # Application entry point
├── dist/                 # Compiled JavaScript (generated)
├── coverage/             # Test coverage reports (generated)
├── jest.config.js        # Jest configuration
├── tsconfig.json         # TypeScript configuration
├── .eslintrc.json        # ESLint configuration
└── package.json          # Project dependencies and scripts
```

## Prerequisites

- Node.js (v18 or higher recommended)
- npm (v8 or higher)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/RogerMicrosoftCode/ExampleAppFoundry.git
cd ExampleAppFoundry
```

2. Install dependencies:
```bash
npm install
```

## Usage

### Development Mode

Run the application in development mode with automatic TypeScript compilation:

```bash
npm run dev
```

The server will start on `http://localhost:3000`

### Build for Production

Compile TypeScript to JavaScript:

```bash
npm run build
```

### Start Production Server

```bash
npm start
```

### Running Tests

Run all tests:
```bash
npm test
```

Run tests in watch mode:
```bash
npm run test:watch
```

Generate coverage report:
```bash
npm run test:coverage
```

### Linting

Check for code quality issues:
```bash
npm run lint
```

Auto-fix linting issues:
```bash
npm run lint:fix
```

## API Endpoints

### Health Check

**GET** `/health`

Returns the health status of the application.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-06T12:00:00.000Z",
  "service": "ExampleAppFoundry"
}
```

### User Management

**GET** `/api/users`

Get all users.

**Response:**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2025-11-06T12:00:00.000Z"
  }
]
```

**GET** `/api/users/:id`

Get a specific user by ID.

**Response:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "createdAt": "2025-11-06T12:00:00.000Z"
}
```

**POST** `/api/users`

Create a new user.

**Request Body:**
```json
{
  "name": "Alice Johnson",
  "email": "alice@example.com"
}
```

**Response:**
```json
{
  "id": 3,
  "name": "Alice Johnson",
  "email": "alice@example.com",
  "createdAt": "2025-11-06T12:00:00.000Z"
}
```

## Architecture

### Controllers
Handle HTTP requests and responses. Controllers should be thin and delegate business logic to services.

### Services
Contain business logic and data manipulation. Services are independent of the HTTP layer.

### Models
Define data structures and types using TypeScript interfaces and classes.

### Utils
Provide utility functions used across the application.

## Development Guidelines

1. **Type Safety**: Always use TypeScript types and interfaces
2. **Testing**: Write tests for all new features and bug fixes
3. **Linting**: Ensure code passes linting before committing
4. **Separation of Concerns**: Keep controllers, services, and models separate
5. **Error Handling**: Always handle errors appropriately

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

