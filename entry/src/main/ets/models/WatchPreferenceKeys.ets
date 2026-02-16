import { PersistenceV2 } from '@kit.ArkUI';

/**
 * 手表端持久化配置
 * 简化版的用户偏好设置
 */
@ObservedV2
export class WatchPreferenceKeys {
  // 警报阈值
  @Trace alertThreshold: number = 80;

  // 是否启用振动提醒
  @Trace vibrateEnabled: boolean = true;

  // 是否启用后台检测
  @Trace backgroundDetection: boolean = false;

  // 频率加权类型 (A/C/Z) - 手表端固定A计权，但保留设置以便同步手机
  @Trace weightingType: string = 'A';  // 默认A计权

  // 校准值
  @Trace calibrationValue: number = 0;

  static getInstance(): WatchPreferenceKeys {
    return PersistenceV2.connect(WatchPreferenceKeys, () => new WatchPreferenceKeys())!;
  }
}
