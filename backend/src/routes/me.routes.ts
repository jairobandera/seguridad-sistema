// src/routes/me.routes.ts
import { Router } from "express";
import { prisma } from "../core/database/prisma";
import { authMiddleware } from "../middleware/auth.middleware";

const router = Router();

router.get("/me", authMiddleware, async (req: any, res) => {
  try {
    const userId = req.user.id;

    const usuario = await prisma.usuario.findUnique({
      where: { id: userId },
      include: {
        casas: {
          include: {
            dispositivos: true,
          },
        },
      },
    });

    if (!usuario) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }

    res.json(usuario);
  } catch (error) {
    res.status(500).json({ error: "Error interno del servidor" });
  }
});

export default router;
