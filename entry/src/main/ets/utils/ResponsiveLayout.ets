/**
 * 响应式布局工具类 - 基于HarmonyOS RWD规范
 * 提供断点检测、布局模式管理和响应式值计算功能
 */

import display from '@ohos.display';
import { DesignConstants } from '../constants/DesignConstants';
import { BusinessError } from '@kit.BasicServicesKit';

// 断点枚举
export enum Breakpoint {
  XS = 'xs', // < 360dp - 超小屏设备
  SM = 'sm', // 360-599dp - 小屏设备
  MD = 'md', // 600-839dp - 中屏设备
  LG = 'lg', // 840-1199dp - 大屏设备
  XL = 'xl' // ≥ 1200dp - 超大屏设备
}

// 布局模式枚举
export enum LayoutMode {
  XSMALL = 'xsmall',
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large',
  XLARGE = 'xlarge'
}

// 断点阈值接口
interface BreakpointThresholds {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

// 布局因子接口
interface LayoutFactors {
  xsmall: number;
  small: number;
  medium: number;
  large: number;
  xlarge: number;
}

// 屏幕信息接口
interface ScreenInfo {
  width: number;
  height: number;
  breakpoint: Breakpoint;
  layoutMode: LayoutMode;
  isLandscape: boolean; // 新增：是否为横屏模式
}

// 断点到布局模式的映射
const BREAKPOINT_TO_LAYOUT: Map<Breakpoint, LayoutMode> = new Map([
  [Breakpoint.XS, LayoutMode.XSMALL],
  [Breakpoint.SM, LayoutMode.SMALL],
  [Breakpoint.MD, LayoutMode.MEDIUM],
  [Breakpoint.LG, LayoutMode.LARGE],
  [Breakpoint.XL, LayoutMode.XLARGE]
]);

// 断点阈值定义（单位：dp）
const BREAKPOINT_THRESHOLDS: BreakpointThresholds = {
  xs: 360,
  sm: 600,
  md: 840,
  lg: 1200,
  xl: Number.MAX_SAFE_INTEGER
};

// 窗口变化监听器类型
export type WindowChangeListener = (width: number, height: number, breakpoint: Breakpoint,
  layoutMode: LayoutMode, isLandscape: boolean) => void;

export class ResponsiveLayout {
  private static instance: ResponsiveLayout;
  private currentWidth: number = 0;
  private currentHeight: number = 0;
  private currentBreakpoint: Breakpoint = Breakpoint.XS;
  private currentLayoutMode: LayoutMode = LayoutMode.XSMALL;
  private isLandscape: boolean = false; // 新增：横屏状态
  private listeners: Set<WindowChangeListener> = new Set();
  private displayChangeCallback: (() => void) | null = null;

  // 私有构造函数
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): ResponsiveLayout {
    if (!ResponsiveLayout.instance) {
      ResponsiveLayout.instance = new ResponsiveLayout();
    }
    return ResponsiveLayout.instance;
  }

  /**
   * 初始化响应式布局系统
   */
  private async initialize(): Promise<void> {
    try {
      // 获取初始屏幕信息
      const displayInfo = await display.getDefaultDisplay();
      this.updateScreenSize(displayInfo.width, displayInfo.height);

      // 注册屏幕变化监听
      this.displayChangeCallback = () => {
        // 当屏幕变化时，重新获取屏幕信息并更新
        display.getDefaultDisplay().then((displayInfo: display.Display) => {
          this.updateScreenSize(displayInfo.width, displayInfo.height);
        }).catch((error: BusinessError) => {
          console.error('[ResponsiveLayout] Failed to get display info:', error);
        });
      };
      display.on('change', this.displayChangeCallback);

    } catch (error) {
      console.error('[ResponsiveLayout] 初始化失败:', error);
    }
  }

