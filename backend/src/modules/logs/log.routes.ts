import { Router } from "express";
import { LogController } from "./log.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new LogController();

// Solo admin ve los logs
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

router.get("/nivel/:nivel", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerPorNivel(req, res)
);

router.get("/origen/:origen", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerPorOrigen(req, res)
);

export default router;
