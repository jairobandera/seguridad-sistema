import { prisma } from "../../core/database/prisma";
import { CrearSesionDTO, ActualizarSesionDTO } from "./sesion.dto";

export class SesionRepository {
  crear(data: CrearSesionDTO) {
    return prisma.sesion.create({ data });
  }

  obtenerPorUsuario(usuarioId: number) {
    return prisma.sesion.findMany({
      where: { usuarioId },
      orderBy: { inicio: "desc" },
    });
  }

  obtenerPorId(id: number) {
    return prisma.sesion.findUnique({ where: { id } });
  }

  actualizar(id: number, data: ActualizarSesionDTO) {
    return prisma.sesion.update({
      where: { id },
      data,
    });
  }

  desactivar(id: number) {
    return prisma.sesion.update({
      where: { id },
      data: { activa: false },
    });
  }
}
