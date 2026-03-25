# ESP32 MQTT 智慧农业系统

## 与蓝牙版本的区别

| 特性 | 蓝牙版本 | MQTT版本 |
|------|----------|----------|
| 通信方式 | BLE 蓝牙 | WiFi + MQTT |
| 连接距离 | 10-100米 | 任意距离（需网络） |
| 需要服务器 | 否 | 是（MQTT Broker） |
| 多设备支持 | 单设备 | 多设备 |
| 数据存储 | 无 | 可存储到云端 |

## 硬件要求

与蓝牙版本相同，参见 `../esp32_smart_agriculture/README.md`

## 额外要求

- WiFi 网络（2.4GHz）
- MQTT Broker（公共服务器或自建）

## 配置说明

打开 `esp32_mqtt_agriculture.ino`，修改以下配置：

```cpp
const char* ssid = "YOUR_WIFI_SSID";        // WiFi名称
const char* password = "YOUR_WIFI_PASSWORD"; // WiFi密码
```

## MQTT 服务器选项

### 选项1：公共服务器（免费，推荐测试）

代码默认使用 `broker.emqx.io`，无需修改。

### 选项2：自建服务器

修改以下配置：

```cpp
const char* mqtt_server = "你的服务器IP";
const int mqtt_port = 1883;
```

## Topic 说明

| Topic | 方向 | 说明 |
|-------|------|------|
| `agriculture/sensor/data` | ESP32 → APP | 传感器数据 |
| `agriculture/cmd` | APP → ESP32 | 控制命令 |

## 数据格式

### 传感器数据（ESP32 发布）

```json
{
  "temperature": 25.5,
  "humidity": 65,
  "soilMoisture": 45,
  "lightLevel": 300,
  "waterLevel": 75,
  "co2": 450,
  "timestamp": 1234567890
}
```

### 控制命令（APP 发送）

```json
{
  "cmd": "irrigation",
  "value": 1
}
```

支持的命令：

| cmd | value | 说明 |
|-----|-------|------|
| irrigation | 0/1 | 灌溉开关 |
| light | 0/1 | 灯光开关 |
| brightness | 0-100 | 灯光亮度 |
| target_moisture | 20-80 | 目标湿度 |

## 上传步骤

1. 安装 Arduino IDE 和 ESP32 开发板支持
2. 安装依赖库：
   - `PubSubClient` by Nick O'Leary
   - `ArduinoJson` by Benoit Blanchon
   - `DHT sensor library` by Adafruit
3. 选择开发板：ESP32 Dev Module
4. 修改 WiFi 配置
5. 上传代码

## 测试方法

### 使用 MQTT 工具测试

1. 下载 MQTT 客户端工具（如 MQTTX）
2. 连接到 `broker.emqx.io:1883`
3. 订阅 `agriculture/sensor/data` 查看数据
4. 发布到 `agriculture/cmd` 发送命令

### 命令行测试

```bash
# 订阅传感器数据
mosquitto_sub -h broker.emqx.io -t "agriculture/sensor/data"

# 发送控制命令
mosquitto_pub -h broker.emqx.io -t "agriculture/cmd" -m '{"cmd":"irrigation","value":1}'
```

## 常见问题

### WiFi 连接失败
- 检查 WiFi 名称和密码
- 确认是 2.4GHz 网络（ESP32 不支持 5GHz）
- 检查 WiFi 信号强度

### MQTT 连接失败
- 检查网络是否正常
- 尝试其他公共服务器
- 检查防火墙设置

### 数据不上传
- 检查串口输出是否有错误
- 确认 Topic 订阅正确
- 检查 JSON 格式

## 文件说明

```
esp32_mqtt_agriculture/
├── esp32_mqtt_agriculture.ino  # MQTT版本代码
└── README.md                    # 本文档
```
