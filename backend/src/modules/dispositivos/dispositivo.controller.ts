import { Request, Response } from "express";
import { DispositivoService } from "./dispositivo.service";
import { logger } from "../../core/logger";

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

}
