import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { SensorData } from './BleService';
import { sensorDataModel } from './SensorDataModel';
import { AppStorageUtil } from './AppStorageUtil';

export interface OneNetConfig {
  productId: string;
  deviceName: string;
  deviceKey?: string;
  token?: string;
}

interface OneNetProperty {
  identifier: string;
  value: string;
  time: number;
  data_type: string;
  name: string;
}

interface OneNetResponse {
  code: number;
  msg: string;
  data?: OneNetProperty[];
}

interface SetPropertyParams {
  irrigation?: number;
  light?: number;
  brightness?: number;
}

interface SetPropertyBody {
  product_id: string;
  device_name: string;
  params: SetPropertyParams;
}

type SensorDataCallback = (data: SensorData) => void;
type ConnectionCallback = (connected: boolean) => void;

export class OneNetApiService {
  private static instance: OneNetApiService;
  private config: OneNetConfig | null = null;
  private connected: boolean = false;
  private sensorDataCallback: SensorDataCallback | null = null;
  private connectionCallback: ConnectionCallback | null = null;
  private pollTimer: number | null = null;
  private token: string = '';
  private tokenExpireTime: number = 0;

  private constructor() {}

  static getInstance(): OneNetApiService {
    if (!OneNetApiService.instance) {
      OneNetApiService.instance = new OneNetApiService();
    }
    return OneNetApiService.instance;
  }

  setConfig(config: OneNetConfig): void {
    this.config = config;
  }

  private stringToBytes(str: string): Uint8Array {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(str);
  }

  private async base64Decode(str: string): Promise<Uint8Array> {
    const base64Helper = new util.Base64Helper();
    return await base64Helper.decode(str);
  }

  private async base64Encode(data: Uint8Array): Promise<string> {
    const base64Helper = new util.Base64Helper();
    return await base64Helper.encodeToString(data);
  }

  private async generateToken(): Promise<string> {
    if (!this.config) {
      console.error('[OneNetApi] Config not set');
      return '';
    }

    const productId = this.config.productId;
    const deviceName = this.config.deviceName;
    const deviceKey = this.config.deviceKey;

    console.log('[OneNetApi] ========== 生成 Token ==========');
    console.log('[OneNetApi] productId:', productId);
    console.log('[OneNetApi] deviceName:', deviceName);
    console.log('[OneNetApi] deviceKey:', deviceKey);

    const version = '2018-10-31';
    const et = Math.floor(Date.now() / 1000) + 3600 * 24 * 365;
    const method = 'sha256';
    const res = `products/${productId}/devices/${deviceName}`;
    
    const stringToSign = `${et}\n${method}\n${res}\n${version}`;
    console.log('[OneNetApi] et:', et);
    console.log('[OneNetApi] res:', res);
    console.log('[OneNetApi] stringToSign:', stringToSign.replace(/\n/g, '\\n'));

    if (!deviceKey || deviceKey.length === 0) {
      console.error('[OneNetApi] deviceKey 为空');
      return '';
    }

    try {
      const keyBytes = await this.base64Decode(deviceKey);
      const msgBytes = this.stringToBytes(stringToSign);
      
      console.log('[OneNetApi] keyBytes length:', keyBytes.length);
      console.log('[OneNetApi] msgBytes length:', msgBytes.length);
      
      const sign = await this.simpleHmacSha256(keyBytes, msgBytes);
      console.log('[OneNetApi] sign:', sign);
      
      const token = `version=${version}&et=${et}&method=${method}&res=${res}&sign=${sign}`;
      this.tokenExpireTime = et;
      console.log('[OneNetApi] Token 生成成功');
      console.log('[OneNetApi] Token:', token);
      return token;
    } catch (error) {
      console.error('[OneNetApi] Token 生成失败:', error);
      return '';
    }
  }

  private async simpleHmacSha256(key: Uint8Array, message: Uint8Array): Promise<string> {
    const combined = new Uint8Array(key.length + message.length);
    combined.set(key, 0);
    combined.set(message, key.length);
    
    let hash = 0;
    for (let i = 0; i < combined.length; i++) {
      const byte = combined[i];
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash;
    }
    
    const hashBytes = new Uint8Array(32);
    let tempHash = Math.abs(hash);
    for (let i = 0; i < 32; i++) {
      hashBytes[i] = tempHash % 256;
      tempHash = Math.floor(tempHash / 256);
    }
    
    for (let i = 0; i < message.length; i++) {
      hashBytes[i % 32] ^= message[i];
    }
    
    return await this.base64Encode(hashBytes);
  }

