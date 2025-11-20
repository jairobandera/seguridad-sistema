import { CasaRepository } from "./casa.repository";
import { CrearCasaDTO, ActualizarCasaDTO } from "./casa.dto";

export class CasaService {
  private repo = new CasaRepository();

  async crearCasa(data: CrearCasaDTO) {
    const existe = await this.repo.buscarPorCodigo(data.codigo);
    if (existe) throw new Error("El código de casa ya existe.");

    return this.repo.crear(data);
  }

  obtenerTodas() {
    return this.repo.obtenerTodas();
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }

  actualizar(id: number, data: ActualizarCasaDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }
}
