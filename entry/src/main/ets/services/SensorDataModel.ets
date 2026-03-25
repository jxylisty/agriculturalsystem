import { SensorData } from './BleService';

@Observed
export class SensorDataModel {
  temperature: number = 25;
  humidity: number = 65;
  soilMoisture: number = 45;
  lightLevel: number = 300;
  waterLevel: number = 75;
  co2: number = 450;
  timestamp: number = Date.now();

  update(data: SensorData): void {
    console.log('[SensorDataModel] update called: temp=' + data.temperature + ', humidity=' + data.humidity);
    this.temperature = data.temperature;
    this.humidity = data.humidity;
    this.soilMoisture = data.soilMoisture;
    this.lightLevel = data.lightLevel;
    this.waterLevel = data.waterLevel;
    this.co2 = data.co2;
    this.timestamp = data.timestamp || Date.now();
    console.log('[SensorDataModel] update done: this.temperature=' + this.temperature);
  }
}

export const sensorDataModel = new SensorDataModel();
