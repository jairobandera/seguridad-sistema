import { prisma } from "../../core/database/prisma";
import { CrearLogDTO } from "./log.dto";

export class LogRepository {
  crear(data: CrearLogDTO) {
    return prisma.logSistema.create({ data });
  }

  obtenerTodos() {
    return prisma.logSistema.findMany({
      orderBy: { fechaHora: "desc" }
    });
  }

  obtenerPorNivel(nivel: string) {
    return prisma.logSistema.findMany({
      where: { nivel },
      orderBy: { fechaHora: "desc" }
    });
  }

  obtenerPorOrigen(origen: string) {
    return prisma.logSistema.findMany({
      where: { origen },
      orderBy: { fechaHora: "desc" }
    });
  }
}
