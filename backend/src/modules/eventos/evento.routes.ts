import { Router } from "express";
import { EventoController } from "./evento.controller";
import { auth } from "../../core/middleware/auth";
import { requireRole } from "../../core/middleware/roles";
import { prisma } from "../../core/database/prisma";

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

/**
 * GET /api/eventos/ultimos?limite=10
 * Devuelve los últimos N eventos del usuario logueado
 * (según sus casas y dispositivos).
 */
router.get("/ultimos", auth, async (req, res) => {
  try {
    const userId = (req as any).user?.id as number | undefined;
    if (!userId) {
      return res.status(401).json({ message: "Usuario no autenticado" });
    }

    const rawLimite = (req.query.limite as string) || "10";
    let limite = parseInt(rawLimite, 10);
    if (isNaN(limite) || limite <= 0) limite = 10;
    if (limite > 50) limite = 50;

    const eventos = await prisma.evento.findMany({
      where: {
        dispositivo: {
          casa: {
            usuarioId: userId,
          },
        },
      },
      orderBy: {
        fechaHora: "desc",
      },
      take: limite,
      include: {
        dispositivo: {
          include: {
            casa: true,
          },
        },
      },
    });

    const data = eventos.map((e) => ({
      id: e.id,
      tipo: e.tipo,
      valor: e.valor,
      fechaHora: e.fechaHora,
      origen: e.origen,
      dispositivo: e.dispositivo
        ? {
            id: e.dispositivo.id,
            deviceId: e.dispositivo.deviceId,
            nombre: e.dispositivo.nombre,
          }
        : null,
      casa:
        e.dispositivo && e.dispositivo.casa
          ? {
              id: e.dispositivo.casa.id,
              codigo: e.dispositivo.casa.codigo,
              numero: e.dispositivo.casa.numero,
              barrio: e.dispositivo.casa.barrio,
            }
          : null,
    }));

    return res.json({ eventos: data });
  } catch (err) {
    console.error("Error en /api/eventos/ultimos", err);
    return res
      .status(500)
      .json({ message: "Error obteniendo últimos eventos" });
  }
});

export default router;
