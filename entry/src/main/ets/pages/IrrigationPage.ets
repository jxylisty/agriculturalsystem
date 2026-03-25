import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { ControlStateUtil, setProgrammaticUpdate, getProgrammaticUpdate } from '../services/ControlState';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';
import { promptAction } from '@kit.ArkUI';

@Component
struct IrrigationStatus {
  @ObjectLink data: SensorDataModel;

  build() {
    Column() {
      Text('当前状态')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      Row() {
        Column() {
          Text('水箱水位')
            .fontSize(12)
            .fontColor('#888888');
          Text(`${this.data.waterLevel.toFixed(0)}%`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 });
        }
        .width('45%')
        .padding(15)
        .backgroundColor('#F9F9F9')
        .borderRadius(8);

        Column() {
          Text('土壤湿度')
            .fontSize(12)
            .fontColor('#888888');
          Text(`${this.data.soilMoisture.toFixed(0)}%`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 });
        }
        .width('45%')
        .padding(15)
        .backgroundColor('#F9F9F9')
        .borderRadius(8);
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width('90%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10);
  }
}

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

  aboutToAppear(): void {
    this.isMqttMode = mqttService.isConnected();
    console.log('[IrrigationPage] aboutToAppear, isMqttMode=' + this.isMqttMode + ', irrigationOn=' + this.irrigationOn + ', irrigationAutoMode=' + this.irrigationAutoMode);
  }

  private toggleIrrigation(): void {
    if (this.irrigationAutoMode && this.isMqttMode) {
      promptAction.showDialog({
        title: '自动模式提示',
        message: '当前处于自动模式，系统会根据土壤湿度自动控制灌溉。\n\n手动操作可能会被自动控制覆盖，是否继续？',
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

        if (!this.isMqttMode) {
          Column() {
            Row() {
              Text('⚠️ 本地模式')
                .fontSize(14)
                .fontColor('#FF9800');
            }
            .width('100%');
            Text('控制命令仅在本地生效，不会发送到设备')
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
        }

        if (this.irrigationAutoMode && this.isMqttMode) {
          Column() {
            Row() {
              Text('🤖 自动模式运行中')
                .fontSize(14)
                .fontColor('#4CAF50');
            }
            .width('100%');
            Text('系统会根据土壤湿度自动控制灌溉，开关已被禁用')
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
              .blockColor('#2196F3')
              .trackColor('#BBDEFB')
              .onChange((value: number) => {
                this.tankWaterLevel = Math.round(value);
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#FFE0B2')
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
              .blockColor('#2196F3')
              .trackColor('#BBDEFB')
              .onChange((value: number) => {
                this.pumpEfficiency = Math.round(value);
              });
          }
          .width('48%')
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10);
        }
        .width('90%')
        .margin({ bottom: 20 });

        Column() {
          Row() {
            Text('灌溉开关')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.irrigationOn })
              .enabled(!this.irrigationAutoMode || !this.isMqttMode)
              .opacity(this.irrigationAutoMode && this.isMqttMode ? 0.4 : 1)
              .onChange((isOn: boolean) => {
                if (getProgrammaticUpdate()) {
                  setProgrammaticUpdate(false);
                  return;
                }
                this.toggleIrrigation();
              });
          }
          .width('100%')
          .padding(15);

          Divider();

          Row() {
            Text('自动模式')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.irrigationAutoMode })
              .onChange((isOn: boolean) => {
                if (getProgrammaticUpdate()) {
                  setProgrammaticUpdate(false);
                  return;
                }
                this.toggleAutoMode();
              });
          }
          .width('100%')
          .padding(15);
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        IrrigationStatus({ data: this.sensorData });

        Column() {
          Text('目标湿度设置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text('目标湿度: ')
              .fontSize(14);
            Text(`${this.targetMoisture}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold);
          }
          .width('100%')
          .margin({ bottom: 10 });

          Slider({
            value: this.targetMoisture,
            min: 20,
            max: 80,
            step: 5,
            style: SliderStyle.OutSet
          })
            .blockColor('#2196F3')
            .trackColor('#BBDEFB')
            .onChange((value: number) => {
              this.updateTargetMoisture(Math.round(value));
            });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ top: 20, bottom: 20 });

        Button(this.irrigationOn ? '关闭灌溉' : '开启灌溉')
          .width('90%')
          .height(50)
          .backgroundColor(this.irrigationOn ? '#F44336' : '#4CAF50')
          .onClick(() => {
            this.toggleIrrigation();
          })
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
}
