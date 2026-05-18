# 🏠 Sistema de Seguridad Residencial

Sistema modular de seguridad residencial capaz de detectar eventos críticos, enviar alertas en tiempo real, notificaciones SMS a contactos de emergencia y aplicaciones multiplataforma, utilizando hardware económico y tecnologías abiertas.

## 🚀 Tecnologías Principales

### Backend
- **Node.js** → API REST
- **Express 5** → Framework web
- **TypeScript** → Tipado estático
- **PostgreSQL** → Base de datos relacional
- **Prisma ORM** → ORM moderno
- **MQTT (Mosquitto)** → Comunicación tiempo real con ESP32
- **Socket.IO** → WebSockets para frontend
- **JWT** → Autenticación
- **bcrypt** → Hash de contraseñas
- **Twilio** → Envío de SMS
- **Firebase Admin** → Notificaciones push (FCM)

### Frontend
- **Flutter** → App multiplataforma (Android, iOS, Web, Desktop)
- **Dart** → Lenguaje de programación

### Firmware
- **ESP32** → Microcontrolador con WiFi + BLE
- **Arduino Framework** → Desarrollo de firmware
- **NimBLE** → Biblioteca BLE de baja energía
- **PubSubClient** → Cliente MQTT

---

## 📁 Estructura de Carpetas

```
/seguridad-sistema/
├── esp32/              → Firmware ESP32 (Arduino)
│   └── seguridad_esp32.ino
│
├── backend/            → API REST, WebSockets, MQTT bridge
│   ├── src/
│   ├── prisma/
│   └── package.json
│
├── frontend/           → Flutter (Android, iOS, Web, Desktop)
│   └── seguridad_app/
│       └── lib/
│
├── AGENTS.md           → Instrucciones para agentes de IA
└── README.md
```

---

## ⚙️ Requisitos Previos

### 1. **Node.js (v25.4.0)**
**Descarga:** https://nodejs.org/es/download/current  
**Versión recomendada:** v25.4.0 o superior

```sh
# Verificar instalación
node --version
npm --version
```

### 2. **PostgreSQL**
**Descarga:** https://www.postgresql.org/download/  
**Versión recomendada:** 15+  

```sh
# Crear base de datos
psql -U postgres -c "CREATE DATABASE seguridad;"
```

### 3. **Mosquitto MQTT Broker**
**Descarga:** https://mosquitto.org/download/  
**Versión recomendada:** 2.0+

**Windows:** Instalador directo desde la web  
**Linux:** `sudo apt install mosquitto mosquitto-clients`  
**Docker:** `docker run -d -p 1883:1883 eclipse-mosquitto`

### 4. **Flutter SDK (3.41.7)**
**Descarga:** https://docs.flutter.dev/get-started/install  
**Versión recomendada:** 3.41.7 (canal stable)

```sh
# Verificar instalación
flutter --version
flutter doctor
```

### 5. **Android Studio** (para desarrollo Flutter/Android)
**Descarga:** https://developer.android.com/studio  
**Versión recomendada:**latest stable

**Componentes necesarios:**
- Android SDK
- Android SDK Platform-tools
- Android SDK Build-tools
- Android Emulator (opcional)

### 6. **Arduino IDE** (para firmware ESP32)
**Descarga:** https://www.arduino.cc/en/software  
**Versión recomendada:** 2.3.2+

**Configuración ESP32:**
1. Abrir Arduino IDE
2. Ir a `Archivo → Preferencias`
3. En "URLs adicionales de placas", agregar:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Ir a `Herramientas → Placa → Gestor de placas`
5. Buscar "esp32" e instalar "esp32 by Espressif Systems"
6. Seleccionar placa: `ESP32 Dev Module`

### 7. **Librerías Arduino necesarias**
Instalar desde `Herramientas → Gestionar librerías`:
- `PubSubClient` by Nick O'Leary (MQTT)
- `NimBLE-Arduino` by h2zero (BLE)

---

## 🔧 Configuración del Backend

### 1️⃣ Clonar el repositorio

```sh
git clone https://github.com/jairobandera/seguridad-sistema.git
cd seguridad-sistema/backend
```

### 2️ Instalar dependencias

```sh
# Con pnpm (recomendado - más rápido y seguro)
pnpm install

# O con npm (alternativa)
npm install
```

### 3️⃣ Configurar archivo `.env`

Crear archivo `.env` en `/backend` con:

