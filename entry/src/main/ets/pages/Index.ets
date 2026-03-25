import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';
import { AppStorageUtil } from '../services/AppStorageUtil';

@Entry
@Component
struct Index {
  @StorageLink('is_connected') isConnected: boolean = false;
  @StorageLink('mode_status') modeStatus: string = '本地模拟模式';
  @State sensorData: SensorDataModel = sensorDataModel;

  private refreshTimer: number = -1;

  aboutToAppear(): void {
    console.log('[Index] aboutToAppear, isConnected=' + this.isConnected);
  }

  aboutToDisappear(): void {
    this.stopPolling();
  }

  onPageShow(): void {
    this.refreshStatus();
  }

  private startPolling(): void {
    this.refreshTimer = setInterval(() => {
      this.refreshStatus();
    }, 5000);
    console.log('[Index] Polling started');
  }

  private stopPolling(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  private refreshStatus(): void {
    this.isConnected = AppStorageUtil.isConnected();
    this.modeStatus = AppStorageUtil.getModeStatus();
  }

  build() {
    Scroll() {
      Column() {
        Text('智慧农业控制中心')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40, bottom: 20 });

        Row() {
          Text('当前模式: ')
            .fontSize(16);
          Text(this.modeStatus)
            .fontSize(16)
            .fontColor(this.isConnected ? '#4CAF50' : '#FF9800');
        }
        .margin({ bottom: 15 });

        if (!this.isConnected) {
          Column() {
            Row() {
              Text('⚠️ 当前为模拟数据模式')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FF9800');
            }
            .width('100%');
            Text('点击下方"连接模式"切换到云服务')
              .fontSize(12)
              .fontColor('#888888')
              .width('100%')
              .margin({ top: 5 });
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#FFF8E1')
          .borderRadius(10)
          .margin({ bottom: 20 });
        } else {
          Column() {
            Row() {
              Text('✓ 已连接到云服务')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#4CAF50');
            }
            .width('100%');
            Text('实时接收传感器数据')
              .fontSize(12)
              .fontColor('#888888')
              .width('100%')
              .margin({ top: 5 });
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10)
          .margin({ bottom: 20 });
        }

        Column({ space: 15 }) {
          Row() {
            Column() {
              Text('智能灌溉')
                .fontSize(18)
                .fontWeight(FontWeight.Medium);
              Text('控制水阀灌溉')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 5 });
            }
            .alignItems(HorizontalAlign.Start);
            Blank();
            Text('>').fontSize(20).fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => { router.pushUrl({ url: 'pages/IrrigationPage' }); });

          Row() {
            Column() {
              Text('智能补光')
                .fontSize(18)
                .fontWeight(FontWeight.Medium);
              Text('控制植物补光')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 5 });
            }
            .alignItems(HorizontalAlign.Start);
            Blank();
            Text('>').fontSize(20).fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => { router.pushUrl({ url: 'pages/LightPage' }); });

          Row() {
            Column() {
              Text('阈值预警')
                .fontSize(18)
                .fontWeight(FontWeight.Medium);
              Text('设置预警参数')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 5 });
            }
            .alignItems(HorizontalAlign.Start);
            Blank();
            Text('>').fontSize(20).fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => { router.pushUrl({ url: 'pages/AlertPage' }); });

          Row() {
            Column() {
              Text('连接模式')
                .fontSize(18)
                .fontWeight(FontWeight.Medium);
              Text('切换蓝牙/云服务')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 5 });
            }
            .alignItems(HorizontalAlign.Start);
            Blank();
            Text('>').fontSize(20).fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => { router.pushUrl({ url: 'pages/ModeSelectPage' }); });

          Row() {
            Column() {
              Text('环境数据查询')
                .fontSize(18)
                .fontWeight(FontWeight.Medium);
              Text('查看详细环境数据')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 5 });
            }
            .alignItems(HorizontalAlign.Start);
            Blank();
            Text('>').fontSize(20).fontColor('#CCCCCC');
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => { router.pushUrl({ url: 'pages/DataPage' }); })
          .margin({ top: 20, bottom: 30 });
        }
        .width('90%')
        .margin({ top: 20 });
      }
      .width('100%')
      .backgroundColor('#F5F5F5');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Auto);
  }
}
