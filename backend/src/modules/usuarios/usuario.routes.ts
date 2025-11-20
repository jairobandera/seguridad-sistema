import { Router } from "express";
import { UsuarioController } from "./usuario.controller";
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

export default router;