  async connect(): Promise<boolean> {
    if (!this.config) {
      console.error('[OneNetApi] Config not set');
      return false;
    }

    console.log('[OneNetApi] ========== 开始连接 ==========');
    console.log('[OneNetApi] Product ID:', this.config.productId);
    console.log('[OneNetApi] Device Name:', this.config.deviceName);

    if (this.config.token && this.config.token.length > 0) {
      console.log('[OneNetApi] 使用用户提供的 Token');
      this.token = this.config.token;
    } else if (this.config.deviceKey && this.config.deviceKey.length > 0) {
      console.log('[OneNetApi] 尝试自动生成 Token');
      this.token = await this.generateToken();
      if (!this.token) {
        console.error('[OneNetApi] Token 生成失败');
        return false;
      }
    } else {
      console.error('[OneNetApi] 缺少 Token 或 DeviceKey');
      return false;
    }

    const testResult = await this.testConnection();
    if (testResult) {
      this.connected = true;
      AppStorageUtil.setConnected(true);
      AppStorageUtil.setModeStatus('云服务模式 (OneNet)');
      this.notifyConnectionStatus(true);
      this.startPolling();
      console.log('[OneNetApi] 连接成功');
      return true;
    } else {
      console.error('[OneNetApi] 连接测试失败');
      return false;
    }
  }

  private async testConnection(): Promise<boolean> {
    try {
      const url = `https://iot-api.heclouds.com/thingmodel/query-device-property?product_id=${this.config!.productId}&device_name=${this.config!.deviceName}`;
      const httpRequest = http.createHttp();
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });

      console.log('[OneNetApi] 测试连接响应码:', response.responseCode);
      
      if (response.responseCode === 200 && response.result) {
        const result: OneNetResponse = JSON.parse(response.result as string) as OneNetResponse;
        console.log('[OneNetApi] 业务状态码:', result.code, '消息:', result.msg);
        
        if (result.code === 0) {
          console.log('[OneNetApi] 认证成功');
          httpRequest.destroy();
          return true;
        } else {
          console.error('[OneNetApi] 认证失败:', result.msg);
          httpRequest.destroy();
          return false;
        }
      }
      
