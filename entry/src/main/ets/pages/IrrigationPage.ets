import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { ControlStateUtil, setProgrammaticUpdate, getProgrammaticUpdate } from '../services/ControlState';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct IrrigationPage {
  @State sensorData: SensorDataModel = sensorDataModel;
  @StorageLink('irrigationOn') irrigationOn: boolean = false;
  @StorageLink('irrigationAutoMode') irrigationAutoMode: boolean = true;
  @StorageLink('targetMoisture') targetMoisture: number = 50;
  @State tankWaterLevel: number = 80;
  @State pumpEfficiency: number = 85;
  @State isMqttMode: boolean = false;
  @State lastYearWaterUsage: number = 12500;
  @State lastHourWaterUsage: number = 350;
  @State recommendedPumpEfficiency: number = 92;
  @State estimatedIrrigationTime: number = 240;

  aboutToAppear(): void {
    this.isMqttMode = mqttService.isConnected();
    console.log('[IrrigationPage] aboutToAppear, isMqttMode=' + this.isMqttMode + ', irrigationOn=' + this.irrigationOn + ', irrigationAutoMode=' + this.irrigationAutoMode);
  }

  private toggleIrrigation(): void {
    if (this.irrigationAutoMode && this.isMqttMode) {
      promptAction.showDialog({
        title: '自动模式提示',
        message: '当前处于自动模式，系统会根据土壤湿度自动控制灌溉。\\n\\n手动操作可能会被自动控制覆盖，是否继续？',
        buttons: [
          { text: '取消', color: '#888888' },
          { text: '继续操作', color: '#4CAF50' }
        ]
      }, (err, data) => {
        if (!err && data.index === 1) {
          this.doToggleIrrigation();
        }
      });
    } else {
      this.doToggleIrrigation();
    }
  }

  private doToggleIrrigation(): void {
    const newState = !this.irrigationOn;
    console.log('[IrrigationPage] doToggleIrrigation: ' + this.irrigationOn + ' -> ' + newState);
    ControlStateUtil.updateIrrigation(newState, this.irrigationAutoMode, this.targetMoisture);
    if (this.isMqttMode) {
      mqttService.publishIrrigationCommand(newState, this.irrigationAutoMode, this.targetMoisture);
    }
  }

  private toggleAutoMode(): void {
    const newAutoMode = !this.irrigationAutoMode;
    console.log('[IrrigationPage] toggleAutoMode: ' + this.irrigationAutoMode + ' -> ' + newAutoMode);
    ControlStateUtil.updateIrrigation(this.irrigationOn, newAutoMode, this.targetMoisture);
    if (this.isMqttMode) {
      mqttService.publishIrrigationCommand(this.irrigationOn, newAutoMode, this.targetMoisture);
    }
  }

  private updateTargetMoisture(value: number): void {
    console.log('[IrrigationPage] updateTargetMoisture: ' + value);
    ControlStateUtil.updateIrrigation(this.irrigationOn, undefined, value);
    if (this.isMqttMode) {
      mqttService.publishTargetMoistureCommand(value);
    }
  }

  private refreshData(): void {
    console.log('[IrrigationPage] refreshData');
    // 模拟数据刷新效果 - 创建一个新的SensorDataModel实例
    const newData = new SensorDataModel();
    // 复制当前数据到新实例
    newData.temperature = sensorDataModel.temperature;
    newData.humidity = sensorDataModel.humidity;
    newData.soilMoisture = sensorDataModel.soilMoisture;
    newData.lightLevel = sensorDataModel.lightLevel;
    newData.waterLevel = sensorDataModel.waterLevel;
    newData.co2 = sensorDataModel.co2;
    newData.timestamp = sensorDataModel.timestamp;

    this.sensorData = newData;
    if (this.isMqttMode) {
      // 如果是MQTT模式，可以请求最新数据
      promptAction.showToast({
        message: '数据已刷新',
        duration: 1500
      });
    } else {
      promptAction.showToast({
        message: '本地数据已刷新',
        duration: 1500
      });
    }
  }

  private refreshTemperature(): void {
    console.log('[IrrigationPage] refreshTemperature');
    // 模拟温度数据刷新
    const newData = new SensorDataModel();
    newData.temperature = sensorDataModel.temperature;
    newData.humidity = this.sensorData.humidity;
    newData.soilMoisture = this.sensorData.soilMoisture;
    newData.lightLevel = this.sensorData.lightLevel;
    newData.waterLevel = this.sensorData.waterLevel;
    newData.co2 = this.sensorData.co2;
    newData.timestamp = Date.now();

    this.sensorData = newData;
    promptAction.showToast({
      message: '温度数据已刷新',
      duration: 1000
    });
  }

  private refreshHumidity(): void {
    console.log('[IrrigationPage] refreshHumidity');
    // 模拟湿度数据刷新
    const newData = new SensorDataModel();
    newData.temperature = this.sensorData.temperature;
    newData.humidity = sensorDataModel.humidity;
    newData.soilMoisture = this.sensorData.soilMoisture;
    newData.lightLevel = this.sensorData.lightLevel;
    newData.waterLevel = this.sensorData.waterLevel;
    newData.co2 = this.sensorData.co2;
    newData.timestamp = Date.now();

    this.sensorData = newData;
    promptAction.showToast({
      message: '湿度数据已刷新',
      duration: 1000
    });
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
          Text('智能灌溉')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Row({ space: 10 }) {
          Column() {
            Text('当前温度')
              .fontSize(14)
              .fontColor('#666666');
            Text(`${this.sensorData.temperature.toFixed(1)}°C`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5722')
              .margin({ top: 5 });
            Button('刷新')
              .width('100%')
              .height(28)
              .fontSize(12)
              .backgroundColor('#FF5722')
              .fontColor('#FFFFFF')
              .margin({ top: 8 })
              .onClick(() => {
                this.refreshTemperature();
              });
          }
          .width('45%')
          .height(120)
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Column() {
            Text('当前湿度')
              .fontSize(14)
              .fontColor('#666666');
            Text(`${this.sensorData.humidity.toFixed(0)}%`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#388E3C')
              .margin({ top: 5 });
            Button('刷新')
              .width('100%')
              .height(28)
              .fontSize(12)
              .backgroundColor('#388E3C')
              .fontColor('#FFFFFF')
              .margin({ top: 8 })
              .onClick(() => {
                this.refreshHumidity();
              });
          }
          .width('45%')
          .height(120)
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }
        .width('90%')
        .margin({ bottom: 10 });



        Row({ space: 10 }) {
          Column() {
            Text('水箱水量')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 15 });

            Row() {
              Text('当前: ')
                .fontSize(14);
              Text(`${this.tankWaterLevel}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 10 });

            Slider({
              value: this.tankWaterLevel,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#388E3C')
              .trackColor('#C8E6C9')
              .onChange((value: number) => {
                this.tankWaterLevel = Math.round(value);
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10);

          Column() {
            Row() {
              Text('水泵能效')
                .fontSize(16)
                .fontWeight(FontWeight.Medium);
              Blank();
              Text(this.pumpEfficiency === 0 ? '关闭' : '开启')
                .fontSize(12)
                .fontColor(this.pumpEfficiency === 0 ? '#F44336' : '#4CAF50')
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 15 });

            Row() {
              Text('当前: ')
                .fontSize(14);
              Text(`${this.pumpEfficiency}%`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .margin({ bottom: 10 });

            Slider({
              value: this.pumpEfficiency,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#388E3C')
              .trackColor('#C8E6C9')
              .onChange((value: number) => {
                this.pumpEfficiency = Math.round(value);
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#E8F5E9')
          .borderRadius(10);
        }
        .width('90%')
        .margin({ bottom: 20 });

        Column() {
          Text('灌溉信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 });

          Row() {
            Text('过去一年灌溉水量: ')
              .fontSize(14)
              .fontColor('#333333');
            Text(`${this.lastYearWaterUsage.toLocaleString()} ml`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#388E3C');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          Row() {
            Text('过去一小时灌溉水量: ')
              .fontSize(14)
              .fontColor('#333333');
            Text(`${this.lastHourWaterUsage.toLocaleString()} ml`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          Row() {
            Text('推荐水泵能效: ')
              .fontSize(14)
              .fontColor('#333333');
            Text(`${this.recommendedPumpEfficiency.toFixed(0)}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9800');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });

          Row() {
            Text('预计水箱可灌溉时长: ')
              .fontSize(14)
              .fontColor('#333333');
            Text(`${this.estimatedIrrigationTime.toLocaleString()} min`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3');
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#E8F5E9')
        .borderRadius(10)
        .margin({ bottom: 30 });
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