import { router } from '@kit.ArkUI';
import { dataManager, SensorData, LightConfig } from '../services/DataManager';

@Entry
@Component
struct LightPage {
  @State isLightOn: boolean = false;
  @State lightBrightness: number = 50;
  @State autoMode: boolean = true;
  @State currentLightLevel: number = 300;
  @State startTime: string = '06:00';
  @State endTime: string = '18:00';

  aboutToAppear(): void {
    const config = dataManager.getLightConfig();
    this.isLightOn = config.isOn;
    this.autoMode = config.autoMode;
    this.lightBrightness = config.brightness;
    this.startTime = config.startTime;
    this.endTime = config.endTime;

    const currentData = dataManager.getCurrentData();
    this.currentLightLevel = currentData.lightLevel;

    dataManager.setDataCallback((data: SensorData) => {
      this.currentLightLevel = data.lightLevel;
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
          Text('智能光照')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 20 });
        }
        .width('90%')
        .margin({ top: 20, bottom: 30 });

        Column() {
          Row() {
            Text('光照开关')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.isLightOn })
              .onChange((isOn: boolean) => {
                this.isLightOn = isOn;
                dataManager.setLightConfig({ isOn: isOn });
              });
          }
          .width('100%')
          .padding(15);

          Divider();

          Row() {
            Text('自动模式')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.autoMode })
              .onChange((isOn: boolean) => {
                this.autoMode = isOn;
                dataManager.setLightConfig({ autoMode: isOn });
              });
          }
          .width('100%')
          .padding(15);
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column() {
          Text('当前环境光照')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text(`${this.currentLightLevel.toFixed(0)}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold);
            Text(' lux')
              .fontSize(16)
              .margin({ top: 15 });
          }
        }
        .width('90%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column() {
          Text('亮度调节')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text('亮度: ')
              .fontSize(14);
            Text(`${this.lightBrightness}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold);
          }
          .width('100%')
          .margin({ bottom: 10 });

          Slider({
            value: this.lightBrightness,
            min: 0,
            max: 100,
            step: 5,
            style: SliderStyle.OutSet
          })
            .blockColor('#FFC107')
            .trackColor('#FFF9C4')
            .onChange((value: number) => {
              this.lightBrightness = Math.round(value);
              dataManager.setLightConfig({ brightness: this.lightBrightness });
            });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column() {
          Text('定时设置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 });

          Row() {
            Text('开启时间: ')
              .fontSize(14);
            Text(this.startTime)
              .fontSize(14)
              .fontWeight(FontWeight.Bold);
          }
          .width('100%')
          .margin({ bottom: 8 });

          Row() {
            Text('关闭时间: ')
              .fontSize(14);
            Text(this.endTime)
              .fontSize(14)
              .fontWeight(FontWeight.Bold);
          }
          .width('100%');
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Button(this.isLightOn ? '关闭灯光' : '开启灯光')
          .width('90%')
          .height(50)
          .backgroundColor(this.isLightOn ? '#FF9800' : '#FFC107')
          .onClick(() => {
            this.isLightOn = !this.isLightOn;
            dataManager.setLightConfig({ isOn: this.isLightOn });
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
