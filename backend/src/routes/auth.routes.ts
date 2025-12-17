import { Router } from "express";
import { prisma } from "../core/database/prisma";
import * as bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const router = Router();

// =========================
// LOGIN
// =========================
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log("📩 Login recibido:", email, password);

    if (!email || !password) {
      return res.status(400).json({ ok: false, error: "Faltan datos" });
    }

    const user = await prisma.usuario.findUnique({ where: { email } });
    console.log("👤 Usuario encontrado:", user);

    if (!user) {
      return res.status(400).json({ ok: false, error: "Usuario no existe" });
    }

    if (!user.activo) {
      return res.status(403).json({ ok: false, error: "Usuario inactivo" });
    }

    console.log("🔐 Comparando password...");
    const valid = await bcrypt.compare(password, user.passwordHash);
    console.log("Resultado bcrypt:", valid);

    if (!valid) {
      return res.status(400).json({ ok: false, error: "Credenciales inválidas" });
    }

    const token = jwt.sign(
      { id: user.id, rol: user.rol },
      process.env.JWT_SECRET!,
      { expiresIn: "7d" }
    );

    return res.json({ ok: true, token });

  } catch (e) {
    console.error("🔥 ERROR LOGIN:", e);
    return res.status(500).json({ ok: false, error: "Error interno" });
  }
});

export default router;
