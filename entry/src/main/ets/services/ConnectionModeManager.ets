import { bleService } from './BleService';
import { mqttService, MqttConfig } from './MqttService';
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
    } else if (this.currentMode === 'mqtt' && mqttService.isConnected()) {
      await mqttService.disconnect();
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

    if (mqttService.isConnected()) {
      console.log('[ConnectionModeManager] MQTT already connected');
      return true;
    }

    if (config) {
      mqttService.setConfig(config);
    }

    const success = await mqttService.connect();
    this.connected = success;
    this.notifyStatus();
    return success;
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
        mqttService.publishIrrigationCommand(value === 1);
        return true;
      } else if (cmd === 'light') {
        mqttService.publishLightCommand(value === 1);
        return true;
      } else if (cmd === 'brightness') {
        mqttService.publishBrightnessCommand(value);
        return true;
      } else if (cmd === 'target_moisture') {
        mqttService.publishTargetMoistureCommand(value);
        return true;
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
