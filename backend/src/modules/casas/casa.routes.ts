import { Router } from "express";
import { CasaController } from "./casa.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new CasaController();

// Crear casa → solo ADMIN o GUARDIA
router.post("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.crear(req, res)
);

// Ver todas las casas → solo ADMIN
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodas(req, res)
);

// Ver casa por ID → dueños pueden ver SOLO su casa
router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

// Actualizar casa → admin
router.put("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.actualizar(req, res)
);

// Eliminar (deshabilitar)
router.delete("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.eliminar(req, res)
);

// Cambiar estado de alarma
router.post("/:id/seguridad", auth, (req, res) => controller.cambiarSeguridad(req, res));

export default router;
