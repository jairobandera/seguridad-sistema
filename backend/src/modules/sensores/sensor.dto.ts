export interface CrearSensorDTO {
  tipo: string;
  pin?: string;
  descripcion?: string;
  dispositivoId: number;
}

export interface ActualizarSensorDTO {
  tipo?: string;
  pin?: string;
  descripcion?: string;
  activo?: boolean;
}
