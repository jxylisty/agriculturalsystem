import { SensorData, bleService } from './BleService';

export interface AlertThreshold {
  name: string;
  minValue: number;
  maxValue: number;
  unit: string;
}

export interface IrrigationConfig {
  isOn: boolean;
  autoMode: boolean;
  targetMoisture: number;
  duration: number;
}

export interface LightConfig {
  isOn: boolean;
  autoMode: boolean;
  brightness: number;
  startTime: string;
  endTime: string;
}

export interface AlertRecord {
  id: string;
  type: string;
  message: string;
  value: number;
  threshold: string;
  timestamp: number;
}

export interface IrrigationWaterEstimate {
  waterAmount: number;
  duration: number;
}

class DataManager {
  private static instance: DataManager;

  private currentData: SensorData = {
    temperature: 25,
    humidity: 65,
    soilMoisture: 45,
    lightLevel: 300,
    waterLevel: 75,
    co2: 450,
    timestamp: Date.now()
  };

  private thresholds: AlertThreshold[] = [
    { name: 'temperature', minValue: 15, maxValue: 35, unit: '°C' },
    { name: 'humidity', minValue: 40, maxValue: 80, unit: '%' },
    { name: 'soilMoisture', minValue: 30, maxValue: 70, unit: '%' },
    { name: 'lightLevel', minValue: 100, maxValue: 1000, unit: 'lux' },
    { name: 'waterLevel', minValue: 20, maxValue: 100, unit: '%' },
    { name: 'co2', minValue: 300, maxValue: 1000, unit: 'ppm' }
  ];

  private irrigationConfig: IrrigationConfig = {
    isOn: false,
    autoMode: true,
    targetMoisture: 50,
    duration: 10
  };

  private lightConfig: LightConfig = {
    isOn: false,
    autoMode: true,
    brightness: 50,
    startTime: '06:00',
    endTime: '18:00'
  };

