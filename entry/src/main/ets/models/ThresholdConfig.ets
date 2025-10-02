/**
 * 阈值配置模型定义
 * 支持分层架构的阈值管理系统
 */

// 阈值管理模式枚举
export enum ThresholdMode {
  SMART_PRESET = 'smart_preset',    // 智能预设模式
  TIME_SCHEDULING = 'time_scheduling', // 时段调度模式  
  CUSTOM = 'custom'                 // 自定义模式
}

// 预设类型枚举
export enum PresetType {
  QUIET_ENVIRONMENT = 'quiet_environment',    // 安静环境
  GENERAL_ENVIRONMENT = 'general_environment', // 一般环境
  NOISY_ENVIRONMENT = 'noisy_environment',    // 嘈杂环境
  DANGEROUS_ENVIRONMENT = 'dangerous_environment', // 危险环境
  CUSTOM = 'custom'                           // 自定义
}

// 阈值配置接口
export interface ThresholdConfig {
  mode: ThresholdMode;             // 当前模式
  baseThreshold: number;           // 基准阈值
  daytimeThreshold: number;        // 白天阈值
  nighttimeThreshold: number;      // 夜间阈值
  currentPreset: PresetType;       // 当前预设
  timeSchedulingEnabled: boolean;  // 时段调度启用状态
  lastModified: number;            // 最后修改时间戳
}

// 预设阈值配置
export interface PresetThreshold {
  type: PresetType;
  name: string;
  baseValue: number;
  description: string;
  color: Resource;
}

// 时段调度配置
export interface TimeSchedulingConfig {
  daytimeStart: number;    // 白天开始时间 (小时)
  daytimeEnd: number;      // 白天结束时间 (小时)
  nighttimeStart: number;  // 夜间开始时间 (小时)
  nighttimeEnd: number;    // 夜间结束时间 (小时)
}

// 阈值计算规则
export interface ThresholdCalculationRule {
  presetType: PresetType;
  daytimeDifference: number;  // 白天阈值差值
  nighttimeDifference: number; // 夜间阈值差值
}

// 默认配置
export const DEFAULT_THRESHOLD_CONFIG: ThresholdConfig = {
  mode: ThresholdMode.SMART_PRESET,
  baseThreshold: 55,
  daytimeThreshold: 65,
  nighttimeThreshold: 45,
  currentPreset: PresetType.GENERAL_ENVIRONMENT,
  timeSchedulingEnabled: true,
  lastModified: Date.now()
};

// 预设阈值配置
export const PRESET_THRESHOLDS: PresetThreshold[] = [
  {
    type: PresetType.QUIET_ENVIRONMENT,
    name: '安静环境',
    baseValue: 40,
    description: '图书馆、卧室等需要安静的环境',
    color: $r('sys.color.ohos_id_color_palette2') // 绿色
  },
  {
    type: PresetType.GENERAL_ENVIRONMENT,
    name: '一般环境',
    baseValue: 55,
    description: '办公室、教室等日常环境',
    color: $r('sys.color.ohos_id_color_palette5') // 浅蓝色
  },
  {
    type: PresetType.NOISY_ENVIRONMENT,
    name: '嘈杂环境',
    baseValue: 70,
    description: '街道、商场等嘈杂环境',
    color: $r('sys.color.ohos_id_color_palette3') // 黄色
  },
  {
    type: PresetType.DANGEROUS_ENVIRONMENT,
    name: '危险环境',
    baseValue: 85,
    description: '工厂、工地等可能损伤听力的环境',
    color: $r('sys.color.ohos_id_color_palette4') // 红色
  }
];

// 时段调度配置
export const DEFAULT_TIME_SCHEDULING_CONFIG: TimeSchedulingConfig = {
  daytimeStart: 6,   // 6:00
  daytimeEnd: 22,    // 22:00
  nighttimeStart: 22, // 22:00
  nighttimeEnd: 6    // 6:00
};

// 阈值计算规则
export const THRESHOLD_CALCULATION_RULES: ThresholdCalculationRule[] = [
  {
    presetType: PresetType.QUIET_ENVIRONMENT,
    daytimeDifference: 5,
    nighttimeDifference: -5
  },
  {
    presetType: PresetType.GENERAL_ENVIRONMENT,
    daytimeDifference: 10,
    nighttimeDifference: -10
  },
  {
    presetType: PresetType.NOISY_ENVIRONMENT,
    daytimeDifference: 15,
    nighttimeDifference: -15
  },
  {
    presetType: PresetType.DANGEROUS_ENVIRONMENT,
    daytimeDifference: 20,
    nighttimeDifference: -20
  }
];