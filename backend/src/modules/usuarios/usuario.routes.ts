import { Router } from "express";
import { UsuarioController } from "./usuario.controller";
import prisma from "../../core/prisma";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const controller = new UsuarioController();
const router = Router();

// Registro
router.post("/", (req, res) => controller.crear(req, res));

// Login
router.post("/login", (req, res) => controller.login(req, res));

// Obtener todos (solo admin)
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

// Actualizar usuario (admin o dueño de la cuenta)
router.put("/:id", auth, (req, res) => controller.actualizar(req, res));

// Eliminar usuario (admin)
router.delete("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.eliminar(req, res)
);

// ===========================================
// GUARDAR TOKEN FCM DEL USUARIO LOGUEADO
// ===========================================
router.post("/fcm-token", auth, async (req, res) => {
  try {
    const user = req.user as { id: number };

    if (!req.body.token) {
      return res.status(400).json({ error: "Token FCM requerido" });
    }

    await prisma.usuario.update({
      where: { id: user.id },
      data: { fcmToken: req.body.token },
    });

    res.json({ ok: true });
  } catch (e: any) {
    console.error(e);
    res.status(500).json({ error: "Error guardando FCM token" });
  }
});


export default router;
