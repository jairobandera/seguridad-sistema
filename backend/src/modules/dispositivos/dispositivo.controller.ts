import { Request, Response } from "express";
import { DispositivoService } from "./dispositivo.service";
import { logger } from "../../core/logger";
import { mqttStats } from "../../core/mqtt/mqtt";

export class DispositivoController {
  private service = new DispositivoService();

  crear = async (req: Request, res: Response) => {
    try {
      const dispositivo = await this.service.crear(req.body);
      res.json(dispositivo);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodos = async (req: Request, res: Response) => {
    const dispositivos = await this.service.obtenerTodos();
    res.json(dispositivos);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const dispositivo = await this.service.obtenerPorId(id);
    res.json(dispositivo);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const dispositivo = await this.service.actualizar(id, req.body);
      res.json(dispositivo);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const dispositivo = await this.service.eliminar(id);
    res.json(dispositivo);
  };

  marcarOnline = async (req: Request, res: Response) => {
    const { deviceId } = req.body;
    const result = await this.service.marcarOnline(deviceId);
    res.json(result);
  };

  marcarOffline = async (req: Request, res: Response) => {
    const { deviceId } = req.body;
    const result = await this.service.marcarOffline(deviceId);
    res.json(result);
  };

  factoryReset = async (req: Request, res: Response) => {
    try {
      const param = req.params.id;
      logger.info(`🔄 Factory reset solicitado para: ${param}`);
      
      // intentar como id numérico primero, si no, como deviceId
      let dispositivo: any = null;
      const id = Number(param);
      if (!isNaN(id) && id > 0) {
        dispositivo = await this.service.obtenerPorId(id);
      }
      if (!dispositivo) {
        dispositivo = await this.service.obtenerPorDeviceId(param);
      }
      if (!dispositivo) {
        logger.error(` Dispositivo no encontrado: ${param}`);
        return res.status(404).json({ ok: false, error: 'Dispositivo no encontrado' });
      }

      logger.info(`📡 Enviando factory_reset por MQTT a: ${dispositivo.deviceId}`);
      
      // publicar comando MQTT
      const { publishFactoryReset } = await import('./dispositivo.mqtt');
      await publishFactoryReset(dispositivo.deviceId);

      // 🔥 Limpiar credenciales WiFi en la BD inmediatamente
      logger.info(`🧹 Limpiando credenciales WiFi en BD para: ${dispositivo.deviceId}`);
      await this.service.limpiarCredencialesWifi(dispositivo.deviceId);

      logger.info(`✅ Factory reset completado para: ${dispositivo.deviceId}`);
      return res.json({ ok: true, message: 'Comando enviado' });
    } catch (err: any) {
      logger.error(`❌ Error en factory reset: ${err.message}`);
      return res.status(500).json({ ok: false, error: err.message });
    }
  };

  async registrar(req: Request, res: Response) {
    try {
      const body = req.body;

      logger.info(`📥 Registrar Dispositivo → ${JSON.stringify(body)}`);

      const dispositivo = await this.service.registrarDispositivo(body);

      return res.status(201).json({
        ok: true,
        mensaje: "Dispositivo registrado correctamente",
        data: dispositivo
      });

    } catch (err: any) {
      logger.error(`❌ Error registrando dispositivo: ${err.message}`);
      return res.status(400).json({
        ok: false,
        error: err.message
      });
    }
  }

  mqttStatus = async (_req: Request, res: Response) => {
    res.json({
      ok: true,
      data: mqttStats,
    });
  };

  obtenerEstadoWifi = async (req: Request, res: Response) => {
    try {
      const deviceId = req.params.deviceId;
      const estado = await this.service.obtenerEstadoWifi(deviceId);
      res.json({ ok: true, data: estado });
    } catch (err: any) {
      res.status(404).json({ ok: false, error: err.message });
    }
  };
}
