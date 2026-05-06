import admin from "firebase-admin";
import fs from "fs";

// Cargar credenciales desde el archivo JSON
let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  // Producción (Render)
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  // Desarrollo local
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH!;
  serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, "utf8")
  );
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

export async function notificarFCM(token: string, titulo: string, cuerpo: string) {
  try {
    await admin.messaging().send({
      token,
      notification: {
        title: titulo,
        body: cuerpo,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "alarma_puerta_v2",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    console.log("📨 Notificación enviada a:", token);

  } catch (err) {
    console.error("❌ Error enviando FCM:", err);
  }
}
