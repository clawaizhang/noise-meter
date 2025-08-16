export interface SystemMemInfo {
  totalMem: bigint; // KB
  freeMem: bigint; // KB 
  availableMem: bigint; // KB
  usagePercentage?: number; // 可选：使用百分比
}

export interface StorageInfo {
  total: number; // 字节
  used: number;
  free: number;
}

export interface BatteryInfo {
  level: number; // 0-100
  status: 'charging'|'discharging'|'full'|'unknown'; 
}