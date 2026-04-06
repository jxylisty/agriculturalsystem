#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <base64.h>
#include <mbedtls/md.h>

#define DHTPIN 4
#define DHTTYPE DHT11
#define SOIL_MOISTURE_PIN 34
#define LIGHT_SENSOR_PIN 35
#define WATER_LEVEL_PIN 32
#define CO2_PIN 33
#define IRRIGATION_RELAY_PIN 25
#define LIGHT_RELAY_PIN 26

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// OneNet MQTT 配置
const char* mqtt_server = "mqtts.heclouds.com";
const int mqtt_port = 1883;
const char* product_id = "bvEMtNm7tH";
const char* device_name = "jiaoxue";
const char* device_key = "ckg5NGxRakJjT2RRWmh1TWxzMlFzTEU3V3BVeXFvR1Q=";

// OneNet 主题
const char* topic_data = "$sys/" + String(product_id) + "/" + String(device_name) + "/thing/property/post";
const char* topic_cmd = "$sys/" + String(product_id) + "/" + String(device_name) + "/thing/service/+/invoke";

String mqtt_client_id;
String mqtt_username;
String mqtt_password;

WiFiClient espClient;
PubSubClient mqttClient(espClient);
DHT dht(DHTPIN, DHTTYPE);

struct SensorData {
  float temperature;
  float humidity;
  int soilMoisture;
  int lightLevel;
  int waterLevel;
  int co2;
  unsigned long timestamp;
};

struct ControlState {
  bool irrigationOn;
  bool lightOn;
  int brightness;
  int targetMoisture;
};

SensorData sensorData;
ControlState controlState;
unsigned long lastMsgTime = 0;
const long msgInterval = 5000;

String generateOneNetToken() {
  String version = "2018-10-31";
  unsigned long et = millis() / 1000 + 3600 * 24 * 365;
  String method = "sha256";
  String res = "products/" + String(product_id) + "/devices/" + String(device_name);
  
  String stringToSign = String(et) + "\n" + method + "\n" + res + "\n" + version;
  
  unsigned char hmacResult[32];
  mbedtls_md_hmac(mbedtls_md_info_from_type(MBEDTLS_MD_SHA256),
                  (const unsigned char*)device_key, strlen(device_key),
                  (const unsigned char*)stringToSign.c_str(), stringToSign.length(),
                  hmacResult);
  
  String sign = base64::encode(hmacResult, 32);
  sign.replace("\n", "");
  
  String token = version + "&" + String(et) + "&" + method + "&" + res + "&" + sign;
  return token;
}

void initOneNetConfig() {
  mqtt_client_id = String(device_name);
  mqtt_username = String(product_id);
  mqtt_password = generateOneNetToken();
  
  Serial.println("=== OneNet Config ===");
  Serial.print("Client ID: ");
  Serial.println(mqtt_client_id);
  Serial.print("Username: ");
  Serial.println(mqtt_username);
  Serial.print("Token generated: ");
  Serial.println(mqtt_password.length() > 20 ? "OK" : mqtt_password);
  Serial.println("====================");
}

void setupWifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");

  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, message);

  if (error) {
    Serial.print("deserializeJson() failed: ");
    Serial.println(error.c_str());
    return;
  }

  const char* cmd = doc["cmd"];
  int value = doc["value"] | 0;

  if (strcmp(cmd, "irrigation") == 0) {
    controlState.irrigationOn = (value == 1);
    digitalWrite(IRRIGATION_RELAY_PIN, controlState.irrigationOn ? HIGH : LOW);
    Serial.printf("Irrigation: %s\n", controlState.irrigationOn ? "ON" : "OFF");
  } 
  else if (strcmp(cmd, "light") == 0) {
    controlState.lightOn = (value == 1);
    digitalWrite(LIGHT_RELAY_PIN, controlState.lightOn ? HIGH : LOW);
    Serial.printf("Light: %s\n", controlState.lightOn ? "ON" : "OFF");
  }
  else if (strcmp(cmd, "brightness") == 0) {
    controlState.brightness = value;
    Serial.printf("Brightness: %d\n", controlState.brightness);
  }
  else if (strcmp(cmd, "target_moisture") == 0) {
    controlState.targetMoisture = value;
    Serial.printf("Target Moisture: %d\n", controlState.targetMoisture);
  }
}

