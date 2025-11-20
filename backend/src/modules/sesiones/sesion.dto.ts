export interface CrearSesionDTO {
  jwtToken: string;
  ip?: string;
  dispositivo?: string;
  usuarioId: number;
  expiracion?: Date;
}

export interface ActualizarSesionDTO {
  activa?: boolean;
  expiracion?: Date;
}
