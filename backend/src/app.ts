import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();

// Middlewares base
app.use(express.json());
app.use(cors());

// Rutas
import usuarioRoutes from "./modules/usuarios/usuario.routes";
import casaRoutes from "./modules/casas/casa.routes";
import dispositivoRoutes from "./modules/dispositivos/dispositivo.routes";
import sensorRoutes from "./modules/sensores/sensor.routes";
import eventoRoutes from "./modules/eventos/evento.routes";
import notificacionRoutes from "./modules/notificaciones/notificacion.routes";
import contactoRoutes from "./modules/contactos/contacto.routes";
import sesionRoutes from "./modules/sesiones/sesion.routes";
import logRoutes from "./modules/logs/log.routes";

// Prefijos (muy importante para orden)
app.use("/api/usuarios", usuarioRoutes);
app.use("/api/casas", casaRoutes);
app.use("/api/dispositivos", dispositivoRoutes);
app.use("/api/sensores", sensorRoutes);
app.use("/api/eventos", eventoRoutes);
app.use("/api/notificaciones", notificacionRoutes);
app.use("/api/contactos", contactoRoutes);
app.use("/api/sesiones", sesionRoutes);
app.use("/api/logs", logRoutes);

// Ruta mínima para probar
app.get("/status", (req, res) => {
  res.json({ ok: true, message: "Backend funcionando" });
});

export default app;
