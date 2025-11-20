import { Request, Response } from "express";
import { SesionService } from "./sesion.service";

export class SesionController {
  private service = new SesionService();

  obtenerPorUsuario = async (req: Request, res: Response) => {
    const usuarioId = Number(req.params.usuarioId);
    const sesiones = await this.service.obtenerPorUsuario(usuarioId);
    res.json(sesiones);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const sesion = await this.service.obtenerPorId(id);
    res.json(sesion);
  };

  desactivar = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const sesion = await this.service.desactivar(id);
    res.json(sesion);
  };
}
