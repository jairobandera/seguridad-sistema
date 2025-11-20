import { SensorRepository } from "./sensor.repository";
import { CrearSensorDTO, ActualizarSensorDTO } from "./sensor.dto";

export class SensorService {
  private repo = new SensorRepository();

  async crear(data: CrearSensorDTO) {
    // Validación: no puede haber 2 sensores en el mismo pin del mismo dispositivo
    if (data.pin) {
      const existe = await this.repo.buscarPorPinYDispositivo(
        data.pin,
        data.dispositivoId
      );
      if (existe)
        throw new Error("Ya existe un sensor en ese pin del dispositivo.");
    }

    return this.repo.crear(data);
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  actualizar(id: number, data: ActualizarSensorDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }
}
