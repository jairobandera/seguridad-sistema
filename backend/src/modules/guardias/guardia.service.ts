import { prisma } from "../../core/database/prisma";
import { getIO } from '../../core/socket/socket';

type DbEvento = any;

function tipoSeveridad(tipo: string) {
  if (tipo === "PUERTA_ABIERTA" || tipo === "DISPOSITIVO_OFFLINE") return "CRITICAL";
  return "INFO";
}

function toEventoDTO(e: DbEvento) {
  const disp = e.dispositivo;
  const casa = disp?.casa ?? null;
  const user = casa?.usuario ?? null;

  return {
    id: e.id,
    tipo: e.tipo,
    severidad: e.severidad ?? tipoSeveridad(e.tipo),
    fechaHora: e.fechaHora,
    origen: e.origen ?? null,
    valor: e.valor ?? null,

    dispositivo: disp
      ? {
        deviceId: disp.deviceId,
        nombre: disp.nombre ?? null,
        online: disp.online === true,
      }
      : null,

    casa: casa
      ? {
        id: casa.id,
        codigo: casa.codigo,
        calle: casa.calle ?? null,
        numero: casa.numero ?? null,
        manzana: casa.manzana ?? null,
        barrio: casa.barrio ?? null,
        alarmaArmada: casa.alarmaArmada === true,
      }
      : null,

    cliente: user
      ? {
        id: user.id,
        nombre: user.nombre,
        apellido: user.apellido,
        telefono: user.telefono ?? null,
        email: user.email,
      }
      : null,

    estado: {
      leido: e.estado?.leido === true,
      atendido: e.estado?.atendido === true,
      leidoEn: e.estado?.leidoEn ?? null,
      atendidoEn: e.estado?.atendidoEn ?? null,
    },
  };
}

export class GuardiaService {
  // 📌 Eventos globales (historial) + filtro por casa
  async obtenerEventosGlobales(opts?: { casaId?: number; limit?: number }) {
    const limit = opts?.limit ?? 50;

    const where: any = {};
    if (opts?.casaId) {
      where.dispositivo = { casaId: opts.casaId };
    }

    const rows = await prisma.evento.findMany({
      where,
      take: limit,
      orderBy: { fechaHora: "desc" },
      include: {
        dispositivo: {
          include: {
            casa: { include: { usuario: true } },
          },
        },
        estado: true,
        sensor: true,
      },
    });

    return rows.map(toEventoDTO);
  }

  // ✅ Lista de casas para UI (buscador por cliente + cards)
  async obtenerCasasParaGuardia() {
    const casas = await prisma.casa.findMany({
      where: { activa: true },
      include: {
        usuario: true,
        dispositivos: {
          include: {
            eventos: {
              where: { tipo: { in: ["PUERTA_ABIERTA", "PUERTA_CERRADA"] } }, // ✅ solo puerta
              take: 1,
              orderBy: { fechaHora: "desc" },
            },
          },
        },
      },
      orderBy: { id: "desc" },
    });

    // Para contar "no leídos" sin N+1 (sumamos por casa)
    const casaIds = casas.map((c) => c.id);

    const noLeidos = await prisma.evento.findMany({
      where: {
        // ✅ SOLO eventos de puerta
        tipo: { in: ["PUERTA_ABIERTA", "PUERTA_CERRADA"] },

        dispositivo: { casaId: { in: casaIds } },
        OR: [
          { estado: { is: null } },
          { estado: { is: { leido: false } } },
        ],
      },
      select: { dispositivo: { select: { casaId: true } } },
    });

    const countByCasaId = new Map<number, number>();
    for (const ev of noLeidos) {
      const cId = ev.dispositivo.casaId;
      if (!cId) continue;
      countByCasaId.set(cId, (countByCasaId.get(cId) ?? 0) + 1);
    }

    return casas.map((c) => {
      const cliente = `${c.usuario.nombre} ${c.usuario.apellido}`.trim();

      const dispositivoOnline = c.dispositivos.some((d) => d.online === true);

      // último evento de puerta (más reciente entre dispositivos)
      let ultimoPuerta: any = null;
      for (const d of c.dispositivos) {
        const ev = d.eventos?.[0];
        if (!ev) continue;
        if (!ultimoPuerta || ev.fechaHora > ultimoPuerta.fechaHora) ultimoPuerta = ev;
      }

      const puertaEstado =
        ultimoPuerta?.tipo === "PUERTA_ABIERTA"
          ? "ABIERTA"
          : ultimoPuerta?.tipo === "PUERTA_CERRADA"
            ? "CERRADA"
            : "SIN_DATO";

      const puertaAbierta = puertaEstado == "ABIERTA";

      return {
        id: c.id,
        cliente,
        barrio: c.barrio ?? "",
        calle: c.calle ?? "",
        numero: c.numero ?? "",
        dispositivoOnline,
        alarmaArmada: c.alarmaArmada === true,
        eventosNoLeidos: countByCasaId.get(c.id) ?? 0,

        // ✅ ahora último evento es de puerta
        ultimoEvento: ultimoPuerta ? { tipo: ultimoPuerta.tipo, fechaHora: ultimoPuerta.fechaHora } : null,
        puertaEstado,
        puertaAbierta,
      };

    });
  }

