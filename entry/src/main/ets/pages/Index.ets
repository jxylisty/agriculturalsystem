import { router } from '@kit.ArkUI';
import { dataManager, SensorData } from '../services/DataManager';
import { bleService } from '../services/BleService';

@Entry
@Component
struct Index {
  @State deviceStatus: string = '未连接';
  @State isConnected: boolean = false;
  @State temperature: number = 25;
  @State humidity: number = 65;
  @State soilMoisture: number = 45;
  @State lightLevel: number = 300;
  @State waterLevel: number = 75;
  @State co2: number = 450;

  aboutToAppear(): void {
    this.isConnected = bleService.getConnectionStatus();
    
    const initialData = dataManager.getCurrentData();
    this.temperature = initialData.temperature;
    this.humidity = initialData.humidity;
    this.soilMoisture = initialData.soilMoisture;
    this.lightLevel = initialData.lightLevel;
    this.waterLevel = initialData.waterLevel;
    this.co2 = initialData.co2;

    dataManager.setDataCallback((data: SensorData) => {
      this.temperature = data.temperature;
      this.humidity = data.humidity;
      this.soilMoisture = data.soilMoisture;
      this.lightLevel = data.lightLevel;
      this.waterLevel = data.waterLevel;
      this.co2 = data.co2;
      this.isConnected = bleService.getConnectionStatus();
    });
  }

  build() {
    Scroll() {
      Column() {
        Text('智慧农业控制中心')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40, bottom: 20 });

        Row() {
          Text('蓝牙状态: ')
            .fontSize(16);
          Text(this.isConnected ? '已连接' : '未连接')
            .fontSize(16)
            .fontColor(this.isConnected ? '#4CAF50' : '#F44336');
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

            Text('请前往「设备管理」连接硬件获取真实数据')
              .fontSize(12)
              .fontColor('#2196F3')
              .width('100%')
              .margin({ top: 8 });
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#FFF8E1')
          .borderRadius(10)
          .margin({ bottom: 20 });
        }

        Column({ space: 15 }) {
          this.MenuItem('智能灌溉', '控制灌溉系统', () => {
            router.pushUrl({ url: 'pages/IrrigationPage' });
          });

          this.MenuItem('智能光照', '控制光照系统', () => {
            router.pushUrl({ url: 'pages/LightPage' });
          });

          this.MenuItem('阈值预警', '设置预警参数', () => {
            router.pushUrl({ url: 'pages/AlertPage' });
          });

          this.MenuItem('设备管理', '蓝牙设备连接', () => {
            router.pushUrl({ url: 'pages/DevicePage' });
          });
        }
        .width('90%')
        .margin({ top: 20 });

        Text('当前环境数据')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 30, bottom: 10 });

        Row() {
          this.DataCard('温度', `${this.temperature.toFixed(1)}°C`);
          this.DataCard('湿度', `${this.humidity.toFixed(0)}%`);
          this.DataCard('土壤', `${this.soilMoisture.toFixed(0)}%`);
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 });

        Row() {
          this.DataCard('CO2', `${this.co2.toFixed(0)}ppm`);
          this.DataCard('光照', `${this.lightLevel.toFixed(0)}lux`);
          this.DataCard('水位', `${this.waterLevel.toFixed(0)}%`);
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 30 });
      }
      .width('100%')
      .backgroundColor('#F5F5F5');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Auto);
  }

  @Builder
  MenuItem(title: string, desc: string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium);
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 5 });
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      Text('>')
        .fontSize(20)
        .fontColor('#CCCCCC');
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .onClick(onClick);
  }

  @Builder
  DataCard(title: string, value: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor('#888888');
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 5 });
    }
    .width('30%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10);
  }
}
