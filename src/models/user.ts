export interface User {
  id: number;
  name: string;
  email: string;
  createdAt: Date;
}

export class UserModel {
  id: number;
  name: string;
  email: string;
  createdAt: Date;

  constructor(id: number, name: string, email: string) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.createdAt = new Date();
  }

  toJSON(): User {
    return {
      id: this.id,
      name: this.name,
      email: this.email,
      createdAt: this.createdAt
    };
  }
}
