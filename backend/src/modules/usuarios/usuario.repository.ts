import { prisma } from "../../core/database/prisma";
import { CrearUsuarioDTO, ActualizarUsuarioDTO } from "./usuario.dto";

export class UsuarioRepository {
  async crear(data: CrearUsuarioDTO & { passwordHash: string }) {
    return prisma.usuario.create({
      data: {
        nombre: data.nombre,
        apellido: data.apellido,
        email: data.email,
        telefono: data.telefono,
        passwordHash: data.passwordHash,
        rol: data.rol,
      },
    });
  }

  async buscarPorEmail(email: string) {
    return prisma.usuario.findUnique({
      where: { email },
    });
  }

  async obtenerTodos() {
    return prisma.usuario.findMany();
  }

  async actualizar(id: number, data: ActualizarUsuarioDTO) {
    return prisma.usuario.update({
      where: { id },
      data,
    });
  }

  async eliminar(id: number) {
    return prisma.usuario.update({
      where: { id },
      data: { activo: false },
    });
  }

  async obtenerPorId(id: number) {
    return prisma.usuario.findUnique({ where: { id } });
  }
}
