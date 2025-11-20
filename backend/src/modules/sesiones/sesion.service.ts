import { SesionRepository } from "./sesion.repository";
import { CrearSesionDTO, ActualizarSesionDTO } from "./sesion.dto";

export class SesionService {
  private repo = new SesionRepository();

  crearSesion(data: CrearSesionDTO) {
    return this.repo.crear(data);
  }

  obtenerPorUsuario(usuarioId: number) {
    return this.repo.obtenerPorUsuario(usuarioId);
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  actualizar(id: number, data: ActualizarSesionDTO) {
    return this.repo.actualizar(id, data);
  }

  desactivar(id: number) {
    return this.repo.desactivar(id);
  }
}