  private alertHistory: AlertRecord[] = [];
  private dataCallback: ((data: SensorData) => void) | null = null;
  private alertCallback: ((alert: AlertRecord) => void) | null = null;

  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager();
    }
    return DataManager.instance;
  }

  getCurrentData(): SensorData {
    return this.currentData;
  }

  updateSensorData(data: SensorData): void {
    this.currentData = data;
    this.checkAlerts();
    if (this.dataCallback) {
      this.dataCallback(data);
    }
  }

  setDataCallback(callback: (data: SensorData) => void): void {
    this.dataCallback = callback;
  }

  setAlertCallback(callback: (alert: AlertRecord) => void): void {
    this.alertCallback = callback;
  }

  getThresholds(): AlertThreshold[] {
    return this.thresholds;
  }

  updateThreshold(name: string, minValue: number, maxValue: number): void {
    const threshold = this.thresholds.find(t => t.name === name);
    if (threshold) {
      threshold.minValue = minValue;
      threshold.maxValue = maxValue;
    }
  }

  getIrrigationConfig(): IrrigationConfig {
    return this.irrigationConfig;
  }

  setIrrigationConfig(config: Partial<IrrigationConfig>): void {
    if (config.isOn !== undefined) {
      this.irrigationConfig.isOn = config.isOn;
    }
    if (config.autoMode !== undefined) {
      this.irrigationConfig.autoMode = config.autoMode;
    }
    if (config.targetMoisture !== undefined) {
      this.irrigationConfig.targetMoisture = config.targetMoisture;
    }
    if (config.duration !== undefined) {
      this.irrigationConfig.duration = config.duration;
    }
    if (config.isOn !== undefined) {
      bleService.sendCommand('irrigation', config.isOn ? 1 : 0);
    }
    if (config.targetMoisture !== undefined) {
      bleService.sendCommand('target_moisture', config.targetMoisture);
    }
  }

  getLightConfig(): LightConfig {
    return this.lightConfig;
  }

  setLightConfig(config: Partial<LightConfig>): void {
    if (config.isOn !== undefined) {
      this.lightConfig.isOn = config.isOn;
    }
    if (config.autoMode !== undefined) {
      this.lightConfig.autoMode = config.autoMode;
    }
    if (config.brightness !== undefined) {
      this.lightConfig.brightness = config.brightness;
    }
    if (config.startTime !== undefined) {
      this.lightConfig.startTime = config.startTime;
    }
    if (config.endTime !== undefined) {
      this.lightConfig.endTime = config.endTime;
    }
    if (config.isOn !== undefined) {
      bleService.sendCommand('light', config.isOn ? 1 : 0);
    }
    if (config.brightness !== undefined) {
      bleService.sendCommand('brightness', config.brightness);
    }
  }

  getAlertHistory(): AlertRecord[] {
    return this.alertHistory;
  }

  clearAlertHistory(): void {
    this.alertHistory = [];
  }

  private checkAlerts(): void {
    this.thresholds.forEach(threshold => {
      let value: number | undefined = undefined;
      if (threshold.name === 'temperature') {
        value = this.currentData.temperature;
      } else if (threshold.name === 'humidity') {
        value = this.currentData.humidity;
      } else if (threshold.name === 'soilMoisture') {
        value = this.currentData.soilMoisture;
      } else if (threshold.name === 'lightLevel') {
        value = this.currentData.lightLevel;
      } else if (threshold.name === 'waterLevel') {
        value = this.currentData.waterLevel;
      } else if (threshold.name === 'co2') {
        value = this.currentData.co2;
      }
      if (value !== undefined) {
        if (value < threshold.minValue || value > threshold.maxValue) {
          const alert: AlertRecord = {
            id: `${Date.now()}_${threshold.name}`,
            type: threshold.name,
            message: `${threshold.name}异常: ${value}${threshold.unit}`,
            value: value,
            threshold: `${threshold.minValue}-${threshold.maxValue}${threshold.unit}`,
            timestamp: Date.now()
          };
          this.alertHistory.unshift(alert);
          if (this.alertCallback) {
            this.alertCallback(alert);
          }
        }
      }
    });
  }

  async autoControl(): Promise<void> {
    if (this.irrigationConfig.autoMode) {
      if (this.currentData.soilMoisture < this.irrigationConfig.targetMoisture - 5) {
        this.setIrrigationConfig({ isOn: true });
      } else if (this.currentData.soilMoisture >= this.irrigationConfig.targetMoisture) {
        this.setIrrigationConfig({ isOn: false });
      }
    }

    if (this.lightConfig.autoMode) {
      if (this.currentData.lightLevel < 200) {
        this.setLightConfig({ isOn: true });
      } else if (this.currentData.lightLevel > 800) {
        this.setLightConfig({ isOn: false });
      }
    }
  }

  calculateIrrigationWater(cropType: string = 'default'): number {
    const moistureDeficit = Math.max(0, this.irrigationConfig.targetMoisture - this.currentData.soilMoisture);
    const tempFactor = this.currentData.temperature > 30 ? 1.2 : (this.currentData.temperature < 15 ? 0.8 : 1.0);
    
    const cropFactors: Record<string, number> = {
      'vegetable': 1.0,
      'fruit': 1.3,
      'grain': 0.8,
      'flower': 1.1,
      'default': 1.0
    };
    
    const cropFactor = cropFactors[cropType] || 1.0;
    const baseWater = moistureDeficit * 0.5;
    const calculatedWater = baseWater * tempFactor * cropFactor;
    
    return Math.round(calculatedWater * 100) / 100;
  }

  getIrrigationWaterEstimate(cropType: string = 'default'): IrrigationWaterEstimate {
    const waterAmount = this.calculateIrrigationWater(cropType);
    const duration = Math.ceil(waterAmount / 0.5);
    const result: IrrigationWaterEstimate = {
      waterAmount: waterAmount,
      duration: duration
    };
    return result;
  }

  simulateDataUpdate(): void {
    const randomVariation = () => Math.random() * 4 - 2;

    this.updateSensorData({
      temperature: Math.max(10, Math.min(40, this.currentData.temperature + randomVariation())),
      humidity: Math.max(30, Math.min(90, this.currentData.humidity + randomVariation())),
      soilMoisture: Math.max(20, Math.min(80, this.currentData.soilMoisture + randomVariation())),
      lightLevel: Math.max(50, Math.min(1000, this.currentData.lightLevel + randomVariation() * 50)),
      waterLevel: Math.max(10, Math.min(100, this.currentData.waterLevel + randomVariation())),
      co2: Math.max(300, Math.min(1500, this.currentData.co2 + randomVariation() * 30)),
      timestamp: Date.now()
    });
  }
}

export const dataManager = DataManager.getInstance();

export { SensorData };