```env
DATABASE_URL="postgresql://postgres:tu_password@localhost:5432/seguridad"
JWT_SECRET="tu_secreto_muy_seguro_cambialo"
MQTT_URL="mqtt://localhost:1883"
PORT=3000
LOG_LEVEL=info

# Twilio (SMS)
TWILIO_ACCOUNT_SID="tu_account_sid"
TWILIO_AUTH_TOKEN="tu_auth_token"
TWILIO_PHONE_NUMBER="+1234567890"

# Firebase (notificaciones push)
FIREBASE_PROJECT_ID="tu_project_id"
```

### 4️ Configurar Firebase Admin SDK (notificaciones push)

**Paso 1: Crear proyecto en Firebase Console**

1. Ir a https://console.firebase.google.com/
2. Click en "Agregar proyecto" o seleccionar uno existente
3. Anotar el `Project ID` para el `.env`

**Paso 2: Generar clave de servicio (service account)**

1. En Firebase Console, ir a `Configuración del proyecto` (engranaje)
2. Pestaña `Cuentas de servicio`
3. Click en `Generar nueva clave privada`
4. Se descargará un archivo JSON (ej: `service-account.json`)

**Paso 3: Colocar el archivo en el backend**

```sh
# Crear directorio firebase en backend
mkdir backend/firebase

# Mover el archivo descargado
mv ~/Downloads/service-account.json backend/firebase/
```

**Estructura resultante:**
```
backend/
├── firebase/
│   └── service-account.json   (NO subir a git - está en .gitignore)
├── src/
├── prisma/
└── package.json
```

**Nota:** El archivo `service-account.json` contiene credenciales sensibles y está excluido del repositorio en `.gitignore`. Cada desarrollador debe colocar su propio archivo.

### 5️⃣ Configurar Firebase en Flutter (cliente)

**Para Android:**

1. En Firebase Console, ir a `Configuración del proyecto`
2. En `Tus apps`, agregar app Android con package: `com.example.seguridad_app`
3. Descargar `google-services.json`
4. Colocar en `frontend/seguridad_app/android/app/google-services.json`

**Para iOS:**

1. Agregar app iOS en Firebase Console
2. Descargar `GoogleService-Info.plist`
3. Colocar en `frontend/seguridad_app/ios/Runner/GoogleService-Info.plist`

**Para Web:**

1. Agregar app Web en Firebase Console
2. Copiar configuración en `frontend/seguridad_app/web/index.html`

### 6️⃣ Generar cliente Prisma

```sh
npx prisma generate
```

### 5️⃣ Ejecutar migraciones

```sh
npx prisma migrate dev --name init
```

### 6️⃣ Abrir Prisma Studio (opcional)

```sh
npx prisma studio
```

---

## 🚀 Levantar el servidor

```sh
cd backend
npm run dev
```

El servidor iniciará en `http://0.0.0.0:3000`

---

## 📱 Configuración del Frontend (Flutter)

### 1️⃣ Navegar al proyecto Flutter

```sh
cd frontend/seguridad_app
```

### 2️⃣ Instalar dependencias

```sh
flutter pub get
```

### 3️⃣ Configurar Firebase (opcional)

Colocar `google-services.json` en `android/app/` para notificaciones push.

### 4️⃣ Ejecutar en dispositivo/emulador

```sh
# Listar dispositivos conectados
flutter devices

# Ejecutar en Android
flutter run

# Build APK
flutter build apk

# Build para Web
flutter build web
```

---

## 🔌 Firmware ESP32

### 1️⃣ Abrir el sketch

Abrir `esp32/seguridad_esp32.ino` en Arduino IDE.

### 2️⃣ Configurar MQTT

Editar líneas 9-10 del archivo `.ino`:

```cpp
const char* MQTT_HOST = "192.168.1.34";  // IP de tu servidor MQTT
const uint16_t MQTT_PORT = 1883;
```

### 3️⃣ Seleccionar placa y puerto

- **Placa:** `ESP32 Dev Module`
- **Puerto:** COMx (Windows) o `/dev/ttyUSB0` (Linux)

### 4️⃣ Subir firmware

Click en "Subir" (flecha derecha) en Arduino IDE.

### 5️⃣ Abrir Monitor Serie

- Baud rate: `115200`
- Ver logs de conexión BLE, WiFi y MQTT

---

## 🔌 Probar MQTT (opcional)

### Publicar evento de puerta

```sh
mosquitto_pub -t "home/ABC123/door/open" -m '{"deviceId":"ABC123","tipo":"PUERTA_ABIERTA","valor":"1"}'
```

### Publicar heartbeat

