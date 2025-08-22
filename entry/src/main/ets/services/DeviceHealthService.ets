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
  CellularNetworkInfo,
  SystemMemInfo,
  StorageInfo,
  SensorInfo
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

export class DeviceHealthService {
  private static instance: DeviceHealthService;
  private healthInfo: DeviceHealthInfo;
  private netConnection: connection.NetConnection;
  private networkHealthScore: number = 100;
  private updateCallbacks: Array<(score: number) => void> = [];

  private constructor() {
    console.log('[DeviceHealthService] Initializing service...');
    this.healthInfo = this.getDefaultHealthInfo();
    this.netConnection = connection.createNetConnection();
    this.registerNetworkListener();
    this.setupNetworkQualityMonitor();
    this.startMonitoring();
    console.log('[DeviceHealthService] Service initialized successfully');
  }

  public static getInstance(): DeviceHealthService {
    if (!DeviceHealthService.instance) {
      DeviceHealthService.instance = new DeviceHealthService();
    }
    return DeviceHealthService.instance;
  }

  private getDefaultHealthInfo(): DeviceHealthInfo {
    return new DeviceHealthInfo(
      new BatteryInfo(0, 100, 0, 'unknown'),
      new PerformanceInfo(0, new SystemMemInfo(8000000n, 4000000n, 4000000n), new StorageInfo(128000000, 64000000, 64000000)),
      new NetworkInfo(false, 'none', 0, 0, 0, 0, 0, false, false, false),
      new SensorInfo('normal'),
      75, // 设置一个合理的默认分数
      '',
    );
  }

  public async updateHealthInfo(): Promise<void> {
    console.log('[DeviceHealthService] Updating health info...');
    try {
      // 获取电池信息
      this.healthInfo.battery.level = batteryInfo.batterySOC;
      this.healthInfo.battery.health = batteryInfo.healthStatus === batteryInfo.BatteryHealthState.GOOD ? 100 :
        batteryInfo.healthStatus === batteryInfo.BatteryHealthState.OVERHEAT ? 60 : 30;
      this.healthInfo.battery.temperature = batteryInfo.batteryTemperature;
      this.healthInfo.battery.status =
        batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.ENABLE ? 'charging' : 'discharging';

      // 获取性能数据
      try {
        const cpuUsage = hidebug.getCpuUsage();
        this.healthInfo.performance.cpu = cpuUsage * 100;
      } catch (error) {
        console.error('获取CPU使用率失败:', error);
        this.healthInfo.performance.cpu = 0; // 设置默认值
      }

      // 获取内存和存储信息（模拟数据）
      this.healthInfo.performance.memory.totalMem = 8000000n; // 8GB
      this.healthInfo.performance.memory.availableMem = 4000000n; // 4GB
      this.healthInfo.performance.storage.total = 128000000; // 128GB
      this.healthInfo.performance.storage.used = 64000000; // 64GB
      this.healthInfo.performance.storage.free = 64000000; // 64GB

      this.calculateHealthScore();
      this.healthInfo.lastUpdated = new Date().toISOString();
      console.log('[DeviceHealthService] Health info updated:', JSON.stringify(this.healthInfo));
      this.emitUpdate();
    } catch (error) {
      console.error('更新健康信息失败:', error);
    }
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
    console.log('[DeviceHealthService] Calculating health score...');
    const weights: HealtyWeight = {
      battery: 0.3,
      performance: 0.4,
      network: 0.2,
      sensors: 0.1
    };

    // 电池分数（0-100）
    const batteryScore = this.healthInfo.battery.health;

    // CPU分数（CPU使用率越低分数越高）
    const cpuScore = Math.max(0, 100 - this.healthInfo.performance.cpu);

    // 内存分数（可用内存比例）
    const totalMem = Number(this.healthInfo.performance.memory.totalMem);
    const availableMem = Number(this.healthInfo.performance.memory.availableMem);
    const memoryScore = totalMem > 0 ? Math.round((availableMem / totalMem) * 100) : 80;

    // 网络分数（使用网络健康分数）
    const networkScore = this.networkHealthScore;

    // 传感器分数（正常=100，警告=60，错误=30）
    const sensorScore = this.healthInfo.sensors.status === 'normal' ? 100 :
                       this.healthInfo.sensors.status === 'warning' ? 60 : 30;

    // 计算加权总分
    this.healthInfo.score = Math.round((
      batteryScore * weights.battery +
      ((cpuScore * 0.5) + (memoryScore * 0.5)) * weights.performance +
      networkScore * weights.network +
      sensorScore * weights.sensors
    ));

    console.log('[DeviceHealthService] Final health score:', this.healthInfo.score);
  }

  private registerNetworkListener(): void {
    console.log('[DeviceHealthService] Registering network listener...');
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
    console.log('[DeviceHealthService] Starting health monitoring with 5s interval');
    setInterval(() => this.updateHealthInfo(), 5000);
  }

  private async updateNetworkInfo(netCap?: connection.NetCapabilities): Promise<void> {
    console.log('[DeviceHealthService] Updating network info...');
    try {
      const netHandle = connection.getDefaultNetSync();
      const cellularInfo = await this.getCellularNetworkInfo();

      this.healthInfo.network.isConnected =
        netCap?.networkCap?.includes(connection.NetCap.NET_CAPABILITY_INTERNET) ?? false;
      this.healthInfo.network.type = this.mapNetType(netCap?.bearerTypes[0]);
      this.healthInfo.network.signalStrength = cellularInfo.signalStrength;
      this.healthInfo.network.networkGeneration = cellularInfo.generation;
      this.healthInfo.network.downloadSpeed = netCap?.linkDownBandwidthKbps || 0;
      this.healthInfo.network.uploadSpeed = netCap?.linkUpBandwidthKbps || 0;
      this.healthInfo.network.latency = 55;
      this.healthInfo.network.packetLoss = 0;
      this.healthInfo.network.isMetered = connection.isDefaultNetMeteredSync();
      this.healthInfo.network.isBlocked = this.healthInfo.network.isBlocked;
      this.healthInfo.network.is5GReady = cellularInfo.is5GReady;

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
      return new CellularNetworkInfo(this.mapGeneration(radioTech.psRadioTech),
        this.getMaxSignalLevel(signalInfo), is5GSupported);
    } catch (error) {
      console.error('Get cellular network info failed:', error);
      return new CellularNetworkInfo('4g', 0, false);
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
    console.log('[DeviceHealthService] Emitting update with score:', this.healthInfo.score);
    console.log('[DeviceHealthService] Number of registered callbacks:', this.updateCallbacks.length);
    this.updateCallbacks.forEach(cb => cb(this.healthInfo.score));
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