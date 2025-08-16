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
  isConnected: boolean;
  type: 'wifi' | 'cellular' | 'ethernet' | 'none';
  signalStrength: number; // 0-4
  networkGeneration?: string;
  downloadSpeed: number; // kbps
  uploadSpeed: number; // kbps
  latency: number; // ms
  packetLoss: number; // percentage
  isMetered:boolean;
  isBlocked:boolean;
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