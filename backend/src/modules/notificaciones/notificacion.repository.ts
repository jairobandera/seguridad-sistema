import { prisma } from "../../core/database/prisma";
import { CrearNotificacionDTO } from "./notificacion.dto";

export class NotificacionRepository {
  crear(data: CrearNotificacionDTO) {
    return prisma.notificacion.create({
      data,
      include: { usuario: true, evento: true },
    });
  }

  obtenerTodas() {
    return prisma.notificacion.findMany({
      orderBy: { enviadoEn: "desc" },
      include: { usuario: true, evento: true },
    });
  }

  obtenerPorUsuario(usuarioId: number) {
    return prisma.notificacion.findMany({
      where: { usuarioId },
      include: { evento: true },
      orderBy: { enviadoEn: "desc" },
    });
  }

  obtenerPorEvento(eventoId: number) {
    return prisma.notificacion.findMany({
      where: { eventoId },
      include: { usuario: true },
    });
  }

  marcarEntregado(id: number) {
    return prisma.notificacion.update({
      where: { id },
      data: { entregado: true },
    });
  }
}
