/**
 * 声级校准常量定义
 * 包含声学专业内容、技术参数和校准配置
 */

// 校准模式枚举
export enum CalibrationMode {
  MANUAL = 'manual',
  AUTO = 'auto'
}

// 校准状态枚举
export enum CalibrationStatus {
  IDLE = 'idle',
  PREPARING = 'preparing',
  CALIBRATING = 'calibrating',
  COMPLETED = 'completed',
  ERROR = 'error'
}

// 环境噪声等级
export enum EnvironmentNoiseLevel {
  EXCELLENT = 'excellent',    // < 30dB - 非常适合校准
  GOOD = 'good',              // 30-40dB - 适合校准
  FAIR = 'fair',              // 40-50dB - 勉强校准
  POOR = 'poor',              // > 50dB - 不适合校准
}

// 校准精度等级
export enum CalibrationAccuracy {
  HIGH = 'high',      // ±0.5dB
  MEDIUM = 'medium',  // ±1.0dB
  LOW = 'low'         // ±2.0dB
}

// 声学原理说明
export interface AcousticTheory {
  principle: string;           // 基本原理
  timeConstant: string;        // 时间常数
  frequencyResponse: string;   // 频率响应
  standardReference: string;   // 标准依据
  physicalPrinciple: string;   // 物理原理
}

// 应用场景说明
export interface ApplicationScenario {
  title: string;              // 场景标题
  description: string;        // 场景描述
  example: string;            // 实际示例
}

// 技术参数
export interface TechnicalParams {
  calibrationRange: string;     // 校准范围
  frequencyRange: string;       // 频率范围
  dynamicRange: string;         // 动态范围
  samplingRate: string;         // 采样率
  accuracy: string;             // 精度
  resolution: string;           // 分辨率
}

// 声学解释内容
export const ACOUSTIC_EXPLANATIONS: Record<string, AcousticTheory> = {
  'calibration': {
    principle: '声级校准通过调整麦克风灵敏度，确保测量结果与标准声压级一致',
    timeConstant: '快速响应(125ms)用于瞬时声级，慢速响应(1s)用于平均声级',
    frequencyResponse: '20Hz-20kHz全频段响应，符合IEC 61672标准',
    standardReference: '基于IEC 61672-1:2013电声学-声级计标准',
    physicalPrinciple: '声压级SPL=20×log₁₀(P/P₀)，其中P₀=20μPa为参考声压'
  }
};

// 应用场景
export const APPLICATION_SCENARIOS: Record<string, ApplicationScenario[]> = {
  'calibration': [
    {
      title: '环境噪声监测',
      description: '用于城市环境噪声、工业噪声等长期监测场景',
      example: '城市交通噪声监测、工厂车间噪声评估'
    },
    {
      title: '声学实验室',
      description: '需要高精度声级测量的科研和测试环境',
      example: '声学材料测试、扬声器频率响应测量'
    },
    {
      title: '职业健康',
      description: '工作场所噪声暴露评估和听力保护',
      example: '工厂工人噪声暴露监测、办公室环境评估'
    }
  ]
};

// 技术参数配置
export const TECHNICAL_PARAMS: TechnicalParams = {
  calibrationRange: '-30dB 至 +30dB',
  frequencyRange: '20Hz - 20kHz',
  dynamicRange: '30dB - 130dB',
  samplingRate: '44.1kHz',
  accuracy: '±0.5dB (A计权)',
  resolution: '0.1dB'
};

// 环境噪声阈值 (dB)
interface EnvironmentThreshold {
  EXCELLENT: number;
  GOOD: number;
  FAIR: number;
  POOR: number;
}

export const ENVIRONMENT_THRESHOLDS: EnvironmentThreshold = {
  EXCELLENT: 20,   // 优秀环境 < 20dB
  GOOD: 25,        // 良好环境 20-25dB
  FAIR: 30,        // 一般环境 25-30dB
  POOR: 30         // 差环境 > 30dB
};

// 校准配置
interface CaliConfig {
  AUTO_CALIBRATION_DURATION: number;
  COUNTDOWN_DURATION: number;
  REFERENCE_LEVEL: number;
  TARGET_CALIBRATION_VALUE: number;
  MIN_CALIBRATION_VALUE: number;
  MAX_CALIBRATION_VALUE: number;
  PRESET_VALUES: number[];
}

export const CALIBRATION_CONFIG: CaliConfig = {
  AUTO_CALIBRATION_DURATION: 8,      // 自动校准时长(秒)
  COUNTDOWN_DURATION: 3,             // 倒计时时长(秒)
  REFERENCE_LEVEL: 25,               // 参考声级(dB) - 更新为25dB
  TARGET_CALIBRATION_VALUE: 25,      // 目标校准值25dB
  MIN_CALIBRATION_VALUE: -30,        // 最小校准值
  MAX_CALIBRATION_VALUE: 30,         // 最大校准值
  PRESET_VALUES: [-20, -10, 0, 10, 20] // 预设校准点
};

// 颜色配置
interface CaliColors {
  PRIMARY: Resource;
  SUCCESS: Resource;
  WARNING: Resource;
  ERROR: Resource;
  BACKGROUND: Resource;
  CARD_BACKGROUND: Resource;
}

export const CALIBRATION_COLORS: CaliColors = {
  PRIMARY: $r('sys.color.ohos_id_color_palette1'),
  SUCCESS: $r('sys.color.ohos_id_color_palette2'),
  WARNING: $r('sys.color.ohos_id_color_palette3'),
  ERROR: $r('sys.color.ohos_id_color_palette4'),
  BACKGROUND: $r('sys.color.background_secondary'),
  CARD_BACKGROUND: $r('sys.color.comp_background_primary')
};