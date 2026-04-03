# 硬件组接口文档

## 概述

本文档为硬件开发者提供智慧农业系统的蓝牙通信协议说明。硬件设备通过BLE与APP通信，上传传感器数据并接收控制命令。

---

## 蓝牙配置

### BLE参数

| 参数 | 值 |
|------|-----|
| 蓝牙版本 | BLE 4.2+ |
| 连接方式 | 从设备模式 |
| 广播名称 | SmartAgriculture_XX (XX为设备编号) |
| MTU | 建议 128 字节 |

### 服务UUID（建议）

| 服务 | UUID |
|------|------|
| 主服务 | 0000FFE0-0000-1000-8000-00805F9B34FB |
| 数据特征 | 0000FFE1-0000-1000-8000-00805F9B34FB |
| 命令特征 | 0000FFE2-0000-1000-8000-00805F9B34FB |

---

## 数据上传协议

### 传感器数据格式

硬件设备定期向APP上传传感器数据，使用JSON格式：

```json
{
  "temperature": 25.5,
  "humidity": 65,
  "soilMoisture": 45,
  "lightLevel": 300,
  "waterLevel": 75,
  "co2": 450,
  "timestamp": 1700000000
}
```

### 字段说明

| 字段 | 类型 | 单位 | 范围 | 说明 |
|------|------|------|------|------|
| temperature | number | °C | -20 ~ 60 | 环境温度 |
| humidity | number | % | 0 ~ 100 | 空气湿度 |
| soilMoisture | number | % | 0 ~ 100 | 土壤湿度 |
| lightLevel | number | lux | 0 ~ 10000 | 光照强度 |
| waterLevel | number | % | 0 ~ 100 | 水箱水位 |
| co2 | number | ppm | 0 ~ 5000 | CO2浓度 |
| timestamp | number | 秒 | - | Unix时间戳 |

### 上传频率

- **默认频率**: 每 5 秒上传一次
- **预警状态**: 每 1 秒上传一次
- **待机状态**: 每 30 秒上传一次

---

## 控制命令协议

### 命令格式

APP向硬件发送控制命令，使用JSON格式：

```json
{
  "cmd": "irrigation",
  "value": 1,
  "timestamp": 1700000000000
}
```

### 支持的命令

| 命令 | cmd | value | 说明 |
|------|-----|-------|------|
| 灌溉开关 | irrigation | 0=关, 1=开 | 控制水泵 |
| 目标湿度 | target_moisture | 20-80 | 自动灌溉目标值 |
| 灯光开关 | light | 0=关, 1=开 | 控制LED |
| 灯光亮度 | brightness | 0-100 | LED亮度百分比 |

### 命令示例

#### 开启灌溉

```json
{
  "cmd": "irrigation",
  "value": 1,
  "timestamp": 1700000000000
}
```

---

## MQTT 云端协议（APP ↔ 云服务器 ↔ ESP32）

### MQTT 连接参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| Broker URL | broker.emqx.io | MQTT 服务器地址 |
| Port | 1883 | MQTT 端口 |
| Client ID | 自动生成 | 客户端标识 |

### 主题（Topic）

| 方向 | Topic | 说明 |
|------|-------|------|
| APP 订阅 | /hi3861/temperature | 接收传感器数据（Hi3861简化格式） |
| APP 订阅 | agriculture/cmd/response | 接收控制命令响应 |
| APP 发布 | agriculture/cmd | 发送控制命令 |

### 传感器数据格式（云服务器 → APP）

#### 标准格式（ESP32设备）
```json
{
  "temperature": 25.5,
  "humidity": 65,
  "soilMoisture": 45,
  "lightLevel": 300,
  "waterLevel": 75,
  "co2": 450,
  "timestamp": 1700000000000
}
```

#### 简化格式（Hi3861设备）
```json
{
  "temperature": 25.5,
  "timestamp": 1700000000000
}
```

### 控制命令格式（APP → 云服务器 → ESP32）

#### 灌溉命令

