import { Router } from "express";
import { DispositivoController } from "./dispositivo.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new DispositivoController();

// Registrar dispositivo
router.post("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.crear(req, res)
);

// Obtener todos
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

// Obtener por ID
router.get("/:id", auth, (req, res) =>
  controller.obtenerPorId(req, res)
);

// Actualizar
router.put("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.actualizar(req, res)
);

// Eliminar (deshabilitar)
router.delete("/:id", auth, requireRole("ADMIN"), (req, res) =>
  controller.eliminar(req, res)
);

// ESP32 MQTT heartbeat
router.post("/online", (req, res) =>
  controller.marcarOnline(req, res)
);

router.post("/offline", (req, res) =>
  controller.marcarOffline(req, res)
);

router.post("/registrar", (req, res) =>
  controller.registrar(req, res)
);


export default router;
