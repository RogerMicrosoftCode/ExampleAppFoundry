import { UserService } from './userService';

describe('UserService', () => {
  let userService: UserService;

  beforeEach(() => {
    userService = new UserService();
  });

  describe('getAllUsers', () => {
    it('should return all users', () => {
      const users = userService.getAllUsers();
      expect(users).toHaveLength(2);
      expect(users[0].name).toBe('John Doe');
      expect(users[1].name).toBe('Jane Smith');
    });
  });

  describe('getUserById', () => {
    it('should return a user by id', () => {
      const user = userService.getUserById(1);
      expect(user).toBeDefined();
      expect(user?.name).toBe('John Doe');
      expect(user?.email).toBe('john@example.com');
    });

    it('should return undefined for non-existent user', () => {
      const user = userService.getUserById(999);
      expect(user).toBeUndefined();
    });
  });

  describe('createUser', () => {
    it('should create a new user', () => {
      const newUser = userService.createUser('Alice Johnson', 'alice@example.com');
      expect(newUser).toBeDefined();
      expect(newUser.name).toBe('Alice Johnson');
      expect(newUser.email).toBe('alice@example.com');
      expect(newUser.id).toBe(3);
    });

    it('should add the user to the list', () => {
      userService.createUser('Bob Wilson', 'bob@example.com');
      const users = userService.getAllUsers();
      expect(users).toHaveLength(3);
    });
  });

  describe('deleteUser', () => {
    it('should delete an existing user', () => {
      const result = userService.deleteUser(1);
      expect(result).toBe(true);
      expect(userService.getAllUsers()).toHaveLength(1);
    });

    it('should return false for non-existent user', () => {
      const result = userService.deleteUser(999);
      expect(result).toBe(false);
      expect(userService.getAllUsers()).toHaveLength(2);
    });
  });
});
