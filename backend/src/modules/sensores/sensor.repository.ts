import { prisma } from "../../core/database/prisma";
import { CrearSensorDTO, ActualizarSensorDTO } from "./sensor.dto";

export class SensorRepository {
  crear(data: CrearSensorDTO) {
    return prisma.sensor.create({ data });
  }

  obtenerTodos() {
    return prisma.sensor.findMany({
      include: { dispositivo: true },
    });
  }

  obtenerPorId(id: number) {
    return prisma.sensor.findUnique({
      where: { id },
      include: { dispositivo: true, eventos: true },
    });
  }

  actualizar(id: number, data: ActualizarSensorDTO) {
    return prisma.sensor.update({
      where: { id },
      data,
    });
  }

  eliminar(id: number) {
    return prisma.sensor.update({
      where: { id },
      data: { activo: false },
    });
  }

  buscarPorPinYDispositivo(pin: string, dispositivoId: number) {
    return prisma.sensor.findFirst({
      where: { pin, dispositivoId },
    });
  }
}
