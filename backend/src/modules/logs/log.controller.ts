import { Request, Response } from "express";
import { LogService } from "./log.service";

export class LogController {
  private service = new LogService();

  obtenerTodos = async (req: Request, res: Response) => {
    const logs = await this.service.obtenerTodos();
    res.json(logs);
  };

  obtenerPorNivel = async (req: Request, res: Response) => {
    const nivel = req.params.nivel;
    const logs = await this.service.obtenerPorNivel(nivel);
    res.json(logs);
  };

  obtenerPorOrigen = async (req: Request, res: Response) => {
    const origen = req.params.origen;
    const logs = await this.service.obtenerPorOrigen(origen);
    res.json(logs);
  };
}
