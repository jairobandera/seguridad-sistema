import { JwtPayload } from "../../core/auth/auth.types";

declare module "express-serve-static-core" {
  interface Request {
    user?: {
      id: number;
      email: string;
      rol: string;
    };
  }
}
