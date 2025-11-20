import { Request, Response, NextFunction } from "express";

export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as any).user;

    if (!user) return res.status(401).json({ error: "No autenticado" });

    if (!roles.includes(user.rol))
      return res.status(403).json({ error: "No autorizado" });

    next();
  };
}
