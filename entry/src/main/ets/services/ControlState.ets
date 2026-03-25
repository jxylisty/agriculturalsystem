import { SensorData } from './BleService';

let isProgrammaticUpdate = false;

export function setProgrammaticUpdate(value: boolean): void {
  isProgrammaticUpdate = value;
}

export function getProgrammaticUpdate(): boolean {
  return isProgrammaticUpdate;
}

@Observed
export class ControlState {
  irrigationOn: boolean = false;
  irrigationAutoMode: boolean = true;
  targetMoisture: number = 50;
  
  lightOn: boolean = false;
  lightAutoMode: boolean = true;
  lightBrightness: number = 50;

  updateIrrigation(on: boolean, autoMode?: boolean, targetMoisture?: number): void {
    this.irrigationOn = on;
    if (autoMode !== undefined) this.irrigationAutoMode = autoMode;
    if (targetMoisture !== undefined) this.targetMoisture = targetMoisture;
  }

  updateLight(on: boolean, autoMode?: boolean, brightness?: number): void {
    this.lightOn = on;
    if (autoMode !== undefined) this.lightAutoMode = autoMode;
    if (brightness !== undefined) this.lightBrightness = brightness;
  }
}

export const controlState = new ControlState();

export class ControlStateUtil {
  static getIrrigationOn(): boolean {
    return AppStorage.get<boolean>('irrigationOn') ?? false;
  }
  static setIrrigationOn(value: boolean): void {
    AppStorage.setOrCreate('irrigationOn', value);
  }
  
  static getIrrigationAutoMode(): boolean {
    return AppStorage.get<boolean>('irrigationAutoMode') ?? true;
  }
  static setIrrigationAutoMode(value: boolean): void {
    AppStorage.setOrCreate('irrigationAutoMode', value);
  }
  
  static getTargetMoisture(): number {
    return AppStorage.get<number>('targetMoisture') ?? 50;
  }
  static setTargetMoisture(value: number): void {
    AppStorage.setOrCreate('targetMoisture', value);
  }
  
  static getLightOn(): boolean {
    return AppStorage.get<boolean>('lightOn') ?? false;
  }
  static setLightOn(value: boolean): void {
    AppStorage.setOrCreate('lightOn', value);
  }
  
  static getLightAutoMode(): boolean {
    return AppStorage.get<boolean>('lightAutoMode') ?? true;
  }
  static setLightAutoMode(value: boolean): void {
    AppStorage.setOrCreate('lightAutoMode', value);
  }
  
  static getLightBrightness(): number {
    return AppStorage.get<number>('lightBrightness') ?? 50;
  }
  static setLightBrightness(value: number): void {
    AppStorage.setOrCreate('lightBrightness', value);
  }

  static updateIrrigation(on: boolean, autoMode?: boolean, targetMoisture?: number): void {
    console.log('[ControlStateUtil] updateIrrigation called: on=' + on + ', autoMode=' + autoMode + ', targetMoisture=' + targetMoisture);
    
    setProgrammaticUpdate(true);
    ControlStateUtil.setIrrigationOn(on);
    if (autoMode !== undefined) ControlStateUtil.setIrrigationAutoMode(autoMode);
    if (targetMoisture !== undefined) ControlStateUtil.setTargetMoisture(targetMoisture);
    
    controlState.irrigationOn = on;
    if (autoMode !== undefined) controlState.irrigationAutoMode = autoMode;
    if (targetMoisture !== undefined) controlState.targetMoisture = targetMoisture;
    
    console.log('[ControlStateUtil] updateIrrigation done. AppStorage irrigationOn=' + AppStorage.get<boolean>('irrigationOn'));
  }

  static updateLight(on: boolean, autoMode?: boolean, brightness?: number): void {
    console.log('[ControlStateUtil] updateLight called: on=' + on + ', autoMode=' + autoMode + ', brightness=' + brightness);
    
    setProgrammaticUpdate(true);
    ControlStateUtil.setLightOn(on);
    if (autoMode !== undefined) ControlStateUtil.setLightAutoMode(autoMode);
    if (brightness !== undefined) ControlStateUtil.setLightBrightness(brightness);
    
    controlState.lightOn = on;
    if (autoMode !== undefined) controlState.lightAutoMode = autoMode;
    if (brightness !== undefined) controlState.lightBrightness = brightness;
    
    console.log('[ControlStateUtil] updateLight done. AppStorage lightOn=' + AppStorage.get<boolean>('lightOn') + ', lightBrightness=' + AppStorage.get<number>('lightBrightness'));
  }

  static initDefaults(): void {
    console.log('[ControlStateUtil] initDefaults called');
    if (AppStorage.get<boolean>('irrigationOn') === undefined) {
      ControlStateUtil.setIrrigationOn(false);
    }
    if (AppStorage.get<boolean>('irrigationAutoMode') === undefined) {
      ControlStateUtil.setIrrigationAutoMode(true);
    }
    if (AppStorage.get<number>('targetMoisture') === undefined) {
      ControlStateUtil.setTargetMoisture(50);
    }
    if (AppStorage.get<boolean>('lightOn') === undefined) {
      ControlStateUtil.setLightOn(false);
    }
    if (AppStorage.get<boolean>('lightAutoMode') === undefined) {
      ControlStateUtil.setLightAutoMode(true);
    }
    if (AppStorage.get<number>('lightBrightness') === undefined) {
      ControlStateUtil.setLightBrightness(50);
    }
  }
}
