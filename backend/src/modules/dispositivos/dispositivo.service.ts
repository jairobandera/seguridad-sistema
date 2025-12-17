import { DispositivoRepository } from "./dispositivo.repository";
import { CrearDispositivoDTO, ActualizarDispositivoDTO, RegistrarDispositivoDTO } from "./dispositivo.dto";

export class DispositivoService {
  private repo = new DispositivoRepository();

  // Crear tradicional (desde panel admin)
  async crear(data: CrearDispositivoDTO) {
    const existe = await this.repo.obtenerPorDeviceId(data.deviceId);
    if (existe) throw new Error("Este deviceId ya está registrado.");

    return this.repo.crear(data);
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  actualizar(id: number, data: ActualizarDispositivoDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }

  marcarOnline(deviceId: string) {
    return this.repo.actualizarOnline(deviceId, true);
  }

  marcarOffline(deviceId: string) {
    return this.repo.actualizarOnline(deviceId, false);
  }

  // Registrar dispositivo manual (para emparejar MAC con casa)
  async registrarDispositivo(data: RegistrarDispositivoDTO) {

    if (!data.deviceId || data.deviceId.trim().length < 6) {
      throw new Error("El deviceId (MAC) es inválido.");
    }

    if (!data.casaId || isNaN(data.casaId)) {
      throw new Error("El campo casaId es obligatorio.");
    }

    const casa = await this.repo.casaExiste(data.casaId);
    if (!casa) throw new Error(`La casa con ID ${data.casaId} no existe.`);

    const yaExiste = await this.repo.existeDeviceId(data.deviceId);
    if (yaExiste) throw new Error("Este dispositivo ya está registrado.");

    return this.repo.registrar(data);
  }
}
