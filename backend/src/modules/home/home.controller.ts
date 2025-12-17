import { Request, Response } from "express";
import prisma from "../../core/prisma";

export class HomeController {
  static async getHome(req: Request, res: Response) {
    try {
      const usuarioId = req.user?.id;

      // Usuario logueado
      const usuario = await prisma.usuario.findUnique({
        where: { id: usuarioId },
        select: {
          id: true,
          nombre: true,
          apellido: true,
          email: true,
          rol: true,
        },
      });

      if (!usuario) {
        return res.status(404).json({ ok: false, message: "Usuario no encontrado" });
      }

      // Casa única del usuario
      const casa = await prisma.casa.findFirst({
        where: { usuarioId: usuarioId },
      });

      if (!casa) {
        return res.status(404).json({
          ok: false,
          message: "El usuario no tiene una casa asignada",
        });
      }

      // Dispositivos + sensores
      const dispositivos = await prisma.dispositivo.findMany({
        where: { casaId: casa.id },
        include: { sensores: true },
      });

      // Últimos 10 eventos
      const eventos = await prisma.evento.findMany({
        where: { dispositivo: { casaId: casa.id } },
        orderBy: { fechaHora: "desc" },
        take: 10,
      });

      return res.json({
        ok: true,
        usuario,
        casa: {
          id: casa.id,
          codigo: casa.codigo,
          calle: casa.calle,
          numero: casa.numero,
          barrio: casa.barrio,
          alarmaArmada: casa.alarmaArmada,
        },
        dispositivos,
        eventos,
      });

    } catch (err) {
      console.error("❌ Error en GET /home:", err);
      return res.status(500).json({ ok: false, message: "Error interno del servidor" });
    }
  }

  // ================================
  // ARMAR / DESARMAR ALARMA
  // ================================
  static async armar(req: Request, res: Response) {
    try {
      const usuarioId = req.user?.id;

      const casa = await prisma.casa.findFirst({
        where: { usuarioId },
      });

      if (!casa) return res.status(404).json({ ok: false, message: "Casa no encontrada" });

      await prisma.casa.update({
        where: { id: casa.id },
        data: { alarmaArmada: true },
      });

      return res.json({ ok: true, message: "Alarma armada" });
    } catch (err) {
      console.error("❌ Error al armar alarma:", err);
      return res.status(500).json({ ok: false, message: "Error interno del servidor" });
    }
  }

  static async desarmar(req: Request, res: Response) {
    try {
      const usuarioId = req.user?.id;

      const casa = await prisma.casa.findFirst({
        where: { usuarioId },
      });

      if (!casa) return res.status(404).json({ ok: false, message: "Casa no encontrada" });

      await prisma.casa.update({
        where: { id: casa.id },
        data: { alarmaArmada: false },
      });

      return res.json({ ok: true, message: "Alarma desarmada" });
    } catch (err) {
      console.error("❌ Error al desarmar alarma:", err);
      return res.status(500).json({ ok: false, message: "Error interno del servidor" });
    }
  }
}
