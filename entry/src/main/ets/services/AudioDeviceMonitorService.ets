import audio from '@ohos.multimedia.audio';
import common from '@ohos.app.ability.common';
import { NotificationHelper } from '../utils/NotificationHelper';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AudioDeviceMonitorService';
const DOMAIN = 0xFF00;

/**
 * 设备连接状态
 */
export enum DeviceConnectionState {
  CONNECTED = 0,          // 设备连接
  DISCONNECTED = 1        // 设备断开
}

/**
 * 音频设备信息
 */
export interface AudioDeviceInfo {
  deviceType: number;             // 设备类型（使用系统定义的设备类型）
  deviceRole: number;             // 设备角色
  deviceName: string;             // 设备名称
  connectionState: DeviceConnectionState; // 连接状态
  timestamp: number;              // 状态变更时间戳
}

/**
 * 音频设备监听服务
 * 提供外置音频设备接入/断开检测和通知功能
 */
export class AudioDeviceMonitorService {
  private static instance: AudioDeviceMonitorService | null = null;

  // 音频管理器实例
  private audioManager: audio.AudioManager | null = null;
  // 音频路由管理器实例
  private audioRoutingManager: audio.AudioRoutingManager | null = null;
  // 应用上下文
  private context: common.UIAbilityContext | null = null;
  // 通知助手
  private notificationHelper: NotificationHelper | null = null;
  // 监听状态
  private isMonitoring: boolean = false;
  // 当前连接的设备列表
  private connectedDevices: AudioDeviceInfo[] = [];
  // 设备变更回调函数
  private deviceChangeCallbacks: ((deviceInfo: AudioDeviceInfo) => void)[] = [];

  /**
   * 获取单例实例
   */
  public static getInstance(): AudioDeviceMonitorService {
    if (!AudioDeviceMonitorService.instance) {
      AudioDeviceMonitorService.instance = new AudioDeviceMonitorService();
    }
    return AudioDeviceMonitorService.instance;
  }

  private constructor() {
    // 私有构造函数
  }

  /**
   * 初始化服务
   * @param context 应用上下文
   */
  public async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context;
      
      // 初始化音频管理器
      this.audioManager = audio.getAudioManager();
      if (!this.audioManager) {
        throw new Error('无法获取音频管理器');
      }

      // 初始化音频路由管理器
      this.audioRoutingManager = this.audioManager.getRoutingManager();
      if (!this.audioRoutingManager) {
        throw new Error('无法获取音频路由管理器');
      }

      // 初始化通知助手
      this.notificationHelper = NotificationHelper.getInstance(context);

