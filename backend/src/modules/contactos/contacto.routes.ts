import { Router } from "express";
import { ContactoController } from "./contacto.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new ContactoController();

// Crear contacto — solo dueños o admin
router.post("/", auth, (req, res) =>
  controller.crear(req, res)
);

// Obtener todos — solo admin
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

// Obtener por usuario — dueño puede ver los suyos
router.get("/usuario/:usuarioId", auth, (req, res) =>
  controller.obtenerPorUsuario(req, res)
);

// Detalle de un contacto
router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

// Actualizar
router.put("/:id", auth, (req, res) =>
  controller.actualizar(req, res)
);

// Deshabilitar
router.delete("/:id", auth, (req, res) =>
  controller.eliminar(req, res)
);

export default router;
