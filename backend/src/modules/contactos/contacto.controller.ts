import { Request, Response } from "express";
import { ContactoService } from "./contacto.service";

export class ContactoController {
  private service = new ContactoService();

  crear = async (req: Request, res: Response) => {
    try {
      const contacto = await this.service.crear(req.body);
      res.json(contacto);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodos = async (req: Request, res: Response) => {
    const contactos = await this.service.obtenerTodos();
    res.json(contactos);
  };

  obtenerPorUsuario = async (req: Request, res: Response) => {
    const usuarioId = Number(req.params.usuarioId);
    const contactos = await this.service.obtenerPorUsuario(usuarioId);
    res.json(contactos);
  };

  obtenerPorId = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const contacto = await this.service.obtenerPorId(id);
    res.json(contacto);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const contacto = await this.service.actualizar(id, req.body);
      res.json(contacto);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    const contacto = await this.service.eliminar(id);
    res.json(contacto);
  };
}