  async marcarLote(
    ids: number[],
    guardiaId: number,
    opts: { leido?: boolean; atendido?: boolean }
  ) {
    const now = new Date();

    const tx = ids.map((eventoId) =>
      prisma.eventoEstado.upsert({
        where: { eventoId },
        update: {
          guardiaId,
          ...(opts.leido
            ? { leido: true, leidoEn: now }
            : {}),
          ...(opts.atendido
            ? { atendido: true, atendidoEn: now }
            : {}),
        },
        create: {
          eventoId,
          guardiaId,
          leido: opts.leido === true,
          atendido: opts.atendido === true,
          leidoEn: opts.leido ? now : null,
          atendidoEn: opts.atendido ? now : null,
        },
      })
    );

    await prisma.$transaction(tx);
    const io = getIO();
    const leido = opts.leido === true || opts.atendido === true;
    const atendido = opts.atendido === true;

    for (const eventoId of ids) {
      io.to("GUARDIAS").emit("evento_estado_actualizado", {
        eventoId,
        leido,
        atendido,
        guardiaId,
      });
    }

  }

  async marcarTodoCasa(casaId: number, guardiaId: number) {
    const now = new Date();

    // 1) traer TODOS los eventos de puerta de esa casa que estén sin estado o no leídos / no atendidos
    const eventos = await prisma.evento.findMany({
      where: {
        tipo: { in: ["PUERTA_ABIERTA", "PUERTA_CERRADA"] },
        dispositivo: { casaId },
        OR: [
          { estado: { is: null } },
          { estado: { is: { leido: false } } },
          { estado: { is: { atendido: false } } },
        ],
      },
      select: { id: true },
    });

    const ids = eventos.map((e) => e.id);
    if (!ids.length) return;

    // 2) crear estados faltantes (para los que tenían estado null)
    await prisma.eventoEstado.createMany({
      data: ids.map((eventoId) => ({ eventoId, guardiaId })),
      skipDuplicates: true,
    });

    // 3) marcar todos como leídos + atendidos
    await prisma.eventoEstado.updateMany({
      where: { eventoId: { in: ids } },
      data: {
        guardiaId,
        leido: true,
        atendido: true,
        leidoEn: now,
        atendidoEn: now,
      },
    });
    const io = getIO();
    for (const eventoId of ids) {
      io.to("GUARDIAS").emit("evento_estado_actualizado", {
        eventoId,
        leido: true,
        atendido: true,
        guardiaId,
      });
    }
  }

  // 📌 Eventos críticos
  async obtenerEventosCriticos(opts?: { limit?: number }) {
    const limit = opts?.limit ?? 50;

    const rows = await prisma.evento.findMany({
      where: {
        tipo: { in: ["PUERTA_ABIERTA", "DISPOSITIVO_OFFLINE"] },
      },
      orderBy: { fechaHora: "desc" },
      take: limit,
      include: {
        dispositivo: { include: { casa: { include: { usuario: true } } } },
        estado: true,
      },
    });

    return rows.map(toEventoDTO);
  }

  async marcarLeido(eventoId: number, guardiaId: number) {
    return this.marcarEventoLeido(eventoId, guardiaId);
  }

  async marcarAtendido(eventoId: number, guardiaId: number) {
    return this.marcarEventoAtendido(eventoId, guardiaId);
  }

  async obtenerPanelGuardia() {
    const [eventosCriticos, eventosNoLeidos, dispositivosOffline, ultimosEventos] =
      await Promise.all([
        prisma.evento.findMany({
          where: {
            tipo: { in: ["PUERTA_ABIERTA", "DISPOSITIVO_OFFLINE"] },
            OR: [{ estado: { is: null } }, { estado: { is: { atendido: false } } }],
          },
          orderBy: { fechaHora: "desc" },
          take: 20,
          include: {
            dispositivo: { include: { casa: { include: { usuario: true } } } },
            estado: true,
          },
        }),

        prisma.evento.findMany({
          where: {
            OR: [{ estado: { is: null } }, { estado: { is: { leido: false } } }],
          },
          orderBy: { fechaHora: "desc" },
          take: 20,
          include: {
            dispositivo: { include: { casa: { include: { usuario: true } } } },
            estado: true,
          },
        }),

        prisma.dispositivo.count({ where: { online: false } }),

        prisma.evento.findMany({
          orderBy: { fechaHora: "desc" },
          take: 20,
          include: {
            dispositivo: { include: { casa: { include: { usuario: true } } } },
            estado: true,
          },
        }),
      ]);

    return {
      eventosCriticos: eventosCriticos.map(toEventoDTO),
      eventosNoLeidos: eventosNoLeidos.map(toEventoDTO),
      dispositivosOffline,
      ultimosEventos: ultimosEventos.map(toEventoDTO),
    };
  }

  async marcarEventoAtendido(eventoId: number, guardiaId: number) {
    const now = new Date();

    const eventoEstado = await prisma.eventoEstado.upsert({
      where: { eventoId },
      update: {
        guardiaId,
        atendido: true,
        atendidoEn: now,

        // ✅ atendido implica leído
        leido: true,
        leidoEn: now,
      },
      create: {
        eventoId,
        guardiaId,
        atendido: true,
        atendidoEn: now,

        // ✅ atendido implica leído
        leido: true,
        leidoEn: now,
      },
    });
    // 🔔 SINCRONIZACIÓN TOTAL
    getIO().to("GUARDIAS").emit("evento_estado_actualizado", {
      eventoId,
      atendido: true,
      leido: true,
      guardiaId,
    });

    return eventoEstado;
  }

  async marcarEventoLeido(eventoId: number, guardiaId: number) {
    const eventoEstado = await prisma.eventoEstado.upsert({
      where: { eventoId },
      update: {
        leido: true,
        leidoEn: new Date(),
        guardiaId,
      },
      create: {
        eventoId,
        leido: true,
        leidoEn: new Date(),
        guardiaId,
      },
    });

    // 🔔 SINCRONIZACIÓN TOTAL
    getIO().to("GUARDIAS").emit("evento_estado_actualizado", {
      eventoId,
      atendido: eventoEstado.atendido,
      leido: true,
      guardiaId,
    });

    return eventoEstado;
  }

}
