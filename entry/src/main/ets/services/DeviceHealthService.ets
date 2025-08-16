import batteryInfo from '@ohos.batteryInfo';
import { connection } from '@kit.NetworkKit';
import { radio } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { netQuality } from '@kit.NetworkBoostKit';
import {
  DeviceHealthInfo,
  BatteryInfo,
  PerformanceInfo,
  NetworkInfo,
  NetType,
  NetworkGeneration,
  CellularNetworkInfo
} from '../types/DeviceHealthInfo';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

interface NetworkQosParams {
  latency: number;
  uploadSpeed: number;
  downloadSpeed: number;
};

interface HealtyWeight {
  battery: number;
  performance: number;
  network: number;
  sensors: number;
}

interface WeakSignalPrediction {
  isLastPredictionValid: boolean;
  startTime: number;
  duration: number;
}

interface NetworkQosExtended extends netQuality.NetworkQos {
  weakSignalPrediction?: WeakSignalPrediction;
}

interface weakSignalPredictionObj {
  weakSignalPrediction?: WeakSignalPrediction;
}

export class DeviceHealthService {
  private static instance: DeviceHealthService;
  private healthInfo: DeviceHealthInfo;
  private netConnection: connection.NetConnection;
  private networkHealthScore: number = 100;
  private updateCallbacks: Array<(score: number) => void> = [];

  private constructor() {
    this.healthInfo = this.getDefaultHealthInfo();
    this.netConnection = connection.createNetConnection();
    this.registerNetworkListener();
    this.setupNetworkQualityMonitor();
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
        isBlocked: false,
        is5GReady: false
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

  private setupNetworkQualityMonitor(): void {
    try {
      netQuality.on('netQosChange', (list: Array<netQuality.NetworkQos>) => {
        if (list.length > 0) {
          list.forEach((qos) => {
            console.info(`Received network QoS update`);
            this.updateNetworkHealthScore({
              latency: qos.rttMs,
              uploadSpeed: qos.linkUpRate,
              downloadSpeed: qos.linkDownRate
            });
            this.handleNetworkQualityChange(qos as NetworkQosExtended);
          });
        }
      });

    } catch (err) {
      console.error('Network monitoring error:', (err as BusinessError).message);
    }
  }

  private updateNetworkHealthScore(params: NetworkQosParams): void {
    const latencyScore = Math.max(0, 100 - (params.latency / 10));
    const speedScore = Math.min(100,
      (params.uploadSpeed / 5e6 + params.downloadSpeed / 20e6) * 50
    );
    this.networkHealthScore = Math.round(latencyScore * 0.6 + speedScore * 0.4);
    this.healthInfo.network.latency = params.latency;
    this.healthInfo.network.uploadSpeed = params.uploadSpeed;
    this.healthInfo.network.downloadSpeed = params.downloadSpeed;
    this.calculateHealthScore();
  }

  private handleNetworkQualityChange(qos: NetworkQosExtended): void {
    if (qos.rttMs > 200) {
      this.adjustDataStrategy('highLatency');
    }
    if (qos.weakSignalPrediction?.isLastPredictionValid) {
      this.prepareForWeakSignal(
        qos.weakSignalPrediction.startTime,
        qos.weakSignalPrediction.duration
      );
    }
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
      (this.networkHealthScore / 100) * 0.5 +
        (this.healthInfo.network.signalStrength / 4) * 0.3 +
        (1 - this.healthInfo.network.packetLoss / 100) * 0.2;

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
      const cellularInfo = await this.getCellularNetworkInfo();

      this.healthInfo.network = {
        isConnected: netCap?.networkCap?.includes(connection.NetCap.NET_CAPABILITY_INTERNET) ?? false,
        type: this.mapNetType(netCap?.bearerTypes[0]),
        signalStrength: cellularInfo.signalStrength,
        networkGeneration: cellularInfo.generation,
        downloadSpeed: netCap?.linkDownBandwidthKbps || 0,
        uploadSpeed: netCap?.linkUpBandwidthKbps || 0,
        latency: 55,
        packetLoss: 0,
        isMetered: connection.isDefaultNetMeteredSync(),
        isBlocked: this.healthInfo.network.isBlocked,
        is5GReady: cellularInfo.is5GReady
      };

      this.calculateHealthScore();
      this.emitUpdate();
    } catch (error) {
      console.error('更新网络信息失败:', error);
    }
  }

  private mapNetType(bearerType?: connection.NetBearType): NetType {
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

  private async getCellularNetworkInfo(): Promise<CellularNetworkInfo> {
    try {
      const slotId = await radio.getPrimarySlotId();
      const radioTech = radio.getRadioTechSync(slotId);
      const signalInfo = radio.getSignalInformationSync(slotId);
      const is5GSupported = radio.isNRSupported(slotId);

      return {
        generation: this.mapGeneration(radioTech.psRadioTech),
        signalStrength: this.getMaxSignalLevel(signalInfo),
        is5GReady: is5GSupported && radioTech.psRadioTech === radio.RadioTechnology.RADIO_TECHNOLOGY_NR
      };
    } catch (error) {
      console.error('Get cellular network info failed:', error);
      return {
        generation: '4g',
        signalStrength: 0,
        is5GReady: false
      };
    }
  }

  private mapGeneration(tech: radio.RadioTechnology): NetworkGeneration {
    switch (tech) {
      case radio.RadioTechnology.RADIO_TECHNOLOGY_GSM:
      case radio.RadioTechnology.RADIO_TECHNOLOGY_1XRTT:
        return '2g';
      case radio.RadioTechnology.RADIO_TECHNOLOGY_WCDMA:
      case radio.RadioTechnology.RADIO_TECHNOLOGY_HSPA:
      case radio.RadioTechnology.RADIO_TECHNOLOGY_TD_SCDMA:
        return '3g';
      case radio.RadioTechnology.RADIO_TECHNOLOGY_LTE:
      case radio.RadioTechnology.RADIO_TECHNOLOGY_LTE_CA:
        return '4g';
      case radio.RadioTechnology.RADIO_TECHNOLOGY_NR:
        return '5g';
      default:
        return '4g';
    }
  }

  private calculateLatencyStatus(rtt: number): string {
    if (rtt < 50) return 'excellent';
    if (rtt < 100) return 'good';
    if (rtt < 200) return 'fair';
    return 'poor';
  }

  private getMaxSignalLevel(signals: radio.SignalInformation[]): number {
    return signals.reduce((max, signal) =>
    Math.max(max, signal.signalLevel), 0);
  }

  private handleBlockStatus(blocked: boolean): void {
    this.healthInfo.network.isBlocked = blocked;
    this.calculateHealthScore();
    this.emitUpdate();
  }

  public getHealthInfo(): DeviceHealthInfo {
    return this.healthInfo;
  }

  public registerUpdateListener(callback: (score: number) => void): void {
    this.updateCallbacks.push(callback);
  }

  private emitUpdate(): void {
    this.updateCallbacks.forEach(cb => cb(this.healthInfo.score));
  }

  // 保留原有测试方法
  public testScoring(): void {
    // ...原有测试代码...
  }

  private adjustDataStrategy(reason: string): void {
    // 实现高延迟时的数据策略调整
    console.log(`Adjusting data strategy due to: ${reason}`);
  }

  private prepareForWeakSignal(startTime: number, duration: number): void {
    // 实现弱信号预测处理
    console.log(`Preparing for weak signal starting at ${new Date(startTime)} for ${duration}ms`);
  }
}