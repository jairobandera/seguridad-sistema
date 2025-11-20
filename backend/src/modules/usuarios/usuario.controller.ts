import { Request, Response } from "express";
import { UsuarioService } from "./usuario.service";

export class UsuarioController {
  private service = new UsuarioService();

  crear = async (req: Request, res: Response) => {
    try {
      const usuario = await this.service.crearUsuario(req.body);
      res.json(usuario);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  login = async (req: Request, res: Response) => {
    try {
      const { email, password } = req.body;
      const result = await this.service.login(email, password);
      res.json(result);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  obtenerTodos = async (req: Request, res: Response) => {
    const usuarios = await this.service.obtenerTodos();
    res.json(usuarios);
  };

  actualizar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const usuario = await this.service.actualizar(id, req.body);
      res.json(usuario);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };

  eliminar = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const usuario = await this.service.eliminar(id);
      res.json(usuario);
    } catch (err: any) {
      res.status(400).json({ error: err.message });
    }
  };
}
