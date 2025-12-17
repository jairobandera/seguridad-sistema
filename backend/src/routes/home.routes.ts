import { Router } from "express";
import { HomeController } from "../modules/home/home.controller";
import { authMiddleware } from "../middleware/auth.middleware";

const router = Router();

// Todas requieren login
router.get("/", authMiddleware, HomeController.getHome);

router.post("/armar", authMiddleware, HomeController.armar);
router.post("/desarmar", authMiddleware, HomeController.desarmar);

export default router;
