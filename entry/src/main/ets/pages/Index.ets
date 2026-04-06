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

  aboutToAppear(): void {
    console.log('[Index] aboutToAppear, isConnected=' + this.isConnected);
  }

  onPageShow(): void {
    this.isConnected = AppStorageUtil.isConnected();
    this.modeStatus = AppStorageUtil.getModeStatus();
  }

  build() {
    Scroll() {
      Column() {
        Image($r('app.media.0'))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
          .margin({ top: 0, bottom: 10 })
          .zIndex(999);

        Row() {
          Text('连接状态: ')
            .fontSize(16)
            .fontColor('#FFFFFF');
          Text(this.isConnected ? '已连接' : '未连接')
            .fontSize(16)
            .fontColor(this.isConnected ? '#4CAF50' : '#F44336');
        }
        .margin({ bottom: 10 });

        if (!this.isConnected) {
          Column() {
            Row() {
              Text('⚠️ 当前为模拟数据模式')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FF9800');
            }
            .width('100%')
            .margin({ bottom: 8 });

            Text('以下数据为系统模拟生成，非真实传感器数据：')
              .fontSize(12)
              .fontColor('#888888')
              .width('100%')
              .margin({ bottom: 5 });

            Text('• 温度、湿度：模拟环境数据')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%');

            Text('• 土壤湿度、光照：模拟传感器读数')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%');

            Text('• CO2浓度、水位：模拟监测数据')
              .fontSize(11)
              .fontColor('#AAAAAA')
              .width('100%');

            Text('请连接云服务获取真实数据')
              .fontSize(12)
              .fontColor('#2196F3')
              .width('100%')
              .margin({ top: 8 });
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#FFF8E1')
          .borderRadius(10)
          .margin({ bottom: 15 });
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
            Text(`温度: ${this.sensorData.temperature.toFixed(1)}°C | 土壤水分: ${this.sensorData.soilMoisture.toFixed(0)}%`)
              .fontSize(12)
              .fontColor('#666666')
              .width('100%')
              .margin({ top: 5 });
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10)
          .margin({ bottom: 15 });
        }

        Column({ space: 10 }) {
          this.MenuItem('智能灌溉', '控制灌溉系统', 1, () => {
            router.pushUrl({ url: 'pages/IrrigationPage' });
          });

          this.MenuItem('智能光照', '控制光照系统', 2, () => {
            router.pushUrl({ url: 'pages/LightPage' });
          });

          this.MenuItem('阈值预警', '设置预警参数', 3, () => {
            router.pushUrl({ url: 'pages/AlertPage' });
          });

          this.MenuItem('连接模式', '切换蓝牙/云服务', 4, () => {
            router.pushUrl({ url: 'pages/ModeSelectPage' });
          });

          this.MenuItem('当前数据', '查看当前环境数据', 5, () => {
            router.pushUrl({ url: 'pages/DataPage' });
          });
        }
        .width('90%')
        .margin({ top: 15, bottom: 20 });
      }
      .width('100%')
      .backgroundColor('#4CAF50');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#4CAF50')
    .scrollBar(BarState.Auto);
  }

  @Builder
  MenuItem(title: string, desc: string, imageIndex: number, onClick: () => void) {
    Row({ space: 10 }) {
      Image($r(`app.media.${imageIndex}`))
        .width(96)
        .height(96)
        .objectFit(ImageFit.Contain)
        .align(Alignment.Center)
        .margin({ left: 0 });

      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium);
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 5 });
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .margin({ left: 10 });

      Blank();
      Blank();

      Text('>')
        .fontSize(20)
        .fontColor('#CCCCCC')
        .align(Alignment.Center)
        .margin({ right: 15 });
    }
    .width('100%')
    .height(80)
    .padding({ left: 15, right: 0, top: 0, bottom: 0 })
    .backgroundColor('#E8F5E9')
    .borderRadius(10)
    .alignItems(VerticalAlign.Center)
    .onClick(onClick);
  }
}
