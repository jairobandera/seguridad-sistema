import { prisma } from "../../core/database/prisma";
import { CrearDispositivoDTO, ActualizarDispositivoDTO, RegistrarDispositivoDTO } from "./dispositivo.dto";

export class DispositivoRepository {

  // Crear desde ADMIN / panel
  crear(data: CrearDispositivoDTO) {
    return prisma.dispositivo.create({
      data: {
        deviceId: data.deviceId,
        nombre: data.nombre,
        tipo: data.tipo,
        firmwareVersion: data.firmwareVersion,
        casa: {
          connect: { id: data.casaId }
        }
      }
    });
  }

  obtenerTodos() {
    return prisma.dispositivo.findMany({
      include: { casa: true, sensores: true },
    });
  }

  obtenerPorId(id: number) {
    return prisma.dispositivo.findUnique({
      where: { id },
      include: { casa: true, sensores: true, eventos: true },
    });
  }

  obtenerPorDeviceId(deviceId: string) {
    return prisma.dispositivo.findUnique({ where: { deviceId } });
  }

  actualizar(id: number, data: ActualizarDispositivoDTO) {
    return prisma.dispositivo.update({ where: { id }, data });
  }

  actualizarOnline(deviceId: string, online: boolean) {
    return prisma.dispositivo.update({
      where: { deviceId },
      data: { online, ultimaConexion: new Date() },
    });
  }

  eliminar(id: number) {
    return prisma.dispositivo.update({
      where: { id },
      data: { online: false },
    });
  }

  // Nuevo método para registrar un dispositivo (manual)
  registrar(data: RegistrarDispositivoDTO) {
    return prisma.dispositivo.create({
      data: {
        deviceId: data.deviceId,
        nombre: data.nombre ?? `ESP32-${data.deviceId}`,
        tipo: "ESP32",
        firmwareVersion: null,
        casa: {
          connect: { id: data.casaId }
        }
      }
    });
  }

  casaExiste(casaId: number) {
    return prisma.casa.findUnique({ where: { id: casaId } });
  }

  existeDeviceId(deviceId: string) {
    return prisma.dispositivo.findUnique({ where: { deviceId } });
  }
}
