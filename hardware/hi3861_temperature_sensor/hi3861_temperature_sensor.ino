/*
 * Hi3861 Temperature Sensor MQTT Client
 * 专为Hi3861设备设计的简化MQTT温度传感器
 * 使用简化的消息格式：{"temperature":25.5,"timestamp":1234567890}
 * 主题：/hi3861/temperature
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// WiFi配置
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT配置
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_client_id = "hi3861-temp-sensor";
const char* topic_data = "/hi3861/temperature";

// 温度传感器引脚（根据实际硬件调整）
#define TEMP_SENSOR_PIN A0

WiFiClient espClient;
PubSubClient mqttClient(espClient);

unsigned long lastMsgTime = 0;
const long msgInterval = 5000; // 5秒发送一次

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

void reconnect() {
  while (!mqttClient.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (mqttClient.connect(mqtt_client_id)) {
      Serial.println("connected");
      Serial.printf("Using topic: %s\n", topic_data);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

float readTemperature() {
  // 模拟温度传感器读取（根据实际传感器调整）
  int rawValue = analogRead(TEMP_SENSOR_PIN);
  
  // 模拟值转换为温度（示例转换公式）
  float voltage = rawValue * (3.3 / 4095.0);
  float temperature = (voltage - 0.5) * 100.0; // LM35传感器公式
  
  // 添加一些随机波动模拟真实环境
  temperature += (random(-50, 50) / 100.0);
  
  return temperature;
}

void publishTemperatureData() {
  float temperature = readTemperature();
  unsigned long timestamp = millis();
  
  // 简化的消息格式，符合Hi3861需求
  StaticJsonDocument<128> doc;
  doc["temperature"] = temperature;
  doc["timestamp"] = timestamp;

  char jsonBuffer[128];
  serializeJson(doc, jsonBuffer);

  mqttClient.publish(topic_data, jsonBuffer);
  Serial.print("Published to ");
  Serial.print(topic_data);
  Serial.print(": ");
  Serial.println(jsonBuffer);
}

void setup() {
  Serial.begin(115200);
  
  // 初始化温度传感器引脚
  pinMode(TEMP_SENSOR_PIN, INPUT);
  
  // 设置随机种子
  randomSeed(analogRead(0));
  
  setupWifi();

  mqttClient.setServer(mqtt_server, mqtt_port);

  Serial.println("Hi3861 Temperature MQTT System Started");
  Serial.println("Using simplified message format for Hi3861 compatibility");
  Serial.printf("MQTT Topic: %s\n", topic_data);
  Serial.println("Message format: {\"temperature\":25.5,\"timestamp\":1234567890}");
}

void loop() {
  if (!mqttClient.connected()) {
    reconnect();
  }
  mqttClient.loop();

  unsigned long now = millis();
  if (now - lastMsgTime > msgInterval) {
    lastMsgTime = now;
    publishTemperatureData();
  }
}

/*
 * 使用说明：
 * 1. 修改WiFi配置（ssid和password）
 * 2. 根据实际硬件调整温度传感器引脚和读取逻辑
 * 3. 上传代码到Hi3861设备
 * 4. 打开串口监视器查看输出
 * 5. HarmonyOS APP将自动接收温度数据
 *
 * 消息格式说明：
 * - 符合要求的JSON格式：{"temperature":25.5,"timestamp":1234567890}
 * - temperature: 温度值（摄氏度）
 * - timestamp: 时间戳（毫秒）
 *
 * 主题说明：
 * - 使用要求的主题：/hi3861/temperature
 * - HarmonyOS APP已配置订阅此主题
 */