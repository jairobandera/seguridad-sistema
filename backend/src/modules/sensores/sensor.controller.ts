import { Request, Response } from "express";
import { SensorService } from "./sensor.service";

export class SensorController {
  private service = new SensorService();

  crear = async (req: Request, res: Response) => {
    try {
      const sensor = await this.service.crear(req.body);
      res.json(sensor);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodos = async (req: Request, res: Response) => {
    const sensores = await this.service.obtenerTodos();
    res.json(sensores);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const sensor = await this.service.obtenerPorId(id);
    res.json(sensor);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const sensor = await this.service.actualizar(id, req.body);
      res.json(sensor);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const sensor = await this.service.eliminar(id);
      res.json(sensor);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };
}
