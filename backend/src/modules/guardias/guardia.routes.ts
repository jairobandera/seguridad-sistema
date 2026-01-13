import { Router } from "express";
import { GuardiaController } from "./guardia.controller";
import { authMiddleware } from "../../middleware/auth.middleware";

const router = Router();
const controller = new GuardiaController();

// 🔐 JWT
router.use(authMiddleware);

// 🛡️ SOLO GUARDIA
router.use((req, res, next) => {
  const user = (req as any).user;
  if (!user || user.rol !== "GUARDIA") {
    return res.status(403).json({ ok: false, error: "FORBIDDEN_GUARDIA" });
  }
  next();
});

// 📌
router.get("/panel", controller.panel);
router.get("/eventos", controller.eventos); // soporta ?casaId=123
router.get("/eventos-criticos", controller.eventosCriticos);
router.post("/eventos/:id/leido", controller.marcarLeido);
router.post("/eventos/:id/atendido", controller.marcarAtendido);
router.post("/eventos/marcar-lote", controller.marcarLote);
router.post("/casas/:casaId/marcar-todo", controller.marcarTodoCasa);

// ✅ NUEVO: listado de casas para la UI del guardia
router.get("/casas", controller.casas);

export default router;
