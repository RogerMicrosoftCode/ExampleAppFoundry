import { Router, Request, Response } from 'express';
import { UserService } from '../services/userService';

const router = Router();
// Note: In a production app, consider using dependency injection
const userService = new UserService();

/**
 * Validates email format using a simple, ReDoS-safe approach
 * @param email - The email string to validate
 * @returns true if valid, false otherwise
 */
function isValidEmail(email: string): boolean {
  // Basic validation: check for @ symbol and basic structure
  if (typeof email !== 'string' || email.length > 254) {
    return false;
  }
  
  const atIndex = email.indexOf('@');
  if (atIndex === -1 || atIndex === 0 || atIndex === email.length - 1) {
    return false;
  }
  
  const localPart = email.substring(0, atIndex);
  const domainPart = email.substring(atIndex + 1);
  
  // Basic checks: no spaces, domain has a dot, etc.
  if (localPart.includes(' ') || domainPart.includes(' ')) {
    return false;
  }
  
  const dotIndex = domainPart.indexOf('.');
  return dotIndex > 0 && dotIndex < domainPart.length - 1;
}

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
  if (!isValidEmail(email)) {
    res.status(400).json({ error: 'Invalid email format' });
    return;
  }
  
  const newUser = userService.createUser(name, email);
  res.status(201).json(newUser);
});

export { router as userController };
