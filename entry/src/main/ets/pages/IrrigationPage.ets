import { router } from '@kit.ArkUI';
import { dataManager, SensorData, IrrigationConfig } from '../services/DataManager';

@Entry
@Component
struct IrrigationPage {
  @State isIrrigationOn: boolean = false;
  @State waterLevel: number = 75;
  @State soilMoisture: number = 45;
  @State temperature: number = 25;
  @State autoMode: boolean = true;
  @State targetMoisture: number = 50;
  @State cropType: string = 'vegetable';
  @State estimatedWater: number = 0;
  @State estimatedDuration: number = 0;

  aboutToAppear(): void {
    const config = dataManager.getIrrigationConfig();
    this.isIrrigationOn = config.isOn;
    this.autoMode = config.autoMode;
    this.targetMoisture = config.targetMoisture;

    const currentData = dataManager.getCurrentData();
    this.waterLevel = currentData.waterLevel;
    this.soilMoisture = currentData.soilMoisture;
    this.temperature = currentData.temperature;

    dataManager.setDataCallback((data: SensorData) => {
      this.waterLevel = data.waterLevel;
      this.soilMoisture = data.soilMoisture;
      this.temperature = data.temperature;
      this.calculateWater();
    });

    this.calculateWater();
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

        Column() {
          Row() {
            Text('灌溉开关')
              .fontSize(18);
            Blank();
            Toggle({ type: ToggleType.Switch, isOn: this.isIrrigationOn })
              .onChange((isOn: boolean) => {
                this.isIrrigationOn = isOn;
                dataManager.setIrrigationConfig({ isOn: isOn });
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
                dataManager.setIrrigationConfig({ autoMode: isOn });
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
          Text('当前状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 });

          Row() {
            this.StatusItem('水箱水位', `${this.waterLevel.toFixed(0)}%`);
            this.StatusItem('土壤湿度', `${this.soilMoisture.toFixed(0)}%`);
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

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
              this.targetMoisture = Math.round(value);
              dataManager.setIrrigationConfig({ targetMoisture: this.targetMoisture });
              this.calculateWater();
            });
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Column() {
          Text('灌溉水量计算')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 });

          Row() {
            Text('作物类型: ')
              .fontSize(14);
            Select([
              { value: '蔬菜', icon: '' },
              { value: '水果', icon: '' },
              { value: '谷物', icon: '' },
              { value: '花卉', icon: '' }
            ])
              .selected(this.getSelectIndex())
              .value(this.getCropName())
              .onSelect((index: number) => {
                this.setCropType(index);
                this.calculateWater();
              });
          }
          .width('100%')
          .margin({ bottom: 15 });

          Row() {
            this.WaterInfoItem('预计用水', `${this.estimatedWater.toFixed(1)}L`);
            this.WaterInfoItem('预计时长', `${this.estimatedDuration}分钟`);
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 });

        Button(this.isIrrigationOn ? '关闭灌溉' : '开启灌溉')
          .width('90%')
          .height(50)
          .backgroundColor(this.isIrrigationOn ? '#F44336' : '#4CAF50')
          .onClick(() => {
            this.isIrrigationOn = !this.isIrrigationOn;
            dataManager.setIrrigationConfig({ isOn: this.isIrrigationOn });
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

  @Builder
  StatusItem(title: string, value: string) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor('#888888');
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 5 });
    }
    .width('45%')
    .padding(15)
    .backgroundColor('#F9F9F9')
    .borderRadius(8);
  }

  @Builder
  WaterInfoItem(title: string, value: string) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor('#888888');
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3')
        .margin({ top: 5 });
    }
    .width('45%')
    .padding(15)
    .backgroundColor('#E3F2FD')
    .borderRadius(8);
  }

  private getCropName(): string {
    if (this.cropType === 'vegetable') return '蔬菜';
    if (this.cropType === 'fruit') return '水果';
    if (this.cropType === 'grain') return '谷物';
    if (this.cropType === 'flower') return '花卉';
    return '蔬菜';
  }

  private getSelectIndex(): number {
    if (this.cropType === 'vegetable') return 0;
    if (this.cropType === 'fruit') return 1;
    if (this.cropType === 'grain') return 2;
    if (this.cropType === 'flower') return 3;
    return 0;
  }

  private setCropType(index: number): void {
    if (index === 0) this.cropType = 'vegetable';
    else if (index === 1) this.cropType = 'fruit';
    else if (index === 2) this.cropType = 'grain';
    else if (index === 3) this.cropType = 'flower';
    else this.cropType = 'vegetable';
  }

  private calculateWater(): void {
    const moistureDeficit = Math.max(0, this.targetMoisture - this.soilMoisture);
    const tempFactor = this.temperature > 30 ? 1.2 : (this.temperature < 15 ? 0.8 : 1.0);
    
    let cropFactor = 1.0;
    if (this.cropType === 'vegetable') cropFactor = 1.0;
    else if (this.cropType === 'fruit') cropFactor = 1.3;
    else if (this.cropType === 'grain') cropFactor = 0.8;
    else if (this.cropType === 'flower') cropFactor = 1.1;
    
    this.estimatedWater = Math.round(moistureDeficit * 0.5 * tempFactor * cropFactor * 100) / 100;
    this.estimatedDuration = Math.ceil(this.estimatedWater / 0.5);
  }
}
