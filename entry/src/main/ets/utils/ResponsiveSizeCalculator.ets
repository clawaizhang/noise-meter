/**
 * 响应式尺寸计算工具类
 * 基于横向断点、纵向断点和窗口尺寸计算响应式比例
 */

export class ResponsiveSizeCalculator {
  /**
   * 计算响应式比例因子
   * @param widthBp 横向断点
   * @param heightBp 纵向断点
   * @param width 窗口宽度
   * @param height 窗口高度
   * @returns 响应式比例因子
   */
  static calculateResponsiveScale(
    widthBp: WidthBreakpoint,
    heightBp: HeightBreakpoint,
    width: number,
    height: number
  ): number {
    // 基础比例因子
    let scale = 1.0;
    
    // 基于横向断点调整
    switch (widthBp) {
      case WidthBreakpoint.WIDTH_XS:
        scale = 0.9;  // 超小屏幕稍微缩小
        break;
      case WidthBreakpoint.WIDTH_SM:
        scale = 1.0;  // 小屏幕基准值
        break;
      case WidthBreakpoint.WIDTH_MD:
        scale = 1.05; // 中等屏幕适度放大
        break;
      case WidthBreakpoint.WIDTH_LG:
        scale = 1.1;  // 大屏幕进一步放大
        break;
      case WidthBreakpoint.WIDTH_XL:
        scale = 1.15; // 超大屏幕适度放大
        break;
        break;
    }
    
    // 基于纵向断点微调
    switch (heightBp) {

      case HeightBreakpoint.HEIGHT_SM:
        scale *= 1.0;  // 基准值
        break;
      case HeightBreakpoint.HEIGHT_MD:
        scale *= 1.02; // 纵向空间适中，微调
        break;
      case HeightBreakpoint.HEIGHT_LG:
        scale *= 1.05; // 纵向空间大，适度放大
        break;
    }
    
    // 限制在合理范围内 (0.8 - 1.3)
    return Math.max(0.8, Math.min(1.3, scale));
  }

  /**
   * 计算响应式字体尺寸
   * @param baseSize 基础字体尺寸
   * @param scale 响应式比例因子
   * @returns 响应式字体尺寸
   */
  static calculateFontSize(baseSize: number, scale: number): number {
    return Math.round(baseSize * scale);
  }

  /**
   * 计算响应式间距
   * @param baseSpacing 基础间距
   * @param scale 响应式比例因子
   * @returns 响应式间距
   */
  static calculateSpacing(baseSpacing: number, scale: number): number {
    return Math.round(baseSpacing * scale);
  }

  /**
   * 计算响应式图标尺寸
   * @param baseIconSize 基础图标尺寸
   * @param scale 响应式比例因子
   * @returns 响应式图标尺寸
   */
  static calculateIconSize(baseIconSize: number, scale: number): number {
    return Math.round(baseIconSize * scale);
  }

  /**
   * 计算响应式圆角
   * @param baseBorderRadius 基础圆角
   * @param scale 响应式比例因子
   * @returns 响应式圆角
   */
  static calculateBorderRadius(baseBorderRadius: number, scale: number): number {
    // 对于固定值（如 full），不应用比例
    if (baseBorderRadius === 999) {
      return baseBorderRadius;
    }
    return Math.round(baseBorderRadius * scale);
  }
}