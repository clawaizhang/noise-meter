/**
 * 阈值配置模型定义
 * 简化架构：环境类型选择 + 时段调度开关
 */

// 环境类型枚举
export enum PresetType {
  QUIET_ENVIRONMENT = 'quiet_environment',    // 安静环境
  GENERAL_ENVIRONMENT = 'general_environment', // 一般环境
  NOISY_ENVIRONMENT = 'noisy_environment',    // 嘈杂环境
  DANGEROUS_ENVIRONMENT = 'dangerous_environment', // 危险环境
  CUSTOM = 'custom'                           // 自定义环境
}

// 预设阈值配置
export interface PresetThreshold {
  type: PresetType;
  name: string;
  baseValue: number;
  description: string;
  color: Resource;
}

@ObservedV2
export class ThresholdConfig {
  @Trace currentPreset: PresetType;           // 当前环境类型
  @Trace timeSchedulingEnabled: boolean;      // 时段调度开关
  @Trace baseThreshold: number;               // 统一阈值（时段调度关闭时）
  @Trace daytimeThreshold: number;            // 白天阈值（时段调度开启时）
  @Trace nighttimeThreshold: number;          // 夜间阈值（时段调度开启时）
  @Trace lastModified: number;                // 最后修改时间

  constructor(
    currentPreset: PresetType,
    timeSchedulingEnabled: boolean,
    baseThreshold: number,
    daytimeThreshold: number,
    nighttimeThreshold: number,
    lastModified: number
  ) {
    this.currentPreset = currentPreset;
    this.timeSchedulingEnabled = timeSchedulingEnabled;
    this.baseThreshold = baseThreshold;
    this.daytimeThreshold = daytimeThreshold;
    this.nighttimeThreshold = nighttimeThreshold;
    this.lastModified = lastModified;
  }
}

@ObservedV2
export class TimeSchedulingConfig {
  @Trace daytimeStart: number;
  @Trace daytimeEnd: number;
  @Trace nighttimeStart: number;
  @Trace nighttimeEnd: number;

  constructor(daytimeStart: number, daytimeEnd: number, nighttimeStart: number, nighttimeEnd: number) {
    this.daytimeStart = daytimeStart;
    this.daytimeEnd = daytimeEnd;
    this.nighttimeStart = nighttimeStart;
    this.nighttimeEnd = nighttimeEnd;
  }
}

// 阈值计算规则
export interface ThresholdCalculationRule {
  presetType: PresetType;
  daytimeDifference: number;  // 白天阈值差值
  nighttimeDifference: number; // 夜间阈值差值
}

// 默认配置
export const DEFAULT_THRESHOLD_CONFIG: ThresholdConfig = new ThresholdConfig(PresetType.GENERAL_ENVIRONMENT, true, 55, 65, 45, Date.now())

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
export const DEFAULT_TIME_SCHEDULING_CONFIG: TimeSchedulingConfig = new TimeSchedulingConfig(6, 22, 22, 6);
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