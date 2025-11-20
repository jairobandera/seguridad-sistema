import { LogRepository } from "./log.repository";
import { CrearLogDTO } from "./log.dto";

export class LogService {
  private repo = new LogRepository();

  crear(data: CrearLogDTO) {
    return this.repo.crear(data);
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  obtenerPorNivel(nivel: string) {
    return this.repo.obtenerPorNivel(nivel);
  }

  obtenerPorOrigen(origen: string) {
    return this.repo.obtenerPorOrigen(origen);
  }
}

// 🟢 Logger global para usar en todo el backend
export const logSistema = {
  info: (mensaje: string, origen = "backend") =>
    new LogService().crear({ nivel: "INFO", mensaje, origen }),

  warn: (mensaje: string, origen = "backend") =>
    new LogService().crear({ nivel: "WARN", mensaje, origen }),

  error: (mensaje: string, origen = "backend") =>
    new LogService().crear({ nivel: "ERROR", mensaje, origen }),

  critical: (mensaje: string, origen = "backend") =>
    new LogService().crear({ nivel: "CRITICAL", mensaje, origen }),
};
