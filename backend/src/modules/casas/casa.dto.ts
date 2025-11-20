export interface CrearCasaDTO {
  codigo: string;
  calle?: string;
  numero?: string;
  manzana?: string;
  barrio?: string;
  usuarioId: number;
}

export interface ActualizarCasaDTO {
  calle?: string;
  numero?: string;
  manzana?: string;
  barrio?: string;
  activa?: boolean;
}
