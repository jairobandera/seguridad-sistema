export interface CrearDispositivoDTO {
  deviceId: string;
  nombre?: string;
  tipo?: string;
  firmwareVersion?: string;
  casaId: number;
}

export interface ActualizarDispositivoDTO {
  nombre?: string;
  tipo?: string;
  firmwareVersion?: string;
  online?: boolean;
  ultimaConexion?: Date;
}
