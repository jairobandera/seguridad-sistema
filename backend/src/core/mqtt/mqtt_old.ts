import mqtt from "mqtt";
import prisma from "../prisma";
import { logger } from "../logger";

const mqttUrl = process.env.MQTT_URL || "mqtt://192.168.1.50:1883";

const client = mqtt.connect(mqttUrl, {
  clientId: "backend-" + Math.random().toString(16).slice(2),
  clean: true,
});

client.on("connect", () => {
  logger.info("🔌 Conectado a MQTT: " + mqttUrl);

  client.subscribe("casa/+/dispositivo/+/heartbeat", (err) => {
    logger.info("sub heartbeat: " + (err || "OK"));
  });

  client.subscribe("casa/+/dispositivo/+/event", (err) => {
    logger.info("sub event: " + (err || "OK"));
  });

  logger.info("📡 Suscrito a tópicos de eventos y heartbeats");
});


// =====================================================
// MANEJO DE MENSAJES MQTT
// =====================================================
client.on("message", async (topic, message) => {
  const payload = message.toString();

  try {
    const match = topic.match(/^casa\/(\d+)\/dispositivo\/(\d+)\/(event|heartbeat)$/);
    if (!match) return;

    const [, casaId, dispositivoId, tipo] = match;

    logger.info(`📥 MQTT: ${topic} → ${payload}`);

    // ===============================
    // HEARTBEAT
    // ===============================
    if (tipo === "heartbeat") {
      await prisma.dispositivo.update({
        where: { id: Number(dispositivoId) },
        data: {
          online: true,
          ultimaConexion: new Date(),
        },
      });

      logger.info(`💓 Heartbeat de dispositivo ${dispositivoId}`);
      return;
    }

    // ===============================
    // EVENTO
    // ===============================
    if (tipo === "event") {
      const data = JSON.parse(payload);

      const tipoEvento = data.tipo ?? "DESCONOCIDO";
      const valor = data.valor ?? null;

      await prisma.evento.create({
        data: {
          tipo: tipoEvento,
          valor: valor,
          origen: "MQTT",
          dispositivoId: Number(dispositivoId),
          sensorId: data.sensorId ?? null,
        },
      });

      logger.info(`🚨 Evento registrado: ${tipoEvento} (${valor})`);
    }

  } catch (err) {
    logger.error("❌ Error procesando MQTT");
    logger.error(String(err)); // <- convertimos err a string
  }
});
