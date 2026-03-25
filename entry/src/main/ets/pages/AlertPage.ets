import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';

interface AlertItem {
  name: string;
  key: string;
  minValue: number;
  maxValue: number;
  currentValue: number;
  unit: string;
  isAlert: boolean;
}

@Entry
@Component
struct AlertPage {
  @State alertList: AlertItem[] = [
    { name: '温度', key: 'temperature', minValue: 15, maxValue: 35, currentValue: 25, unit: '°C', isAlert: false },
    { name: '湿度', key: 'humidity', minValue: 30, maxValue: 80, currentValue: 60, unit: '%', isAlert: false },
    { name: '土壤湿度', key: 'soilMoisture', minValue: 20, maxValue: 70, currentValue: 50, unit: '%', isAlert: false },
    { name: '光照强度', key: 'lightLevel', minValue: 100, maxValue: 800, currentValue: 300, unit: 'lux', isAlert: false },
    { name: '水位', key: 'waterLevel', minValue: 20, maxValue: 100, currentValue: 80, unit: '%', isAlert: false },
    { name: 'CO2浓度', key: 'co2', minValue: 300, maxValue: 1000, currentValue: 450, unit: 'ppm', isAlert: false }
  ];
  @State sensorData: SensorDataModel = sensorDataModel;
  @State isMqttMode: boolean = false;

  aboutToAppear(): void {
    this.isMqttMode = mqttService.isConnected();
    this.updateCurrentValues();
    console.log('[AlertPage] aboutToAppear, isMqttMode=' + this.isMqttMode);
  }

  private updateCurrentValues(): void {
    const data = sensorDataModel;
    const newList: AlertItem[] = [];
    for (let i = 0; i < this.alertList.length; i++) {
      const item = this.alertList[i];
      let value = 0;
      
      switch (item.key) {
        case 'temperature': value = data.temperature; break;
        case 'humidity': value = data.humidity; break;
        case 'soilMoisture': value = data.soilMoisture; break;
        case 'lightLevel': value = data.lightLevel; break;
        case 'waterLevel': value = data.waterLevel; break;
        case 'co2': value = data.co2; break;
      }

      newList.push({
        name: item.name,
        key: item.key,
        minValue: item.minValue,
        maxValue: item.maxValue,
        currentValue: value,
        unit: item.unit,
        isAlert: value < item.minValue || value > item.maxValue
      });
    }
    this.alertList = newList;
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
          Text('阈值预警')
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
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column() {
          Text('预警状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            ForEach(this.alertList, (item: AlertItem) => {
              Circle({ width: 12, height: 12 })
                .fill(item.isAlert ? '#F44336' : '#4CAF50')
                .margin({ right: 5 });
            });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center);

          Text(this.hasAlert() ? '存在异常' : '系统正常')
            .fontSize(14)
            .fontColor(this.hasAlert() ? '#F44336' : '#4CAF50')
            .margin({ top: 5 });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFE0B2')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column({ space: 10 }) {
          ForEach(this.alertList, (item: AlertItem, index: number) => {
            this.AlertItemCard(item, index);
          });
        }
        .width('90%');

        Button('刷新数据')
          .width('90%')
          .height(50)
          .backgroundColor('#2196F3')
          .onClick(() => {
            this.updateCurrentValues();
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

  hasAlert(): boolean {
    for (let i = 0; i < this.alertList.length; i++) {
      if (this.alertList[i].isAlert) {
        return true;
      }
    }
    return false;
  }

  @Builder
  AlertItemCard(item: AlertItem, index: number) {
    Column() {
      Row() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Blank();
        if (item.isAlert) {
          Text('异常')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10);
        }
      }
      .width('100%');

      Row() {
        Text(`当前: ${item.currentValue.toFixed(1)}${item.unit}`)
          .fontSize(14);
        Blank();
        Text(`范围: ${item.minValue}-${item.maxValue}${item.unit}`)
          .fontSize(12)
          .fontColor('#888888');
      }
      .width('100%')
      .margin({ top: 8 });

      Row() {
        Text('下限:')
          .fontSize(12);
        TextInput({ text: item.minValue.toString() })
          .type(InputType.Number)
          .width(60)
          .height(30)
          .fontSize(12)
          .onChange((value: string) => {
            const minVal = parseInt(value) || 0;
            this.alertList[index].minValue = minVal;
            this.alertList[index].isAlert = item.currentValue < minVal || item.currentValue > item.maxValue;
          });
        Text('上限:')
          .fontSize(12)
          .margin({ left: 10 });
        TextInput({ text: item.maxValue.toString() })
          .type(InputType.Number)
          .width(60)
          .height(30)
          .fontSize(12)
          .onChange((value: string) => {
            const maxVal = parseInt(value) || 0;
            this.alertList[index].maxValue = maxVal;
            this.alertList[index].isAlert = item.currentValue < item.minValue || item.currentValue > maxVal;
          });
      }
      .width('100%')
      .margin({ top: 10 });
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10);
  }
}
