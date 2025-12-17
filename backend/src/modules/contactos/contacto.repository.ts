import { prisma } from "../../core/database/prisma";
import { CrearContactoDTO, ActualizarContactoDTO } from "./contacto.dto";

export class ContactoRepository {
  crear(data: CrearContactoDTO, usuarioId: number) {
    return prisma.contactoEmergencia.create({
      data: {
        nombre: data.nombre,
        telefono: data.telefono,
        relacion: data.relacion ?? null,
        usuarioId: usuarioId,      // 👈 OBLIGATORIO
      },
    });
  }

  obtenerTodos() {
    return prisma.contactoEmergencia.findMany({
      include: { usuario: true },
      orderBy: { id: "desc" },
    });
  }

  obtenerPorUsuario(usuarioId: number) {
    return prisma.contactoEmergencia.findMany({
      where: { usuarioId, activo: true },
      include: { usuario: true },
      orderBy: { id: "desc" },
    });
  }

  obtenerPorId(id: number) {
    return prisma.contactoEmergencia.findUnique({
      where: { id },
      include: { usuario: true },
    });
  }

  actualizar(id: number, data: ActualizarContactoDTO) {
    return prisma.contactoEmergencia.update({
      where: { id },
      data,
    });
  }

  eliminar(id: number) {
    return prisma.contactoEmergencia.update({
      where: { id },
      data: { activo: false },
    });
  }
}
