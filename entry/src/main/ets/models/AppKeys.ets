import { DataProcessingState } from './DataProcessingState';
import { UIDisplayState } from './UIDisplayState';

@ObservedV2
export class AppKeys {

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
  systemNotificationPermissionGranted: boolean = false; // 系统通知权限状态

  // 双管线架构状态引用
  dataProcessingState: DataProcessingState = new DataProcessingState();

  @Trace
  uiDisplayState: UIDisplayState = new UIDisplayState();
}
