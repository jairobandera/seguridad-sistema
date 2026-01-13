import mqtt from "mqtt";
import { prisma } from "../database/prisma";
import { logger } from "../logger";
import { sendTestSms } from "../twilio";
import { resolverDestinatarios } from "../../utils/resolverDestinatarios";
import { notificarFCM } from "../notificaciones/fcm";
import { getIO } from "../socket/socket";
import { buildEventDTO } from "../factories/event.factory";

const mqttUrl = process.env.MQTT_URL || "mqtt://192.168.1.50:1883";

const client = mqtt.connect(mqttUrl, {
  clientId: "backend-" + Math.random().toString(16).slice(2),
  clean: true,
  username: process.env.MQTT_USERNAME || undefined,
  password: process.env.MQTT_PASSWORD || undefined,
});

// =======================================================
// Helpers
// =======================================================

// Asegura que exista un Dispositivo con ese deviceId y lo marca online
async function upsertDispositivoOnline(deviceId: string) {
  const ahora = new Date();

  const existente = await prisma.dispositivo.findUnique({
    where: { deviceId },
  });

  if (existente) {
    return prisma.dispositivo.update({
      where: { deviceId },
      data: {
        online: true,
        ultimaConexion: ahora,
      },
    });
  }

  // Creación mínima, sin casa asociada
  return prisma.dispositivo.create({
    data: {
      deviceId,
      nombre: `Dispositivo ${deviceId}`,
      online: true,
      ultimaConexion: ahora,
    },
  });
}

// Parsea JSON sin tirar el proceso
function safeJsonParse<T = any>(raw: string): T | null {
  try {
    return JSON.parse(raw);
  } catch (e) {
    logger.warn(`MQTT payload no es JSON válido: ${raw}`);
    return null;
  }
}

// Saca el deviceId del topic: home/{deviceId}/...
function deviceIdFromTopic(topic: string): string | null {
  const parts = topic.split("/");
  // home/{deviceId}/...
  if (parts.length >= 2 && parts[0] === "home") {
    return parts[1] || null;
  }
  return null;
}

async function buildDoorOpenedSms(deviceId: string): Promise<string> {
  // Buscamos el dispositivo con su casa y el usuario dueño
  const disp = await prisma.dispositivo.findUnique({
    where: { deviceId },
    include: {
      casa: {
        include: {
          usuario: true,
        },
      },
    },
  });

  // Si no hay dispositivo/casa/usuario, mandamos algo genérico
  if (!disp || !disp.casa || !disp.casa.usuario) {
    return `ALERTA: Se abrió la puerta de un dispositivo no asignado (deviceId=${deviceId})`;
  }

  const casa = disp.casa;
  const usuario = casa.usuario;

  const nombreCompleto = `${usuario.nombre} ${usuario.apellido}`.trim();
  const numeroCasa = casa.numero || casa.codigo || "sin número";

  // 👉 SMS “lindo” sin mostrar deviceId
  return `Cliente: ${nombreCompleto}, la puerta se abrió. Casa=${numeroCasa}`;
}


// =======================================================
// Conexión y suscripciones
// =======================================================
client.on("connect", () => {
  logger.info("🔌 Conectado a MQTT: " + mqttUrl);

  // Registro inicial de dispositivo
  client.subscribe("home/register", (err) => {
    logger.info("sub home/register: " + (err || "OK"));
  });

  // Eventos de puerta
  client.subscribe("home/+/door/open", (err) => {
    logger.info("sub home/+/door/open: " + (err || "OK"));
  });

  client.subscribe("home/+/door/closed", (err) => {
    logger.info("sub home/+/door/closed: " + (err || "OK"));
  });

  // Heartbeat
  client.subscribe("home/+/heartbeat", (err) => {
    logger.info("sub home/+/heartbeat: " + (err || "OK"));
  });

  // ACK de configuración WiFi
  client.subscribe("home/+/wifi/ack", (err) => {
    logger.info("sub home/+/wifi/ack: " + (err || "OK"));
  });
});

