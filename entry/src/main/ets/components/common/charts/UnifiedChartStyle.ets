/**
 * 统一图表样式配置类
 * 基于频谱柱状图的设计风格，为所有图表组件提供一致的视觉体验
 */

import { resourceManager } from '@kit.LocalizationKit';
import { ChartColorStop } from '@ohos/mpchart';

// 分贝颜色映射接口
export interface DbColorRange {
  minDb: number;
  maxDb: number;
  color: string;
}

// 限制线配置接口
export interface LimitLineConfig {
  value: number;
  label: string;
  color: string;
}

// 字体大小配置接口
export interface FontSizes {
  title: number;
  axis: number;
  value: number;
  legend: number;
  marker: number;
  stats?: number; // 可选属性，用于统计图表
}

// 线条宽度配置接口
export interface LineWidths {
  ultra_thin:number;
  thin: number;
  normal: number;
  thick: number;
  grid: number;
}

// 透明度配置接口
export interface Opacity {
  grid: number;
  fill: number;
  highlight: number;
}

// 圆角半径配置接口
export interface BorderRadius {
  small: number;
  medium: number;
  large: number;
}

// 间距配置接口
export interface Spacing {
  xs: number;
  sm: number;
  md: number;
  lg: number;
}

// 统一图表样式配置类
export class UnifiedChartStyle {
  // 基础颜色配置
  static readonly PRIMARY_COLOR = '#0099CC';
  static readonly BACKGROUND_COLOR = '#191A1C'; // 黑色背景，与频谱柱状图一致
  static readonly GRID_COLOR = '#666666'; // 深灰色网格线，适合黑色背景
  static readonly TEXT_COLOR = '#FFFFFF'; // 白色文字，适合黑色背景
  static readonly HIGHLIGHT_COLOR = '#888888';
  
  // 分贝级别限制线配置
  static readonly LIMIT_LINES: LimitLineConfig[] = [
    { value: 50, label: '安全', color: '#FF00FF00' }, // 绿色
    { value: 70, label: '注意', color: '#FFFFFF00' }, // 黄色
    { value: 85, label: '危险', color: '#FFFF8800' }, // 橙色
    { value: 110, label: '极限', color: '#FFFF0000' } // 红色
  ];
  
  // 分贝颜色映射
  static readonly DB_COLOR_RANGES: DbColorRange[] = [
    { minDb: 0, maxDb: 50, color: '#FF00FF00' },    // 绿色 - 安全
    { minDb: 50, maxDb: 70, color: '#FFFFFF00' },   // 黄色 - 注意
    { minDb: 70, maxDb: 85, color: '#FFFF8800' },   // 橙色 - 危险
    { minDb: 85, maxDb: 110, color: '#FFFF6600' },  // 深橙色
    { minDb: 110, maxDb: 120, color: '#FFFF0000' }  // 红色 - 极限
  ];
  
  // 字体大小配置
  static readonly FONT_SIZES: FontSizes = {
    title: 16,
    axis: 13,
    value: 10,
    legend: 12,
    marker: 11,
    stats: 14 // 添加统计字体大小
  };
  
  // 线条宽度配置
  static readonly LINE_WIDTHS: LineWidths = {
    ultra_thin:0.5,
    thin: 1.0,
    normal: 1.5,
    thick: 2.0,
    grid: 0.5,
  };
  
  // 透明度配置
  static readonly OPACITY: Opacity = {
    grid: 0.3,
    fill: 0.2,
    highlight: 0.8
  };
  
  // 圆角半径配置
  static readonly BORDER_RADIUS: BorderRadius = {
    small: 4,
    medium: 8,
    large: 16
  };
  
  // 间距配置
  static readonly SPACING: Spacing = {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24
  };
  
  /**
   * 根据分贝值获取对应颜色
   */
  static getDbColor(dbValue: number): string {
    for (const range of UnifiedChartStyle.DB_COLOR_RANGES) {
      if (dbValue >= range.minDb && dbValue < range.maxDb) {
        return range.color;
      }
    }
    // 默认返回最高级别的颜色
    return UnifiedChartStyle.DB_COLOR_RANGES[UnifiedChartStyle.DB_COLOR_RANGES.length - 1].color;
  }
  
  /**
   * 获取渐变填充颜色配置
   */
  static getGradientFillColor(baseColor: string = UnifiedChartStyle.PRIMARY_COLOR): ChartColorStop[] {
    const colorStops: ChartColorStop[] = [];
    
    // 创建从透明到半透明的渐变
    colorStops.push([baseColor + '20', 0]); // 0% 透明度

    return colorStops;
  }
  
  /**
   * 获取柱状图颜色数组
   */
  static getBarColors(count: number): number[] {
    const colors: number[] = [];
    for (let i = 0; i < count; i++) {
      // 根据索引计算分贝值范围
      const dbValue = (i / count) * 120; // 假设最大120dB
      const colorStr = UnifiedChartStyle.getDbColor(dbValue);
      // 将颜色字符串转换为数字格式
      colors.push(parseInt(colorStr.replace('#', '0xFF')));
    }
    return colors;
  }
  
  /**
   * 获取统计分布图的柱状图颜色
   */
  static getStatisticsBarColors(count: number): number[] {
    const colors: number[] = [];
    for (let i = 0; i < count; i++) {
      let color: number;
      if (i < 6) {
        color = 0xFF4CAF50; // 低分贝 - 绿色
      } else if (i < 8) {
        color = 0xFFFF9800; // 中高分贝 - 橙色
      } else {
        color = 0xFFF44336; // 高分贝 - 红色
      }
      colors.push(color);
    }
    return colors;
  }
  
  /**
   * 获取响应式字体大小
   */
  static getResponsiveFontSize(baseSize: number, scaleFactor: number = 1.0): number {
    return Math.round(baseSize * scaleFactor);
  }
  
  /**
   * 获取响应式线条宽度
   */
  static getResponsiveLineWidth(baseWidth: number, scaleFactor: number = 1.0): number {
    return baseWidth * scaleFactor;
  }
  
  /**
   * 格式化频率显示
   */
  static formatFrequency(freq: number): string {
    if (freq >= 1000) {
      return `${(freq / 1000).toFixed(1)}k`;
    } else {
      return `${Math.round(freq)}`;
    }
  }
  
  /**
   * 格式化分贝显示
   */
  static formatDecibel(db: number): string {
    return `${db.toFixed(1)}dB`;
  }
}