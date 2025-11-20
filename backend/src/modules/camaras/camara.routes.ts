import { Router } from "express";
import { CamaraController } from "./camara.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new CamaraController();

// Registrar cámara (admin)
router.post("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.crear(req, res)
);

// Todas las cámaras del sistema (solo admin)
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodas(req, res)
);

// Todas las cámaras de una casa (dueño puede ver las suyas)
router.get("/casa/:casaId", auth, (req, res) =>
  controller.obtenerPorCasa(req, res)
);

// Obtener cámara por ID
router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

// Actualizar cámara
router.put("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.actualizar(req, res)
);

// Deshabilitar cámara
router.delete("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.eliminar(req, res)
);

export default router;
