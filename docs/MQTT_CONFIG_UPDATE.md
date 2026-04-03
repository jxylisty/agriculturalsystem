# MQTT配置更新说明

## 更新概述

本项目已根据需求更新MQTT配置，将主题从 `agriculture/sensor/data` 改为 `/hi3861/temperature`，并简化了消息格式以适配Hi3861设备。

## 修改内容

### 1. HarmonyOS APP端修改

**文件：** `entry/src/main/ets/services/MqttService.ets`

**主要变更：**
- 修改数据主题：`agriculture/sensor/data` → `/hi3861/temperature`
- 简化消息处理逻辑，只解析温度和timestamp字段
- 保持其他功能（命令处理、连接管理等）不变

**关键代码：**
```typescript
private dataTopic: string = '/hi3861/temperature';

// 简化消息处理
private processSensorData(text: string): void {
  const data: SensorMessage = JSON.parse(text) as SensorMessage;
  
  const sensorData: SensorData = {
    temperature: data.temperature ?? this.latestData?.temperature ?? 25,
    humidity: this.latestData?.humidity ?? 60,
    soilMoisture: this.latestData?.soilMoisture ?? 50,
    lightLevel: this.latestData?.lightLevel ?? 500,
    waterLevel: this.latestData?.waterLevel ?? 80,
    co2: this.latestData?.co2 ?? 400,
    timestamp: data.timestamp ?? Date.now()
  };
}
```

### 2. 硬件端修改

**文件：** `hardware/esp32_mqtt_agriculture/esp32_mqtt_agriculture.ino`

**主要变更：**
- 修改发布主题：`agriculture/sensor/data` → `/hi3861/temperature`
- 简化消息格式，只包含温度和timestamp
- 保持传感器读取和控制功能不变

**关键代码：**
```cpp
const char* topic_data = "/hi3861/temperature";

void publishSensorData() {
  // 简化的消息格式，只包含温度和timestamp
  StaticJsonDocument<128> doc;
  doc["temperature"] = sensorData.temperature;
  doc["timestamp"] = sensorData.timestamp;
  
  char jsonBuffer[128];
  serializeJson(doc, jsonBuffer);
  
  mqttClient.publish(topic_data, jsonBuffer);
}
```

### 3. 新增Hi3861专用示例

**文件：** `hardware/hi3861_temperature_sensor/hi3861_temperature_sensor.ino`

**特点：**
- 专为Hi3861设备设计的简化版本
- 只读取和发送温度数据
- 使用要求的主题和消息格式

### 4. 文档更新

**文件：** `docs/HARDWARE_INTERFACE.md`

**更新内容：**
- 更新MQTT主题说明
- 添加Hi3861简化格式说明

## 技术规格

### 当前MQTT配置

| 配置项 | 新值 | 说明 |
|--------|------|------|
| 数据主题 | `/hi3861/temperature` | 接收温度数据 |
| 命令主题 | `agriculture/cmd` | 发送控制命令（保持不变） |
| 消息格式 | `{"temperature":25.5,"timestamp":1234567890}` | 简化的JSON格式 |

### 消息格式对比

**修改前（完整格式）：**
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

**修改后（简化格式）：**
```json
{
  "temperature": 25.5,
  "timestamp": 1234567890
}
```

## 兼容性说明

### 向后兼容性
- 修改后的APP仍能处理完整格式的消息（如果硬件发送完整数据）
- 其他传感器数据将使用上一次的值或默认值
- 控制命令功能完全保持兼容

### 硬件兼容性
- **ESP32设备**：使用修改后的代码，发送简化格式
- **Hi3861设备**：使用专用示例代码，专为温度传感器设计
- **其他设备**：需要适配新的主题和消息格式

## 部署说明

### 1. APP端部署
- 无需额外配置，代码已自动更新
- 重新编译HarmonyOS应用即可

### 2. 硬件端部署
- **ESP32设备**：上传修改后的 `esp32_mqtt_agriculture.ino`
- **Hi3861设备**：上传新的 `hi3861_temperature_sensor.ino`
- 修改WiFi配置和MQTT服务器地址

### 3. 测试验证
1. 启动硬件设备，确认连接到MQTT服务器
2. 启动HarmonyOS APP，连接到同一MQTT服务器
3. 验证温度数据是否正确接收和显示
4. 测试控制命令功能是否正常

## 故障排除

### 常见问题

**Q1: APP收不到数据**
- 确认硬件设备已连接到MQTT服务器
- 检查主题是否正确：`/hi3861/temperature`
- 验证消息格式是否符合要求

**Q2: 温度显示异常**
- 检查硬件温度传感器是否正常工作
- 确认消息中的temperature字段为数字类型
- 查看串口输出调试信息

**Q3: 控制命令不响应**
- 确认命令主题未修改：`agriculture/cmd`
- 检查硬件设备是否正确订阅命令主题
- 验证命令消息格式

### 调试建议

1. **启用调试日志**：查看APP和硬件的串口输出
2. **使用MQTT客户端工具**：如MQTT.fx验证消息收发
3. **分步测试**：先测试基础连接，再测试数据传输

## 后续扩展

如需支持更多Hi3861设备或添加新功能，可考虑：

1. **动态主题配置**：允许运行时修改主题
2. **多设备支持**：支持多种主题和设备类型
3. **协议版本控制**：支持新旧协议格式共存
4. **设备发现机制**：自动识别和配置新设备

## 联系支持

如有问题或需要进一步修改，请联系开发团队。

---

**版本：** v1.0  
**更新日期：** 2024年  
**修改人：** HarmonyOS开发助手