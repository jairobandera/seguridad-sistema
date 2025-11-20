# 🏠 Sistema de Seguridad Residencial

Objetivo General:

Desarrollar un sistema modular de seguridad residencial capaz de detectar eventos críticos, enviar alertas en tiempo real, mandar notificaciones vía sms a dos contactos más y ofrecer aplicaciones multiplataforma, utilizando hardware económico y tecnologías abiertas. también el sistema deberá notificar de alguna manera si el dispositivo se quedo sin internet o se apagó o cualquier fallo debe de poder avisar al dueño del hogar como al guardia del barrio


---

## 🚀 Tecnologías Principales

- **Node.js + Express** → API REST
- **TypeScript**
- **PostgreSQL** → Base de datos
- **Prisma ORM**
- **MQTT (Mosquitto)** → Integración tiempo real con dispositivos ESP32
- **JWT** → Autenticación
- **bcrypt** → Hash de contraseñas
- **dotenv** → Variables de entorno

---

## 📁 Estructura de Carpetas

```
/seguridad-sistema/
│
├── frontend/        → Flutter (Android, iOS, Web, Desktop)
│
├── backend/         → API REST, WebSockets, MQTT bridge
│
├── esp32/           → Código del firmware
│
├── docs/            → Diagramas, casos de uso, documentación
│
├── devops/          → Docker, compose, pipelines, n8n, scripts
│
└── README.md
```

---

# ⚙️ Requisitos Previos

Instalar en cualquier PC:

### 1. **Node.js (v18+)**
https://nodejs.org/

### 2. **PostgreSQL**
https://www.postgresql.org/download/

### 3. **Mosquitto MQTT**
https://mosquitto.org/download/

---

# 🔧 Configuración inicial

## 1️⃣ Clonar el repositorio

```sh
git clone https://github.com/jairobandera/seguridad-sistema.git
cd seguridad-sistema/backend
```

## 2️⃣ Instalar dependencias

```sh
npm install
```

## 3️⃣ Configurar archivo `.env`

```
DATABASE_URL="postgresql://USUARIO:CONTRASEÑA@localhost:5432/seguridad"
JWT_SECRET="ESTE_ES_UN_SECRETO"
MQTT_BROKER="mqtt://localhost:1883"
```

## 4️⃣ Crear base de datos

```sh
psql -U postgres -c "CREATE DATABASE seguridad;"
```

## 5️⃣ Ejecutar migraciones Prisma

```sh
npx prisma migrate dev --name init
```

## 6️⃣ Generar cliente Prisma

```sh
npx prisma generate
```

---

# 🚀 Levantar el servidor

```sh
npm run dev
```

---

# 🔌 Probar MQTT (opcional)

Heartbeat:

```sh
mosquitto_pub -t "casa/12/dispositivo/5/heartbeat" -m "alive"
```

Evento:

```sh
mosquitto_pub -t "casa/12/dispositivo/5/event" -m '{"tipo":"puerta_abierta","valor":"1"}'
```

---

# 🔐 Probar Login

Crear usuario:

```
POST http://localhost:3000/api/usuarios
```

Login:

```
POST http://localhost:3000/api/usuarios/login
```

---

# 📦 Scripts útiles

```sh
npm run dev
npx prisma studio
npx prisma generate
```

---

# 🧹 Ignorados por .gitignore

- `.env`
- `info/`
- `node_modules/`
- `dist/`
- logs

---

# 📱 Próximo paso

Integrar Flutter para login + dashboard.

---