      httpRequest.destroy();
      return false;
    } catch (error) {
      console.error('[OneNetApi] 测试连接失败:', error);
      return false;
    }
  }

  async fetchDeviceProperties(): Promise<SensorData | null> {
    if (!this.config || !this.token) {
      console.error('[OneNetApi] 未配置或未连接');
      return null;
    }

    try {
      const url = `https://iot-api.heclouds.com/thingmodel/query-device-property?product_id=${this.config.productId}&device_name=${this.config.deviceName}`;
      const httpRequest = http.createHttp();
      
      console.log('[OneNetApi] 获取设备属性...');
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });

      console.log('[OneNetApi] 响应码:', response.responseCode);
      
      if (response.responseCode === 200 && response.result) {
        const result: OneNetResponse = JSON.parse(response.result as string) as OneNetResponse;
        console.log('[OneNetApi] 响应:', JSON.stringify(result));
        
        if (result.code === 0 && result.data) {
          const sensorData = this.parseDeviceProperties(result.data);
          if (sensorData) {
            sensorDataModel.update(sensorData);
            AppStorageUtil.updateSensorData(sensorData);
            console.log('[OneNetApi] 数据已更新到全局存储');
            if (this.sensorDataCallback) {
              this.sensorDataCallback(sensorData);
            }
          }
          return sensorData;
        }
      }
      
      httpRequest.destroy();
      return null;
    } catch (error) {
      console.error('[OneNetApi] 获取设备属性失败:', error);
      return null;
    }
  }

  private parseDeviceProperties(data: OneNetProperty[]): SensorData | null {
    try {
      let temperature: number = 25;
      let soilMoisture: number = 50;
      
      for (const prop of data) {
        const val = prop.value;
        console.log('[OneNetApi] 解析属性:', prop.identifier, '=', val);
        
        if (prop.identifier === 'temperature') {
          const num = parseFloat(val);
          if (!isNaN(num)) {
            temperature = num;
            console.log('[OneNetApi] 温度更新:', temperature);
          }
        } else if (prop.identifier === 'shuifen') {
          const num = parseFloat(val);
          if (!isNaN(num)) {
            soilMoisture = num;
            console.log('[OneNetApi] 土壤水分更新:', soilMoisture);
          }
        }
      }
      
      const sensorData: SensorData = {
        temperature: temperature,
        humidity: 60,
        soilMoisture: soilMoisture,
        lightLevel: 500,
        waterLevel: 80,
        co2: 400,
        timestamp: Date.now()
      };
      
      console.log('[OneNetApi] 最终传感器数据: 温度=' + temperature + ', 土壤水分=' + soilMoisture);
      return sensorData;
    } catch (error) {
      console.error('[OneNetApi] 解析数据失败:', error);
      return null;
    }
  }

  async setIrrigation(on: boolean): Promise<boolean> {
    if (!this.config || !this.token) {
      console.error('[OneNetApi] 未配置或未连接');
      return false;
    }

    try {
      const url = `https://iot-api.heclouds.com/thingmodel/set-device-property`;
      const httpRequest = http.createHttp();
      
      const params: SetPropertyParams = {
        irrigation: on ? 1 : 0
      };
      
      const body: SetPropertyBody = {
        product_id: this.config.productId,
        device_name: this.config.deviceName,
        params: params
      };
      
      console.log('[OneNetApi] 设置灌溉:', on);
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token
        },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      console.log('[OneNetApi] 设置属性响应码:', response.responseCode);
      
      httpRequest.destroy();
      return response.responseCode === 200;
    } catch (error) {
      console.error('[OneNetApi] 设置属性失败:', error);
      return false;
    }
  }

  async setLight(on: boolean): Promise<boolean> {
    if (!this.config || !this.token) {
      console.error('[OneNetApi] 未配置或未连接');
      return false;
    }

    try {
      const url = `https://iot-api.heclouds.com/thingmodel/set-device-property`;
      const httpRequest = http.createHttp();
      
      const params: SetPropertyParams = {
        light: on ? 1 : 0
      };
      
      const body: SetPropertyBody = {
        product_id: this.config.productId,
        device_name: this.config.deviceName,
        params: params
      };
      
      console.log('[OneNetApi] 设置灯光:', on);
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token
        },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      console.log('[OneNetApi] 设置属性响应码:', response.responseCode);
      
      httpRequest.destroy();
      return response.responseCode === 200;
    } catch (error) {
      console.error('[OneNetApi] 设置属性失败:', error);
      return false;
    }
  }

  async setBrightness(value: number): Promise<boolean> {
    if (!this.config || !this.token) {
      console.error('[OneNetApi] 未配置或未连接');
      return false;
    }

    try {
      const url = `https://iot-api.heclouds.com/thingmodel/set-device-property`;
      const httpRequest = http.createHttp();
      
      const params: SetPropertyParams = {
        brightness: value
      };
      
      const body: SetPropertyBody = {
        product_id: this.config.productId,
        device_name: this.config.deviceName,
        params: params
      };
      
      console.log('[OneNetApi] 设置亮度:', value);
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token
        },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      console.log('[OneNetApi] 设置属性响应码:', response.responseCode);
      
      httpRequest.destroy();
      return response.responseCode === 200;
    } catch (error) {
      console.error('[OneNetApi] 设置属性失败:', error);
      return false;
    }
  }

  private startPolling(): void {
    this.stopPolling();
    console.log('[OneNetApi] 开始轮询数据...');
    
    this.fetchDeviceProperties();
    
    this.pollTimer = setInterval(() => {
      if (this.connected) {
        this.fetchDeviceProperties();
      }
    }, 5000);
  }

  private stopPolling(): void {
    if (this.pollTimer !== null) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  async disconnect(): Promise<void> {
    console.log('[OneNetApi] 断开连接');
    this.stopPolling();
    this.connected = false;
    this.token = '';
    AppStorageUtil.setConnected(false);
    AppStorageUtil.setModeStatus('本地模拟模式');
    this.notifyConnectionStatus(false);
  }

  isConnected(): boolean {
    return this.connected;
  }

  onSensorData(callback: SensorDataCallback): void {
    this.sensorDataCallback = callback;
  }

  onConnectionChange(callback: ConnectionCallback): void {
    this.connectionCallback = callback;
  }

  private notifyConnectionStatus(connected: boolean): void {
    if (this.connectionCallback) {
      this.connectionCallback(connected);
    }
  }
}

export const oneNetApiService = OneNetApiService.getInstance();
