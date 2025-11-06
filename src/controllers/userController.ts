import { Router, Request, Response } from 'express';
import { UserService } from '../services/userService';

const router = Router();
// Note: In a production app, consider using dependency injection
const userService = new UserService();

// Simple email validation regex
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

router.get('/', (_req: Request, res: Response) => {
  const users = userService.getAllUsers();
  res.status(200).json(users);
});

router.get('/:id', (req: Request, res: Response) => {
  const id = parseInt(req.params.id, 10);
  
  if (isNaN(id)) {
    res.status(400).json({ error: 'Invalid user ID' });
    return;
  }
  
  const user = userService.getUserById(id);
  
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  
  res.status(200).json(user);
});

router.post('/', (req: Request, res: Response) => {
  const { name, email } = req.body;
  
  // Validate required fields
  if (!name || !email) {
    res.status(400).json({ error: 'Name and email are required' });
    return;
  }
  
  // Validate data types
  if (typeof name !== 'string' || typeof email !== 'string') {
    res.status(400).json({ error: 'Name and email must be strings' });
    return;
  }
  
  // Validate email format
  if (!emailRegex.test(email)) {
    res.status(400).json({ error: 'Invalid email format' });
    return;
  }
  
  const newUser = userService.createUser(name, email);
  res.status(201).json(newUser);
});

export { router as userController };