// =======================================================
// Manejo de mensajes
// =======================================================
client.on("message", async (topic, payload) => {
  const raw = payload.toString();
  logger.info(`📩 MQTT [${topic}]: ${raw}`);

  try {
    // Caso especial: home/register (no lleva deviceId en el topic)
    if (topic === "home/register") {
      const data = safeJsonParse<{ deviceId?: string }>(raw);
      const deviceId = data?.deviceId;

      if (!deviceId) {
        logger.warn("home/register sin deviceId, ignorando.");
        return;
      }

      const disp = await upsertDispositivoOnline(deviceId);
      logger.info(`✅ Dispositivo registrado/actualizado: ${disp.deviceId} (id=${disp.id})`);
      return;
    }

    // Resto de topics: home/{deviceId}/...
    const deviceIdTopic = deviceIdFromTopic(topic);
    const data = safeJsonParse<any>(raw) || {};
    const deviceId = data.deviceId || deviceIdTopic;

    if (!deviceId) {
      logger.warn(`Mensaje MQTT sin deviceId (topic=${topic})`);
      return;
    }

    // Normalizamos y dejamos el dispositivo en online
    const dispositivo = await upsertDispositivoOnline(deviceId);

    // home/{deviceId}/door/open
    if (topic.startsWith(`home/${deviceId}/door/open`)) {
      const tipo = data.tipo || "PUERTA_ABIERTA";
      const valor = data.valor ?? "1";

      // Siempre guardar evento primero
      const eventoDb = await prisma.evento.create({
        data: {
          tipo,
          valor: String(valor),
          origen: "MQTT",
          dispositivoId: dispositivo.id,
        },
      });

      // 👇 crear estado inicial del evento
      await prisma.eventoEstado.create({
        data: {
          eventoId: eventoDb.id,
        },
      });

      logger.info(`🚪 [${deviceId}] Evento puerta abierta (valor=${valor})`);

      // ► Obtener datos del cliente / casa / alarma
      const info = await resolverDestinatarios(deviceId);

      // ► Construir evento estándar
      const evento = buildEventDTO({
        tipo: "PUERTA_ABIERTA",
        severidad: "CRITICAL",

        dispositivo: {
          deviceId,
          nombre: dispositivo.nombre,
          online: dispositivo.online,
        },

        casa: info
          ? {
            id: info.casaId,
            codigo: info.codigoCasa,
            numero: info.numeroCasa,
            calle: info.calle,
            manzana: info.manzana,
            barrio: info.barrio,
            alarmaArmada: info.alarmaArmada,
          }
          : undefined,

        cliente: info
          ? {
            id: info.usuarioId,
            nombre: info.nombreCliente,
            apellido: info.apellidoCliente,
            telefono: info.telefonoCliente,
          }
          : undefined,
      });

      // ► Emitir a GUARDIAS
      getIO().to("GUARDIAS").emit("evento", evento);


      if (!info) {
        logger.warn("No se encontró casa/usuario para este dispositivo.");
        return;
      }

      // ► Si la alarma no está activada, NO mandar SMS
      if (!info.alarmaArmada) {
        logger.info("🔕 Alarma desactivada → NO se envía SMS.");
        return;
      }

      if (info.fcmToken) {
        await notificarFCM(
          info.fcmToken,
          "🚨 ¡PUERTA ABIERTA!",
          `Casa ${info.numeroCasa} – ${info.nombreCliente}`
        );
      }
      // =======================================================
      // ALERTA: ENVIAR SMS REAL AL DUEÑO
      // =======================================================

      const smsBodyDueno = `Cliente: ${info.nombreCliente} – Casa ${info.numeroCasa} – La puerta se abrió`;

      try {
        await sendTestSms(smsBodyDueno);
        logger.info(`📨 SMS REAL enviado al dueño (${info.telefonoCliente})`);
      } catch (err) {
        logger.error("❌ Error enviando SMS al dueño");
        logger.error(String(err));
      }

      // =======================================================
      // CONTACTOS DE EMERGENCIA → SOLO LOGS (SIN SMS REAL)
      // =======================================================

      if (info.contactos.length > 0) {
        logger.warn("📞 Contactos de emergencia (NO se envía SMS real):");

        info.contactos.forEach((c: { nombre: string; telefono: string }) =>
          logger.warn(` - ${c.nombre} (${c.telefono}): [SIMULADO] → ALERTA PUERTA ABIERTA`)
        );
      } else {
        logger.warn("⚠️ No hay contactos de emergencia configurados.");
      }


      return;
    }


    // home/{deviceId}/door/closed
    if (topic.startsWith(`home/${deviceId}/door/closed`)) {
      const tipo = data.tipo || "PUERTA_CERRADA";
      const valor = data.valor ?? "0";

      // guardar evento
      const eventoDb = await prisma.evento.create({
        data: {
          tipo,
          valor: String(valor),
          origen: "MQTT",
          dispositivoId: dispositivo.id,
        },
      });

      // crear estado inicial (para contadores)
      await prisma.eventoEstado.create({
        data: { eventoId: eventoDb.id },
      });

      logger.info(`🔒 [${deviceId}] Evento puerta cerrada (valor=${valor})`);

      // resolver info para armar DTO “lindo”
      const info = await resolverDestinatarios(deviceId);

      const evento = buildEventDTO({
        tipo: "PUERTA_CERRADA",
        severidad: "INFO",

        dispositivo: {
          deviceId,
          nombre: dispositivo.nombre,
          online: dispositivo.online,
        },

        casa: info
          ? {
            id: info.casaId,
            codigo: info.codigoCasa,
            numero: info.numeroCasa,
            calle: info.calle,
            manzana: info.manzana,
            barrio: info.barrio,
            alarmaArmada: info.alarmaArmada,
          }
          : undefined,

        cliente: info
          ? {
            id: info.usuarioId,
            nombre: info.nombreCliente,
            apellido: info.apellidoCliente,
            telefono: info.telefonoCliente,
          }
          : undefined,
      });

      // emitir realtime a guardias
      getIO().to("GUARDIAS").emit("evento", evento);

      return;
    }

    // home/{deviceId}/heartbeat
    if (topic.startsWith(`home/${deviceId}/heartbeat`)) {
      // upsertDispositivoOnline ya marcó online y ultimaConexion
      logger.info(`💓 Heartbeat de ${deviceId} recibido.`);
      return;
    }

    // home/{deviceId}/wifi/ack
    if (topic.startsWith(`home/${deviceId}/wifi/ack`)) {
      const status = data.status || "UNKNOWN";
      logger.info(`📶 WiFi ACK de ${deviceId}: ${status} - ${raw}`);
      // Por ahora solo log; si querés podés guardar en LogSistema.
      return;
    }

    // Cualquier otro topic bajo home/ que no hayamos manejado
    logger.warn(`MQTT sin handler específico: topic=${topic}`);

  } catch (err) {
    logger.error("❌ Error procesando MQTT");
    logger.error(String(err));
  }
});

