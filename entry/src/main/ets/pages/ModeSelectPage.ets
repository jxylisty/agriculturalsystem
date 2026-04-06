import { router } from '@kit.ArkUI';
import { connectionModeManager, ConnectionMode, ConnectionStatus } from '../services/ConnectionModeManager';
import { MqttConfig } from '../services/MqttService';
import { bleService, BleDevice } from '../services/BleService';

@Entry
@Component
struct ModeSelectPage {
  @State currentMode: ConnectionMode = 'local';
  @State connected: boolean = false;
  @State statusMessage: string = '本地模拟模式';
  @State showBluetoothScan: boolean = false;
  @State showMqttConfig: boolean = false;
  @State isScanning: boolean = false;
  @State deviceList: BleDevice[] = [];
  @State connectedDevice: BleDevice | null = null;
  @State productId: string = 'bvEMtNm7tH';
  @State deviceName: string = 'jiaoxue';
  @State deviceKey: string = 'ckg5NGxRakJjT2RRWmh1TWxzMlFzTEU3V3BVeXFvR1Q=';
  @State oneNetToken: string = 'version=2018-10-31&res=products%2FbvEMtNm7tH%2Fdevices%2Fjiaoxue&et=1806672609&method=md5&sign=XXPKQJRiLBke0PFSPY%2BQGg%3D%3D';

  aboutToAppear(): void {
    this.currentMode = connectionModeManager.getCurrentMode();
    this.updateStatus(connectionModeManager.getStatus());

    connectionModeManager.onStatusChange((status: ConnectionStatus) => {
      this.updateStatus(status);
    });
  }

  private updateStatus(status: ConnectionStatus): void {
    this.currentMode = status.mode;
    this.connected = status.connected;
    this.statusMessage = status.message;
  }

  async selectMode(mode: ConnectionMode): Promise<void> {
    if (mode === 'local') {
      connectionModeManager.setMode('local');
      this.showMqttConfig = false;
      this.showBluetoothScan = false;
    } else if (mode === 'bluetooth') {
      connectionModeManager.setMode('bluetooth');
      this.showMqttConfig = false;
      this.showBluetoothScan = true;
      this.connected = bleService.getConnectionStatus();
      if (this.connected) {
        const deviceId = bleService.getConnectedDeviceId();
        if (deviceId) {
          this.connectedDevice = {
            deviceId: deviceId,
            deviceName: '已连接设备',
            rssi: 0
          };
        }
      }
    } else if (mode === 'mqtt') {
      connectionModeManager.setMode('mqtt');
      this.showMqttConfig = true;
      this.showBluetoothScan = false;
    }
  }

  async connectMqtt(): Promise<void> {
    if (!this.productId || !this.deviceName) {
      this.statusMessage = '请填写产品ID和设备名称';
      return;
    }

    if (!this.oneNetToken && !this.deviceKey) {
      this.statusMessage = '请填写Token或设备Key';
      return;
    }

    const config: MqttConfig = {
      brokerUrl: 'mqtts.heclouds.com',
      port: 1883,
      clientId: 'harmony-app-' + Date.now(),
      productId: this.productId,
      deviceName: this.deviceName,
      deviceKey: this.deviceKey,
      token: this.oneNetToken
    };

    console.log('[ModeSelectPage] Starting OneNet connection...');
    const success = await connectionModeManager.connectMqtt(config);
    console.log('[ModeSelectPage] Connection result:', success);
    
    if (success) {
      this.showMqttConfig = false;
      this.connected = true;
      this.statusMessage = 'OneNet 已连接';
      setTimeout(() => {
        router.back();
      }, 500);
    } else {
      this.statusMessage = 'OneNet连接失败，请检查配置';
    }
  }

  async scanDevices(): Promise<void> {
    this.isScanning = true;
    this.deviceList = [];

    const success = await bleService.startScan((devices: BleDevice[]) => {
      this.deviceList = devices;
    });

    if (!success) {
      console.error('Failed to start BLE scan');
    }

    setTimeout(async () => {
      await bleService.stopScan();
      this.isScanning = false;
    }, 5000);
  }

  async connectDevice(device: BleDevice): Promise<void> {
    const success = await bleService.connect(device.deviceId);
    if (success) {
      this.connectedDevice = device;
      this.connected = true;
    }
  }

  async disconnectDevice(): Promise<void> {
    await bleService.disconnect();
    this.connectedDevice = null;
    this.connected = false;
    this.deviceList = [];
  }

