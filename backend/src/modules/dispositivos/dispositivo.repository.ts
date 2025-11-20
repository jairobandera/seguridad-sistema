import { prisma } from "../../core/database/prisma";
import { CrearDispositivoDTO, ActualizarDispositivoDTO } from "./dispositivo.dto";

export class DispositivoRepository {
  crear(data: CrearDispositivoDTO) {
    return prisma.dispositivo.create({ data });
  }

  obtenerTodos() {
    return prisma.dispositivo.findMany({
      include: {
        casa: true,
        sensores: true,
      },
    });
  }

  obtenerPorId(id: number) {
    return prisma.dispositivo.findUnique({
      where: { id },
      include: {
        casa: true,
        sensores: true,
        eventos: true,
      },
    });
  }

  obtenerPorDeviceId(deviceId: string) {
    return prisma.dispositivo.findUnique({
      where: { deviceId },
    });
  }

  actualizar(id: number, data: ActualizarDispositivoDTO) {
    return prisma.dispositivo.update({
      where: { id },
      data,
    });
  }

  actualizarOnline(deviceId: string, online: boolean) {
    return prisma.dispositivo.update({
      where: { deviceId },
      data: {
        online,
        ultimaConexion: new Date(),
      },
    });
  }

  eliminar(id: number) {
    return prisma.dispositivo.update({
      where: { id },
      data: { online: false },
    });
  }
}