// =======================================================
// Monitor de dispositivos OFFLINE (CU04)
// =======================================================

const OFFLINE_THRESHOLD_MS =
  Number(process.env.DEVICE_OFFLINE_MS) || 60_000; // 60s sin heartbeat
const HEALTH_CHECK_INTERVAL_MS =
  Number(process.env.DEVICE_HEALTH_INTERVAL_MS) || 30_000; // corre cada 30s

setInterval(async () => {
  const ahora = new Date();
  const limite = new Date(ahora.getTime() - OFFLINE_THRESHOLD_MS);

  try {
    // 1) Buscar dispositivos que están marcados online,
    //    pero cuya ultimaConexion es "vieja"
    const candidatos = await prisma.dispositivo.findMany({
      where: {
        online: true,
        ultimaConexion: { lt: limite },
      },
    });

    if (candidatos.length === 0) {
      return;
    }

    for (const disp of candidatos) {
      // 2) Marcar como OFFLINE
      await prisma.dispositivo.update({
        where: { id: disp.id },
        data: { online: false },
      });

      // 3) Crear evento DISPOSITIVO_OFFLINE
      const eventoDb = await prisma.evento.create({
        data: {
          tipo: "DISPOSITIVO_OFFLINE",
          valor: "",
          fechaHora: ahora,
          origen: "BACKEND_CRON",
          dispositivoId: disp.id,
        },
      });

      // 👇 crear estado inicial del evento
      await prisma.eventoEstado.create({
        data: {
          eventoId: eventoDb.id,
        },
      });


      // ► Resolver info (si existe)
      const info = await resolverDestinatarios(disp.deviceId);

      // ► Construir evento estándar
      const evento = buildEventDTO({
        tipo: "DISPOSITIVO_OFFLINE",
        severidad: "CRITICAL",

        dispositivo: {
          deviceId: disp.deviceId,
          nombre: disp.nombre,
          online: false,
        },

        casa: info
          ? {
            id: info.casaId,
            codigo: info.codigoCasa,
            numero: info.numeroCasa,
            calle: info.calle,
            manzana: info.manzana,
            barrio: info.barrio,
          }
          : undefined,

        cliente: info
          ? {
            id: info.usuarioId,
            nombre: info.nombreCliente,
            apellido: info.apellidoCliente,
            telefono: info.telefonoCliente,
          }
          : undefined,
      });

      // ► Emitir a GUARDIAS
      getIO().to("GUARDIAS").emit("evento", evento);


      if (info) {

        // ► Si la alarma no está activada, NO mandar SMS
        if (!info.alarmaArmada) {
          logger.info("🔕 Alarma desactivada → NO se envía SMS de dispositivo offline.");
          return;
        }

        const { nombreCliente, telefonoCliente, numeroCasa } = info;
        const smsBody = `Cliente: ${nombreCliente} – Casa ${numeroCasa} – El dispositivo está OFFLINE.`;
        await sendTestSms(smsBody);
        logger.info(`📴 SMS OFFLINE enviado a ${telefonoCliente ?? "sin número"}`);
      } else {
        //await sendTestSms(`ALERTA: dispositivo ${disp.deviceId} está OFFLINE.`);
        logger.warn(`📴 SMS OFFLINE genérico enviado para ${disp.deviceId}`);
      }


      logger.warn(
        `📴 Dispositivo marcado OFFLINE: ${disp.deviceId} (id=${disp.id})`
      );

      await sendTestSms(
        `ALERTA: dispositivo ${disp.deviceId} está OFFLINE. Verificar conexión.`
      );

      logger.warn(
        `📴 SMS enviado para el dispositivo: ${disp.deviceId} (id=${disp.id})`
      );

    }
  } catch (err) {
    logger.error("Error en monitor de dispositivos OFFLINE");
    logger.error(String(err));
  }
}, HEALTH_CHECK_INTERVAL_MS);


export default client;
