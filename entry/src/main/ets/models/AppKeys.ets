
@ObservedV2
export class AppKeys {
  @Trace
  db: number = 0;
  @Trace
  peakFreq: number = 0;
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
  spectrumData: Float32Array = new Float32Array(); // 实时频谱数据

  @Trace
  systemNotificationPermissionGranted: boolean = false; // 系统通知权限状态
}
