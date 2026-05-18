#include <WiFi.h>
#include <PubSubClient.h>
#include <Preferences.h>
#include <NimBLEDevice.h>

// =======================
// CONFIG MQTT
// =======================
const char* MQTT_HOST = "192.168.1.17";
const uint16_t MQTT_PORT = 1883;

// =======================
// PINES
// =======================
#define SENSOR_PIN 14

// =======================
// BLE NUS UUIDs (Nordic UART Service)
// =======================
#define NUS_SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_RX_CHAR_UUID "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_TX_CHAR_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_ID_CHAR_UUID "6E400004-B5A3-F393-E0A9-E50E24DCCA9E"

// =======================
// OBJETOS GLOBALES
// =======================
Preferences prefs;
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// BLE
NimBLEServer* pServer = nullptr;
NimBLECharacteristic* pTxCharacteristic = nullptr;
NimBLECharacteristic* pIdCharacteristic = nullptr;
bool bleConnected = false;
String bleBuffer = "";

// WiFi
String currentSsid = "";
bool wifiConnecting = false;

// =======================
// ESTADO GLOBAL
// =======================
String deviceId;
bool posible5G = false;

String baseTopic;
String topicRegister;
String topicDoorOpen;
String topicDoorClosed;
String topicHeartbeat;
String topicWifiConfig;
String topicWifiAck;

bool lastDoorOpen = false;
unsigned long lastHeartbeat = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000;

// Forward declarations
void handleBleCommand(String data);
void reconnectMQTT();

// =====================================================
// BLE Server Callbacks (NimBLE v2.x API)
// =====================================================
class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    bleConnected = true;
    bleBuffer = "";
    Serial.println("BLE conectado");
  }
  void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override {
    bleConnected = false;
    bleBuffer = "";
    Serial.println("BLE desconectado");
    pServer->startAdvertising();
  }
};

// =====================================================
// BLE Write Callback (NimBLE v2.x API)
// =====================================================
class WriteCallback : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    std::string value = pCharacteristic->getValue();
    String chunk = String(value.c_str());

    bleBuffer += chunk;
    Serial.print("BLE RX chunk: ");
    Serial.println(chunk);

    // Si el JSON esta completo (termina con }), procesar
    if (bleBuffer.endsWith("}")) {
      Serial.print("BLE RX completo: ");
      Serial.println(bleBuffer);
      handleBleCommand(bleBuffer);
      bleBuffer = "";
    }
  }
};

// =====================================================
// BLE Read Callback para deviceId
// =====================================================
class ReadIdCallback : public NimBLECharacteristicCallbacks {
  void onRead(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    pCharacteristic->setValue(deviceId.c_str());
    Serial.print("BLE Read ID: ");
    Serial.println(deviceId);
  }
};

// =====================================================
// Enviar respuesta por BLE TX
// =====================================================
void sendBleResponse(String json) {
  if (bleConnected && pTxCharacteristic) {
    // Enviar en chunks si el mensaje es muy largo
    int len = json.length();
    Serial.print("BLE TX (chunked, ");
    Serial.print(len);
    Serial.println(" bytes)");

    if (len <= 20) {
      // Mensaje corto, enviar directo
      pTxCharacteristic->setValue(json.c_str());
      pTxCharacteristic->notify();
      Serial.print("BLE TX: ");
      Serial.println(json);
    } else {
      // Mensaje largo, enviar en partes con delays
      for (int i = 0; i < len; i += 18) {
        int end = (i + 18 < len) ? i + 18 : len;
        String chunk = json.substring(i, end);
        pTxCharacteristic->setValue(chunk.c_str());
        pTxCharacteristic->notify();
        delay(150);
      }
    }
    delay(250);  // Delay para evitar que se combinen notificaciones BLE
  }
}

