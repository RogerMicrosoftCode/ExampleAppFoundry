import { User, UserModel } from '../models/user';

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