  build() {
    Scroll() {
      Column() {
        Text('连接模式选择')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 });

        Text('选择设备连接方式')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 20 });

        this.StatusCard();

        Divider().margin({ top: 20, bottom: 20 });

        this.ModeButtons();

        if (this.showBluetoothScan) {
          Divider().margin({ top: 20, bottom: 20 });
          this.BluetoothScanSection();
        }

        if (this.showMqttConfig) {
          Divider().margin({ top: 20, bottom: 20 });
          this.MqttConfigSection();
        }

        Divider().margin({ top: 20, bottom: 20 });

        Button('返回首页')
          .width('100%')
          .backgroundColor('#388E3C')
          .onClick(() => {
            router.back();
          });
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#4CAF50');
  }

  @Builder
  StatusCard() {
    Column() {
      Row() {
        Text('当前状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);

        Blank();

        Text(this.connected ? '已连接' : '未连接')
          .fontSize(14)
          .fontColor(this.connected ? '#4CAF50' : '#F44336');
      }
      .width('100%')
      .margin({ bottom: 10 });

      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#666666');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#E8F5E9')
    .borderRadius(10);
  }

  @Builder
  ModeButtons() {
    Column() {
      Text('选择连接模式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      this.ModeButton('本地模拟', 'local', '使用模拟数据，无需硬件', '#9E9E9E');

      this.ModeButton('蓝牙连接', 'bluetooth', '近距离直连，10-100米', '#2196F3');

      this.ModeButton('云服务 (OneNet)', 'mqtt', '远程连接，需要网络', '#4CAF50');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#E8F5E9')
    .borderRadius(10);
  }

  @Builder
  ModeButton(title: string, mode: ConnectionMode, desc: string, color: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);

        Text(desc)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      if (this.currentMode === mode) {
        Text('当前')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(color)
          .borderRadius(4);
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.currentMode === mode ? '#C8E6C9' : '#E8F5E9')
    .borderRadius(8)
    .border({ width: 1, color: this.currentMode === mode ? color : '#BDBDBD' })
    .margin({ bottom: 10 })
    .onClick(() => {
      this.selectMode(mode);
    });
  }

  @Builder
  BluetoothScanSection() {
    Column() {
      Row() {
        Text('蓝牙设备')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);

        Blank();

        if (this.connected && this.connectedDevice) {
          Text('已连接: ' + this.connectedDevice.deviceName)
            .fontSize(12)
            .fontColor('#4CAF50');
        }
      }
      .width('100%')
      .margin({ bottom: 15 });

      if (this.connected && this.connectedDevice) {
        Row() {
          Text(`设备ID: ${this.connectedDevice.deviceId}`)
            .fontSize(12)
            .fontColor('#888888');

          Blank();

          Button('断开')
            .fontSize(12)
            .height(28)
            .backgroundColor('#F44336')
            .onClick(() => {
              this.disconnectDevice();
            });
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#C8E6C9')
        .borderRadius(8)
        .margin({ bottom: 15 });
      }

      Row() {
        Text('设备列表')
          .fontSize(14)
          .fontColor('#666666');

        Blank();

        if (this.isScanning) {
          LoadingProgress()
            .width(16)
            .height(16);
          Text('扫描中...')
            .fontSize(12)
            .fontColor('#888888')
            .margin({ left: 5 });
        }
      }
      .width('100%')
      .margin({ bottom: 10 });

      if (this.deviceList.length === 0 && !this.isScanning) {
        Text('暂无设备，请点击扫描')
          .fontSize(14)
          .fontColor('#888888')
          .margin({ top: 10, bottom: 10 });
      }

      Column({ space: 8 }) {
        ForEach(this.deviceList, (device: BleDevice, index: number) => {
          Row() {
            Column() {
              Text(device.deviceName)
                .fontSize(14)
                .fontWeight(FontWeight.Medium);
              Text(device.deviceId)
                .fontSize(10)
                .fontColor('#888888')
                .margin({ top: 2 });
            }
            .alignItems(HorizontalAlign.Start);

            Blank();

            if (this.connectedDevice && this.connectedDevice.deviceId === device.deviceId) {
              Text('已连接')
                .fontSize(12)
                .fontColor('#4CAF50');
            } else {
              Button('连接')
                .fontSize(12)
                .height(28)
                .backgroundColor('#2196F3')
                .onClick(() => {
                  this.connectDevice(device);
                });
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#C8E6C9')
          .borderRadius(8);
        });
      }
      .width('100%')
      .margin({ bottom: 15 });

      Button(this.isScanning ? '扫描中...' : '扫描设备')
        .width('100%')
        .backgroundColor(this.isScanning ? '#CCCCCC' : '#2196F3')
        .enabled(!this.isScanning)
        .onClick(() => {
          this.scanDevices();
        });
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#E8F5E9')
    .borderRadius(10);
  }

  @Builder
  MqttConfigSection() {
    Column() {
      Text('OneNet 平台配置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 10 });

      Text('使用 HTTP API 连接 OneNet 平台')
        .fontSize(12)
        .fontColor('#888888')
        .margin({ bottom: 15 });

      Row() {
        Text('产品ID')
          .width(70);
        TextInput({ text: this.productId, placeholder: '请输入产品ID' })
          .width('65%')
          .onChange((value: string) => {
            this.productId = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('设备名称')
          .width(70);
        TextInput({ text: this.deviceName, placeholder: '请输入设备名称' })
          .width('65%')
          .onChange((value: string) => {
            this.deviceName = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('Token')
          .width(70);
        TextInput({ text: this.oneNetToken, placeholder: '可选：从控制台生成' })
          .width('65%')
          .onChange((value: string) => {
            this.oneNetToken = value;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Text('提示：可在 OneNet 控制台 -> 设备详情 -> Token生成器 生成Token')
        .fontSize(10)
        .fontColor('#999999')
        .margin({ bottom: 10 });

      Row() {
        Text('设备Key')
          .width(70);
        TextInput({ text: this.deviceKey, placeholder: '可选：如果没有Token' })
          .width('65%')
          .type(InputType.Password)
          .onChange((value: string) => {
            this.deviceKey = value;
          });
      }
      .width('100%')
      .margin({ bottom: 15 });

      Button('连接 OneNet')
        .width('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.connectMqtt();
        });
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#E8F5E9')
    .borderRadius(10);
  }
}
