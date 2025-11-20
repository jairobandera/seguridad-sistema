import { Request, Response } from "express";
import { DispositivoService } from "./dispositivo.service";

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
}
