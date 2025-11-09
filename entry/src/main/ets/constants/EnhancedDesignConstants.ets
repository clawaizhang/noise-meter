/**
 * 增强版设计常量系统 - 支持新的UI设计需求
 * 扩展原有DesignConstants，添加新的视觉规范
 */

import { DesignConstants } from './DesignConstants';

// 阴影接口定义
interface ShadowStyle {
  radius: number;
  color: Resource;
  offsetX: number;
  offsetY: number;
}

// 卡片尺寸配置接口
interface CardSizeConfig {
  width: string;
  height: number;
  padding: number;
  borderRadius: number;
  fontSize: {
    title: number;
    description: number;
    status: number;
  };
  iconSize: number;
}

// 布局模式枚举
export enum LayoutMode {
  COMPACT = 'compact',    // 紧凑模式
  STANDARD = 'standard',   // 标准模式
  EXPANDED = 'expanded'    // 展开模式
}

// 用户技能水平枚举
export enum UserSkillLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate',
  EXPERT = 'expert'
}

// 功能优先级视觉配置
export class PriorityVisualConfig {
  static readonly ESSENTIAL: CardSizeConfig = {
    width: '100%',
    height: 80,
    padding: DesignConstants.SPACING_MD,
    borderRadius: DesignConstants.BORDER_RADIUS_MD,
    fontSize: {
      title: DesignConstants.FONT_SIZE_MD,
      description: DesignConstants.FONT_SIZE_SM,
      status: DesignConstants.FONT_SIZE_XS
    },
    iconSize: DesignConstants.ICON_SIZE_LG
  };

  static readonly RECOMMENDED: CardSizeConfig = {
    width: '100%',
    height: 70,
    padding: DesignConstants.SPACING_SM,
    borderRadius: DesignConstants.BORDER_RADIUS_MD,
    fontSize: {
      title: DesignConstants.FONT_SIZE_SM,
      description: DesignConstants.FONT_SIZE_XS,
      status: DesignConstants.FONT_SIZE_XXS
    },
    iconSize: DesignConstants.ICON_SIZE_MD
  };

  static readonly ADVANCED: CardSizeConfig = {
    width: '100%',
    height: 60,
    padding: DesignConstants.SPACING_SM,
    borderRadius: DesignConstants.BORDER_RADIUS_SM,
    fontSize: {
      title: DesignConstants.FONT_SIZE_SM,
      description: DesignConstants.FONT_SIZE_XXS,
      status: DesignConstants.FONT_SIZE_XXS
    },
    iconSize: DesignConstants.ICON_SIZE_SM
  };
}

// 增强版设计常量类
export class EnhancedDesignConstants extends DesignConstants {
  // 新增色彩语义
  static readonly COLOR_QUICK_ACTION = $r('app.color.quick_action');
  static readonly COLOR_ESSENTIAL = $r('app.color.essential');
  static readonly COLOR_RECOMMENDED = $r('app.color.recommended');
  static readonly COLOR_ADVANCED = $r('app.color.advanced');
  static readonly COLOR_LOCKED = $r('app.color.locked');
  static readonly COLOR_SCENE_INDOOR = $r('app.color.scene_indoor');
  static readonly COLOR_SCENE_OUTDOOR = $r('app.color.scene_outdoor');
  static readonly COLOR_SCENE_INDUSTRIAL = $r('app.color.scene_industrial');

  // 增强阴影系统
  static readonly SHADOW_ESSENTIAL: ShadowStyle = {
    radius: 12,
    color: $r('app.color.shadow_essential'),
    offsetX: 0,
    offsetY: 6
  };

  static readonly SHADOW_GLOW: ShadowStyle = {
    radius: 20,
    color: $r('app.color.shadow_glow'),
    offsetX: 0,
    offsetY: 0
  };

  // 动画配置
  static readonly ANIMATION_SPRING = {
    duration: 400,
    curve: Curve.Spring,
    delay: 0
  };

  static readonly ANIMATION_BOUNCE = {
    duration: 600,
    curve: Curve.EaseInOut,
    delay: 0
  };

  // 间距扩展
  static readonly SPACING_5XL = 48;
  static readonly SPACING_6XL = 56;

  // 布局配置
  static readonly LAYOUT_HEADER_HEIGHT = 60;
  static readonly LAYOUT_TAB_HEIGHT = 48;
  static readonly LAYOUT_SEARCH_HEIGHT = 52;

  // 卡片配置
  static readonly CARD_SPACING = 8;
  static readonly CARD_MARGIN_VERTICAL = 6;
  static readonly CARD_HOVER_SCALE = 1.02;
  static readonly CARD_PRESS_SCALE = 0.98;

  // 渐变配置
  static readonly GRADIENT_BRAND = {
    colors: [
      $r('app.color.brand_primary'),
      $r('app.color.brand_secondary')
    ],
    direction: GradientDirection.Right
  };

  static readonly GRADIENT_ESSENTIAL = {
    colors: [
      $r('app.color.essential'),
      $r('app.color.essential_secondary')
    ],
    direction: GradientDirection.Right
  };

  // 透明度配置
  static readonly OPACITY_CARD_HOVER = 0.95;
  static readonly OPACITY_CARD_PRESSED = 0.9;
  static readonly OPACITY_DISABLED_HEAVY = 0.3;
  static readonly OPACITY_OVERLAY = 0.7;

  // 圆角扩展
  static readonly BORDER_RADIUS_CARD = 16;
  static readonly BORDER_RADIUS_PREVIEW = 12;
  static readonly BORDER_RADIUS_TAG = 6;

  // 字重配置
  static readonly FONT_WEIGHT_LIGHT = FontWeight.Lighter;
  static readonly FONT_WEIGHT_REGULAR = FontWeight.Normal;
  static readonly FONT_WEIGHT_MEDIUM = FontWeight.Medium;
  static readonly FONT_WEIGHT_SEMI_BOLD = FontWeight.Medium;
  static readonly FONT_WEIGHT_BOLD = FontWeight.Bold;

  // 行高配置
  static readonly LINE_HEIGHT_TIGHT = 1.2;
  static readonly LINE_HEIGHT_NORMAL = 1.4;
  static readonly LINE_HEIGHT_RELAXED = 1.6;

  // Z轴层级
  static readonly Z_INDEX_BASE = 1;
  static readonly Z_INDEX_CARD = 10;
  static readonly Z_INDEX_DROPDOWN = 100;
  static readonly Z_INDEX_MODAL = 1000;
  static readonly Z_INDEX_TOAST = 2000;
}