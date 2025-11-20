import { Router } from "express";
import { NotificacionController } from "./notificacion.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new NotificacionController();

// Crear notificación
router.post("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.crear(req, res)
);

// Obtener todas
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodas(req, res)
);

// Por usuario (dueño puede ver sus notificaciones)
router.get("/usuario/:usuarioId", auth, (req, res) =>
  controller.obtenerPorUsuario(req, res)
);

// Por evento
router.get("/evento/:eventoId", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerPorEvento(req, res)
);

// Marcar como entregado
router.put("/:id/entregado", auth, requireRole("ADMIN"), (req, res) =>
  controller.marcarEntregado(req, res)
);

export default router;
