@ObservedV2
export class BatteryInfo {
  @Trace level: number;
  @Trace health: number;
  @Trace temperature: number;
  @Trace status: 'charging' | 'discharging' | 'full' | 'unknown';

  constructor(level: number, health: number, temperature: number,
    status: 'charging' | 'discharging' | 'full' | 'unknown') {
    this.level = level;
    this.health = health;
    this.temperature = temperature;
    this.status = status;
  }
}

export class SystemMemInfo {
  totalMem: bigint;
  freeMem: bigint;
  availableMem: bigint;

  constructor(totalMem: bigint, freeMem: bigint, availableMem: bigint) {
    this.totalMem = totalMem;
    this.freeMem = freeMem;
    this.availableMem = availableMem;
  }
}

export class StorageInfo {
  total: number;
  used: number;
  free: number;

  constructor(total: number, used: number, free: number) {
    this.total = total;
    this.used = used;
    this.free = free;
  }
}

@ObservedV2
export class PerformanceInfo {
  @Trace cpu: number;
  @Trace memory: SystemMemInfo;
  @Trace storage: StorageInfo;

  constructor(cpu: number, memory: SystemMemInfo, storage: StorageInfo) {
    this.cpu = cpu;
    this.memory = memory;
    this.storage = storage;
  }
}

@ObservedV2
export class NetworkInfo {
  @Trace isConnected: boolean;
  @Trace type: NetType;
  @Trace signalStrength: number; // 0-4
  @Trace networkGeneration?: string;
  @Trace downloadSpeed: number; // kbps
  @Trace uploadSpeed: number; // kbps
  @Trace latency: number; // ms
  @Trace packetLoss: number; // percentage
  @Trace isMetered: boolean;
  @Trace isBlocked: boolean;
  @Trace is5GReady: boolean;

  constructor(
    isConnected: boolean,
    type: NetType,
    signalStrength: number,
    downloadSpeed: number,
    uploadSpeed: number,
    latency: number,
    packetLoss: number,
    isMetered: boolean,
    isBlocked: boolean,
    is5GReady: boolean,
    networkGeneration?: string,
  ) {
    this.isConnected = isConnected;
    this.type = type;
    this.signalStrength = signalStrength;
    this.networkGeneration = networkGeneration;
    this.downloadSpeed = downloadSpeed;
    this.uploadSpeed = uploadSpeed;
    this.latency = latency;
    this.packetLoss = packetLoss;
    this.isMetered = isMetered;
    this.isBlocked = isBlocked;
    this.is5GReady = is5GReady;
  }
}

export type NetworkGeneration = '2g' | '3g' | '4g' | '5g' | 'unknown';

export type NetType = 'wifi' | 'cellular' | 'ethernet' | 'none';

export class CellularNetworkInfo {
  generation: NetworkGeneration;
  signalStrength: number;
  is5GReady: boolean;
  latency?: number; // 新增网络延迟指标
  quality?: 'excellent' | 'good' | 'fair' | 'poor'; // 新增质量评级
  constructor(generation: NetworkGeneration, signalStrength: number, is5GReady: boolean, latency?: number,
    quality?: 'excellent' | 'good' | 'fair' | 'poor') {
    this.generation = generation;
    this.signalStrength = signalStrength;
    this.is5GReady = is5GReady;
    this.latency = latency;
    this.quality = quality;
  }
}

@ObservedV2
export class SensorInfo {
  @Trace status: 'normal' | 'warning' | 'error';

  constructor(status: 'normal' | 'warning' | 'error') {
    this.status = status;
  }
}

@ObservedV2
export class DeviceHealthInfo {
  @Trace battery: BatteryInfo;
  @Trace performance: PerformanceInfo;
  @Trace network: NetworkInfo;
  @Trace sensors: SensorInfo;
  @Trace score: number;
  @Trace lastUpdated: string;

  constructor(battery: BatteryInfo, performance: PerformanceInfo, network: NetworkInfo, sensors: SensorInfo,
    score: number, lastUpdated: string) {
    this.battery = battery;
    this.performance = performance;
    this.network = network;
    this.sensors = sensors;
    this.score = score;
    this.lastUpdated = lastUpdated;
  }
}

@ObservedV2
export class ScoreHealth {
  icon: Resource;
  label: ResourceStr;
  @Trace value: string;
  @Trace score: number;

  constructor(icon: Resource, label: ResourceStr, value: string, score: number) {
    this.icon = icon;
    this.label = label;
    this.value = value;
    this.score = score;
  }
}