      hilog.info(DOMAIN, TAG, '音频设备监听服务初始化成功');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `音频设备监听服务初始化失败: ${err.code}, ${err.message}`);
      throw new Error(`初始化音频设备监听服务失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 开始监听设备状态变化
   */
  public async startMonitoring(): Promise<void> {
    if (this.isMonitoring) {
      hilog.info(DOMAIN, TAG, '设备监听已启动，无需重复启动');
      return;
    }

    if (!this.audioRoutingManager) {
      throw new Error('音频路由管理器未初始化');
    }

    try {
      // 注册设备变更监听器
      this.audioRoutingManager.on('deviceChange', audio.DeviceFlag.INPUT_DEVICES_FLAG, 
        (deviceChanged: audio.DeviceChangeAction) => {
          this.handleDeviceChange(deviceChanged);
        });

      this.isMonitoring = true;
      hilog.info(DOMAIN, TAG, '开始监听音频设备状态变化');

      // 获取当前已连接的设备
      await this.refreshConnectedDevices();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `启动设备监听失败: ${err.code}, ${err.message}`);
      throw new Error(`启动音频设备监听失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 停止监听设备状态变化
   */
  public async stopMonitoring(): Promise<void> {
    if (!this.isMonitoring || !this.audioRoutingManager) {
      return;
    }

    try {
      // 取消设备变更监听器
      this.audioRoutingManager.off('deviceChange', (deviceChanged: audio.DeviceChangeAction) => {
        // 空回调函数用于取消监听
      });

      this.isMonitoring = false;
      this.connectedDevices = [];
      hilog.info(DOMAIN, TAG, '停止监听音频设备状态变化');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `停止设备监听失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 处理设备状态变化
   * @param deviceChanged 设备变更信息
   */
  private handleDeviceChange(deviceChanged: audio.DeviceChangeAction): void {
    try {
      const changeType = deviceChanged.type;
      const deviceDescriptors = deviceChanged.deviceDescriptors;

      hilog.info(DOMAIN, TAG, `设备状态变化: 类型=${changeType}, 设备数量=${deviceDescriptors.length}`);

      if (deviceDescriptors.length === 0) {
        return;
      }

      // 处理每个设备的状态变化
      deviceDescriptors.forEach((descriptor: audio.AudioDeviceDescriptor) => {
        this.processDeviceDescriptor(descriptor, changeType);
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `处理设备状态变化失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 处理设备描述符
   * @param descriptor 设备描述符
   * @param changeType 变更类型
   */
  private processDeviceDescriptor(descriptor: audio.AudioDeviceDescriptor, changeType: number): void {
    const deviceType = descriptor.deviceType;
    
    // 只处理外置输入设备
    if (!this.isExternalInputDevice(deviceType)) {
      return;
    }

    const deviceInfo: AudioDeviceInfo = {
      deviceType: deviceType,
      deviceRole: descriptor.deviceRole,
      deviceName: this.getDeviceName(deviceType),
      connectionState: changeType === DeviceConnectionState.CONNECTED ?
        DeviceConnectionState.CONNECTED : DeviceConnectionState.DISCONNECTED,
      timestamp: Date.now()
    };

    // 更新设备列表
    this.updateDeviceList(deviceInfo);

    // 发送通知
    this.sendDeviceNotification(deviceInfo);

    // 通知回调函数
    this.notifyDeviceChangeCallbacks(deviceInfo);

    hilog.info(DOMAIN, TAG, `外置音频设备${changeType === DeviceConnectionState.CONNECTED ? '接入' : '断开'}: ` +
      `类型=${deviceType}, 名称=${deviceInfo.deviceName}`);
  }

  /**
   * 判断是否为外置输入设备
   * @param deviceType 设备类型
   */
  private isExternalInputDevice(deviceType: number): boolean {
    // 使用系统定义的设备类型常量
    return deviceType === 3 ||  // WIRED_HEADSET - 有线耳机，带麦克风
           deviceType === 7 ||  // BLUETOOTH_SCO - 蓝牙设备SCO连接
           deviceType === 22;   // USB_HEADSET - USB耳机，带麦克风
  }

  /**
   * 获取设备名称
   * @param deviceType 设备类型
   */
  private getDeviceName(deviceType: number): string {
    switch (deviceType) {
      case 3:   // WIRED_HEADSET
        return '有线耳机';
      case 7:   // BLUETOOTH_SCO
        return '蓝牙耳机';
      case 22:  // USB_HEADSET
        return 'USB耳机';
      case 15:  // MIC
        return '内置麦克风';
      default:
        return '未知设备';
    }
  }

  /**
   * 更新设备列表
   * @param deviceInfo 设备信息
   */
  private updateDeviceList(deviceInfo: AudioDeviceInfo): void {
    const existingIndex = this.connectedDevices.findIndex(
      device => device.deviceType === deviceInfo.deviceType
    );

    if (deviceInfo.connectionState === DeviceConnectionState.CONNECTED) {
      if (existingIndex >= 0) {
        // 更新现有设备
        this.connectedDevices[existingIndex] = deviceInfo;
      } else {
        // 添加新设备
        this.connectedDevices.push(deviceInfo);
      }
    } else {
      // 移除断开连接的设备
      if (existingIndex >= 0) {
        this.connectedDevices.splice(existingIndex, 1);
      }
    }
  }

  /**
   * 发送设备状态通知
   * @param deviceInfo 设备信息
   */
  private async sendDeviceNotification(deviceInfo: AudioDeviceInfo): Promise<void> {
    if (!this.notificationHelper) {
      return;
    }

    try {
      const notificationId = 1000 + deviceInfo.deviceType; // 唯一通知ID
      const title = '音频设备状态';
      let text = '';
      let additionalText = '';

      if (deviceInfo.connectionState === DeviceConnectionState.CONNECTED) {
        text = '检测到外置音频设备接入, 噪音检测可能不准确';
        additionalText = `设备: ${deviceInfo.deviceName}`;
      } else {
        text = '外置音频设备已断开';
        additionalText = `设备: ${deviceInfo.deviceName}`;
      }

      await this.notificationHelper.showNotification(notificationId, title, text, additionalText);
      hilog.info(DOMAIN, TAG, `设备状态通知已发送: ${text}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `发送设备状态通知失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 刷新当前连接的设备列表
   */
  private async refreshConnectedDevices(): Promise<void> {
    if (!this.audioRoutingManager) {
      return;
    }

    try {
      const devices = await this.audioRoutingManager.getDevices(audio.DeviceFlag.INPUT_DEVICES_FLAG);
      this.connectedDevices = [];

      devices.forEach((descriptor: audio.AudioDeviceDescriptor) => {
        const deviceType = descriptor.deviceType;
        if (this.isExternalInputDevice(deviceType)) {
          const deviceInfo: AudioDeviceInfo = {
            deviceType: deviceType,
            deviceRole: descriptor.deviceRole,
            deviceName: this.getDeviceName(deviceType),
            connectionState: DeviceConnectionState.CONNECTED,
            timestamp: Date.now()
          };
          this.connectedDevices.push(deviceInfo);
        }
      });

      hilog.info(DOMAIN, TAG, `刷新设备列表完成，当前连接设备数量: ${this.connectedDevices.length}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `刷新设备列表失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 获取当前连接的设备列表
   */
  public getConnectedDevices(): AudioDeviceInfo[] {
    return [...this.connectedDevices];
  }

  /**
   * 检查是否有外置设备连接
   */
  public hasExternalDeviceConnected(): boolean {
    return this.connectedDevices.length > 0;
  }

  /**
   * 添加设备变更监听回调
   * @param callback 回调函数
   */
  public addDeviceChangeListener(callback: (deviceInfo: AudioDeviceInfo) => void): void {
    this.deviceChangeCallbacks.push(callback);
  }

  /**
   * 移除设备变更监听回调
   * @param callback 回调函数
   */
  public removeDeviceChangeListener(callback: (deviceInfo: AudioDeviceInfo) => void): void {
    const index = this.deviceChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.deviceChangeCallbacks.splice(index, 1);
    }
  }

  /**
   * 通知设备变更回调函数
   * @param deviceInfo 设备信息
   */
  private notifyDeviceChangeCallbacks(deviceInfo: AudioDeviceInfo): void {
    this.deviceChangeCallbacks.forEach(callback => {
      try {
        callback(deviceInfo);
      } catch (error) {
        const err = error as BusinessError;
        hilog.error(DOMAIN, TAG, `设备变更回调执行失败: ${err.code}, ${err.message}`);
      }
    });
  }

  /**
   * 销毁服务
   */
  public async destroy(): Promise<void> {
    try {
      await this.stopMonitoring();
      this.deviceChangeCallbacks = [];
      this.connectedDevices = [];
      this.audioRoutingManager = null;
      this.audioManager = null;
      this.context = null;
      this.notificationHelper = null;
      
      hilog.info(DOMAIN, TAG, '音频设备监听服务已销毁');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `销毁服务失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 检查是否正在监听
   */
  public isMonitoringActive(): boolean {
    return this.isMonitoring;
  }
}