// =====================================================
// Parsear JSON simple (sin libreria) - VERSION MEJORADA
// =====================================================
String jsonGet(String json, String key) {
  String search = "\"" + key + "\"";
  int idx = json.indexOf(search);
  if (idx == -1) return "";
  int colon = json.indexOf(":", idx);
  if (colon == -1) return "";
  
  // Saltar espacios y comillas después del :
  int start = colon + 1;
  while (start < json.length() && (json[start] == ' ' || json[start] == '"')) start++;
  
  // Buscar el fin del valor (coma o })
  int end = start;
  while (end < json.length() && json[end] != ',' && json[end] != '}') end++;
  
  // Si termina con comilla, removerla
  if (end > start && json[end-1] == '"') end--;
  
  String value = json.substring(start, end);
  value.trim();  // Remover espacios restantes
  return value;
}

// =====================================================
// Handler de comandos BLE
// =====================================================
void handleBleCommand(String data) {
  String cmd = jsonGet(data, "cmd");

  if (cmd == "status") {
    String json = "{";
    json += "\"wifiConnected\":" + String(WiFi.status() == WL_CONNECTED ? "true" : "false") + ",";
    json += "\"ssid\":\"" + prefs.getString("ssid", "") + "\",";
    json += "\"possible5G\":" + String(posible5G ? "true" : "false") + ",";
    json += "\"deviceId\":\"" + deviceId + "\"";
    json += "}";
    sendBleResponse(json);
    return;
  }

  if (cmd == "wifi") {
    String ssid = jsonGet(data, "ssid");
    String pass = jsonGet(data, "pass");

    // DEBUG: Mostrar SSID recibido
    Serial.print("SSID recibido: [");
    Serial.print(ssid);
    Serial.println("]");
    Serial.print("Pass recibido: [");
    Serial.print(pass);
    Serial.println("]");

    if (ssid.length() == 0) {
      sendBleResponse("{\"result\":\"error\",\"reason\":\"ssid_vacio\"}");
      return;
    }

    prefs.putString("ssid", ssid);
    prefs.putString("pass", pass);

    sendBleResponse("{\"result\":\"accepted\"}");
    delay(100);

    // Enviar ok INMEDIATAMENTE antes de iniciar WiFi (mientras BLE aun esta estable)
    sendBleResponse("{\"result\":\"ok\",\"ssid\":\"" + ssid + "\"}");
    delay(100);

    // Guardar SSID actual para publicar despues por MQTT
    currentSsid = ssid;
    wifiConnecting = true;

    // CRITICO: Detener cualquier conexión WiFi en curso antes de iniciar nueva
    wl_status_t currentStatus = WiFi.status();
    if (currentStatus == WL_CONNECTED) {
      Serial.println("WiFi.disconnect() - ya estaba conectado, desconectando...");
      WiFi.disconnect(true);
      delay(500);
    }
    
    // CRITICO: Forzar disconnect aunque este en estado WL_CONNECT_STARTED
    // Esto evita el error "sta is connecting, cannot set config"
    Serial.println("WiFi.disconnect(true) - forzando disconnect...");
    WiFi.disconnect(true);
    delay(1000);  // Dar tiempo a que el estado WiFi se resetee completamente
    
    // Recién ahora intentar WiFi
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), pass.c_str());

    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 30000) {
      delay(500);
      Serial.print(".");
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("WiFi conectada via BLE");
      posible5G = false;
      wifiConnecting = false;
      currentSsid = ssid;

      if (!mqttClient.connected()) {
        reconnectMQTT();
      } else {
        String statusPayload = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"WIFI_CONNECTED\",\"ssid\":\"" + ssid + "\",\"wifi\":true,\"mqtt\":true,\"rssi\":" + String(WiFi.RSSI()) + "}";
        mqttClient.publish((baseTopic + "/status").c_str(), statusPayload.c_str());
        Serial.println("MQTT Status publicado: " + statusPayload);
      }
    } else {
      Serial.println("No se pudo conectar via BLE.");
      posible5G = true;
      wifiConnecting = false;
      sendBleResponse("{\"result\":\"error\",\"reason\":\"no_conecto_wifi\"}");
    }
    return;
  }

  if (cmd == "clear_wifi") {
    prefs.remove("ssid");
    prefs.remove("pass");
    currentSsid = "";
    Serial.println("BLE: credenciales borradas");

    WiFi.disconnect(true);
    delay(500);

    sendBleResponse("{\"result\":\"cleared\"}");
    delay(200);  // Dar tiempo a que se envíe la respuesta
    
    // Reiniciar la placa para que quede sin WiFi
    Serial.println("Reiniciando ESP32...");
    delay(1000);
    ESP.restart();
    return;
  }

  Serial.print("BLE: comando desconocido: ");
  Serial.println(cmd);
}

