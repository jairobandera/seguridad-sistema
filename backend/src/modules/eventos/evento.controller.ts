import { Request, Response } from "express";
import { EventoService } from "./evento.service";

export class EventoController {
  private service = new EventoService();

  crear = async (req: Request, res: Response) => {
    try {
      const evento = await this.service.crearEvento(req.body);
      res.json(evento);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodos = async (req: Request, res: Response) => {
    const eventos = await this.service.obtenerTodos();
    res.json(eventos);
  };

  obtenerPorDispositivo = async (req: Request, res: Response) => {
    const id = Number(req.params.dispositivoId);
    const eventos = await this.service.obtenerPorDispositivo(id);
    res.json(eventos);
  };

  obtenerPorCasa = async (req: Request, res: Response) => {
    const casaId = Number(req.params.casaId);
    const eventos = await this.service.obtenerPorCasa(casaId);
    res.json(eventos);
  };
}