  /**
   * 更新屏幕尺寸并通知监听器
   */
  private updateScreenSize(width: number, height: number): void {
    const vpWidth = px2vp(width);
    const vpHeight = px2vp(height);

    // 检测是否为横屏模式
    const newIsLandscape = vpWidth > vpHeight;

    // 只有当尺寸真正变化或横屏状态变化时才更新
    if (Math.abs(vpWidth - this.currentWidth) > 1 ||
        Math.abs(vpHeight - this.currentHeight) > 1 ||
        newIsLandscape !== this.isLandscape) {
      
      this.currentWidth = vpWidth;
      this.currentHeight = vpHeight;
      this.isLandscape = newIsLandscape;

      const newBreakpoint = this.getBreakpoint(vpWidth);
      const newLayoutMode = this.getLayoutMode(newBreakpoint);

      // 只有当断点、布局模式或横屏状态变化时才通知监听器
      if (newBreakpoint !== this.currentBreakpoint ||
          newLayoutMode !== this.currentLayoutMode ||
          newIsLandscape !== this.isLandscape) {
        
        this.currentBreakpoint = newBreakpoint;
        this.currentLayoutMode = newLayoutMode;

        this.notifyListeners(vpWidth, vpHeight, newBreakpoint, newLayoutMode);
      }
    }
  }

  /**
   * 根据宽度获取断点
   */
  public getBreakpoint(width: number): Breakpoint {
    if (width < BREAKPOINT_THRESHOLDS.xs) {
      return Breakpoint.XS;
    }
    if (width < BREAKPOINT_THRESHOLDS.sm) {
      return Breakpoint.SM;
    }
    if (width < BREAKPOINT_THRESHOLDS.md) {
      return Breakpoint.MD;
    }
    if (width < BREAKPOINT_THRESHOLDS.lg) {
      return Breakpoint.LG;
    }
    return Breakpoint.XL;
  }

  /**
   * 根据断点获取布局模式
   */
  public getLayoutMode(breakpoint: Breakpoint): LayoutMode {
    const layoutMode = BREAKPOINT_TO_LAYOUT.get(breakpoint);
    return layoutMode ?? LayoutMode.XSMALL;
  }

  /**
   * 获取响应式值
   * @param values 包含不同布局模式对应值的对象
   */
  public getResponsiveValue<T>(values: Record<LayoutMode, T>): T {
    switch (this.currentLayoutMode) {
      case LayoutMode.XSMALL:
        return values.xsmall;
      case LayoutMode.SMALL:
        return values.small;
      case LayoutMode.MEDIUM:
        return values.medium;
      case LayoutMode.LARGE:
        return values.large;
      case LayoutMode.XLARGE:
        return values.xlarge;
      default:
        return values.medium;
    }
  }

  /**
   * 获取响应式间距
   */
  public getSpacing(baseSize: number = DesignConstants.SPACING_MD): number {
    const spacingFactors: LayoutFactors = {
      xsmall: 0.8,
      small: 0.9,
      medium: 1.0,
      large: 1.1,
      xlarge: 1.2
    };

    const factor = this.getLayoutFactor(spacingFactors);
    return Math.round(baseSize * factor);
  }

  /**
   * 获取响应式字体大小
   */
  public getFontSize(baseSize: number = DesignConstants.FONT_SIZE_MD): number {
    const fontSizeFactors: LayoutFactors = {
      xsmall: 0.85,
      small: 0.9,
      medium: 1.0,
      large: 1.1,
      xlarge: 1.2
    };

    const factor = this.getLayoutFactor(fontSizeFactors);
    return Math.round(baseSize * factor);
  }

  /**
   * 获取布局因子
   */
  private getLayoutFactor(factors: LayoutFactors): number {
    switch (this.currentLayoutMode) {
      case LayoutMode.XSMALL:
        return factors.xsmall;
      case LayoutMode.SMALL:
        return factors.small;
      case LayoutMode.MEDIUM:
        return factors.medium;
      case LayoutMode.LARGE:
        return factors.large;
      case LayoutMode.XLARGE:
        return factors.xlarge;
      default:
        return factors.medium;
    }
  }

