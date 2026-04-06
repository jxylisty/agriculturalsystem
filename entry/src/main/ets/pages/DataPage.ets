import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';
import { AppStorageUtil } from '../services/AppStorageUtil';

@Entry
@Component
struct DataPage {
  @State sensorData: SensorDataModel = sensorDataModel;
  @StorageLink('is_connected') isConnected: boolean = false;
  @State isMqttMode: boolean = false;

  aboutToAppear(): void {
    this.isMqttMode = AppStorageUtil.isConnected();
    console.log('[DataPage] aboutToAppear, isMqttMode=' + this.isMqttMode + ', temperature=' + this.sensorData.temperature);
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .onClick(() => {
              router.back();
            });
          Text('环境数据查询')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Column() {
          Text('连接状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text('状态: ')
              .fontSize(14);
            Text(this.isConnected ? '已连接' : '未连接')
              .fontSize(14)
              .fontColor(this.isConnected ? '#4CAF50' : '#F44336')
              .fontWeight(FontWeight.Medium);
          }

          if (!this.isConnected) {
            Text('当前为本地模拟数据模式')
              .fontSize(12)
              .fontColor('#FF9800')
              .margin({ top: 5 });
          } else {
            Text('已连接云服务，数据每5秒刷新')
              .fontSize(12)
              .fontColor('#4CAF50')
              .margin({ top: 5 });
          }
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Text('当前环境数据')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 15 })
          .width('90%');

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Column() {
              Text('温度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('环境温度')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.temperature.toFixed(1)}°C`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);

          Row({ space: 10 }) {
            Column() {
              Text('土壤湿度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('土壤水分含量')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.soilMoisture.toFixed(0)}%`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);

          Row({ space: 10 }) {
            Column() {
              Text('湿度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('空气湿度')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.humidity.toFixed(0)}%`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);

          Row({ space: 10 }) {
            Column() {
              Text('CO2浓度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('二氧化碳浓度')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.co2.toFixed(0)}ppm`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);

          Row({ space: 10 }) {
            Column() {
              Text('光照强度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('光照强度')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.lightLevel.toFixed(0)}lux`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);

          Row({ space: 10 }) {
            Column() {
              Text('水位')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Text('水箱水位')
                .fontSize(12)
                .fontColor('#888888')
                .margin({ top: 3 });
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Center);
            Blank();
            Text(`${this.sensorData.waterLevel.toFixed(0)}%`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center);
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);
        }
        .width('90%');

        Button('刷新数据')
          .width('90%')
          .height(50)
          .backgroundColor('#2196F3')
          .onClick(() => {
            console.log('[DataPage] Refresh button clicked, temperature=' + this.sensorData.temperature + ', soilMoisture=' + this.sensorData.soilMoisture);
          })
          .margin({ top: 20, bottom: 30 });
      }
      .width('100%')
      .backgroundColor('#FFA726');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFA726')
    .scrollBar(BarState.Auto);
  }
}
