import { Request, Response } from "express";
import { ContactoService } from "./contacto.service";
import prisma from "../../core/prisma";

export class ContactoController {
  private service = new ContactoService();

  crear = async (req: Request, res: Response) => {
    try {
      const user = req.user as { id: number };
      const contacto = await this.service.crear(req.body, user.id);
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

  // Obtener mis contactos
  obtenerMisContactos = async (req: Request, res: Response) => {
    const user = req.user as { id: number };
    const contactos = await prisma.contactoEmergencia.findMany({
      where: { usuarioId: user.id, activo: true },
    });
    res.json(contactos);
  };

  // Guardar máximo dos contactos
  guardarContactos = async (req: Request, res: Response) => {
    try {
      const user = req.user as { id: number };
      const nuevos = req.body.contactos;

      if (!Array.isArray(nuevos) || nuevos.length > 2) {
        return res.status(400).json({ error: "Máximo 2 contactos permitidos" });
      }

      const actualizados = await this.service.guardarContactos(user.id, nuevos);
      res.json(actualizados);

    } catch (err: any) {
      console.error(err);
      res.status(500).json({ error: "Error guardando contactos" });
    }
  };
}
