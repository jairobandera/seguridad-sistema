export type Severidad = "INFO" | "WARN" | "CRITICAL";

export interface EventDTO {
  tipo: string;
  severidad: Severidad;
  fecha: string;

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
}
