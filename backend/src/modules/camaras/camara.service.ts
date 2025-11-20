import { CamaraRepository } from "./camara.repository";
import { CrearCamaraDTO, ActualizarCamaraDTO } from "./camara.dto";

export class CamaraService {
  private repo = new CamaraRepository();

  async crear(data: CrearCamaraDTO) {
    if (!data.urlRTSP && !data.urlWebRTC)
      throw new Error("Debe especificar al menos una URL de cámara");

    return this.repo.crear(data);
  }

  obtenerTodas() {
    return this.repo.obtenerTodas();
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  obtenerPorCasa(casaId: number) {
    return this.repo.obtenerPorCasa(casaId);
  }

  actualizar(id: number, data: ActualizarCamaraDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }
}
