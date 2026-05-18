# AGENTS.md - Seguridad Residencial

## Project Overview
Multi-platform residential security system with ESP32 hardware, Node.js/TypeScript backend, and Flutter mobile app.

## Architecture

```
/seguridad-sistema/
├── backend/           # Node.js + Express + TypeScript + Prisma + MQTT + Socket.IO
├── frontend/          # Flutter (Android, iOS, Web, Desktop)
├── esp32/             # ESP32 firmware (Arduino, BLE + MQTT)
│   └── seguridad_esp32/
── .agents/skills/    # OpenCode skills config
```

## Backend (`/backend`)

**Stack:** Node.js 18+, Express 5, TypeScript, Prisma ORM, PostgreSQL, MQTT (Mosquitto), Socket.IO, JWT

**Entry point:** `src/server.ts` - loads MQTT, creates HTTP server, initializes Socket.IO on port 3000

**Key modules:**
- `src/core/` - config, logger, Prisma client, MQTT, Socket.IO, Twilio SMS, FCM notifications
- `src/modules/` - feature controllers (usuarios, casas, dispositivos, eventos, camaras)
- `src/middleware/` - auth (JWT), roles, validation, error handling

**Database:** PostgreSQL with Prisma schema at `prisma/schema.prisma`
- Main entities: Usuario, Casa, Dispositivo, Sensor, Evento, Notificacion, Camara

**Required `.env` variables:**
```
DATABASE_URL="postgresql://USER:PASS@localhost:5432/seguridad"
JWT_SECRET="<secret>"
PORT=3000
LOG_LEVEL=info

# Network configuration
MQTT_BROKER_HOST="localhost"
MQTT_BROKER_PORT=1883
API_BASE_URL="http://localhost:3000"

# Firebase (optional - for push notifications)
FIREBASE_PROJECT_ID="your_project_id"
```

**Firebase Setup:**
1. Create service account key in Firebase Console
2. Save as `backend/firebase/service-account.json` (excluded from git)
3. For Flutter: add `google-services.json` to `frontend/seguridad_app/android/app/`

**Environment Template:**
- Copy `.env.example` to `.env` and fill in your values
- `.env` is excluded from git - each developer has their own configuration

**Commands (run from `/backend`):**
```sh
pnpm install                    # Install deps
pnpm prisma generate            # Generate Prisma client (required after schema changes)
pnpm prisma migrate dev         # Run migrations
pnpm prisma studio              # Open DB GUI
pnpm run dev                    # Start dev server (ts-node-dev with hot reload)
```

**MQTT topics:**
- `home/{deviceId}/door/open` - Door opened event
- `home/{deviceId}/door/closed` - Door closed event
- `home/{deviceId}/heartbeat` - Device alive (every 30s)
- `home/{deviceId}/wifi/config` - WiFi config command to device
- `home/register` - Device registration

**Test MQTT publish:**
```sh
mosquitto_pub -t "home/ABC123/door/open" -m '{"deviceId":"ABC123","tipo":"PUERTA_ABIERTA","valor":"1"}'
```

## Frontend (`/frontend/seguridad_app`)

**Stack:** Flutter (SDK 3.3.4+), Dart

**Dependencies:** Firebase Messaging, Socket.IO, BLE (`flutter_reactive_ble`), SharedPreferences, JWT auth

**Entry point:** `lib/main.dart` -> `lib/app.dart`

**Core structure:**
- `lib/core/` - API client, auth, notifications, storage, Socket.IO
- `lib/features/` - admin, auth, cliente, guardia pages/services/models

**Commands (run from `/frontend/seguridad_app`):**
```sh
flutter pub get              # Install deps
flutter run                  # Run on connected device
flutter build apk            # Build Android APK
```

**User roles:** Admin, Cliente (homeowner), Guardia (security guard)

## ESP32 Firmware (`/esp32/seguridad_esp32`)

**Stack:** Arduino framework, ESP32, PubSubClient (MQTT), NimBLE (BLE server)

**Entry point:** `seguridad_esp32/seguridad_esp32.ino`

**Features:**
- BLE UART service for WiFi provisioning (Nordic UART UUIDs)
- MQTT communication with backend
- Door sensor monitoring (GPIO 14, magnetic reed switch)
- Heartbeat every 30s with RSSI
- WiFi credentials stored in Preferences (flash)

**BLE Commands (JSON via UART RX):**
- `{"cmd":"status"}` - Get WiFi/MQTT status
- `{"cmd":"wifi","ssid":"...","pass":"..."}` - Configure WiFi
- `{"cmd":"clear_wifi"}` - Reset WiFi credentials

**MQTT hardcoded:** Host `192.168.1.64`, Port `1883` (update in `.ino` for different network)

**Important fix:** Before calling `WiFi.begin()`, always call `WiFi.disconnect(true)` with 1000ms delay to avoid "sta is connecting, cannot set config" error when retrying connections.

## Skills Loaded
- `esp32-firmware-engineer` - ESP-IDF/Arduino embedded development
- `mqtt-development` - MQTT messaging patterns
- `nodejs-backend-patterns` - Express/TypeScript backend

## Development Gotchas

1. **Prisma client must be regenerated** after any schema change: `npx prisma generate`
2. **Backend requires MQTT broker running** - install Mosquitto or use Docker
3. **ESP32 uses hardcoded MQTT IP** - update `MQTT_HOST` in `.ino` to match your network
4. **Firebase service account** excluded from git - place at `backend/firebase/service-account.json`
5. **Server binds to `0.0.0.0`** for external access (Android emulator, physical devices)
6. **ESP32 WiFi reconnect fix** - Always call `WiFi.disconnect(true)` with 1000ms delay before `WiFi.begin()` to avoid connection state errors
7. **Device online status** - Backend now keeps `online=true` even with `ERROR_WIFI` (device is reachable via MQTT regardless of WiFi status)

## Ignored Files
- `.env*` files (all environments)
- `backend/node_modules/`, `dist/`
- `backend/firebase/service-account.json` (Firebase credentials)
- `frontend/**/build/`, `.dart_tool/`
- `esp32/build/`
- `info/` (personal files)
