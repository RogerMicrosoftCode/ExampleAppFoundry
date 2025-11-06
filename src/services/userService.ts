import { User, UserModel } from '../models/user';

/**
 * UserService manages user data operations.
 * 
 * Note: This service uses in-memory storage for demonstration purposes.
 * In a production application, you should use a persistent database.
 * Data will be lost on server restart and won't scale across multiple instances.
 */
export class UserService {
  private users: UserModel[] = [];
  private nextId: number = 1;

  constructor() {
    // Initialize with some example users
    this.users.push(new UserModel(this.nextId++, 'John Doe', 'john@example.com'));
    this.users.push(new UserModel(this.nextId++, 'Jane Smith', 'jane@example.com'));
  }

  getAllUsers(): User[] {
    return this.users.map(user => user.toJSON());
  }

  getUserById(id: number): User | undefined {
    const user = this.users.find(u => u.id === id);
    return user ? user.toJSON() : undefined;
  }

  createUser(name: string, email: string): User {
    const newUser = new UserModel(this.nextId++, name, email);
    this.users.push(newUser);
    return newUser.toJSON();
  }

  deleteUser(id: number): boolean {
    const index = this.users.findIndex(u => u.id === id);
    if (index === -1) {
      return false;
    }
    this.users.splice(index, 1);
    return true;
  }
}
