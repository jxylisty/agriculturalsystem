# MQTT 云服务模式使用指南

## 概述

MQTT 模式是独立于蓝牙模式的另一种通信方式，通过云服务器中转数据，实现远程控制。本项目已适配中国移动物联网平台（OneNet）。

## 架构说明

```
┌─────────────┐      WiFi      ┌─────────────┐      网络      ┌─────────────┐
│   ESP32     │ ─────────────▶ │   OneNet    │ ◀───────────── │  手机 APP   │
│  (硬件端)   │                │  (云平台)   │                │  (远程端)   │
└─────────────┘                └─────────────┘                └─────────────┘
```

## OneNet 平台配置

### 第一步：创建产品和设备

1. 登录 [OneNet 控制台](https://open.iot.10086.cn/)
2. 创建产品，选择"物联使能" -> "MQTT"
3. 创建设备，记录以下信息：
   - **产品ID** (Product ID)
   - **设备名称** (Device Name)
   - **设备Key** (Device Key)

### 第二步：配置 ESP32

1. 打开 `hardware/esp32_mqtt_agriculture/esp32_mqtt_agriculture.ino`
2. 修改配置：
   ```cpp
   const char* ssid = "你的WiFi名称";
   const char* password = "你的WiFi密码";
   
   // OneNet 配置
   const char* product_id = "你的产品ID";
   const char* device_name = "你的设备名称";
   const char* device_key = "你的设备Key";
   ```
3. 上传代码到 ESP32

### 第三步：配置 APP

1. 运行 APP，进入 MQTT 测试页面
2. 选择"OneNet平台"模式
3. 输入产品ID、设备名称、设备Key
4. 点击"连接"按钮

## 文件结构

```
项目目录/
├── hardware/
│   ├── esp32_smart_agriculture/    # 蓝牙版本（原有）
│   │   ├── esp32_smart_agriculture.ino
│   │   └── README.md
│   └── esp32_mqtt_agriculture/     # MQTT版本（OneNet适配）
│       ├── esp32_mqtt_agriculture.ino
│       └── README.md
│
├── entry/src/main/ets/
│   ├── services/
│   │   ├── BleService.ets          # 蓝牙服务（原有）
│   │   ├── DataManager.ets         # 数据管理（原有）
│   │   └── MqttService.ets         # MQTT服务（OneNet适配）
│   └── pages/
│       ├── Index.ets               # 首页（原有）
│       └── MqttTestPage.ets        # MQTT测试页（OneNet配置）
│
└── docs/
    └── MQTT_GUIDE.md               # 本文档
```

## 快速开始

### 第一步：配置 ESP32

1. 打开 `hardware/esp32_mqtt_agriculture/esp32_mqtt_agriculture.ino`
2. 修改 WiFi 配置：
   ```cpp
   const char* ssid = "你的WiFi名称";
   const char* password = "你的WiFi密码";
   ```
3. 上传代码到 ESP32

### 第二步：测试 MQTT 连接

1. 打开 DevEco Studio
2. 运行 APP
3. 进入 MQTT 测试页面（从首页跳转或直接访问）
4. 点击"连接"按钮
5. 观察数据是否正常接收

### 第三步：测试控制命令

1. 在 MQTT 测试页面点击"开启灌溉"
2. 观察 ESP32 串口输出
3. 确认继电器动作

## MqttService API

### 初始化

```typescript
import { mqttService, MqttConfig } from '../services/MqttService';

// OneNet 配置
const config: MqttConfig = {
  brokerUrl: 'mqtts.heclouds.com',
  port: 1883,
  clientId: 'harmony-app',
  productId: '你的产品ID',
  deviceName: '你的设备名称',
  deviceKey: '你的设备Key'
};
mqttService.setConfig(config);
```

### 连接/断开

```typescript
// 连接
await mqttService.connect();

// 断开
await mqttService.disconnect();

// 检查连接状态
const connected = mqttService.isConnected();
```

### 接收数据

```typescript
// 设置数据回调
mqttService.onSensorData((data: SensorData) => {
  console.log('温度:', data.temperature);
  console.log('湿度:', data.humidity);
  // ... 其他数据
});

// 获取最新数据
const latestData = mqttService.getLatestData();
```

### 发送命令

```typescript
// 灌溉控制
mqttService.publishIrrigationCommand(true);  // 开启
mqttService.publishIrrigationCommand(false); // 关闭

// 灯光控制
mqttService.publishLightCommand(true);  // 开启
mqttService.publishLightCommand(false); // 关闭

// 亮度设置
mqttService.publishBrightnessCommand(80);  // 80%

// 目标湿度设置
mqttService.publishTargetMoistureCommand(60);  // 60%
```

### 连接状态监听

```typescript
mqttService.onConnectionChange((connected: boolean) => {
  if (connected) {
    console.log('MQTT 已连接');
  } else {
    console.log('MQTT 已断开');
  }
});
```

## OneNet 数据格式

### 上报数据格式

```json
{
  "params": {
    "temperature": 25.5,
    "humidity": 65,
    "soilMoisture": 45,
    "lightLevel": 300,
    "waterLevel": 75,
    "co2": 450
  }
}
```

### 控制命令格式

```json
{
  "cmd": "irrigation",
  "value": 1,
  "timestamp": 1700000000000
}
```

## 与蓝牙模式的切换

### 方案一：独立使用

蓝牙模式和 MQTT 模式完全独立，分别使用不同的页面和服务。

### 方案二：统一入口（需要修改 DataManager）

在 DataManager 中添加模式切换：

```typescript
// DataManager.ets 中添加
export class DataManager {
  private connectionMode: 'bluetooth' | 'mqtt' = 'bluetooth';

  setConnectionMode(mode: 'bluetooth' | 'mqtt'): void {
    this.connectionMode = mode;
  }

  async getSensorData(): Promise<SensorData> {
    if (this.connectionMode === 'mqtt') {
      return mqttService.getLatestData() || this.getMockData();
    } else {
      return bleService.getSensorData() || this.getMockData();
    }
  }
}
```

## 注意事项

1. **网络依赖**：MQTT 模式需要设备连接网络
2. **延迟**：相比蓝牙直连，MQTT 有网络延迟
3. **OneNet 认证**：需要正确配置产品ID、设备名称和设备Key
4. **Token 生成**：系统会自动生成 OneNet 认证 Token

## 常见问题

### Q: 连接失败怎么办？

A: 检查以下几点：
- WiFi 是否正常
- OneNet 产品ID、设备名称、设备Key是否正确
- 设备是否已在 OneNet 平台创建
- 网络是否允许访问外网

### Q: 收不到数据？

A: 检查：
- ESP32 是否正常上传数据（查看串口输出）
- 设备是否已连接到 OneNet 平台
- 数据格式是否符合 OneNet 要求

### Q: 命令发送后无响应？

A: 检查：
- ESP32 是否正常接收命令（查看串口输出）
- 命令格式是否正确
- 主题订阅是否正确

## 相关文档

- [硬件接线说明](../hardware/esp32_mqtt_agriculture/README.md)
- [UI组接口文档](./UI_INTERFACE.md)
- [硬件组接口文档](./HARDWARE_INTERFACE.md)
