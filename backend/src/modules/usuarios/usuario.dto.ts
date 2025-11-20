export interface CrearUsuarioDTO {
  nombre: string;
  apellido: string;
  email: string;
  telefono?: string;
  password: string;
  rol: string; // "DUENO", "GUARDIA", "ADMIN"
}

export interface ActualizarUsuarioDTO {
  nombre?: string;
  apellido?: string;
  telefono?: string;
  rol?: string;
  activo?: boolean;
}
