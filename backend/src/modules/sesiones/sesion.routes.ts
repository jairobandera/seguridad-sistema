import { Router } from "express";
import { SesionController } from "./sesion.controller";
import { auth } from "../../core/middleware/auth";

const router = Router();
const controller = new SesionController();

// Historial de sesiones de un usuario
router.get("/usuario/:usuarioId", auth, (req, res) =>
  controller.obtenerPorUsuario(req, res)
);

// Obtener una sesión por ID
router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

// Desactivar sesión
router.put("/:id/desactivar", auth, (req, res) =>
  controller.desactivar(req, res)
);

export default router;
