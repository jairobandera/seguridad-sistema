import { prisma } from "../../core/database/prisma";
import { CrearEventoDTO } from "./evento.dto";

export class EventoRepository {
  crear(data: CrearEventoDTO) {
    return prisma.evento.create({
      data,
      include: {
        dispositivo: true,
        sensor: true,
      },
    });
  }

  obtenerTodos() {
    return prisma.evento.findMany({
      orderBy: { fechaHora: "desc" },
      include: {
        dispositivo: true,
        sensor: true,
      },
    });
  }

  obtenerPorDispositivo(dispositivoId: number) {
    return prisma.evento.findMany({
      where: { dispositivoId },
      orderBy: { fechaHora: "desc" },
      include: {
        dispositivo: true,
        sensor: true,
      },
    });
  }

  obtenerPorCasa(casaId: number) {
    return prisma.evento.findMany({
      where: {
        dispositivo: {
          casaId,
        },
      },
      orderBy: { fechaHora: "desc" },
      include: {
        dispositivo: true,
        sensor: true,
      },
    });
  }
}
