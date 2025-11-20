import mqtt from "mqtt";
import { prisma } from "../database/prisma";
import { logSistema } from "../../modules/logs/log.service";

const MQTT_URL = process.env.MQTT_URL || "mqtt://localhost:1883";

console.log("🔌 Conectando al broker MQTT:", MQTT_URL);

export const mqttClient = mqtt.connect(MQTT_URL, {
  reconnectPeriod: 3000,
  clientId: "backend-" + Math.random().toString(16).slice(2)
});

mqttClient.on("connect", () => {
  console.log("🟢 Conectado al broker MQTT");
});

mqttClient.subscribe("casa/+/dispositivo/+/event", { qos: 1 });
mqttClient.subscribe("casa/+/dispositivo/+/heartbeat", { qos: 1 });

mqttClient.on("message", async (topic, payload) => {
  const data = payload.toString();
  console.log("📩 MQTT mensaje recibido:", topic, data);

  // Detectar heartbeat
  if (topic.includes("heartbeat")) {
    const parts = topic.split("/");
    const casaId = Number(parts[1]);
    const dispositivoId = Number(parts[3]);

    await prisma.dispositivo.update({
      where: { id: dispositivoId },
      data: {
        ultimaConexion: new Date(),
        online: true,
      },
    });

    logSistema.info(`Heartbeat recibido de dispositivo ${dispositivoId}`, "mqtt");
  }
});

mqttClient.on("error", (err) => {
  console.error("🔴 Error MQTT:", err);
});

mqttClient.on("reconnect", () => {
  console.log("🟡 Reintentando conexión MQTT...");
});
