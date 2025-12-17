// src/core/config.ts
import dotenv from 'dotenv';
dotenv.config();

function required(name: string, value?: string) {
  if (!value) {
    console.error(`❌ ERROR: Falta variable de entorno: ${name}`);
    process.exit(1);
  }
  return value;
}

export const config = {
  PORT: Number(process.env.PORT) || 3000,

  JWT_SECRET: required('JWT_SECRET', process.env.JWT_SECRET),

  MQTT_URL: required('MQTT_URL', process.env.MQTT_URL),
  MQTT_USERNAME: process.env.MQTT_USERNAME || undefined,
  MQTT_PASSWORD: process.env.MQTT_PASSWORD || undefined,

  LOG_LEVEL: process.env.LOG_LEVEL || 'info',
};

console.log(`⚙️ Configuración cargada:
 - PORT: ${config.PORT}
 - MQTT_URL: ${config.MQTT_URL}
 - LOG_LEVEL: ${config.LOG_LEVEL}
`);
