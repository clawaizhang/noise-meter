
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

  // 响应式设计系统属性
  @Trace
  responsive: ResponsiveDesignSystem = new ResponsiveDesignSystem();
}

// 响应式设计系统类
@ObservedV2
export class ResponsiveDesignSystem {
  // 响应式字体系统
  @Trace
  fontSize: ResponsiveFontSize = new ResponsiveFontSize();

  // 响应式间距系统
  @Trace
  spacing: ResponsiveSpacing = new ResponsiveSpacing();

  // 响应式图标尺寸
  @Trace
  iconSize: ResponsiveIconSize = new ResponsiveIconSize();

  // 响应式圆角
  @Trace
  borderRadius: ResponsiveBorderRadius = new ResponsiveBorderRadius();
}

// 响应式字体系统类
@ObservedV2
export class ResponsiveFontSize {
  @Trace xs: number = 10;   // 10px * scale
  @Trace sm: number = 12;   // 12px * scale
  @Trace md: number = 14;   // 14px * scale
  @Trace lg: number = 16;   // 16px * scale
  @Trace xl: number = 18;   // 18px * scale
  @Trace xxl: number = 20;  // 20px * scale
  @Trace xxxl: number = 24; // 24px * scale
  @Trace xxxxl: number = 32; // 32px * scale
}

// 响应式间距系统类
@ObservedV2
export class ResponsiveSpacing {
  @Trace xs: number = 4;    // 4px * scale
  @Trace sm: number = 8;    // 8px * scale
  @Trace md: number = 12;   // 12px * scale
  @Trace lg: number = 16;   // 16px * scale
  @Trace xl: number = 20;   // 20px * scale
  @Trace xxl: number = 24;  // 24px * scale
  @Trace xxxl: number = 32; // 32px * scale
  @Trace xxxxl: number = 40; // 40px * scale
}

// 响应式图标尺寸类
@ObservedV2
export class ResponsiveIconSize {
  @Trace xs: number = 12;   // 12px * scale
  @Trace sm: number = 16;   // 16px * scale
  @Trace md: number = 20;   // 20px * scale
  @Trace lg: number = 24;   // 24px * scale
  @Trace xl: number = 32;   // 32px * scale
  @Trace xxl: number = 40;  // 40px * scale
  @Trace xxxl: number = 48; // 48px * scale
}

// 响应式圆角类
@ObservedV2
export class ResponsiveBorderRadius {
  @Trace xs: number = 4;    // 4px * scale
  @Trace sm: number = 8;    // 8px * scale
  @Trace md: number = 12;   // 12px * scale
  @Trace lg: number = 16;   // 16px * scale
  @Trace xl: number = 20;   // 20px * scale
  @Trace xxl: number = 24;  // 24px * scale
  @Trace full: number = 999; // 999px (固定值)
}
