import { AppStorageV2 } from '@kit.ArkUI';

/**
 * 手表端应用状态管理
 * 简化的状态管理，专注于核心检测功能
 */
@ObservedV2
export class WatchAppKeys {
  // 窗口相关
  @Trace windowWidth: number = 200;
  @Trace windowHeight: number = 200;
  @Trace isRoundScreen: boolean = false; // 是否为圆形表盘

  // 应用状态
  @Trace isAppForeground: boolean = true;

  // 检测状态
  @Trace isDetecting: boolean = false;
  @Trace currentDecibel: number = 0;
  @Trace minDecibel: number = 0;
  @Trace avgDecibel: number = 0;
  @Trace maxDecibel: number = 0;

  // 警报状态
  @Trace isAlertActive: boolean = false;
  @Trace alertThreshold: number = 80; // 默认阈值80dB

  // 噪音等级描述
  @Trace noiseLevelDescription: string = '等待检测';
  @Trace noiseLevelColor: ResourceColor = $r('app.color.font_secondary');

  // 检测时长（秒）
  @Trace detectionDuration: number = 0;

  static getInstance(): WatchAppKeys {
    return AppStorageV2.connect(WatchAppKeys)!;
  }
}