```json
{
  "cmd": "irrigation",
  "value": 1,
  "irrigation": true,
  "irrigationAuto": false,
  "targetMoisture": 50,
  "timestamp": 1700000000000,
  "fromSelf": true
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| cmd | string | 命令类型：irrigation |
| value | number | 0=关闭, 1=开启 |
| irrigation | boolean | 灌溉开关状态 |
| irrigationAuto | boolean | 是否自动模式 |
| targetMoisture | number | 目标湿度（20-80） |
| timestamp | number | 时间戳 |
| fromSelf | boolean | 是否为APP自身发送（用于过滤） |

#### 光照命令

```json
{
  "cmd": "light",
  "value": 1,
  "light": true,
  "lightAuto": false,
  "brightness": 50,
  "timestamp": 1700000000000,
  "fromSelf": true
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| cmd | string | 命令类型：light |
| value | number | 0=关闭, 1=开启 |
| light | boolean | 光照开关状态 |
| lightAuto | boolean | 是否自动模式 |
| brightness | number | 亮度值（0-100） |
| timestamp | number | 时间戳 |
| fromSelf | boolean | 是否为APP自身发送 |

#### 四向光照命令（东/西/南/北）

> ⚠️ 注意：当前 APP 仅发送固定值50，未实现真正的四向分别控制

```json
{
  "cmd": "light",
  "value": 50,
  "brightness": 50,
  "timestamp": 1700000000000,
  "fromSelf": true
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| cmd | string | 命令类型：light |
| value | number | 固定亮度值 |
| brightness | number | 亮度值（0-100） |
| timestamp | number | 时间戳 |
| fromSelf | boolean | 是否为APP自身发送 |

#### 目标湿度命令

```json
{
  "cmd": "target_moisture",
  "value": 50,
  "timestamp": 1700000000000
}
```

### ESP32 MQTT 示例代码

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

const char* ssid = "你的WiFi名称";
const char* password = "你的WiFi密码";
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

void callback(char* topic, byte* payload, unsigned int length) {
  // 接收 APP 控制命令
  StaticJsonDocument<256> doc;
  deserializeJson(doc, payload, length);

  const char* cmd = doc["cmd"];

  if (strcmp(cmd, "irrigation") == 0) {
    int value = doc["value"];
    bool autoMode = doc["autoMode"];
    // 控制灌溉...
  }
  else if (strcmp(cmd, "light") == 0) {
    int value = doc["value"];
    // 控制灯光...
  }
  else if (strcmp(cmd, "light_directional") == 0) {
    int east = doc["east"];
    int west = doc["west"];
    int south = doc["south"];
    int north = doc["north"];
    // 控制四向灯光...
  }
}

void reconnect() {
  while (!client.connected()) {
    if (client.connect("ESP32_Client")) {
      client.subscribe("agriculture/control/cmd");
    }
  }
}

void sendSensorData() {
  StaticJsonDocument<256> doc;
  doc["temperature"] = readTemperature();
  doc["humidity"] = readHumidity();
  doc["soilMoisture"] = readSoilMoisture();
  doc["lightLevel"] = readLightLevel();
  doc["waterLevel"] = readWaterLevel();
  doc["co2"] = readCO2();
  doc["timestamp"] = millis();

  char buffer[256];
  serializeJson(doc, buffer);
  client.publish("agriculture/sensor/data", buffer);
}
```

---

## 硬件响应协议

硬件收到命令后应返回确认：

```json
{
  "cmd": "irrigation",
  "status": "ok",
  "message": "灌溉已开启"
}
```

### 状态码

| status | 说明 |
|--------|------|
| ok | 命令执行成功 |
| error | 命令执行失败 |
| invalid | 无效命令 |

---

## ESP32 示例代码

### 数据上传

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

// 传感器引脚
#define DHT_PIN 4
#define SOIL_PIN 34
#define LIGHT_PIN 35
#define WATER_PIN 32
#define CO2_PIN 33

// 执行器引脚
#define PUMP_PIN 25
#define LED_PIN 26

BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
BLECharacteristic* pCmdCharacteristic = NULL;

bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      parseCommand(value);
    }
};

void parseCommand(String json) {
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, json);
  
  if (error) {
    Serial.println("JSON解析失败");
    return;
  }
  
  const char* cmd = doc["cmd"];
  int value = doc["value"];
  
  if (strcmp(cmd, "irrigation") == 0) {
    digitalWrite(PUMP_PIN, value ? HIGH : LOW);
    Serial.printf("灌溉: %s\n", value ? "开启" : "关闭");
  }
  else if (strcmp(cmd, "light") == 0) {
    digitalWrite(LED_PIN, value ? HIGH : LOW);
    Serial.printf("灯光: %s\n", value ? "开启" : "关闭");
  }
  else if (strcmp(cmd, "brightness") == 0) {
    ledcWrite(0, value * 2.55);  // PWM控制
    Serial.printf("亮度: %d%%\n", value);
  }
  else if (strcmp(cmd, "target_moisture") == 0) {
    targetMoisture = value;
    Serial.printf("目标湿度: %d%%\n", value);
  }
}

void sendSensorData() {
  StaticJsonDocument<256> doc;
  
  doc["temperature"] = dht.readTemperature();
  doc["humidity"] = dht.readHumidity();
  doc["soilMoisture"] = map(analogRead(SOIL_PIN), 0, 4095, 0, 100);
  doc["lightLevel"] = map(analogRead(LIGHT_PIN), 0, 4095, 0, 1000);
  doc["waterLevel"] = map(analogRead(WATER_PIN), 0, 4095, 0, 100);
  doc["co2"] = readCO2();
  doc["timestamp"] = millis() / 1000;
  
  char buffer[256];
  serializeJson(doc, buffer);
  
  pDataCharacteristic->setValue(buffer);
  pDataCharacteristic->notify();
}

