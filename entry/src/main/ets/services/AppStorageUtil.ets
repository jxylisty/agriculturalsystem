import { SensorData } from './BleService';

export class AppStorageUtil {
  static readonly KEY_TEMPERATURE: string = 'sensor_temperature';
  static readonly KEY_HUMIDITY: string = 'sensor_humidity';
  static readonly KEY_SOIL_MOISTURE: string = 'sensor_soilMoisture';
  static readonly KEY_LIGHT_LEVEL: string = 'sensor_lightLevel';
  static readonly KEY_WATER_LEVEL: string = 'sensor_waterLevel';
  static readonly KEY_CO2: string = 'sensor_co2';
  static readonly KEY_IS_CONNECTED: string = 'is_connected';
  static readonly KEY_MODE_STATUS: string = 'mode_status';

  static init(): void {
    AppStorage.setOrCreate(AppStorageUtil.KEY_TEMPERATURE, 25);
    AppStorage.setOrCreate(AppStorageUtil.KEY_HUMIDITY, 65);
    AppStorage.setOrCreate(AppStorageUtil.KEY_SOIL_MOISTURE, 45);
    AppStorage.setOrCreate(AppStorageUtil.KEY_LIGHT_LEVEL, 300);
    AppStorage.setOrCreate(AppStorageUtil.KEY_WATER_LEVEL, 75);
    AppStorage.setOrCreate(AppStorageUtil.KEY_CO2, 450);
    AppStorage.setOrCreate(AppStorageUtil.KEY_IS_CONNECTED, false);
    AppStorage.setOrCreate(AppStorageUtil.KEY_MODE_STATUS, '本地模拟模式');
  }

  static updateSensorData(data: SensorData): void {
    AppStorage.setOrCreate(AppStorageUtil.KEY_TEMPERATURE, data.temperature);
    AppStorage.setOrCreate(AppStorageUtil.KEY_HUMIDITY, data.humidity);
    AppStorage.setOrCreate(AppStorageUtil.KEY_SOIL_MOISTURE, data.soilMoisture);
    AppStorage.setOrCreate(AppStorageUtil.KEY_LIGHT_LEVEL, data.lightLevel);
    AppStorage.setOrCreate(AppStorageUtil.KEY_WATER_LEVEL, data.waterLevel);
    AppStorage.setOrCreate(AppStorageUtil.KEY_CO2, data.co2);
    console.log('[AppStorageUtil] Sensor data updated:', JSON.stringify(data));
  }

  static setConnected(connected: boolean): void {
    AppStorage.setOrCreate(AppStorageUtil.KEY_IS_CONNECTED, connected);
  }

  static setModeStatus(status: string): void {
    AppStorage.setOrCreate(AppStorageUtil.KEY_MODE_STATUS, status);
  }

  static getTemperature(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_TEMPERATURE) || 25;
  }

  static getHumidity(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_HUMIDITY) || 65;
  }

  static getSoilMoisture(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_SOIL_MOISTURE) || 45;
  }

  static getLightLevel(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_LIGHT_LEVEL) || 300;
  }

  static getWaterLevel(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_WATER_LEVEL) || 75;
  }

  static getCo2(): number {
    return AppStorage.get<number>(AppStorageUtil.KEY_CO2) || 450;
  }

  static isConnected(): boolean {
    return AppStorage.get<boolean>(AppStorageUtil.KEY_IS_CONNECTED) || false;
  }

  static getModeStatus(): string {
    return AppStorage.get<string>(AppStorageUtil.KEY_MODE_STATUS) || '本地模拟模式';
  }
}
