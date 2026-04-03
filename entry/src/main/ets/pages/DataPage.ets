import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';

@Component
struct SensorDisplay {
  @ObjectLink data: SensorDataModel;

  build() {
    Column({ space: 10 }) {
      this.DataItem('温度', `${this.data.temperature.toFixed(1)}°C`, '环境温度');
      this.DataItem('湿度', `${this.data.humidity.toFixed(0)}%`, '空气湿度');
      this.DataItem('土壤湿度', `${this.data.soilMoisture.toFixed(0)}%`, '土壤水分含量');
      this.DataItem('CO2浓度', `${this.data.co2.toFixed(0)}ppm`, '二氧化碳浓度');
      this.DataItem('光照强度', `${this.data.lightLevel.toFixed(0)}lux`, '光照强度');
      this.DataItem('水位', `${this.data.waterLevel.toFixed(0)}%`, '水箱水位');
    }
    .width('90%');
  }

  @Builder
  DataItem(title: string, value: string, desc: string) {
    Row({ space: 10 }) {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 3 });
      }
      .alignItems(HorizontalAlign.Start)
      .align(Alignment.Center);

      Blank();

      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .align(Alignment.Center);
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#E8F5E9')
    .borderRadius(10)
    .alignItems(VerticalAlign.Center);
  }
}

@Entry
@Component
struct DataPage {
  @State sensorData: SensorDataModel = sensorDataModel;
  @State isMqttMode: boolean = false;

  aboutToAppear(): void {
    this.isMqttMode = mqttService.isConnected();
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
            Text('MQTT状态: ')
              .fontSize(14);
            Text(this.isMqttMode ? '已连接' : '未连接')
              .fontSize(14)
              .fontColor(this.isMqttMode ? '#4CAF50' : '#F44336')
              .fontWeight(FontWeight.Medium);
          }

          if (!this.isMqttMode) {
            Text('当前为本地模拟数据模式')
              .fontSize(12)
              .fontColor('#FF9800')
              .margin({ top: 5 });
          }
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
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
          .backgroundColor('#E8F5E9')
          .borderRadius(10)
          .alignItems(VerticalAlign.Center);
        }
        .width('90%');

        Button('刷新数据')
          .width('90%')
          .height(50)
          .backgroundColor('#388E3C')
          .onClick(() => {
            console.log('[DataPage] Refresh button clicked, temperature=' + this.sensorData.temperature);
          })
          .margin({ top: 20, bottom: 30 });
      }
      .width('100%')
      .backgroundColor('#4CAF50');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#4CAF50')
    .scrollBar(BarState.Auto);
  }
}