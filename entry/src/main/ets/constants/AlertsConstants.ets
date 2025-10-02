/**
 * 警报与通知常量定义
 * 包含声学专业内容、警报类型和配置参数
 */

// 警报类型枚举
export enum AlertType {
  INSTANT_PEAK = 'instant_peak',     // 瞬时峰值警报
  CONTINUOUS_EXPOSURE = 'continuous_exposure', // 持续暴露警报
  ENVIRONMENT_STANDARD = 'environment_standard', // 环境标准警报
  CUSTOM_THRESHOLD = 'custom_threshold' // 自定义阈值警报
}

// 警报状态枚举
export enum AlertStatus {
  IDLE = 'idle',          // 空闲状态
  MONITORING = 'monitoring', // 监控中
  WARNING = 'warning',    // 警告状态
  ALERT = 'alert',        // 警报状态
  MUTED = 'muted'         // 静音状态
}

// 环境噪声等级
export enum EnvironmentNoiseLevel {
  EXCELLENT = 'excellent', // < 30dB - 非常安静
  GOOD = 'good',         // 30-50dB - 良好环境
  FAIR = 'fair',         // 50-70dB - 一般环境
  POOR = 'poor',         // 70-85dB - 嘈杂环境
  DANGEROUS = 'dangerous' // > 85dB - 危险环境
}

// 通知类型枚举
export enum NotificationType {
  SOUND = 'sound',        // 声音提示
  VIBRATION = 'vibration', // 振动提示
  VISUAL = 'visual',      // 视觉提示
  SYSTEM = 'system'       // 系统通知
}

// 时段类型枚举
export enum TimePeriod {
  ALL_DAY = 'all_day',    // 全天统一
  DAYTIME = 'daytime',    // 白天 (6:00-22:00)
  NIGHTTIME = 'nighttime', // 夜间 (22:00-6:00)
  SLEEP = 'sleep'         // 睡眠时段
}

// 声学原理说明
export interface AcousticTheory {
  principle: string;      // 基本原理
  healthImpact: string;   // 健康影响
  standardReference: string; // 标准依据
  physicalPrinciple: string; // 物理原理
}

// 预设阈值配置
export interface PresetThreshold {
  name: string;           // 预设名称
  value: number;          // 阈值(dB)
  description: string;    // 描述
  color: Resource;        // 颜色
}

// 技术参数
export interface TechnicalParams {
  frequencyRange: string; // 频率范围
  dynamicRange: string;   // 动态范围
  accuracy: string;       // 精度
  responseTime: string;   // 响应时间
}

// 声学解释内容
export const ACOUSTIC_EXPLANATIONS: Record<string, AcousticTheory> = {
  'alerts': {
    principle: '声级警报基于声压级测量，当环境噪声超过设定阈值时触发警报',
    healthImpact: '长期暴露在85dB以上环境可能导致听力损伤，70dB以下为安全范围',
    standardReference: '基于GB3096-2008声环境质量标准和IEC 61672声级计标准',
    physicalPrinciple: '声压级SPL=20×log₁₀(P/P₀)，其中P₀=20μPa为参考声压'
  }
};

// 预设阈值配置
export const PRESET_THRESHOLDS: PresetThreshold[] = [
  {
    name: '安静环境',
    value: 40,
    description: '图书馆、卧室等需要安静的环境',
    color: $r('sys.color.ohos_id_color_palette2') // 绿色
  },
  {
    name: '一般环境',
    value: 55,
    description: '办公室、教室等日常环境',
    color: $r('sys.color.ohos_id_color_palette5') // 浅蓝色
  },
  {
    name: '嘈杂环境',
    value: 70,
    description: '街道、商场等嘈杂环境',
    color: $r('sys.color.ohos_id_color_palette3') // 黄色
  },
  {
    name: '危险环境',
    value: 85,
    description: '工厂、工地等可能损伤听力的环境',
    color: $r('sys.color.ohos_id_color_palette4') // 红色
  }
];

// 技术参数配置
export const TECHNICAL_PARAMS: TechnicalParams = {
  frequencyRange: '20Hz - 20kHz',
  dynamicRange: '30dB - 130dB',
  accuracy: '±0.5dB (A计权)',
  responseTime: '快速125ms / 慢速1s'
};

// 时段配置
interface TimePeriodConfig {
  DAYTIME_START: number;
  DAYTIME_END: number;
  NIGHTTIME_START: number;
  NIGHTTIME_END: number;
}

export const TIME_PERIOD_CONFIG: TimePeriodConfig = {
  DAYTIME_START: 6,   // 白天开始时间 (6:00)
  DAYTIME_END: 22,    // 白天结束时间 (22:00)
  NIGHTTIME_START: 22, // 夜间开始时间 (22:00)
  NIGHTTIME_END: 6    // 夜间结束时间 (6:00)
};

// 智能联动配置
interface SmartLinkageConfig {
  ENABLED: boolean;
  PRESET_THRESHOLD_DIFFERENCES: Record<string, number>;
}

export const SMART_LINKAGE_CONFIG: SmartLinkageConfig = {
  ENABLED: true,
  PRESET_THRESHOLD_DIFFERENCES: {
    'quiet_environment': 5,    // 安静环境差值
    'general_environment': 10, // 一般环境差值
    'noisy_environment': 15,   // 嘈杂环境差值
    'dangerous_environment': 20 // 危险环境差值
  }
};

// 预设映射表
export const PRESET_MAPPING: Record<string, string> = {
  'quiet_environment': '安静环境',
  'general_environment': '一般环境',
  'noisy_environment': '嘈杂环境',
  'dangerous_environment': '危险环境',
  'custom': '自定义'
};

export interface DayNightTime {
  daytime: number;
  nighttime: number;
}

// 颜色配置
interface AlertColors {
  PRIMARY: Resource;
  SUCCESS: Resource;
  WARNING: Resource;
  ERROR: Resource;
  BACKGROUND: Resource;
  CARD_BACKGROUND: Resource;
}

export const ALERT_COLORS: AlertColors = {
  PRIMARY: $r('sys.color.ohos_id_color_palette1'),
  SUCCESS: $r('sys.color.ohos_id_color_palette2'),
  WARNING: $r('sys.color.ohos_id_color_palette3'),
  ERROR: $r('sys.color.ohos_id_color_palette4'),
  BACKGROUND: $r('sys.color.background_secondary'),
  CARD_BACKGROUND: $r('sys.color.comp_background_primary')
};