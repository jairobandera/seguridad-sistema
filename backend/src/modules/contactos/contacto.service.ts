import { ContactoRepository } from "./contacto.repository";
import { CrearContactoDTO, ActualizarContactoDTO } from "./contacto.dto";
import prisma from "../../core/prisma";

export class ContactoService {
  private repo = new ContactoRepository();

  async crear(data: CrearContactoDTO, usuarioId: number) {
    // Validación básica
    if (!data.telefono.match(/^\+?\d+$/)) {
      throw new Error("El teléfono debe contener solo números (o formato internacional).");
    }

    return this.repo.crear(data, usuarioId);
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  obtenerPorUsuario(usuarioId: number) {
    return this.repo.obtenerPorUsuario(usuarioId);
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  actualizar(id: number, data: ActualizarContactoDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }

  async guardarContactos(usuarioId: number, contactos: any[]) {
    await prisma.contactoEmergencia.deleteMany({
      where: { usuarioId },
    });

    if (contactos.length > 0) {
      await prisma.contactoEmergencia.createMany({
        data: contactos.map((c) => ({
          nombre: c.nombre,
          telefono: c.telefono,
          relacion: c.relacion || null,
          usuarioId,
        })),
      });
    }

    return prisma.contactoEmergencia.findMany({
      where: { usuarioId },
    });
  }
}
