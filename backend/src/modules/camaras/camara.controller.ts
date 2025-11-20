import { Request, Response } from "express";
import { CamaraService } from "./camara.service";

export class CamaraController {
  private service = new CamaraService();

  crear = async (req: Request, res: Response) => {
    try {
      const camara = await this.service.crear(req.body);
      res.json(camara);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodas = async (req: Request, res: Response) => {
    const camaras = await this.service.obtenerTodas();
    res.json(camaras);
  };

  obtenerPorCasa = async (req: Request, res: Response) => {
    const casaId = Number(req.params.casaId);
    const camaras = await this.service.obtenerPorCasa(casaId);
    res.json(camaras);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const camara = await this.service.obtenerPorId(id);
    res.json(camara);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const camara = await this.service.actualizar(id, req.body);
      res.json(camara);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const camara = await this.service.eliminar(id);
    res.json(camara);
  };
}
