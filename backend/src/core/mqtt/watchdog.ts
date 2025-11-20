import { prisma } from "../database/prisma";
import { logSistema } from "../../modules/logs/log.service";

export function iniciarWatchdog() {
  setInterval(async () => {
    const ahora = new Date();
    const timeoutMs = 30000; // 30 segundos
    const limite = new Date(ahora.getTime() - timeoutMs);

    const dispositivos = await prisma.dispositivo.findMany({
      where: {
        OR: [
          { ultimaConexion: { lt: limite } },
          { ultimaConexion: null }, // nunca envió heartbeat
        ],
        online: true,
      },
    });

    for (const disp of dispositivos) {
      await prisma.dispositivo.update({
        where: { id: disp.id },
        data: { online: false },
      });

      logSistema.error(`Dispositivo ${disp.id} OFFLINE`, "watchdog");

      // TODO: crear Evento en BD (lo hacemos después)
    }
  }, 5000); // corre cada 5 segundos
}
