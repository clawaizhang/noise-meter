import batteryInfo from '@ohos.batteryInfo';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';
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
  private netConnection: connection.NetConnection;

  private constructor() {
    this.healthInfo = this.getDefaultHealthInfo();
    this.netConnection = connection.createNetConnection();
    this.registerNetworkListener();
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
      battery: {
        level: 0,
        health: 100,
        temperature: 25,
        status: 'unknown'
      },
      performance: {
        cpu: 0,
        memory: { totalMem: 0n, freeMem: 0n, availableMem: 0n },
        storage: { total: 0, used: 0, free: 0 }
      },
      network: {
        isConnected: false,
        type: 'none',
        signalStrength: 0,
        networkGeneration: 'unknown',
        downloadSpeed: 0,
        uploadSpeed: 0,
        latency: 0,
        packetLoss: 0,
        isMetered: false,
        isBlocked: false
      },
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
    setTimeout(async () => {
      try {
        const cpuUsage = hidebug.getCpuUsage();
        this.healthInfo.performance.cpu = cpuUsage * 100;
        this.calculateHealthScore();
        this.emitUpdate();
      } catch (error) {
        console.error('获取CPU使用率失败:', error);
      }
    }, 0);
    this.healthInfo.performance.cpu = 0;

    this.calculateHealthScore();
    this.healthInfo.lastUpdated = new Date().toISOString();
    this.emitUpdate();
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

    const networkScore =
      (this.healthInfo.network.signalStrength / 4) * 0.4 +
        (1 - Math.min(this.healthInfo.network.latency / 1000, 1)) * 0.3 +
        (1 - this.healthInfo.network.packetLoss / 100) * 0.3;

    this.healthInfo.score = Math.round((
      batteryScore * weights.battery +
        (cpuScore * 0.6 + memoryScore * 0.4) * weights.performance +
        networkScore * weights.network +
        (this.healthInfo.sensors.status === 'normal' ? 1 : 0.5) * weights.sensors
    ) * 100);
  }

  private registerNetworkListener(): void {
    this.netConnection.register((err: BusinessError) => {
      if (err) {
        console.error('注册网络监听器失败:', err);
        return;
      }

      this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
        this.updateNetworkInfo(data.netCap);
      });

      this.netConnection.on('netBlockStatusChange', (data: connection.NetBlockStatusInfo) => {
        this.handleBlockStatus(data.blocked);
      });
    });
  }

  private startMonitoring(): void {
    setInterval(() => this.updateHealthInfo(), 5000);
  }

  private async updateNetworkInfo(netCap?: connection.NetCapabilities): Promise<void> {
    try {
      const netHandle = connection.getDefaultNetSync();
      const connProperties = connection.getConnectionPropertiesSync(netHandle);

      this.healthInfo.network = {
        isConnected: netCap?.networkCap?.includes(connection.NetCap.NET_CAPABILITY_INTERNET) ?? false,
        type: this.mapNetType(netCap?.bearerTypes[0]),
        signalStrength: this.getSignalStrength(netHandle),
        networkGeneration: this.getNetworkGeneration(netCap),
        downloadSpeed: netCap?.linkDownBandwidthKbps || 0,
        uploadSpeed:  netCap?.linkUpBandwidthKbps || 0,
        latency: this.calculateLatency(netHandle),
        packetLoss: 0,
        isMetered: connection.isDefaultNetMeteredSync(),
        isBlocked: this.healthInfo.network.isBlocked
      };

      this.calculateHealthScore();
      this.emitUpdate();
    } catch (error) {
      console.error('更新网络信息失败:', error);
    }
  }

  private mapNetType(bearerType?: connection.NetBearType): string {
    switch (bearerType) {
      case connection.NetBearType.BEARER_WIFI:
        return 'wifi';
      case connection.NetBearType.BEARER_ETHERNET:
        return 'ethernet';
      case connection.NetBearType.BEARER_CELLULAR:
        return 'cellular';
      default:
        return 'none';
    }
  }

  private getNetworkGeneration(netCap?: connection.NetCapabilities): string {
    if (!netCap) {
      return 'unknown';
    }
    if (netCap.networkCap?.includes(connection.NetCap.NET_CAPABILITY_NR)) {
      return '5g';
    }
    if (netCap.networkCap?.includes(connection.NetCap.NET_CAPABILITY_LTE)) {
      return '4g';
    }
    return '3g';
  }

  private handleBlockStatus(blocked: boolean): void {
    this.healthInfo.network.isBlocked = blocked;
    this.calculateHealthScore();
    this.emitUpdate();
  }

  public getHealthInfo(): DeviceHealthInfo {
    return this.healthInfo;
  }

  private emitUpdate(): void {
    if (this.onUpdate) {
      this.onUpdate();
    }
  }

  // 保留原有测试方法
  public testScoring(): void {
    // ...原有测试代码...
  }
}