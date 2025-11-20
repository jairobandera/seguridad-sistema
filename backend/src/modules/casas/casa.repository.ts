import { prisma } from "../../core/database/prisma";
import { CrearCasaDTO, ActualizarCasaDTO } from "./casa.dto";

export class CasaRepository {
  crear(data: CrearCasaDTO) {
    return prisma.casa.create({ data });
  }

  obtenerTodas() {
    return prisma.casa.findMany({ include: { usuario: true } });
  }

  obtenerPorId(id: number) {
    return prisma.casa.findUnique({
      where: { id },
      include: { usuario: true, dispositivos: true, camaras: true },
    });
  }

  actualizar(id: number, data: ActualizarCasaDTO) {
    return prisma.casa.update({
      where: { id },
      data,
    });
  }

  eliminar(id: number) {
    return prisma.casa.update({
      where: { id },
      data: { activa: false },
    });
  }

  buscarPorCodigo(codigo: string) {
    return prisma.casa.findUnique({ where: { codigo } });
  }
}