// =====================================================
// Iniciar servidor BLE
// =====================================================
void iniciarBLE() {
  String shortMac = getShortMac();
  String deviceName = "HUB-" + shortMac;

  NimBLEDevice::init(deviceName.c_str());
  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  NimBLEService* pService = pServer->createService(NUS_SERVICE_UUID);

  // TX: solo NOTIFY
  pTxCharacteristic = pService->createCharacteristic(
    NUS_TX_CHAR_UUID,
    NIMBLE_PROPERTY::NOTIFY);

  // RX: WRITE + WRITE_NR
  NimBLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
    NUS_RX_CHAR_UUID,
    NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  pRxCharacteristic->setCallbacks(new WriteCallback());

  // ID: READ
  pIdCharacteristic = pService->createCharacteristic(
    NUS_ID_CHAR_UUID,
    NIMBLE_PROPERTY::READ);
  pIdCharacteristic->setValue(deviceId.c_str());
  pIdCharacteristic->setCallbacks(new ReadIdCallback());

  pService->start();

  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(NUS_SERVICE_UUID);
  pAdvertising->setName(deviceName.c_str());
  pAdvertising->start();

  Serial.print("BLE iniciado: ");
  Serial.println(deviceName);
}

// =====================================================
// HELPERS - MAC address (se lee UNA sola vez en setup)
// =====================================================
String getDeviceIdFromMac() {
  WiFi.mode(WIFI_STA);
  delay(200);
  uint8_t mac[6];
  WiFi.macAddress(mac);
  String macStr = "";
  for (int i = 0; i < 6; i++) {
    if (mac[i] < 0x10) macStr += "0";
    macStr += String(mac[i], HEX);
  }
  macStr.toUpperCase();
  return macStr;
}

String getShortMac() {
  if (deviceId.length() >= 4) {
    return deviceId.substring(deviceId.length() - 4);
  }
  return deviceId;
}

// =====================================================
// INTENTAR CONECTAR WIFI (credenciales guardadas)
// =====================================================
void conectarWifiGuardada() {
  String ssid = prefs.getString("ssid", "");
  String pass = prefs.getString("pass", "");

  // DEBUG: Mostrar SSID guardado
  Serial.print("WiFi guardada SSID: [");
  Serial.print(ssid);
  Serial.println("]");

  if (ssid.length() == 0) {
    Serial.println("No hay WiFi guardada. Esperando configuracion por BLE.");
    return;
  }

  Serial.print("Intentando conectar a WiFi guardada: ");
  Serial.println(ssid);

  // CRITICO: Si ya estaba conectado, desconectar primero
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi.disconnect() - ya estaba conectado, desconectando...");
    WiFi.disconnect(true);
    delay(300);
  }
  
  // CRITICO: Forzar disconnect aunque este en estado WL_CONNECT_STARTED
  Serial.println("WiFi.disconnect(true) - forzando disconnect...");
  WiFi.disconnect(true);
  delay(1000);  // Dar tiempo a que el estado WiFi se resetee completamente

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), pass.c_str());

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 30000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi conectada");
    posible5G = false;
    currentSsid = ssid;
    if (mqttClient.connected()) {
      String statusPayload = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"WIFI_CONNECTED\",\"ssid\":\"" + ssid + "\",\"wifi\":true,\"mqtt\":true,\"rssi\":" + String(WiFi.RSSI()) + "}";
      mqttClient.publish((baseTopic + "/status").c_str(), statusPayload.c_str());
      Serial.println("MQTT Status publicado: " + statusPayload);
    }
  } else {
    Serial.println("No se pudo conectar. Posible red 5GHz o clave incorrecta.");
    posible5G = true;
    String payload = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"ERROR_WIFI\",\"wifi\":false,\"mqtt\":false}";
    mqttClient.publish((baseTopic + "/status").c_str(), payload.c_str());
  }
}

