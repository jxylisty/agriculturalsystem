import { router } from '@kit.ArkUI';
import { mqttService } from '../services/MqttService';
import { ControlStateUtil, setProgrammaticUpdate, getProgrammaticUpdate } from '../services/ControlState';
import { SensorDataModel, sensorDataModel } from '../services/SensorDataModel';
import { promptAction } from '@kit.ArkUI';

@Component
struct LightStatus {
  @ObjectLink data: SensorDataModel;

  build() {
    Column() {
      Text('当前光照')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 });

      Row() {
        Column() {
          Text('光照强度')
            .fontSize(12)
            .fontColor('#888888');
          Text(`${this.data.lightLevel.toFixed(0)} lux`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 });
        }
        .width('100%')
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
struct LightPage {
  @State sensorData: SensorDataModel = sensorDataModel;
  @StorageLink('lightOn') lightOn: boolean = false;
  @StorageLink('lightAutoMode') lightAutoMode: boolean = true;
  @State currentLightLevel: number = 300;
  @State eastBrightness: number = 50;
  @State westBrightness: number = 50;
  @State southBrightness: number = 50;
  @State northBrightness: number = 50;
  @State lightDirection: string = '东南';
  @State recommendedStrength: number = 400;
  @State recommendedDirection: string = '东南';
  @State isMqttMode: boolean = false;

  aboutToAppear(): void {
    this.isMqttMode = mqttService.isConnected();
    console.log('[LightPage] aboutToAppear, isMqttMode=' + this.isMqttMode + ', lightOn=' + this.lightOn + ', lightAutoMode=' + this.lightAutoMode);
  }

  private toggleLight(): void {
    if (this.lightAutoMode && this.isMqttMode) {
      promptAction.showDialog({
        title: '自动模式提示',
        message: '当前处于自动模式，系统会根据光照强度自动控制补光。\n\n手动操作可能会被自动控制覆盖，是否继续？',
        buttons: [
          { text: '取消', color: '#888888' },
          { text: '继续操作', color: '#4CAF50' }
        ]
      }, (err, data) => {
        if (!err && data.index === 1) {
          this.doToggleLight();
        }
      });
    } else {
      this.doToggleLight();
    }
  }

  private doToggleLight(): void {
    const newState = !this.lightOn;
    console.log('[LightPage] doToggleLight: ' + this.lightOn + ' -> ' + newState);
    ControlStateUtil.updateLight(newState, this.lightAutoMode);
    if (this.isMqttMode) {
      mqttService.publishLightCommand(newState, this.lightAutoMode);
    }
  }

  private toggleAutoMode(): void {
    const newAutoMode = !this.lightAutoMode;
    console.log('[LightPage] toggleAutoMode: ' + this.lightAutoMode + ' -> ' + newAutoMode);
    ControlStateUtil.updateLight(this.lightOn, newAutoMode);
    if (this.isMqttMode) {
      mqttService.publishLightCommand(this.lightOn, newAutoMode);
    }
  }

  private updateBrightness(): void {
    if (this.isMqttMode) {
      mqttService.publishLightDirectionalCommand(
        this.eastBrightness,
        this.westBrightness,
        this.southBrightness,
        this.northBrightness
      );
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
          Text('智能光照')
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

        if (this.lightAutoMode && this.isMqttMode) {
          Column() {
            Row() {
              Text('🤖 自动模式运行中')
                .fontSize(14)
                .fontColor('#4CAF50');
            }
            .width('100%');
            Text('系统会根据光照强度自动控制补光，开关已被禁用')
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
            Text('当前光照强度')
              .fontSize(14)
              .fontColor('#666666');
            Row({ space: 5 }) {
              Text(`${this.sensorData.lightLevel.toFixed(0)}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold);
              Text(' lux')
                .fontSize(14)
                .fontColor('#666666');
            }
            .margin({ top: 5 });
          }
          .width('48%')
          .height(80)
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Column() {
            Text('当前光照方向')
              .fontSize(14)
              .fontColor('#666666');
            Text(this.lightDirection)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 5 });
          }
          .width('48%')
          .height(80)
          .padding(15)
          .backgroundColor('#FFE0B2')
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }
        .width('90%')
        .margin({ bottom: 20 });

        Column() {
          Row() {
            Text('补光开关')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.lightOn })
              .enabled(!this.lightAutoMode || !this.isMqttMode)
              .opacity(this.lightAutoMode && this.isMqttMode ? 0.4 : 1)
              .onChange((isOn: boolean) => {
                if (getProgrammaticUpdate()) {
                  setProgrammaticUpdate(false);
                  return;
                }
                this.toggleLight();
              });
          }
          .width('100%')
          .padding(15);

          Divider();

          Row() {
            Text('自动模式')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.lightAutoMode })
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

        LightStatus({ data: this.sensorData });

        Column({ space: 15 }) {
          this.LightSliderBuilder('东向灯强', this.eastBrightness, (value: number) => {
            this.eastBrightness = value;
            this.updateBrightness();
          });

          this.LightSliderBuilder('西向灯强', this.westBrightness, (value: number) => {
            this.westBrightness = value;
            this.updateBrightness();
          });

          this.LightSliderBuilder('南向灯强', this.southBrightness, (value: number) => {
            this.southBrightness = value;
            this.updateBrightness();
          });

          this.LightSliderBuilder('北向灯强', this.northBrightness, (value: number) => {
            this.northBrightness = value;
            this.updateBrightness();
          });
        }
        .width('90%')
        .margin({ top: 20, bottom: 20 });

        Button(this.lightOn ? '关闭补光' : '开启补光')
          .width('90%')
          .height(50)
          .backgroundColor(this.lightOn ? '#F44336' : '#4CAF50')
          .onClick(() => {
            this.toggleLight();
          })
          .margin({ bottom: 30 });
      }
      .width('100%')
      .backgroundColor('#FFA726');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFA726')
    .scrollBar(BarState.Auto);
  }

  @Builder
  LightSliderBuilder(label: string, brightness: number, onChange: (value: number) => void) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(16)
        .width('25%');

      Slider({
        value: brightness,
        min: 0,
        max: 100,
        step: 5,
        style: SliderStyle.OutSet
      })
        .blockColor('#FFC107')
        .trackColor('#FFF9C4')
        .width('60%')
        .onChange((sliderValue: number) => {
          const roundedValue = Math.round(sliderValue);
          onChange(roundedValue);
        });

      Column() {
        Circle({ width: 12, height: 12 })
          .fill(this.isMqttMode ? '#4CAF50' : '#F44336');
        Text(this.isMqttMode ? '已连接' : '离线')
          .fontSize(8)
          .fontColor(this.isMqttMode ? '#4CAF50' : '#F44336')
          .margin({ top: 2 });
      }
      .width('15%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFE0B2')
    .borderRadius(10)
    .alignItems(VerticalAlign.Center);
  }
}
