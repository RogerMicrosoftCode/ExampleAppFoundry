import request from 'supertest';
import { App } from '../../app';

describe('User Controller', () => {
  let app: App;

  beforeAll(() => {
    app = new App();
  });

  describe('GET /api/users', () => {
    it('should return all users', async () => {
      const response = await request(app.getApp())
        .get('/api/users')
        .expect(200);

      expect(response.body).toBeInstanceOf(Array);
      expect(response.body.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/users/:id', () => {
    it('should return a user by valid id', async () => {
      const response = await request(app.getApp())
        .get('/api/users/1')
        .expect(200);

      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('email');
    });

    it('should return 400 for invalid id', async () => {
      const response = await request(app.getApp())
        .get('/api/users/invalid')
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Invalid user ID');
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app.getApp())
        .get('/api/users/999')
        .expect(404);

      expect(response.body).toHaveProperty('error', 'User not found');
    });
  });

  describe('POST /api/users', () => {
    it('should create a new user with valid data', async () => {
      const newUser = {
        name: 'Test User',
        email: 'test@example.com'
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(newUser)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('name', newUser.name);
      expect(response.body).toHaveProperty('email', newUser.email);
    });

    it('should return 400 when name is missing', async () => {
      const invalidUser = {
        email: 'test@example.com'
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Name and email are required');
    });

    it('should return 400 when email is missing', async () => {
      const invalidUser = {
        name: 'Test User'
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Name and email are required');
    });

    it('should return 400 for invalid email format', async () => {
      const invalidUser = {
        name: 'Test User',
        email: 'invalid-email'
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Invalid email format');
    });

    it('should return 400 when name is not a string', async () => {
      const invalidUser = {
        name: 123,
        email: 'test@example.com'
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Name and email must be strings');
    });

    it('should return 400 when email is not a string', async () => {
      const invalidUser = {
        name: 'Test User',
        email: 123
      };

      const response = await request(app.getApp())
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      expect(response.body).toHaveProperty('error', 'Name and email must be strings');
    });
  });
});
