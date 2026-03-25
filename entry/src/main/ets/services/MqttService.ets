import { webSocket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';
import { SensorData } from './BleService';
import { controlState, ControlStateUtil } from './ControlState';
import { sensorDataModel } from './SensorDataModel';
import { AppStorageUtil } from './AppStorageUtil';

export const SENSOR_DATA_EVENT_ID = 10001;
export const CONTROL_CMD_EVENT_ID = 10002;

export interface MqttConfig {
  brokerUrl: string;
  port: number;
  clientId: string;
  username?: string;
  password?: string;
}

interface SensorMessage {
  temperature?: number;
  humidity?: number;
  soilMoisture?: number;
  lightLevel?: number;
  waterLevel?: number;
  co2?: number;
  timestamp?: number;
}

interface ControlMessage {
  cmd?: string;
  value?: number;
  irrigation?: boolean;
  irrigationAuto?: boolean;
  targetMoisture?: number;
  light?: boolean;
  lightAuto?: boolean;
  brightness?: number;
  timestamp?: number;
  fromSelf?: boolean;
}

type SensorDataCallback = (data: SensorData) => void;
type ConnectionCallback = (connected: boolean) => void;
type ControlCallback = (cmd: string, value: number) => void;

export class MqttService {
  private static instance: MqttService;
  private config: MqttConfig | null = null;
  private connected: boolean = false;
  private mqttConnected: boolean = false;
  private sensorDataCallback: SensorDataCallback | null = null;
  private connectionCallback: ConnectionCallback | null = null;
  private controlCallback: ControlCallback | null = null;
  private latestData: SensorData | null = null;
  private ws: webSocket.WebSocket | null = null;
  private dataTopic: string = 'agriculture/sensor/data';
  private cmdTopic: string = 'agriculture/cmd';
  private cmdResponseTopic: string = 'agriculture/cmd/response';
  private keepAliveTimer: number | null = null;
  private connectResolve: ((success: boolean) => void) | null = null;
  private packetId: number = 1;
  private lastSentTimestamps: Map<string, number> = new Map();

  private constructor() {}

  static getInstance(): MqttService {
    if (!MqttService.instance) {
      MqttService.instance = new MqttService();
    }
    return MqttService.instance;
  }

  setConfig(config: MqttConfig): void {
    this.config = config;
  }

  async connect(): Promise<boolean> {
    if (!this.config) {
      console.error('[MqttService] Config not set');
      return false;
    }

    if (this.connected && this.mqttConnected) {
      return true;
    }

    try {
      console.log('[MqttService] Connecting to:', this.config.brokerUrl);

      this.ws = webSocket.createWebSocket();

      const wsUrl = this.buildWebSocketUrl();
      console.log('[MqttService] WebSocket URL:', wsUrl);

      this.ws.on('message', (err, value) => {
        if (err) {
          console.error('[MqttService] Message error:', err);
          return;
        }
        this.handleMqttMessage(value);
      });

      this.ws.on('close', (err, value) => {
        console.log('[MqttService] WebSocket closed');
        this.handleDisconnect();
      });

      this.ws.on('error', (err) => {
        console.error('[MqttService] WebSocket error:', err);
        if (this.connectResolve) {
          this.connectResolve(false);
          this.connectResolve = null;
        }
      });

      this.ws.on('open', (err, value) => {
        if (err) {
          console.error('[MqttService] WebSocket open error:', err);
          if (this.connectResolve) {
            this.connectResolve(false);
            this.connectResolve = null;
          }
          return;
        }
        console.log('[MqttService] WebSocket opened, sending MQTT CONNECT');
        this.connected = true;
        AppStorageUtil.setConnected(true);
        AppStorageUtil.setModeStatus('云服务模式');
        this.sendMqttConnect();
      });

      const connectResult = await this.ws.connect(wsUrl, {
        protocol: 'mqtt'
      });
      console.log('[MqttService] WebSocket connect result:', connectResult);

      if (!connectResult) {
        console.error('[MqttService] WebSocket connect failed');
        return false;
      }

      console.log('[MqttService] Waiting for WebSocket open...');

      return new Promise<boolean>((resolve) => {
        this.connectResolve = resolve;
        setTimeout(() => {
          if (this.connectResolve) {
            console.log('[MqttService] MQTT connection timeout');
            this.connectResolve(false);
            this.connectResolve = null;
          }
        }, 10000);
      });
    } catch (error) {
      console.error('[MqttService] Connection failed:', error);
      this.handleDisconnect();
      return false;
    }
  }

  private buildWebSocketUrl(): string {
    const host = this.config!.brokerUrl;
    const clientId = this.config!.clientId || 'harmony-app-' + Date.now();
    return `wss://${host}:8084/mqtt?clientId=${clientId}`;
  }

  private sendMqttConnect(): void {
    const clientId = this.config!.clientId || 'harmony-app-' + Date.now();
    const keepAlive = 60;

    const clientIdBytes = this.stringToBytes(clientId);
    const variableHeader = new Uint8Array([
      0x00, 0x04,
      0x4D, 0x51, 0x54, 0x54,
      0x04,
      0x02,
      (keepAlive >> 8) & 0xFF,
      keepAlive & 0xFF
    ]);

    const payload = new Uint8Array(2 + clientIdBytes.length);
    payload[0] = (clientIdBytes.length >> 8) & 0xFF;
    payload[1] = clientIdBytes.length & 0xFF;
    payload.set(clientIdBytes, 2);

    const remainingLength = variableHeader.length + payload.length;
    const encodedLength = this.encodeRemainingLength(remainingLength);
    const packet = new Uint8Array(1 + encodedLength.length + remainingLength);
    
    packet[0] = 0x10;
    packet.set(encodedLength, 1);
    packet.set(variableHeader, 1 + encodedLength.length);
    packet.set(payload, 1 + encodedLength.length + variableHeader.length);

    this.sendRaw(packet);
    console.log('[MqttService] Sent MQTT CONNECT, clientId:', clientId);
  }

  private encodeRemainingLength(length: number): Uint8Array {
    const bytes: number[] = [];
    let remaining = length;
    do {
      let byte = remaining % 128;
      remaining = Math.floor(remaining / 128);
      if (remaining > 0) {
        byte |= 0x80;
      }
      bytes.push(byte);
    } while (remaining > 0);
    return new Uint8Array(bytes);
  }

  private stringToBytes(str: string): Uint8Array {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(str);
  }

  private sendRaw(data: Uint8Array): void {
    if (this.ws) {
      const buffer = data.buffer;
      this.ws.send(buffer).then(() => {
        console.log('[MqttService] Sent raw data, length:', data.length);
      }).catch((err: Error) => {
        console.error('[MqttService] Send raw error:', err);
      });
    }
  }

  private handleMqttMessage(value: string | ArrayBuffer): void {
    try {
      let data: Uint8Array;
      if (typeof value === 'string') {
        const encoder = new util.TextEncoder();
        data = encoder.encodeInto(value);
      } else {
        data = new Uint8Array(value);
      }

      if (data.length === 0) return;

      const packetType = (data[0] & 0xF0) >> 4;
      console.log('[MqttService] Received MQTT packet type:', packetType, 'length:', data.length);

      switch (packetType) {
        case 2:
          this.handleConnack(data);
          break;
        case 3:
          this.handlePublish(data);
          break;
        case 4:
          console.log('[MqttService] Received PUBACK');
          break;
        case 9:
          console.log('[MqttService] Received SUBACK');
          break;
        case 13:
          console.log('[MqttService] Received PINGRESP');
          break;
        default:
          console.log('[MqttService] Unknown packet type:', packetType);
      }
    } catch (error) {
      console.error('[MqttService] Handle MQTT message error:', error);
    }
  }

  private handleConnack(data: Uint8Array): void {
    console.log('[MqttService] CONNACK data:', data[0], data[1], data[2], data[3]);
    if (data.length >= 4 && data[3] === 0x00) {
      console.log('[MqttService] MQTT CONNACK - Connection accepted');
      this.mqttConnected = true;
      this.notifyConnectionStatus(true);
      this.subscribeTopics();
      this.startKeepAlive();
      
      if (this.connectResolve) {
        this.connectResolve(true);
        this.connectResolve = null;
      }
    } else {
      console.error('[MqttService] MQTT CONNACK - Connection rejected, code:', data[3]);
      if (this.connectResolve) {
        this.connectResolve(false);
        this.connectResolve = null;
      }
    }
  }

  private handlePublish(data: Uint8Array): void {
    try {
      let index = 1;
      while ((data[index] & 0x80) !== 0) {
        index++;
      }
      index++;

      const topicLength = (data[index] << 8) | data[index + 1];
      index += 2;

      const topicBytes = data.slice(index, index + topicLength);
      const decoder = new util.TextDecoder();
      const topic = decoder.decodeToString(topicBytes);
      index += topicLength;

      const qos = (data[0] & 0x06) >> 1;
      if (qos > 0) {
        index += 2;
      }

      const payload = data.slice(index);
      const payloadStr = decoder.decodeToString(payload);
      
      console.log('[MqttService] Received PUBLISH on topic:', topic, 'payload:', payloadStr);
      
      if (topic === this.dataTopic) {
        this.processSensorData(payloadStr);
      } else if (topic === this.cmdResponseTopic) {
        this.processControlCommand(payloadStr);
      } else {
        console.log('[MqttService] Unknown topic, ignoring:', topic);
      }
    } catch (error) {
      console.error('[MqttService] Handle PUBLISH error:', error);
    }
  }

  private processSensorData(text: string): void {
    console.log('[MqttService] processSensorData ENTRY, raw text: ' + text);
    
    try {
      const data: SensorMessage = JSON.parse(text) as SensorMessage;

      const sensorData: SensorData = {
        temperature: data.temperature ?? this.latestData?.temperature ?? 25,
        humidity: data.humidity ?? this.latestData?.humidity ?? 60,
        soilMoisture: data.soilMoisture ?? this.latestData?.soilMoisture ?? 50,
        lightLevel: data.lightLevel ?? this.latestData?.lightLevel ?? 500,
        waterLevel: data.waterLevel ?? this.latestData?.waterLevel ?? 80,
        co2: data.co2 ?? this.latestData?.co2 ?? 400,
        timestamp: data.timestamp ?? Date.now()
      };

      this.latestData = sensorData;
      console.log('[MqttService] Parsed sensor data: temp=' + sensorData.temperature + ', humidity=' + sensorData.humidity);

      // 直接更新数据模型，ArkUI会自动处理UI更新
      console.log('[MqttService] START, before update: sensorDataModel.temperature=' + sensorDataModel.temperature);
      sensorDataModel.update(sensorData);
      console.log('[MqttService] END, after update: sensorDataModel.temperature=' + sensorDataModel.temperature);

      emitter.emit({ eventId: SENSOR_DATA_EVENT_ID }, { data: sensorData });
      console.log('[MqttService] Emitted sensor data event');

      if (this.sensorDataCallback) {
        this.sensorDataCallback(sensorData);
      }

      console.log('[MqttService] Sensor data process done: temp=' + sensorData.temperature);
    } catch (error) {
      console.log('[MqttService] Not valid sensor JSON, error: ' + error);
    }
  }

  private processControlCommand(text: string): void {
    console.log('[MqttService] processControlCommand ENTRY, raw text: ' + text);
    
    try {
      const msg: ControlMessage = JSON.parse(text) as ControlMessage;
      console.log('[MqttService] Parsed msg: cmd=' + msg.cmd + ', value=' + msg.value + ', light=' + msg.light + ', brightness=' + msg.brightness + ', fromSelf=' + msg.fromSelf + ', timestamp=' + msg.timestamp);

      if (msg.fromSelf === true) {
        console.log('[MqttService] Ignoring message with fromSelf=true');
        return;
      }

      if (msg.timestamp !== undefined) {
        const cmdKey = msg.cmd || 'unknown';
        const lastSent = this.lastSentTimestamps.get(cmdKey);
        if (lastSent !== undefined && Math.abs(msg.timestamp - lastSent) < 2000) {
          console.log('[MqttService] Ignoring self-sent command by timestamp: ' + cmdKey + ', lastSent=' + lastSent + ', msg.timestamp=' + msg.timestamp);
          return;
        }
      }

      if (msg.cmd !== undefined && msg.value !== undefined) {
        console.log('[MqttService] Processing cmd=' + msg.cmd + ', value=' + msg.value);
        switch (msg.cmd) {
          case 'irrigation':
            ControlStateUtil.updateIrrigation(msg.value === 1);
            break;
          case 'light':
            ControlStateUtil.updateLight(msg.value === 1);
            break;
          case 'brightness':
            ControlStateUtil.updateLight(ControlStateUtil.getLightOn(), undefined, msg.value);
            break;
          case 'target_moisture':
            ControlStateUtil.updateIrrigation(ControlStateUtil.getIrrigationOn(), undefined, msg.value);
            break;
        }
        if (this.controlCallback) {
          this.controlCallback(msg.cmd, msg.value);
        }
      }

      if (msg.irrigation !== undefined) {
        console.log('[MqttService] Processing irrigation=' + msg.irrigation + ', irrigationAuto=' + msg.irrigationAuto + ', targetMoisture=' + msg.targetMoisture);
        ControlStateUtil.updateIrrigation(msg.irrigation, msg.irrigationAuto, msg.targetMoisture);
      }

      if (msg.light !== undefined) {
        console.log('[MqttService] Processing light=' + msg.light + ', lightAuto=' + msg.lightAuto + ', brightness=' + msg.brightness);
        ControlStateUtil.updateLight(msg.light, msg.lightAuto, msg.brightness);
      }

      console.log('[MqttService] Control state updated successfully');
    } catch (error) {
      console.log('[MqttService] Not valid control JSON, error: ' + error);
    }
  }

  private subscribeTopics(): void {
    console.log('[MqttService] Subscribing to topics...');
    this.subscribeTopic(this.dataTopic);
    this.subscribeTopic(this.cmdResponseTopic);
  }

  private subscribeTopic(topic: string): void {
    const topicBytes = this.stringToBytes(topic);
    const packetId = this.packetId++;
    
    const variableHeader = new Uint8Array([
      (packetId >> 8) & 0xFF,
      packetId & 0xFF
    ]);

    const payload = new Uint8Array(2 + topicBytes.length + 1);
    payload[0] = (topicBytes.length >> 8) & 0xFF;
    payload[1] = topicBytes.length & 0xFF;
    payload.set(topicBytes, 2);
    payload[2 + topicBytes.length] = 0x00;

    const remainingLength = variableHeader.length + payload.length;
    const encodedLength = this.encodeRemainingLength(remainingLength);
    const packet = new Uint8Array(1 + encodedLength.length + remainingLength);
    
    packet[0] = 0x82;
    packet.set(encodedLength, 1);
    packet.set(variableHeader, 1 + encodedLength.length);
    packet.set(payload, 1 + encodedLength.length + variableHeader.length);

    this.sendRaw(packet);
    console.log('[MqttService] Sent MQTT SUBSCRIBE to:', topic);
  }

  private publish(topic: string, payloadStr: string): void {
    const topicBytes = this.stringToBytes(topic);
    const payloadBytes = this.stringToBytes(payloadStr);
    const packetId = this.packetId++;

    const variableHeader = new Uint8Array(2 + topicBytes.length + 2);
    variableHeader[0] = (topicBytes.length >> 8) & 0xFF;
    variableHeader[1] = topicBytes.length & 0xFF;
    variableHeader.set(topicBytes, 2);
    variableHeader[2 + topicBytes.length] = (packetId >> 8) & 0xFF;
    variableHeader[2 + topicBytes.length + 1] = packetId & 0xFF;

    const remainingLength = variableHeader.length + payloadBytes.length;
    const encodedLength = this.encodeRemainingLength(remainingLength);
    const packet = new Uint8Array(1 + encodedLength.length + remainingLength);
    
    packet[0] = 0x32;
    packet.set(encodedLength, 1);
    packet.set(variableHeader, 1 + encodedLength.length);
    packet.set(payloadBytes, 1 + encodedLength.length + variableHeader.length);

    this.sendRaw(packet);
    console.log('[MqttService] Published to:', topic, 'payload:', payloadStr);
  }

  private sendPingreq(): void {
    const packet = new Uint8Array([0xC0, 0x00]);
    this.sendRaw(packet);
    console.log('[MqttService] Sent MQTT PINGREQ');
  }

  async disconnect(): Promise<void> {
    console.log('[MqttService] Disconnecting...');

    this.stopKeepAlive();

    if (this.ws && this.mqttConnected) {
      const packet = new Uint8Array([0xE0, 0x00]);
      this.sendRaw(packet);
    }

    if (this.ws) {
      try {
        await this.ws.close();
      } catch (error) {
        console.error('[MqttService] Close error:', error);
      }
      this.ws = null;
    }

    this.handleDisconnect();
  }

  private handleDisconnect(): void {
    this.connected = false;
    this.mqttConnected = false;
    AppStorageUtil.setConnected(false);
    AppStorageUtil.setModeStatus('本地模拟模式');
    this.notifyConnectionStatus(false);
    console.log('[MqttService] Disconnected');
  }

  private startKeepAlive(): void {
    this.stopKeepAlive();
    this.keepAliveTimer = setInterval(() => {
      if (this.mqttConnected) {
        this.sendPingreq();
      }
    }, 30000);
  }

  private stopKeepAlive(): void {
    if (this.keepAliveTimer !== null) {
      clearInterval(this.keepAliveTimer);
      this.keepAliveTimer = null;
    }
  }

  isConnected(): boolean {
    return this.mqttConnected;
  }

  onSensorData(callback: SensorDataCallback): void {
    this.sensorDataCallback = callback;
  }

  onConnectionChange(callback: ConnectionCallback): void {
    this.connectionCallback = callback;
  }

  onControlCommand(callback: ControlCallback): void {
    this.controlCallback = callback;
  }

  getLatestData(): SensorData | null {
    return this.latestData;
  }

  publishIrrigationCommand(on: boolean, autoMode?: boolean, targetMoisture?: number): void {
    const timestamp = Date.now();
    const payload: ControlMessage = {
      cmd: 'irrigation',
      value: on ? 1 : 0,
      irrigation: on,
      irrigationAuto: autoMode,
      targetMoisture: targetMoisture,
      timestamp: timestamp,
      fromSelf: true
    };
    this.lastSentTimestamps.set('irrigation', timestamp);
    console.log('[MqttService] publishIrrigationCommand: on=' + on + ', autoMode=' + autoMode + ', targetMoisture=' + targetMoisture);
    this.publish(this.cmdTopic, JSON.stringify(payload));
  }

  publishLightCommand(on: boolean, autoMode?: boolean, brightness?: number): void {
    const timestamp = Date.now();
    const payload: ControlMessage = {
      cmd: 'light',
      value: on ? 1 : 0,
      light: on,
      lightAuto: autoMode,
      brightness: brightness,
      timestamp: timestamp,
      fromSelf: true
    };
    this.lastSentTimestamps.set('light', timestamp);
    console.log('[MqttService] publishLightCommand: on=' + on + ', autoMode=' + autoMode + ', brightness=' + brightness);
    this.publish(this.cmdTopic, JSON.stringify(payload));
  }

  publishBrightnessCommand(brightness: number): void {
    const timestamp = Date.now();
    const payload: ControlMessage = {
      cmd: 'brightness',
      value: brightness,
      brightness: brightness,
      timestamp: timestamp,
      fromSelf: true
    };
    this.lastSentTimestamps.set('brightness', timestamp);
    console.log('[MqttService] publishBrightnessCommand: brightness=' + brightness);
    this.publish(this.cmdTopic, JSON.stringify(payload));
  }

  publishLightDirectionalCommand(east: number, west: number, south: number, north: number): void {
    const timestamp = Date.now();
    const avgBrightness = 50;
    const payload: ControlMessage = {
      cmd: 'light',
      value: avgBrightness,
      brightness: avgBrightness,
      timestamp: timestamp,
      fromSelf: true
    };
    this.lastSentTimestamps.set('light', timestamp);
    console.log('[MqttService] publishLightBrightness: fixed value=50');
    this.publish(this.cmdTopic, JSON.stringify(payload));
  }

  publishTargetMoistureCommand(moisture: number): void {
    const timestamp = Date.now();
    const payload: ControlMessage = {
      cmd: 'target_moisture',
      value: moisture,
      targetMoisture: moisture,
      timestamp: timestamp,
      fromSelf: true
    };
    this.lastSentTimestamps.set('target_moisture', timestamp);
    console.log('[MqttService] publishTargetMoistureCommand: moisture=' + moisture);
    this.publish(this.cmdTopic, JSON.stringify(payload));
  }

  private notifyConnectionStatus(connected: boolean): void {
    if (this.connectionCallback) {
      this.connectionCallback(connected);
    }
  }
}

export const mqttService = MqttService.getInstance();
