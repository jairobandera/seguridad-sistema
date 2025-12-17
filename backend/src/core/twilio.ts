// src/twilio.ts
import twilio from "twilio";
import { logger } from "./logger";

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_FROM_NUMBER;
const testTo = process.env.TWILIO_TEST_TO;

let client: twilio.Twilio | null = null;

if (accountSid && authToken) {
  client = twilio(accountSid, authToken);
} else {
  logger.warn(
    "Twilio no está completamente configurado (faltan TWILIO_ACCOUNT_SID o TWILIO_AUTH_TOKEN). SMS desactivado."
  );
}

export async function sendSms(to: string, body: string) {
  if (!client || !fromNumber) {
    logger.warn("sendSms llamado pero Twilio no está configurado. body=" + body);
    return;
  }

  try {
    const msg = await client.messages.create({
      to,
      from: fromNumber,
      body,
    });

    logger.info(`📨 SMS enviado a ${to} (sid=${msg.sid})`);
  } catch (err) {
    logger.error("❌ Error enviando SMS con Twilio");
    logger.error(String(err));
  }
}

/**
 * Para pruebas: usa TWILIO_TEST_TO como destino.
 */
export async function sendTestSms(body: string) {
  if (!testTo) {
    logger.warn(
      "TWILIO_TEST_TO no seteado, no se envía SMS de prueba. Mensaje sería: " +
        body
    );
    return;
  }
  await sendSms(testTo, body);
}
