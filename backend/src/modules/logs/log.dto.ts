export interface CrearLogDTO {
  nivel: string;       // "INFO" | "WARN" | "ERROR" | "CRITICAL"
  mensaje: string;
  origen?: string;     // backend | esp32 | mqtt | n8n | usuario | etc.
}
