export interface CrearContactoDTO {
  nombre: string;
  telefono: string;
  relacion?: string;
  usuarioId: number;
}

export interface ActualizarContactoDTO {
  nombre?: string;
  telefono?: string;
  relacion?: string;
  activo?: boolean;
}
