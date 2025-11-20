export interface CrearEventoDTO {
  tipo: string;              // Ej: "APERTURA_PUERTA", "DESCONEXION", "HEARTBEAT"
  valor?: string;            // Info extra del sensor
  origen?: string;           // Ej: MQTT, ESP32, BACKEND
  dispositivoId: number;
  sensorId?: number;
}
