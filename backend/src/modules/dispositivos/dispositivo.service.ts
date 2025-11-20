import { DispositivoRepository } from "./dispositivo.repository";
import { CrearDispositivoDTO, ActualizarDispositivoDTO } from "./dispositivo.dto";

export class DispositivoService {
  private repo = new DispositivoRepository();

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

  // Este se usa cuando el ESP32 se conecta vía MQTT
  marcarOnline(deviceId: string) {
    return this.repo.actualizarOnline(deviceId, true);
  }

  marcarOffline(deviceId: string) {
    return this.repo.actualizarOnline(deviceId, false);
  }
}
