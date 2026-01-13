import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import meRoutes from "./routes/me.routes";

dotenv.config();

const app = express();

// Middlewares base
app.use(express.json());
app.use(cors());

// Rutas públicas (NO requieren token)
import authRoutes from "./routes/auth.routes";
app.use("/auth", authRoutes);
app.use("/api/auth", authRoutes); 
app.use("/api", meRoutes);

// ⚠️ IMPORTANTE: aplicar JWT DESPUÉS de /auth
import { authMiddleware } from "./middleware/auth.middleware";
app.use("/api", authMiddleware);

// Rutas protegidas
import usuarioRoutes from "./modules/usuarios/usuario.routes";
import casaRoutes from "./modules/casas/casa.routes";
import dispositivoRoutes from "./modules/dispositivos/dispositivo.routes";
import sensorRoutes from "./modules/sensores/sensor.routes";
import eventoRoutes from "./modules/eventos/evento.routes";
import notificacionRoutes from "./modules/notificaciones/notificacion.routes";
import contactoRoutes from "./modules/contactos/contacto.routes";
import sesionRoutes from "./modules/sesiones/sesion.routes";
import logRoutes from "./modules/logs/log.routes";
import homeRoutes from "./routes/home.routes";
import guardiaRoutes from "./modules/guardias/guardia.routes";

app.use("/api/usuarios", usuarioRoutes);
app.use("/api/casa", casaRoutes);
app.use("/api/dispositivos", dispositivoRoutes);
app.use("/api/sensores", sensorRoutes);
app.use("/api/eventos", eventoRoutes);
app.use("/api/notificaciones", notificacionRoutes);
app.use("/api/contactos", contactoRoutes);
app.use("/api/sesiones", sesionRoutes);
app.use("/api/logs", logRoutes);
app.use("/home", homeRoutes);
app.use("/api/guardia", guardiaRoutes);

// Ruta mínima para probar
app.get("/status", (req, res) => {
  res.json({ ok: true, message: "Backend funcionando" });
});

export default app;
