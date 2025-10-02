/**
 * 设计常量系统 - 统一管理设计token
 * 包括间距、字体大小、图标大小、圆角等设计规范
 */

// 阴影接口定义
interface ShadowStyle {
  radius: number;
  color: Resource;
  offsetX: number;
  offsetY: number;
}

// MetricItem配置接口
interface MetricItemConfig {
  ICON_SIZE: number;
  VALUE_SIZE: number;
  LABEL_SIZE: number;
  PADDING: number;
  SPACING: number;
  WIDTH: number;
  HEIGHT: number;
  BORDER_RADIUS: number;
}

// DetailModal配置接口
interface DetailModalConfig {
  PADDING: number;
  SPACING: number;
  BORDER_RADIUS: number;
  TITLE_SIZE: number;
  CONTENT_SIZE: number;
  ICON_SIZE: number;
}

// RatingPanel配置接口
interface RatingPanelConfig {
  WIDTH_LARGE: number;
  WIDTH_MEDIUM: number;
  WIDTH_SMALL: number;
  WIDTH_XSMALL: number;
  HEIGHT_LARGE: number;
  HEIGHT_MEDIUM: number;
  HEIGHT_SMALL: number;
  HEIGHT_XSMALL: number;
  RING_SIZE_LARGE: number;
  RING_SIZE_MEDIUM: number;
  RING_SIZE_SMALL: number;
  RING_SIZE_XSMALL: number;
  STROKE_WIDTH_LARGE: number;
  STROKE_WIDTH_MEDIUM: number;
  STROKE_WIDTH_SMALL: number;
  STROKE_WIDTH_XSMALL: number;
}

// HealthCard布局配置接口（使用相对单位）
interface HealthCardLayoutConfig {
  ITEM_WIDTH: string;
  ITEM_HEIGHT: number;
  ITEM_SPACING: string;
  ROW_SPACING: number;
  CONTAINER_PADDING: number;
}

// 边距配置接口
interface MarginPaddingConfig {
  top: number;
  bottom: number;
  right?: number;
  left?: number;
}

// HealthCard配置接口
interface HealthCardConfig {
  MARGIN_LARGE: MarginPaddingConfig;
  MARGIN_MEDIUM: MarginPaddingConfig;
  MARGIN_SMALL: MarginPaddingConfig;
  MARGIN_XSMALL: MarginPaddingConfig;
  PADDING: MarginPaddingConfig;
}

