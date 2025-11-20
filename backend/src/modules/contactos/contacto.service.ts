import { ContactoRepository } from "./contacto.repository";
import { CrearContactoDTO, ActualizarContactoDTO } from "./contacto.dto";

export class ContactoService {
  private repo = new ContactoRepository();

  async crear(data: CrearContactoDTO) {
    // Validación básica
    if (!data.telefono.match(/^\+?\d+$/)) {
      throw new Error("El teléfono debe contener solo números (o formato internacional).");
    }

    return this.repo.crear(data);
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
}
