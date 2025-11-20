import { Request, Response } from "express";
import { NotificacionService } from "./notificacion.service";

export class NotificacionController {
  private service = new NotificacionService();

  crear = async (req: Request, res: Response) => {
    try {
      const noti = await this.service.crear(req.body);
      res.json(noti);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodas = async (req: Request, res: Response) => {
    const notificaciones = await this.service.obtenerTodas();
    res.json(notificaciones);
  };

  obtenerPorUsuario = async (req: Request, res: Response) => {
    const id = Number(req.params.usuarioId);
    const notificaciones = await this.service.obtenerPorUsuario(id);
    res.json(notificaciones);
  };

  obtenerPorEvento = async (req: Request, res: Response) => {
    const id = Number(req.params.eventoId);
    const notificaciones = await this.service.obtenerPorEvento(id);
    res.json(notificaciones);
  };

  marcarEntregado = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const notificacion = await this.service.marcarEntregado(id);
    res.json(notificacion);
  };
}
