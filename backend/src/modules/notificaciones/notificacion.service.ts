import { NotificacionRepository } from "./notificacion.repository";
import { CrearNotificacionDTO } from "./notificacion.dto";
import axios from "axios";

export class NotificacionService {
  private repo = new NotificacionRepository();

  async crear(data: CrearNotificacionDTO) {
    const notificacion = await this.repo.crear({
      ...data,
      entregado: false,
    });

    // Si querés mandar a n8n directamente:
    if (process.env.N8N_WEBHOOK_URL) {
      try {
        await axios.post(process.env.N8N_WEBHOOK_URL, {
          tipo: notificacion.tipo,
          mensaje: notificacion.mensaje,
          canal: notificacion.canal,
          usuario: notificacion.usuario,
          evento: notificacion.evento,
        });

        await this.repo.marcarEntregado(notificacion.id);
      } catch (e) {
        console.log("⚠ Error enviando a n8n:", e);
      }
    }

    return notificacion;
  }

  obtenerTodas() {
    return this.repo.obtenerTodas();
  }

  obtenerPorUsuario(usuarioId: number) {
    return this.repo.obtenerPorUsuario(usuarioId);
  }

  obtenerPorEvento(eventoId: number) {
    return this.repo.obtenerPorEvento(eventoId);
  }

  marcarEntregado(id: number) {
    return this.repo.marcarEntregado(id);
  }
}
