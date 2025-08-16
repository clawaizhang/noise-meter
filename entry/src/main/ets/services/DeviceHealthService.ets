import batteryInfo from '@ohos.batteryInfo';
import usageStatistics from '@ohos.resourceschedule.usageStatistics';
import netConnection from '@ohos.net.connection';
import { DeviceHealthInfo, BatteryInfo, PerformanceInfo, NetworkInfo } from '../types/DeviceHealthInfo';

interface HealtyWeight {
  battery: number;
  performance: number;
  network: number;
  sensors: number;
}

export class DeviceHealthService {
  private static instance: DeviceHealthService;
  private healthInfo: DeviceHealthInfo;

  private constructor() {
    this.healthInfo = this.getDefaultHealthInfo();
    this.startMonitoring();
  }

  public static getInstance(): DeviceHealthService {
    if (!DeviceHealthService.instance) {
      DeviceHealthService.instance = new DeviceHealthService();
    }
    return DeviceHealthService.instance;
  }

  private getDefaultHealthInfo(): DeviceHealthInfo {
    return {
      battery: { level: 0, health: 100, temperature: 25, status: 'unknown' },
      performance: { cpu: 0, memory: { totalMem: 0n, freeMem: 0n, availableMem: 0n }, storage: { total: 0, used: 0, free: 0 } },
      network: { latency: 0, packetLoss: 0 },
      sensors: { status: 'normal' },
      score: 100,
      lastUpdated: new Date().toISOString()
    };
  }

  public async updateHealthInfo(): Promise<void> {
    // 获取电池信息
    this.healthInfo.battery = {
      level: batteryInfo.batterySOC,
      health: batteryInfo.healthStatus === batteryInfo.BatteryHealthState.GOOD ? 100 :
        batteryInfo.healthStatus === batteryInfo.BatteryHealthState.OVERHEAT ? 60 : 30,
      temperature: batteryInfo.batteryTemperature,
      status: batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.ENABLE ? 'charging' : 'discharging'
    };

    // 获取性能数据
    this.healthInfo.performance.cpu = usageStatistics.getCpuUsage();
    // 内存和存储数据使用现有实现

    // 计算综合评分
    this.healthInfo.score = this.calculateScore();
    this.healthInfo.lastUpdated = new Date().toISOString();
  }

  private calculateHealthScore(): void {
    const weights: HealtyWeight = {
      battery: 0.3,
      performance: 0.4,
      network: 0.2,
      sensors: 0.1
    };

    const batteryScore = this.healthInfo.battery.health * 0.01;
    const cpuScore = 1 - (this.healthInfo.performance.cpu / 100);
    const memoryScore = Number(this.healthInfo.performance.memory.availableMem) /
                       Number(this.healthInfo.performance.memory.totalMem);
    const networkScore = 1 - (this.healthInfo.network.packetLoss / 100);
    
    this.healthInfo.score = Math.round((
      batteryScore * weights.battery +
      (cpuScore * 0.6 + memoryScore * 0.4) * weights.performance +
      networkScore * weights.network +
      (this.healthInfo.sensors.status === 'normal' ? 1 : 0.5) * weights.sensors
    ) * 100);
  }

  private startMonitoring(): void {
    setInterval(() => this.updateHealthInfo(), 5000);
    netConnection.on('netStateChange', () => this.updateNetworkInfo());
  }

  private async updateNetworkInfo(): Promise<void> {
    try {
      const netStats = await netConnection.getDefaultNet();
      const connection = await netConnection.getConnectionProperties();
      
      this.healthInfo.network = {
        latency: connection.rtt ?? 0,
        packetLoss: netStats.packetLossRate ?? 0
      };
      
      this.calculateHealthScore();
      this.healthInfo.lastUpdated = new Date().toISOString();
    } catch (error) {
      console.error('更新网络信息失败:', error);
    }
  }

  public getHealthInfo(): DeviceHealthInfo {
    return this.healthInfo;
  }

  public testScoring(): void {
    // 测试用例1: 最佳状态
    this.healthInfo = {
      battery: { health: 100, level: 100, temperature: 25, status: 'full' },
      performance: { cpu: 20, memory: { totalMem: 8n, availableMem: 6n, freeMem: 5n }, storage: { total: 128, used: 32, free: 96 } },
      network: { latency: 10, packetLoss: 0 },
      sensors: { status: 'normal' },
      score: 0,
      lastUpdated: ''
    };
    this.calculateHealthScore();
    console.log('最佳状态评分:', this.healthInfo.score); // 预期: 95-100

    // 测试用例2: 中等状态
    this.healthInfo = {
      battery: { health: 60, level: 50, temperature: 35, status: 'discharging' },
      performance: { cpu: 60, memory: { totalMem: 8n, availableMem: 3n, freeMem: 2n }, storage: { total: 128, used: 80, free: 48 } },
      network: { latency: 50, packetLoss: 5 },
      sensors: { status: 'warning' },
      score: 0,
      lastUpdated: ''
    };
    this.calculateHealthScore();
    console.log('中等状态评分:', this.healthInfo.score); // 预期: 60-75

    // 测试用例3: 差状态
    this.healthInfo = {
      battery: { health: 30, level: 20, temperature: 45, status: 'discharging' },
      performance: { cpu: 90, memory: { totalMem: 8n, availableMem: 1n, freeMem: 0n }, storage: { total: 128, used: 120, free: 8 } },
      network: { latency: 200, packetLoss: 20 },
      sensors: { status: 'error' },
      score: 0,
      lastUpdated: ''
    };
    this.calculateHealthScore();
    console.log('差状态评分:', this.healthInfo.score); // 预期: 30-50
  }
}