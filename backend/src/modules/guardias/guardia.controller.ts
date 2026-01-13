import { Request, Response } from "express";
import { GuardiaService } from "./guardia.service";

const service = new GuardiaService();

export class GuardiaController {
  async panel(req: Request, res: Response) {
    try {
      const data = await service.obtenerPanelGuardia();
      res.json(data);
    } catch (e) {
      console.error("ERROR panel guardia:", e);
      res.status(500).json({ ok: false, error: "ERROR_PANEL_GUARDIA" });
    }
  }

  async eventos(req: Request, res: Response) {
    const casaId = req.query.casaId ? Number(req.query.casaId) : undefined;
    const data = await service.obtenerEventosGlobales({ casaId, limit: 80 });
    res.json(data);
  }

  async eventosCriticos(req: Request, res: Response) {
    const data = await service.obtenerEventosCriticos({ limit: 80 });
    res.json(data);
  }

  async marcarLeido(req: Request, res: Response) {
    const eventoId = Number(req.params.id);
    const guardiaId = (req as any).user.id;

    await service.marcarLeido(eventoId, guardiaId);
    res.json({ ok: true });
  }

  async marcarAtendido(req: Request, res: Response) {
    const eventoId = Number(req.params.id);
    const guardiaId = (req as any).user.id;

    await service.marcarAtendido(eventoId, guardiaId);
    res.json({ ok: true });
  }

  // ✅ NUEVO
  async casas(req: Request, res: Response) {
    const data = await service.obtenerCasasParaGuardia();
    res.json(data);
  }

  async marcarLote(req: Request, res: Response) {
    const guardiaId = (req as any).user.id;

    const ids = Array.isArray(req.body?.ids) ? req.body.ids.map((n: any) => Number(n)) : [];
    const leido = req.body?.leido === true;
    const atendido = req.body?.atendido === true;

    if (!ids.length) return res.status(400).json({ ok: false, error: "IDS_REQUIRED" });
    if (!leido && !atendido) return res.status(400).json({ ok: false, error: "NOTHING_TO_UPDATE" });

    await service.marcarLote(ids, guardiaId, { leido, atendido });
    res.json({ ok: true });
  }
  async marcarTodoCasa(req: Request, res: Response) {
    const guardiaId = (req as any).user.id;
    const casaId = Number(req.params.casaId);

    if (!casaId) return res.status(400).json({ ok: false, error: "CASA_ID_REQUIRED" });

    await service.marcarTodoCasa(casaId, guardiaId);
    res.json({ ok: true });
  }

}
