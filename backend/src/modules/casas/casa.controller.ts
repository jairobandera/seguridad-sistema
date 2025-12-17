import { Request, Response } from "express";
import { CasaService } from "./casa.service";
import prisma from "../../core/prisma";

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

  async cambiarSeguridad(req: Request, res: Response) {
    try {
      const casaId = Number(req.params.id);
      const user = req.user as { id: number };
      const userId = user.id; // viene del middleware auth

      // 1) Verificar que la casa sea del usuario logueado
      const casa = await prisma.casa.findFirst({
        where: { id: casaId, usuarioId: userId },
      });

      if (!casa) {
        return res.status(404).json({ error: "Casa no encontrada o no pertenece al usuario" });
      }

      // 2) Toggle automático (sin pedir nada en el body)
      const nuevoEstado = !casa.alarmaArmada;

      const actualizada = await prisma.casa.update({
        where: { id: casaId },
        data: { alarmaArmada: nuevoEstado },
      });

      return res.json({
        message: `Seguridad ${nuevoEstado ? "ACTIVADA" : "DESACTIVADA"}`,
        alarmaArmada: actualizada.alarmaArmada,
      });

    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error cambiando estado de seguridad" });
    }
  }

}
