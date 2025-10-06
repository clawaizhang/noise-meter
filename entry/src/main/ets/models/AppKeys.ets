
import { DataProcessingState } from './DataProcessingState';
import { UIDisplayState } from './UIDisplayState';

@ObservedV2
export class AppKeys {
  // TODO: 迁移到双管线架构 - 这些字段将迁移到DataProcessingState和UIDisplayState
  @Trace
  db: number = 0; // 将迁移到UIDisplayState.displayDb
  @Trace
  peakFreq: number = 0; // 将迁移到UIDisplayState.displayPeakFreq
  @Trace
  windowWidthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD; // 窗口宽度断点: xs, sm, md, lg, xl, xxl
  @Trace
  windowHeightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_MD; // 窗口高度断点: xs, sm, md, lg, xl, xxl
  @Trace
  windowWidth: number = 0; // 当前窗口宽度(vp)
  @Trace
  windowHeight: number = 0; // 当前窗口高度(vp)
  @Trace
  isLandscape: boolean = false; // 是否为横屏模式

  @Trace
  microphonePermissionGranted: boolean = false; // 实时麦克风权限状态

  @Trace
  isDisplayApp: boolean = true; // 应用是否处于显示状态

  @Trace
  spectrumData: Float32Array = new Float32Array(); // 将迁移到UIDisplayState.displaySpectrumData

  @Trace
  systemNotificationPermissionGranted: boolean = false; // 系统通知权限状态

  // 双管线架构状态引用
  @Trace
  dataProcessingState: DataProcessingState = new DataProcessingState();

  @Trace
  uiDisplayState: UIDisplayState = new UIDisplayState();
}
