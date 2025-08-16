export interface BatteryInfo {
  level: number;
  health: number;
  temperature: number;
  status: 'charging'|'discharging'|'full'|'unknown';
}

export interface SystemMemInfo {
  totalMem: bigint;
  freeMem: bigint;
  availableMem: bigint;
}

export interface StorageInfo {
  total: number;
  used: number;
  free: number;
}

export interface PerformanceInfo {
  cpu: number;
  memory: SystemMemInfo;
  storage: StorageInfo;
}

export interface NetworkInfo {
  latency: number;
  packetLoss: number;
}

export interface SensorInfo {
  status: 'normal'|'warning'|'error';
}

export interface DeviceHealthInfo {
  battery: BatteryInfo;
  performance: PerformanceInfo;
  network: NetworkInfo;
  sensors: SensorInfo;
  score: number;
  lastUpdated: string;
}