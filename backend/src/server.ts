import dotenv from "dotenv";
dotenv.config();

// 🔥 Inicializa MQTT (infra)
import "./core/mqtt/mqtt";

import http from "http";
import app from "./app";
import { initSocket } from "./core/socket/socket";

// 👈 Convertimos PORT a number
const PORT = Number(process.env.PORT) || 3000;

// 👈 Creamos server HTTP
const server = http.createServer(app);

// 👈 Inicializamos Socket.IO
initSocket(server);

// 👈 Permitimos acceso externo (Android)
server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Servidor iniciado en http://0.0.0.0:${PORT}`);
});