  /**
   * 获取响应式图标尺寸
   */
  public getIconSize(baseSize: number = DesignConstants.ICON_SIZE_MD): number {
    const iconSizeFactors: LayoutFactors = {
      xsmall: 0.8,
      small: 0.9,
      medium: 1.0,
      large: 1.1,
      xlarge: 1.2
    };
    const factor = this.getLayoutFactor(iconSizeFactors);
    return Math.round(baseSize * factor);
  }

  /**
   * 获取响应式度量项宽度
   */
  public getMetricItemWidth(baseWidth: number = DesignConstants.METRIC_ITEM.WIDTH): number {
    const widthFactors: LayoutFactors = {
      xsmall: 0.9,
      small: 0.95,
      medium: 1.0,
      large: 1.05,
      xlarge: 1.1
    };
    const factor = this.getLayoutFactor(widthFactors);
    return Math.round(baseWidth * factor);
  }

  /**
   * 获取响应式度量项高度
   */
  public getMetricItemHeight(baseHeight: number = DesignConstants.METRIC_ITEM.HEIGHT): number {
    const heightFactors: LayoutFactors = {
      xsmall: 0.9,
      small: 0.95,
      medium: 1.0,
      large: 1.05,
      xlarge: 1.1
    };
    const factor = this.getLayoutFactor(heightFactors);
    return Math.round(baseHeight * factor);
  }

  /**
   * 注册窗口变化监听器
   */
  public addChangeListener(listener: WindowChangeListener): void {
    this.listeners.add(listener);
  }

  /**
   * 移除窗口变化监听器
   */
  public removeChangeListener(listener: WindowChangeListener): void {
    this.listeners.delete(listener);
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(width: number, height: number, breakpoint: Breakpoint, layoutMode: LayoutMode): void {
    this.listeners.forEach(listener => {
      try {
        listener(width, height, breakpoint, layoutMode, this.isLandscape);
      } catch (error) {
        console.error('[ResponsiveLayout] 监听器执行错误:', error);
      }
    });
  }

  /**
   * 获取当前屏幕信息
   */
  public getCurrentScreenInfo(): ScreenInfo {
    return {
      width: this.currentWidth,
      height: this.currentHeight,
      breakpoint: this.currentBreakpoint,
      layoutMode: this.currentLayoutMode,
      isLandscape: this.isLandscape
    };
  }

  /**
   * 判断当前是否为横屏模式
   */
  public isLandscapeMode(): boolean {
    return this.isLandscape;
  }

  /**
   * 销毁实例，清理资源
   */
  public destroy(): void {
    if (this.displayChangeCallback) {
      display.off('change', this.displayChangeCallback);
    }
    this.listeners.clear();
    ResponsiveLayout.instance = null!;
  }
}

// 导出便捷函数
export const responsiveLayout = ResponsiveLayout.getInstance();

/**
 * 响应式值构建器 - 用于在组件中便捷使用响应式值
 */
export function responsive<T>(values: Record<LayoutMode, T>): T {
  return responsiveLayout.getResponsiveValue(values);
}

/**
 * 响应式间距构建器
 */
export function responsiveSpacing(baseSize: number = DesignConstants.SPACING_MD): number {
  return responsiveLayout.getSpacing(baseSize);
}

/**
 * 响应式字体构建器
 */
export function responsiveFontSize(baseSize: number = DesignConstants.FONT_SIZE_MD): number {
  return responsiveLayout.getFontSize(baseSize);
}

/**
 * 响应式图标尺寸构建器
 */
export function responsiveIconSize(baseSize: number = DesignConstants.ICON_SIZE_MD): number {
  return responsiveLayout.getIconSize(baseSize);
}

/**
 * 响应式度量项宽度构建器
 */
export function responsiveMetricWidth(baseWidth: number = DesignConstants.METRIC_ITEM.WIDTH): number {
  return responsiveLayout.getMetricItemWidth(baseWidth);
}

/**
 * 响应式度量项高度构建器
 */
export function responsiveMetricHeight(baseHeight: number = DesignConstants.METRIC_ITEM.HEIGHT): number {
  return responsiveLayout.getMetricItemHeight(baseHeight);
}