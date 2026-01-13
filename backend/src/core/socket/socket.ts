import { Server, Socket } from "socket.io";
import jwt from "jsonwebtoken";
import http from "http";

let io: Server;

interface JwtPayload {
  id: number;
  email: string;
  rol: string;
}

export function initSocket(server: http.Server) {
  io = new Server(server, {
    cors: { origin: "*" },
  });

  // 🔐 Middleware de autenticación del socket
  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth?.token;

    if (!token) {
      return next(new Error("Token no enviado"));
    }

    try {
      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET!
      ) as JwtPayload;

      // 👉 SOLO GUARDIAS
      if (decoded.rol !== "GUARDIA") {
        return next(new Error("No autorizado"));
      }

      // Guardamos el user en el socket
      (socket as any).user = decoded;

      next();
    } catch (err) {
      next(new Error("Token inválido"));
    }
  });

  io.on("connection", (socket) => {
    const user = (socket as any).user;
    console.log(`🛡️ Guardia conectado: ${user.email}`);

    // Room global de guardias
    socket.join("GUARDIAS");

    socket.on("disconnect", () => {
      console.log(`❌ Guardia desconectado: ${user.email}`);
    });
  });

  return io;
}

export function getIO(): Server {
  if (!io) throw new Error("Socket.IO no inicializado");
  return io;
}
