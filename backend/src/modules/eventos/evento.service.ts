import { EventoRepository } from "./evento.repository";
import { CrearEventoDTO } from "./evento.dto";

export class EventoService {
  private repo = new EventoRepository();

  async crearEvento(data: CrearEventoDTO) {
    // Validaciones básicas
    if (!data.tipo) throw new Error("El tipo de evento es obligatorio");

    // Crear evento
    const evento = await this.repo.crear(data);

    // Aquí podríamos generar notificaciones automáticas o disparar n8n
    // Por ahora lo dejamos simple.

    return evento;
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  obtenerPorDispositivo(dispositivoId: number) {
    return this.repo.obtenerPorDispositivo(dispositivoId);
  }

  obtenerPorCasa(casaId: number) {
    return this.repo.obtenerPorCasa(casaId);
  }
}
