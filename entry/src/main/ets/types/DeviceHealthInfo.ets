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
  type: NetType;
  signalStrength: number; // 0-4
  networkGeneration?: string;
  downloadSpeed: number; // kbps
  uploadSpeed: number; // kbps
  latency: number; // ms
  packetLoss: number; // percentage
  isMetered:boolean;
  isBlocked:boolean;
  is5GReady:boolean;
}

export type NetworkGeneration = '2g' | '3g' | '4g' | '5g' | 'unknown';
export type NetType =  'wifi' | 'cellular' | 'ethernet' | 'none';

export interface CellularNetworkInfo {
  generation: NetworkGeneration;
  signalStrength: number;
  is5GReady: boolean;
  latency?: number;  // 新增网络延迟指标
  quality?: 'excellent' | 'good' | 'fair' | 'poor'; // 新增质量评级
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