export class DesignConstants {
  // 间距系统 (spacing)
  static readonly SPACING_XS: number = 4;
  static readonly SPACING_SM: number = 8;
  static readonly SPACING_MD: number = 12;
  static readonly SPACING_LG: number = 16;
  static readonly SPACING_XL: number = 20;
  static readonly SPACING_2XL: number = 24;
  static readonly SPACING_3XL: number = 32;
  static readonly SPACING_4XL: number = 40;
  // 字体大小系统 (font size)
  static readonly FONT_SIZE_XS: number = 10;
  static readonly FONT_SIZE_SM: number = 12;
  static readonly FONT_SIZE_MD: number = 14;
  static readonly FONT_SIZE_LG: number = 16;
  static readonly FONT_SIZE_XL: number = 18;
  static readonly FONT_SIZE_2XL: number = 20;
  static readonly FONT_SIZE_3XL: number = 24;
  static readonly FONT_SIZE_4XL: number = 32;
  // 图标大小系统 (icon size)
  static readonly ICON_SIZE_XS: number = 12;
  static readonly ICON_SIZE_SM: number = 16;
  static readonly ICON_SIZE_MD: number = 20;
  static readonly ICON_SIZE_LG: number = 24;
  static readonly ICON_SIZE_XL: number = 32;
  static readonly ICON_SIZE_2XL: number = 40;
  static readonly ICON_SIZE_3XL: number = 48;
  // 圆角系统 (border radius)
  static readonly BORDER_RADIUS_XS: number = 4;
  static readonly BORDER_RADIUS_SM: number = 8;
  static readonly BORDER_RADIUS_MD: number = 12;
  static readonly BORDER_RADIUS_LG: number = 16;
  static readonly BORDER_RADIUS_XL: number = 20;
  static readonly BORDER_RADIUS_2XL: number = 24;
  static readonly BORDER_RADIUS_FULL: number = 999;
  // 边框宽度 (border width)
  static readonly BORDER_WIDTH_SM: number = 1;
  static readonly BORDER_WIDTH_MD: number = 2;
  static readonly BORDER_WIDTH_LG: number = 3;
  // 阴影系统 (shadow)
  static readonly SHADOW_SM: ShadowStyle = {
    radius: 4,
    color: $r('app.color.shadow_light'),
    offsetX: 0,
    offsetY: 2
  };
  static readonly SHADOW_MD: ShadowStyle = {
    radius: 8,
    color: $r('app.color.shadow_medium'),
    offsetX: 0,
    offsetY: 4
  };
  static readonly SHADOW_LG: ShadowStyle = {
    radius: 16,
    color: $r('app.color.shadow_dark'),
    offsetX: 0,
    offsetY: 8
  };
  // 透明度系统 (opacity)
  static readonly OPACITY_DISABLED: number = 0.5;
  static readonly OPACITY_HOVER: number = 0.8;
  static readonly OPACITY_PRESSED: number = 0.7;
  // 动画时长 (animation duration)
  static readonly ANIMATION_DURATION_XS: number = 100;
  static readonly ANIMATION_DURATION_SM: number = 200;
  static readonly ANIMATION_DURATION_MD: number = 300;
  static readonly ANIMATION_DURATION_LG: number = 500;
  static readonly ANIMATION_DURATION_XL: number = 700;
  // 组件特定常量
  static readonly METRIC_ITEM: MetricItemConfig = {
    ICON_SIZE: this.ICON_SIZE_MD, // 20px
    VALUE_SIZE: this.FONT_SIZE_XL, // 18px
    LABEL_SIZE: this.FONT_SIZE_SM, // 12px
    PADDING: this.SPACING_SM, // 8px
    SPACING: this.SPACING_XS, // 4px
    WIDTH: 100, // 减少宽度以适应更多设备
    HEIGHT: 80,
    BORDER_RADIUS: this.BORDER_RADIUS_MD // 12px
  };
  static readonly DETAIL_MODAL: DetailModalConfig = {
    PADDING: this.SPACING_LG, // 16px
    SPACING: this.SPACING_MD, // 12px
    BORDER_RADIUS: this.BORDER_RADIUS_LG, // 16px
    TITLE_SIZE: this.FONT_SIZE_XL, // 18px
    CONTENT_SIZE: this.FONT_SIZE_MD, // 14px
    ICON_SIZE: this.ICON_SIZE_MD // 20px
  };
  static readonly HEALTH_CARD: HealthCardConfig = {
    MARGIN_LARGE: {
      top: 12,
      bottom: 12,
      right: 24,
      left: 24
    },
    MARGIN_MEDIUM: {
      top: 12,
      bottom: 12,
      right: 20,
      left: 20
    },
    MARGIN_SMALL: {
      top: 10,
      bottom: 10,
      right: 16,
      left: 16
    },
    MARGIN_XSMALL: {
      top: 8,
      bottom: 8,
      right: 12,
      left: 12
    },
    PADDING: { top: 8, bottom: 8 }
  };
  // 评分面板布局规范
  static readonly RATING_PANEL: RatingPanelConfig = {
    WIDTH_LARGE: 180,
    WIDTH_MEDIUM: 160,
    WIDTH_SMALL: 140,
    WIDTH_XSMALL: 120,
    HEIGHT_LARGE: 200,
    HEIGHT_MEDIUM: 180,
    HEIGHT_SMALL: 160,
    HEIGHT_XSMALL: 140,
    RING_SIZE_LARGE: 80,
    RING_SIZE_MEDIUM: 70,
    RING_SIZE_SMALL: 60,
    RING_SIZE_XSMALL: 50,
    STROKE_WIDTH_LARGE: 8,
    STROKE_WIDTH_MEDIUM: 7,
    STROKE_WIDTH_SMALL: 6,
    STROKE_WIDTH_XSMALL: 5
  };
  // 健康卡片布局规范（使用相对单位）
  static readonly HEALTH_CARD_LAYOUT: HealthCardLayoutConfig = {
    ITEM_WIDTH: '16%', // 相对宽度，适应不同屏幕
    ITEM_HEIGHT: 80, // 固定高度保持一致性
    ITEM_SPACING: '2%', // 相对间距
    ROW_SPACING: 12,
    CONTAINER_PADDING: 16
  };
}