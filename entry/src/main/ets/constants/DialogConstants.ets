/**
 * 弹窗组件设计常量
 * 统一管理弹窗相关的设计规范和配置
 */

import { DesignConstants } from './DesignConstants';

// 弹窗配置接口
interface DialogConfig {
  MAX_HEIGHT: number | string;
  BORDER_RADIUS: number;
  BACKGROUND_OPACITY: number;
  ANIMATION_DURATION: number;
  DRAG_THRESHOLD: number;
  SCALE_FACTOR: number;
}

// 拖动条配置接口
interface HandleBarConfig {
  WIDTH: number;
  HEIGHT: number;
  BORDER_RADIUS: number;
  MARGIN_TOP: number;
  OPACITY: number;
}

// 内边距配置接口
interface PaddingConfig {
  TOP: number;
  BOTTOM: number;
  HORIZONTAL: number;
}

// 动画配置接口
interface AnimationConfig {
  ENTER_DURATION: number;
  EXIT_DURATION: number;
  BACKGROUND_DURATION: number;
}

// 手势配置接口
interface GestureConfig {
  MAX_DRAG_DISTANCE: number;
  DRAG_PROGRESS_FACTOR: number;
}

// 断点配置接口
interface BreakpointsConfig {
  SMALL: number;
  MEDIUM: number;
  LARGE: number;
}

export class DialogConstants {
  // 弹窗基础配置
  static readonly DIALOG: DialogConfig = {
    MAX_HEIGHT: '85%',
    BORDER_RADIUS: DesignConstants.BORDER_RADIUS_LG,
    BACKGROUND_OPACITY: 0.25,
    ANIMATION_DURATION: 400,
    DRAG_THRESHOLD: 120,
    SCALE_FACTOR: 0.05
  };

  // 拖动条配置
  static readonly HANDLE_BAR: HandleBarConfig = {
    WIDTH: 48,
    HEIGHT: 5,
    BORDER_RADIUS: DesignConstants.BORDER_RADIUS_FULL,
    MARGIN_TOP: DesignConstants.SPACING_SM,
    OPACITY: 0.6
  };

  // 内边距配置
  static readonly PADDING: PaddingConfig = {
    TOP: DesignConstants.SPACING_SM,
    BOTTOM: DesignConstants.SPACING_LG,
    HORIZONTAL: DesignConstants.SPACING_LG
  };

  // 动画配置
  static readonly ANIMATION: AnimationConfig = {
    ENTER_DURATION: 600,
    EXIT_DURATION: 400,
    BACKGROUND_DURATION: 300
  };

  // 手势配置
  static readonly GESTURE: GestureConfig = {
    MAX_DRAG_DISTANCE: 150,
    DRAG_PROGRESS_FACTOR: 0.4
  };

  // 响应式断点
  static readonly BREAKPOINTS: BreakpointsConfig = {
    SMALL: 320,
    MEDIUM: 768,
    LARGE: 1024
  };

  // 响应式配置方法 - 移除以避免this使用问题
}