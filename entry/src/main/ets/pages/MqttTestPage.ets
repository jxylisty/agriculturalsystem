import { router } from '@kit.ArkUI';
import { mqttService, MqttConfig } from '../services/MqttService';
import { SensorData } from '../services/BleService';

@Entry
@Component
struct MqttTestPage {
  @State isConnected: boolean = false;
  @State connectionStatus: string = '未连接';
  @State latestData: SensorData | null = null;
  @State productId: string = 'bvEMtNm7tH';
  @State deviceName: string = 'jiaoxue';
  @State deviceKey: string = 'ckg5NGxRakJjT2RRWmh1TWxzMlFzTEU3V3BVeXFvR1Q=';

  aboutToAppear(): void {
    mqttService.onConnectionChange((connected: boolean) => {
      this.isConnected = connected;
      this.connectionStatus = connected ? '已连接' : '已断开';
    });

    mqttService.onSensorData((data: SensorData) => {
      this.latestData = data;
    });
  }

  async connectToMqtt(): Promise<void> {
    if (!this.productId || !this.deviceName || !this.deviceKey) {
      this.connectionStatus = '请填写完整配置';
      return;
    }

    const config: MqttConfig = {
      brokerUrl: 'mqtts.heclouds.com',
      port: 1883,
      clientId: 'harmony-app-' + Date.now(),
      productId: this.productId,
      deviceName: this.deviceName,
      deviceKey: this.deviceKey
    };

    mqttService.setConfig(config);
    this.connectionStatus = '连接中...';
    
    const success = await mqttService.connect();
    if (success) {
      this.connectionStatus = '已连接';
    } else {
      this.connectionStatus = '连接失败';
    }
  }

  async disconnectFromMqtt(): Promise<void> {
    await mqttService.disconnect();
    this.connectionStatus = '已断开';
    this.latestData = null;
  }

  build() {
    Scroll() {
      Column() {
        Text('OneNet MQTT 测试')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 });

        Text('中国移动物联网平台连接测试')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 20 });

        this.ConnectionSection();
        
        Divider().margin({ top: 20, bottom: 20 });

        if (this.isConnected) {
          this.DataSection();
          
          Divider().margin({ top: 20, bottom: 20 });
          
          this.CommandSection();
        }

        Divider().margin({ top: 20, bottom: 20 });

        Button('返回首页')
          .width('100%')
          .onClick(() => {
            router.back();
          });
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  @Builder
  ConnectionSection() {
    Column() {
      Text('OneNet 配置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      Row() {
        Text('产品ID: ')
          .width(80);
        TextInput({ text: this.productId, placeholder: '请输入产品ID' })
          .width('70%')
          .onChange((value: string) => {
            this.productId = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('设备名称: ')
          .width(80);
        TextInput({ text: this.deviceName, placeholder: '请输入设备名称' })
          .width('70%')
          .onChange((value: string) => {
            this.deviceName = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('设备Key: ')
          .width(80);
        TextInput({ text: this.deviceKey, placeholder: '请输入设备Key' })
          .width('70%')
          .type(InputType.Password)
          .onChange((value: string) => {
            this.deviceKey = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('服务器: ')
          .width(80);
        Text('mqtts.heclouds.com:1883')
          .fontColor('#666666');
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('状态: ')
          .width(80);
        Text(this.connectionStatus)
          .fontColor(this.isConnected ? '#4CAF50' : '#F44336');
      }
      .width('100%')
      .margin({ bottom: 15 });

      Row() {
        Button('连接')
          .width('45%')
          .enabled(!this.isConnected)
          .onClick(() => {
            this.connectToMqtt();
          });

        Blank().width('10%');

        Button('断开')
          .width('45%')
          .enabled(this.isConnected)
          .backgroundColor('#F44336')
          .onClick(() => {
            this.disconnectFromMqtt();
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10);
  }

  @Builder
  DataSection() {
    Column() {
      Text('传感器数据')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      if (this.latestData) {
        this.DataItem('温度', `${this.latestData.temperature.toFixed(1)} °C`);
        this.DataItem('湿度', `${this.latestData.humidity.toFixed(1)} %`);
        this.DataItem('土壤湿度', `${this.latestData.soilMoisture} %`);
        this.DataItem('光照强度', `${this.latestData.lightLevel} lux`);
        this.DataItem('水位', `${this.latestData.waterLevel} %`);
        this.DataItem('CO2', `${this.latestData.co2} ppm`);
      } else {
        Text('等待数据...')
          .fontColor('#999999');
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10);
  }

  @Builder
  DataItem(label: string, value: string) {
    Row() {
      Text(label)
        .width('40%');
      Text(value)
        .width('60%')
        .textAlign(TextAlign.End);
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 });
  }

  @Builder
  CommandSection() {
    Column() {
      Text('控制命令测试')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      Row() {
        Button('开启灌溉')
          .width('45%')
          .onClick(() => {
            mqttService.publishIrrigationCommand(true);
          });

        Blank().width('10%');

        Button('关闭灌溉')
          .width('45%')
          .backgroundColor('#F44336')
          .onClick(() => {
            mqttService.publishIrrigationCommand(false);
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Button('开启灯光')
          .width('45%')
          .onClick(() => {
            mqttService.publishLightCommand(true);
          });

        Blank().width('10%');

        Button('关闭灯光')
          .width('45%')
          .backgroundColor('#F44336')
          .onClick(() => {
            mqttService.publishLightCommand(false);
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10);
  }
}
