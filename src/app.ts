import express, { Application } from 'express';
import { healthController } from './controllers/healthController';
import { userController } from './controllers/userController';

export class App {
  public app: Application;
  private port: number;

  constructor(port: number = 3000) {
    this.app = express();
    this.port = port;
    this.initializeMiddlewares();
    this.initializeRoutes();
  }

  private initializeMiddlewares(): void {
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
  }

  private initializeRoutes(): void {
    this.app.use('/health', healthController);
    this.app.use('/api/users', userController);
  }

  public listen(): void {
    this.app.listen(this.port, () => {
      console.log(`ExampleAppFoundry server listening on port ${this.port}`);
    });
  }

  public getApp(): Application {
    return this.app;
  }
}
