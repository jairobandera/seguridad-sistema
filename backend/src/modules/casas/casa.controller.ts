import { Request, Response } from "express";
import { CasaService } from "./casa.service";

export class CasaController {
  private service = new CasaService();

  crear = async (req: Request, res: Response) => {
    try {
      const data = req.body;
      const casa = await this.service.crearCasa(data);
      res.json(casa);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodas = async (req: Request, res: Response) => {
    const casas = await this.service.obtenerTodas();
    res.json(casas);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const casa = await this.service.obtenerPorId(id);
    res.json(casa);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const casa = await this.service.actualizar(id, req.body);
      res.json(casa);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const casa = await this.service.eliminar(id);
      res.json(casa);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };
}