// =====================================================
// MQTT
// =====================================================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String topicStr = String(topic);
  String data;
  for (unsigned int i = 0; i < length; i++) data += (char)payload[i];

  Serial.print("MQTT mensaje en ");
  Serial.print(topicStr);
  Serial.print(" : ");
  Serial.println(data);

  if (topicStr == topicWifiConfig) {
    String ssid, pass;

    int idxSsid = data.indexOf("\"ssid\"");
    if (idxSsid != -1) {
      int colon = data.indexOf(":", idxSsid);
      int q1 = data.indexOf("\"", colon + 1);
      int q2 = data.indexOf("\"", q1 + 1);
      if (q1 != -1 && q2 != -1) ssid = data.substring(q1 + 1, q2);
    }

    int idxPass = data.indexOf("\"pass\"");
    if (idxPass != -1) {
      int colon = data.indexOf(":", idxPass);
      int q1 = data.indexOf("\"", colon + 1);
      int q2 = data.indexOf("\"", q1 + 1);
      if (q1 != -1 && q2 != -1) pass = data.substring(q1 + 1, q2);
    }

    if (ssid.length() > 0) {
      prefs.putString("ssid", ssid);
      prefs.putString("pass", pass);

      String ack = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"OK\",\"ssid\":\"" + ssid + "\"}";
      mqttClient.publish(topicWifiAck.c_str(), ack.c_str());
      Serial.println("ACK WiFi enviado, reiniciando...");
      delay(500);
      ESP.restart();
    } else {
      String ack = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"ERROR\",\"reason\":\"ssid_missing_or_invalid\"}";
      mqttClient.publish(topicWifiAck.c_str(), ack.c_str());
    }
    return;
  }

  if (topicStr.endsWith("/cmd")) {
    String cmd;
    int idxCmd = data.indexOf("\"cmd\"");
    if (idxCmd != -1) {
      int colon = data.indexOf(':', idxCmd);
      int q1 = data.indexOf('"', colon + 1);
      int q2 = data.indexOf('"', q1 + 1);
      if (q1 != -1 && q2 != -1) cmd = data.substring(q1 + 1, q2);
    }

    if (cmd == "factory_reset") {
      Serial.println("MQTT: factory_reset recibido -> borrando credenciales");
      prefs.remove("ssid");
      prefs.remove("pass");
      currentSsid = "";

      String ack = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"FACTORY_RESET\"}";
      mqttClient.publish(topicWifiAck.c_str(), ack.c_str());

      Serial.println("Reiniciando ESP32...");
      delay(1000);
      ESP.restart();
    }
    return;
  }
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Conectando a MQTT... ");
    String clientId = "esp32-" + deviceId + "-" + String(random(0xFFFF), HEX);

    if (mqttClient.connect(clientId.c_str())) {
      Serial.println("OK");
      mqttClient.subscribe(topicWifiConfig.c_str());
      String payload = "{\"deviceId\":\"" + deviceId + "\"}";
      mqttClient.publish(topicRegister.c_str(), payload.c_str());
      Serial.println("Register publicado: " + payload);
      
      // Publicar estado actual de WiFi
      bool wifiConnected = (WiFi.status() == WL_CONNECTED);
      String statusPayload = "{\"deviceId\":\"" + deviceId + "\",\"status\":\"MQTT_CONNECTED\",\"ssid\":\"" + currentSsid + "\",\"wifi\":" + String(wifiConnected ? "true" : "false") + ",\"mqtt\":true,\"rssi\":" + String(WiFi.RSSI()) + "}";
      mqttClient.publish((baseTopic + "/status").c_str(), statusPayload.c_str());
      Serial.println("Status publicado en reconnect: " + statusPayload);
    } else {
      Serial.print("fallo rc=");
      Serial.print(mqttClient.state());
      Serial.println(" reintentando en 3s...");
      delay(3000);
    }
  }
}

