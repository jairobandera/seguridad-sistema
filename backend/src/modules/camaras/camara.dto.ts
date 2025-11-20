export interface CrearCamaraDTO {
  nombre: string;
  urlRTSP?: string;
  urlWebRTC?: string;
  tipo?: string;     // "IP", "RTSP", "WEBRTC"
  casaId: number;    // A qué casa pertenece
}

export interface ActualizarCamaraDTO {
  nombre?: string;
  urlRTSP?: string;
  urlWebRTC?: string;
  tipo?: string;
  activa?: boolean;
}
