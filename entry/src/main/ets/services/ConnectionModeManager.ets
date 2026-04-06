import { bleService } from './BleService';
import { mqttService, MqttConfig } from './MqttService';
import { oneNetApiService, OneNetConfig } from './OneNetApiService';
import { SensorData } from './BleService';
import { dataManager } from './DataManager';

export type ConnectionMode = 'local' | 'bluetooth' | 'mqtt';

export interface ConnectionStatus {
  mode: ConnectionMode;
  connected: boolean;
  message: string;
}

type StatusCallback = (status: ConnectionStatus) => void;
type DataCallback = (data: SensorData) => void;

class ConnectionModeManager {
  private static instance: ConnectionModeManager;
  private currentMode: ConnectionMode = 'local';
  private connected: boolean = false;
  private statusCallback: StatusCallback | null = null;
  private dataCallback: DataCallback | null = null;

  private constructor() {
    this.setupCallbacks();
  }

  static getInstance(): ConnectionModeManager {
    if (!ConnectionModeManager.instance) {
      ConnectionModeManager.instance = new ConnectionModeManager();
    }
    return ConnectionModeManager.instance;
  }

  private setupCallbacks(): void {
    bleService.onDataReceived((data: SensorData) => {
      console.log('[ConnectionModeManager] Received BLE data:', JSON.stringify(data));
      dataManager.updateSensorData(data);
      if (this.currentMode === 'bluetooth' && this.dataCallback) {
        this.dataCallback(data);
      }
    });

    bleService.onConnectionChange((connected: boolean) => {
      if (this.currentMode === 'bluetooth') {
        this.connected = connected;
        this.notifyStatus();
      }
    });

    mqttService.onSensorData((data: SensorData) => {
      console.log('[ConnectionModeManager] Received MQTT data:', JSON.stringify(data));
      dataManager.updateSensorData(data);
      if (this.currentMode === 'mqtt' && this.dataCallback) {
        this.dataCallback(data);
      }
    });

    mqttService.onConnectionChange((connected: boolean) => {
      if (this.currentMode === 'mqtt') {
        this.connected = connected;
        this.notifyStatus();
      }
    });

    oneNetApiService.onSensorData((data: SensorData) => {
      console.log('[ConnectionModeManager] Received OneNet data:', JSON.stringify(data));
      dataManager.updateSensorData(data);
      if (this.currentMode === 'mqtt' && this.dataCallback) {
        this.dataCallback(data);
      }
    });

    oneNetApiService.onConnectionChange((connected: boolean) => {
      if (this.currentMode === 'mqtt') {
        this.connected = connected;
        this.notifyStatus();
      }
    });
  }

  getCurrentMode(): ConnectionMode {
    return this.currentMode;
  }

  isConnected(): boolean {
    return this.connected;
  }

  getStatus(): ConnectionStatus {
    let message = '';
    if (this.currentMode === 'local') {
      message = '本地模拟模式';
    } else if (this.currentMode === 'bluetooth') {
      message = this.connected ? '蓝牙已连接' : '蓝牙未连接';
    } else if (this.currentMode === 'mqtt') {
      message = this.connected ? 'MQTT已连接' : 'MQTT未连接';
    }

    const status: ConnectionStatus = {
      mode: this.currentMode,
      connected: this.connected,
      message: message
    };
    return status;
  }

  onStatusChange(callback: StatusCallback): void {
    this.statusCallback = callback;
  }

  onDataReceived(callback: DataCallback): void {
    this.dataCallback = callback;
  }

  setMode(mode: ConnectionMode): void {
    if (this.currentMode === mode) {
      return;
    }

    this.disconnectCurrentMode();

    this.currentMode = mode;
    this.connected = false;

    if (mode === 'local') {
      this.connected = true;
    }

    this.notifyStatus();
    console.log('[ConnectionModeManager] Mode changed to:', mode);
  }

  private async disconnectCurrentMode(): Promise<void> {
    if (this.currentMode === 'bluetooth' && bleService.getConnectionStatus()) {
      await bleService.disconnect();
    } else if (this.currentMode === 'mqtt') {
      if (mqttService.isConnected()) {
        await mqttService.disconnect();
      }
      if (oneNetApiService.isConnected()) {
        await oneNetApiService.disconnect();
      }
    }
  }

  async connectBluetooth(): Promise<boolean> {
    if (this.currentMode !== 'bluetooth') {
      this.setMode('bluetooth');
    }

    console.log('[ConnectionModeManager] Starting Bluetooth scan...');
    return true;
  }

  async connectMqtt(config?: MqttConfig): Promise<boolean> {
    if (this.currentMode !== 'mqtt') {
      this.setMode('mqtt');
    }

    if (oneNetApiService.isConnected()) {
      console.log('[ConnectionModeManager] OneNet API already connected');
      return true;
    }

    if (config && config.productId && config.deviceName) {
      const oneNetConfig: OneNetConfig = {
        productId: config.productId,
        deviceName: config.deviceName,
        deviceKey: config.deviceKey,
        token: config.token
      };
      oneNetApiService.setConfig(oneNetConfig);
      
      const success = await oneNetApiService.connect();
      this.connected = success;
      this.notifyStatus();
      return success;
    }

    console.error('[ConnectionModeManager] OneNet config missing');
    return false;
  }

  async disconnect(): Promise<void> {
    await this.disconnectCurrentMode();
    this.connected = false;
    this.notifyStatus();
  }

  async sendCommand(cmd: string, value: number): Promise<boolean> {
    if (!this.connected) {
      console.error('[ConnectionModeManager] Not connected');
      return false;
    }

    if (this.currentMode === 'bluetooth') {
      return bleService.sendCommand(cmd, value);
    } else if (this.currentMode === 'mqtt') {
      if (cmd === 'irrigation') {
        return await oneNetApiService.setIrrigation(value === 1);
      } else if (cmd === 'light') {
        return await oneNetApiService.setLight(value === 1);
      } else if (cmd === 'brightness') {
        return await oneNetApiService.setBrightness(value);
      }
    }

    return false;
  }

  private notifyStatus(): void {
    if (this.statusCallback) {
      this.statusCallback(this.getStatus());
    }
  }
}

export const connectionModeManager = ConnectionModeManager.getInstance();
