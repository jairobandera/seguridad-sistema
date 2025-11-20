import { Router } from "express";
import { EventoController } from "./evento.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";

const router = Router();
const controller = new EventoController();

// Crear evento — usado por ESP32 vía MQTT REST bridge
router.post("/", (req, res) => controller.crear(req, res));

// Obtener todos los eventos — admin
router.get("/", auth, requireRole("ADMIN"), (req, res) =>
  controller.obtenerTodos(req, res)
);

// Eventos por dispositivo
router.get("/dispositivo/:dispositivoId", auth, (req, res) =>
  controller.obtenerPorDispositivo(req, res)
);

// Eventos por casa (para guardias)
router.get("/casa/:casaId", auth, (req, res) =>
  controller.obtenerPorCasa(req, res)
);

export default router;
