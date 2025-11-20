export interface CrearNotificacionDTO {
  tipo: string;        // Ej: "ALERTA_APERTURA", "DISPOSITIVO_OFFLINE"
  mensaje: string;
  canal?: string;      // Ej: "sms", "whatsapp", "email", "push"
  usuarioId: number;
  eventoId: number;
  entregado?: boolean;
}
