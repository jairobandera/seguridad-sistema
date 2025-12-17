import "./core/mqtt/mqtt";
import dotenv from "dotenv";
dotenv.config();

import app from "./app";

// 👈 Convertimos PORT a number
const PORT = Number(process.env.PORT) || 3000;

// 👈 Permitimos acceso externo (Android puede entrar)
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor iniciado en http://0.0.0.0:${PORT}`);
});
