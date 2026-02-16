import deviceInfo from '@ohos.deviceInfo';
import { IAudioService } from '../interfaces/IAudioService';
import { IAlertService } from '../interfaces/IAlertService';
import { IDisplayConfig, DisplayConfigs, PhoneDisplayConfig } from '../interfaces/IDisplayConfig';

// 导入各端实现
import { PhoneAudioService } from '../../phone/impl/PhoneAudioService';
import { PhoneAlertService } from '../../phone/impl/PhoneAlertService';
import { WatchAudioService } from '../../wearable/impl/WatchAudioService';
import { WatchAlertService } from '../../wearable/impl/WatchAlertService';

/**
 * 服务工厂
 * 根据设备类型创建对应的服务实现
 * UI层只依赖此工厂，不直接依赖具体实现
 */
export class ServiceFactory {
  private static instance: ServiceFactory | null = null;
  private deviceType: string;
  private audioService: IAudioService | null = null;
  private alertService: IAlertService | null = null;

  private constructor() {
    this.deviceType = deviceInfo.deviceType || 'phone';
  }

  static getInstance(): ServiceFactory {
    if (!ServiceFactory.instance) {
      ServiceFactory.instance = new ServiceFactory();
    }
    return ServiceFactory.instance;
  }

  /**
   * 获取音频服务
   * 根据设备类型返回对应的实现
   */
  getAudioService(): IAudioService {
    if (!this.audioService) {
      this.audioService = this.createAudioService();
    }
    return this.audioService;
  }

  /**
   * 获取警报服务
   */
  getAlertService(): IAlertService {
    if (!this.alertService) {
      this.alertService = this.createAlertService();
    }
    return this.alertService;
  }

  /**
   * 获取显示配置
   */
  getDisplayConfig(): IDisplayConfig {
    const config = DisplayConfigs.get(this.deviceType);
    return config || PhoneDisplayConfig;
  }

  /**
   * 获取设备类型
   */
  getDeviceType(): string {
    return this.deviceType;
  }

  /**
   * 是否是手表
   */
  isWearable(): boolean {
    return this.deviceType === 'wearable';
  }

  /**
   * 是否是手机/平板
   */
  isPhoneOrTablet(): boolean {
    return this.deviceType === 'phone' || this.deviceType === 'tablet';
  }

  /**
   * 创建音频服务实例
   * 工厂方法：根据设备类型创建对应实现
   */
  private createAudioService(): IAudioService {
    switch (this.deviceType) {
      case 'wearable':
        return new WatchAudioService();
      case 'phone':
      case 'tablet':
      default:
        return new PhoneAudioService();
    }
  }

  /**
   * 创建警报服务实例
   */
  private createAlertService(): IAlertService {
    switch (this.deviceType) {
      case 'wearable':
        return new WatchAlertService();
      case 'phone':
      case 'tablet':
      default:
        return new PhoneAlertService();
    }
  }

  /**
   * 销毁所有服务
   */
  async destroy(): Promise<void> {
    await this.audioService?.release();
    this.audioService = null;
    this.alertService = null;
  }
}

/**
 * 便捷获取服务的方法
 * 可以在UI层直接使用
 */
export function useAudioService(): IAudioService {
  return ServiceFactory.getInstance().getAudioService();
}

export function useAlertService(): IAlertService {
  return ServiceFactory.getInstance().getAlertService();
}

export function useDisplayConfig(): IDisplayConfig {
  return ServiceFactory.getInstance().getDisplayConfig();
}
