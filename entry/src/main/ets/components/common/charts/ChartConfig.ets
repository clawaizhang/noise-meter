/**
 * 图表配置接口定义
 * 提供统一的图表配置参数管理
 */

// 边距配置接口
export interface MarginConfig {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

// 字体大小配置接口
export interface FontSizeConfig {
  title: number;
  axis: number;
  label: number;
  small: number;
}

// 图表类型枚举
export enum ChartType {
  SPECTRUM = 'spectrum',
  SPECTRUM_BAR = 'spectrum_bar',
  TIME_DOMAIN = 'time_domain',
  STATISTICS = 'statistics'
}

// 图表配置接口
export interface ChartConfig {
  // 尺寸配置
  margin: MarginConfig;
  aspectRatio: number;
  
  // 样式配置
  backgroundColor: string;
  gridColor: string;
  textColor: string;
  fontSize: FontSizeConfig;
  
  // 布局配置
  chartType: ChartType;
  responsive: boolean;
}

// 默认图表配置
export const DefaultChartConfig: ChartConfig = {
  margin: {
    top: 20,
    right: 15,
    bottom: 40,
    left: 35
  },
  aspectRatio: 1.5,
  backgroundColor: '#191A1C',
  gridColor: '#666666',
  textColor: '#FFFFFF',
  fontSize: {
    title: 16,
    axis: 12,
    label: 11,
    small: 9
  },
  chartType: ChartType.SPECTRUM,
  responsive: true
};

// 响应式布局配置
export interface ResponsiveConfig {
  smallScreen: ChartConfig;
  mediumScreen: ChartConfig;
  largeScreen: ChartConfig;
}

// 默认响应式配置
export const DefaultResponsiveConfig: ResponsiveConfig = {
  smallScreen: {
    margin: {
      top: 15,
      right: 10,
      bottom: 30,
      left: 25
    },
    aspectRatio: DefaultChartConfig.aspectRatio,
    backgroundColor: DefaultChartConfig.backgroundColor,
    gridColor: DefaultChartConfig.gridColor,
    textColor: DefaultChartConfig.textColor,
    fontSize: {
      title: 14,
      axis: 11,
      label: 10,
      small: 8
    },
    chartType: DefaultChartConfig.chartType,
    responsive: DefaultChartConfig.responsive
  },
  mediumScreen: {
    margin: {
      top: 20,
      right: 15,
      bottom: 40,
      left: 35
    },
    aspectRatio: DefaultChartConfig.aspectRatio,
    backgroundColor: DefaultChartConfig.backgroundColor,
    gridColor: DefaultChartConfig.gridColor,
    textColor: DefaultChartConfig.textColor,
    fontSize: {
      title: 16,
      axis: 12,
      label: 11,
      small: 9
    },
    chartType: DefaultChartConfig.chartType,
    responsive: DefaultChartConfig.responsive
  },
  largeScreen: {
    margin: {
      top: 25,
      right: 20,
      bottom: 50,
      left: 45
    },
    aspectRatio: DefaultChartConfig.aspectRatio,
    backgroundColor: DefaultChartConfig.backgroundColor,
    gridColor: DefaultChartConfig.gridColor,
    textColor: DefaultChartConfig.textColor,
    fontSize: {
      title: 18,
      axis: 14,
      label: 13,
      small: 11
    },
    chartType: DefaultChartConfig.chartType,
    responsive: DefaultChartConfig.responsive
  }
};