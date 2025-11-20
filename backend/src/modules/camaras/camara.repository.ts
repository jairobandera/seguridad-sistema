import { prisma } from "../../core/database/prisma";
import { CrearCamaraDTO, ActualizarCamaraDTO } from "./camara.dto";

export class CamaraRepository {
  crear(data: CrearCamaraDTO) {
    return prisma.camara.create({ data });
  }

  obtenerTodas() {
    return prisma.camara.findMany({
      include: { casa: true },
      orderBy: { id: "desc" }
    });
  }

  obtenerPorId(id: number) {
    return prisma.camara.findUnique({
      where: { id },
      include: { casa: true }
    });
  }

  obtenerPorCasa(casaId: number) {
    return prisma.camara.findMany({
      where: { casaId },
      include: { casa: true }
    });
  }

  actualizar(id: number, data: ActualizarCamaraDTO) {
    return prisma.camara.update({
      where: { id },
      data
    });
  }

  eliminar(id: number) {
    return prisma.camara.update({
      where: { id },
      data: { activa: false }
    });
  }
}
