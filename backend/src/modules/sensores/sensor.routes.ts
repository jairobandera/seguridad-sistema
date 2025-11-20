import { Router } from "express";
import { SensorController } from "./sensor.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new SensorController();

router.post("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.crear(req, res)
);

router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

router.put("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.actualizar(req, res)
);

router.delete("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.eliminar(req, res)
);

export default router;