void reconnect() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection to OneNet...");
    
    if (mqttClient.connect(mqtt_client_id.c_str(), mqtt_username.c_str(), mqtt_password.c_str())) {
      Serial.println("connected");
      mqttClient.subscribe(topic_cmd);
      Serial.printf("Subscribed to: %s\n", topic_cmd);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

int readSoilMoisture() {
  int raw = analogRead(SOIL_MOISTURE_PIN);
  return map(raw, 0, 4095, 100, 0);
}

int readLightLevel() {
  int raw = analogRead(LIGHT_SENSOR_PIN);
  return map(raw, 0, 4095, 0, 1000);
}

int readWaterLevel() {
  int raw = analogRead(WATER_LEVEL_PIN);
  return map(raw, 0, 4095, 0, 100);
}

int readCO2() {
  int raw = analogRead(CO2_PIN);
  return map(raw, 0, 4095, 400, 2000);
}

void readSensors() {
  sensorData.temperature = dht.readTemperature();
  sensorData.humidity = dht.readHumidity();
  sensorData.soilMoisture = readSoilMoisture();
  sensorData.lightLevel = readLightLevel();
  sensorData.waterLevel = readWaterLevel();
  sensorData.co2 = readCO2();
  sensorData.timestamp = millis();

  if (isnan(sensorData.temperature) || isnan(sensorData.humidity)) {
    Serial.println("Failed to read from DHT sensor!");
    sensorData.temperature = 0;
    sensorData.humidity = 0;
  }

  Serial.println("=== Sensor Data ===");
  Serial.printf("Temperature: %.1f C\n", sensorData.temperature);
  Serial.printf("Humidity: %.1f %%\n", sensorData.humidity);
  Serial.printf("Soil Moisture: %d %%\n", sensorData.soilMoisture);
  Serial.printf("Light Level: %d lux\n", sensorData.lightLevel);
  Serial.printf("Water Level: %d %%\n", sensorData.waterLevel);
  Serial.printf("CO2: %d ppm\n", sensorData.co2);
}

void publishSensorData() {
  StaticJsonDocument<256> doc;
  JsonObject params = doc.createNestedObject("params");
  params["temperature"] = sensorData.temperature;
  params["humidity"] = sensorData.humidity;
  params["soilMoisture"] = sensorData.soilMoisture;
  params["lightLevel"] = sensorData.lightLevel;
  params["waterLevel"] = sensorData.waterLevel;
  params["co2"] = sensorData.co2;
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);

  mqttClient.publish(topic_data, jsonBuffer);
  Serial.print("Published to OneNet: ");
  Serial.println(jsonBuffer);
}

void setup() {
  Serial.begin(115200);

  pinMode(IRRIGATION_RELAY_PIN, OUTPUT);
  pinMode(LIGHT_RELAY_PIN, OUTPUT);
  digitalWrite(IRRIGATION_RELAY_PIN, LOW);
  digitalWrite(LIGHT_RELAY_PIN, LOW);

  controlState.irrigationOn = false;
  controlState.lightOn = false;
  controlState.brightness = 50;
  controlState.targetMoisture = 50;

  dht.begin();

  setupWifi();

  initOneNetConfig();
  
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(callback);

  Serial.println("OneNet MQTT Agriculture System Started");
}

void loop() {
  if (!mqttClient.connected()) {
    reconnect();
  }
  mqttClient.loop();

  unsigned long now = millis();
  if (now - lastMsgTime > msgInterval) {
    lastMsgTime = now;
    readSensors();
    publishSensorData();
  }
}