void setup() {
  Serial.begin(115200);
  
  // 初始化BLE
  BLEDevice::init("SmartAgriculture_01");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(BLEUUID("0000FFE0-0000-1000-8000-00805F9B34FB"));
  
  // 数据特征
  pDataCharacteristic = pService->createCharacteristic(
    BLEUUID("0000FFE1-0000-1000-8000-00805F9B34FB"),
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pDataCharacteristic->addDescriptor(new BLE2902());
  
  // 命令特征
  pCmdCharacteristic = pService->createCharacteristic(
    BLEUUID("0000FFE2-0000-1000-8000-00805F9B34FB"),
    BLECharacteristic::PROPERTY_WRITE
  );
  pCmdCharacteristic->setCallbacks(new MyCallbacks());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  
  // 初始化引脚
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  ledcSetup(0, 5000, 8);
  ledcAttachPin(LED_PIN, 0);
}

void loop() {
  if (deviceConnected) {
    sendSensorData();
    delay(5000);  // 每5秒上传一次
  }
}
```

---

## 自动控制逻辑

### 自动灌溉

硬件可实现自动灌溉逻辑：

```cpp
void autoIrrigation() {
  if (autoMode) {
    int soilMoisture = map(analogRead(SOIL_PIN), 0, 4095, 0, 100);
    
    if (soilMoisture < targetMoisture - 5) {
      digitalWrite(PUMP_PIN, HIGH);  // 开启灌溉
    } else if (soilMoisture >= targetMoisture) {
      digitalWrite(PUMP_PIN, LOW);   // 关闭灌溉
    }
  }
}
```

### 自动补光

```cpp
void autoLight() {
  if (autoLightMode) {
    int lightLevel = map(analogRead(LIGHT_PIN), 0, 4095, 0, 1000);
    
    if (lightLevel < 200) {
      digitalWrite(LED_PIN, HIGH);   // 开启补光
    } else if (lightLevel > 800) {
      digitalWrite(LED_PIN, LOW);    // 关闭补光
    }
  }
}
```

---

## 传感器推荐

| 传感器 | 型号 | 接口 | 说明 |
|--------|------|------|------|
| 温湿度 | DHT22 / AHT10 | I2C/单总线 | 精度±0.5°C |
| 土壤湿度 | 电容式土壤传感器 | ADC | 防腐蚀设计 |
| 光照 | BH1750 | I2C | 精度高 |
| CO2 | MH-Z19C | UART | 红外NDIR |
| 水位 | 超声波HC-SR04 | GPIO | 非接触式 |

---

## 执行器规格

| 执行器 | 规格 | 控制方式 |
|--------|------|----------|
| 水泵 | 12V 直流泵 | 继电器/MOSFET |
| LED补光灯 | 12V LED灯带 | PWM调光 |
| 电磁阀 | 12V 电磁阀 | 继电器 |

---

## 通信流程图

```
┌─────────────────────────────────────────────────────────────┐
│                        硬件设备                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                 │
│  │ 传感器  │───▶│  ESP32  │───▶│   BLE   │───┐             │
│  └─────────┘    └─────────┘    └─────────┘   │             │
│       ▲              │                        │             │
│       │              ▼                        │             │
│  ┌─────────┐    ┌─────────┐                  │             │
│  │ 执行器  │◀───│ 控制逻辑 │                  │             │
│  └─────────┘    └─────────┘                  │             │
│                                              │             │
└──────────────────────────────────────────────│─────────────┘
                                               │
                                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         APP                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                 │
│  │   BLE   │───▶│BleService│───▶│DataManager│               │
│  └─────────┘    └─────────┘    └─────────┘                 │
│       ▲              │                        │             │
│       │              ▼                        ▼             │
│       │         ┌─────────┐            ┌─────────┐         │
│       └─────────│ 控制命令 │◀───────────│   UI    │         │
│                 └─────────┘            └─────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 测试建议

### 1. 蓝牙连接测试

- 使用 nRF Connect 或 LightBlue 扫描设备
- 验证广播名称和服务UUID
- 测试连接稳定性

### 2. 数据上传测试

- 连接后观察数据是否正常上传
- 检查JSON格式是否正确
- 验证各传感器数值范围

### 3. 命令响应测试

- 发送控制命令
- 观察执行器响应
- 检查返回状态

---

## 常见问题

### Q1: 蓝牙连接不稳定

- 检查供电是否稳定
- 确认天线连接正常
- 减少周围干扰源

### Q2: 数据上传延迟

- 检查BLE MTU设置
- 优化数据包大小
- 调整上传频率

### Q3: 命令无响应

- 确认特征值权限设置正确
- 检查JSON解析逻辑
- 查看串口调试输出
