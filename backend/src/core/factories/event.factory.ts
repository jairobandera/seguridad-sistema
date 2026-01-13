import { EventDTO, Severidad } from "../dto/event.dto";

export function buildEventDTO(params: {
  tipo: string;
  severidad: Severidad;
  dispositivo: {
    deviceId: string;
    nombre?: string | null;
    online?: boolean;
  };
  casa?: {
    id: number;
    codigo?: string | null;
    numero?: string | null;
    calle?: string | null;
    manzana?: string | null;
    barrio?: string | null;
    alarmaArmada?: boolean;
  };
  cliente?: {
    id: number;
    nombre?: string;
    apellido?: string;
    telefono?: string | null;
  };
}): EventDTO {
  return {
    tipo: params.tipo,
    severidad: params.severidad,
    fecha: new Date().toISOString(),
    dispositivo: params.dispositivo,
    casa: params.casa,
    cliente: params.cliente,
  };
}