// =====================================================
// EVENTOS MQTT
// =====================================================
void publishDoorEvent(bool doorOpen) {
  if (!mqttClient.connected()) return;
  String topic = doorOpen ? topicDoorOpen : topicDoorClosed;
  String tipo = doorOpen ? "PUERTA_ABIERTA" : "PUERTA_CERRADA";
  String valor = doorOpen ? "1" : "0";
  String payload = "{\"deviceId\":\"" + deviceId + "\",\"tipo\":\"" + tipo + "\",\"valor\":\"" + valor + "\"}";
  mqttClient.publish(topic.c_str(), payload.c_str());
  Serial.print("Evento puerta -> ");
  Serial.println(payload);
}

void publishHeartbeat() {
  if (!mqttClient.connected()) return;
  long rssi = WiFi.RSSI();
  String payload = "{\"deviceId\":\"" + deviceId + "\",\"tipo\":\"HEARTBEAT\",\"rssi\":" + String(rssi) + ",\"uptime\":" + String(millis()) + "}";
  mqttClient.publish(topicHeartbeat.c_str(), payload.c_str());
  Serial.print("Heartbeat -> ");
  Serial.println(payload);
}

// =====================================================
// SENSOR
// =====================================================
bool isDoorOpen() {
  int lectura = digitalRead(SENSOR_PIN);
  bool imanCerca = (lectura == LOW);
  return !imanCerca;
}

// =====================================================
// SETUP
// =====================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  pinMode(SENSOR_PIN, INPUT_PULLUP);

  Serial.println("===== ESP32 Seguridad Residencial =====");

  prefs.begin("wifi", false);

  deviceId = getDeviceIdFromMac();
  Serial.print("deviceId (MAC): ");
  Serial.println(deviceId);

  if (deviceId == "000000000000" || deviceId.length() < 12) {
    Serial.println("ERROR: MAC invalida! Reintentando...");
    delay(500);
    deviceId = getDeviceIdFromMac();
    Serial.print("deviceId (reintento): ");
    Serial.println(deviceId);
    if (deviceId == "000000000000" || deviceId.length() < 12) {
      Serial.println("FATAL: No se pudo obtener la MAC. Deteniendo.");
      while (true) { delay(1000); }
    }
  }

  // Iniciar BLE
  iniciarBLE();

  // Intentar conectar con credenciales guardadas
  conectarWifiGuardada();


  Serial.print("IP local: ");
  Serial.println(WiFi.localIP());

  // Topics MQTT
  baseTopic = "home/" + deviceId;
  topicRegister = "home/register";
  topicDoorOpen = baseTopic + "/door/open";
  topicDoorClosed = baseTopic + "/door/closed";
  topicHeartbeat = baseTopic + "/heartbeat";
  topicWifiConfig = baseTopic + "/wifi/config";
  topicWifiAck = baseTopic + "/wifi/ack";

  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi OK -> conectando MQTT");
    reconnectMQTT();
  } else {
    Serial.println("Sin WiFi -> esperando configuracion por BLE");
  }

  lastDoorOpen = isDoorOpen();
  lastHeartbeat = millis();

  Serial.println("===== Setup completo =====");
}

// =====================================================
// LOOP
// =====================================================
void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    if (!mqttClient.connected()) reconnectMQTT();
    mqttClient.loop();

  } else {
    delay(100);
  }

  bool doorOpen = isDoorOpen();
  if (doorOpen != lastDoorOpen) {
    publishDoorEvent(doorOpen);
    lastDoorOpen = doorOpen;
    delay(200);
  }

  unsigned long now = millis();
  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    lastHeartbeat = now;
    publishHeartbeat();
  }

  delay(50);
}