```sh
mosquitto_pub -t "home/ABC123/heartbeat" -m '{"deviceId":"ABC123","tipo":"HEARTBEAT","rssi":-65,"uptime":12345}'
```

### Suscribirse a todos los mensajes

```sh
mosquitto_sub -t "home/#" -v
```

---

## 🔐 Endpoints de API

### Crear usuario

```sh
POST http://localhost:3000/api/usuarios
Content-Type: application/json

{
  "nombre": "Juan",
  "apellido": "Pérez",
  "email": "juan@ejemplo.com",
  "password": "123456",
  "rol": "CLIENTE"
}
```

### Login

```sh
POST http://localhost:3000/api/usuarios/login
Content-Type: application/json

{
  "email": "juan@ejemplo.com",
  "password": "123456"
}
```

### Obtener estado WiFi de dispositivo

```sh
GET http://localhost:3000/api/dispositivos/:deviceId/wifi-status
Authorization: Bearer <token>
```

### Estado de MQTT

```sh
GET http://localhost:3000/api/dispositivos/mqtt-status
```

---

## 📦 Scripts útiles

### Backend

```sh
# Instalación de dependencias (recomendado)
pnpm install

# Desarrollo con hot reload
pnpm run dev

# Abrir Prisma Studio
pnpm prisma studio

# Regenerar cliente Prisma
pnpm prisma generate

# Crear nueva migración
pnpm prisma migrate dev --name <nombre>

# Resetear base de datos
pnpm prisma migrate reset
```

### Flutter

```sh
# Instalar dependencias
flutter pub get

# Ejecutar con hot reload
flutter run

# Build APK release
flutter build apk --release

# Build Web
flutter build web

# Limpiar proyecto
flutter clean
```

---

## 🧹 Archivos ignorados (.gitignore)

- `.env*` (todas las variables de entorno)
- `backend/node_modules/`, `dist/`
- `backend/firebase/service-account.json` (credenciales Firebase)
- `frontend/**/build/`, `.dart_tool/`
- `esp32/build/`
- `info/` (archivos personales)
- `*.log`, `*.tmp`

---

## 📊 Monitoreo y Debugging

### Backend
- Logs en consola con niveles (info, warn, error)
- Prisma Studio para inspeccionar DB
- Endpoint `/api/dispositivos/mqtt-status` para diagnóstico MQTT

### ESP32
- Monitor Serie (115200 baud)
- Logs de conexión BLE, WiFi, MQTT
- RSSI en heartbeats para verificar calidad de señal

### Flutter
- `flutter doctor` para diagnóstico de entorno
- Logs en consola de Android Studio / VS Code
- DevTools para profiling

---

## 🔄 Flujo de Funcionamiento

### Configuración WiFi por BLE

1. App Flutter escanea dispositivos BLE cercanos
2. Se conecta a `HUB-XXXX` (4 últimos dígitos de MAC)
3. Usuario ingresa SSID y contraseña WiFi
4. App envía credenciales por BLE
5. ESP32 guarda en Preferences y conecta a WiFi
6. ESP32 publica estado por MQTT
7. Backend actualiza DB y notifica a Flutter por Socket.IO
8. App muestra "Conectado a [SSID]"

### Detección de eventos

1. Sensor magnético detecta apertura de puerta
2. ESP32 publica evento por MQTT
3. Backend recibe, guarda en DB, envía SMS (si alarma armada)
4. Backend notifica a guardias por Socket.IO
5. App de guardia recibe alerta en tiempo real

### Monitor de dispositivos offline

1. Backend verifica heartbeats cada 15s
2. Si no hay heartbeat en 30s → marca como offline
3. Crea evento `DISPOSITIVO_OFFLINE`
4. Notifica a guardias y dueño (si alarma armada)
5. App actualiza UI automáticamente por Socket.IO

---

## 🛠️ Próximos Pasos

- [ ] Actualizar funcionalidades del administrador (gestión de usuarios, casas, dispositivos)
- [ ] Mejorar panel de guardias (historial de eventos, marcado de eventos como atendidos)
- [ ] Agregar integración con cámaras RTSP/WebRTC
- [ ] Implementar modos de alarma (armado/desarmado) por geolocalización
- [ ] Agregar historial de eventos con filtros y exportación
- [ ] Mejorar notificaciones push con categorías y acciones

---

## 📞 Soporte

Para issues o consultas, abrir un ticket en:  
https://github.com/jairobandera/seguridad-sistema/issues

---

**© 2026 - Sistema de Seguridad Residencial**
