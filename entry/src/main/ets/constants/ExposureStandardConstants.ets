/**
 * 暴露标准常量定义
 * 支持多个国家标准的暴露剂量计算
 */

export enum NoiseExposureStandard {
  INDUSTRIAL = 'industrial',      // 工业企业标准 GBZ 2.2-2007
  ENVIRONMENTAL = 'environmental', // 声环境标准 GB 3096-2008  
  OCCUPATIONAL = 'occupational',   // 职业健康标准 GBZ 49-2014
  SOCIAL = 'social'               // 社会生活标准 GB 22337-2008
}

export enum DecibelRange {
  VERY_QUIET = 'very_quiet',      // 40-50dB: 非常安静
  QUIET = 'quiet',               // 50-60dB: 安静环境  
  MODERATE = 'moderate',         // 60-70dB: 适中环境
  NOISY = 'noisy',               // 70-80dB: 嘈杂环境
  HIGH = 'high',                 // 80-85dB: 高分贝
  VERY_HIGH = 'very_high',       // 85-90dB: 很高分贝
  EXTREME = 'extreme'            // 90+dB: 极端分贝
}

// 标准配置接口
export interface StandardConfig {
  name: string;
  code: string;
  baseLimit: number;
  baseDuration: number;
  description: string;
}

// 分贝区间配置接口
export interface DecibelRangeConfig {
  min: number;
  max: number;
  label: string;
  description: string;
}

// 标准配置信息
export const StandardConfigs: Record<NoiseExposureStandard, StandardConfig> = {
  [NoiseExposureStandard.INDUSTRIAL]: {
    name: '工业企业标准',
    code: 'GBZ 2.2-2007',
    baseLimit: 85, // 85分贝
    baseDuration: 8 * 60 * 60 * 1000, // 8小时
    description: '工作场所噪声暴露标准'
  },
  [NoiseExposureStandard.ENVIRONMENTAL]: {
    name: '声环境标准',
    code: 'GB 3096-2008',
    baseLimit: 65, // 调整为2类功能区标准，更符合实际生活环境
    baseDuration: 24 * 60 * 60 * 1000, // 24小时
    description: '环境噪声管理标准'
  },
  [NoiseExposureStandard.OCCUPATIONAL]: {
    name: '职业健康标准',
    code: 'GBZ 49-2014',
    baseLimit: 80, // 健康保护阈值
    baseDuration: 8 * 60 * 60 * 1000, // 8小时
    description: '职业健康保护标准'
  },
  [NoiseExposureStandard.SOCIAL]: {
    name: '社会生活标准',
    code: 'GB 22337-2008',
    baseLimit: 60, // 生活区域标准
    baseDuration: 24 * 60 * 60 * 1000, // 24小时
    description: '社会生活噪声标准'
  }
};

// 分贝区间配置
export const DecibelRangeConfigs: Record<DecibelRange, DecibelRangeConfig> = {
  [DecibelRange.VERY_QUIET]: {
    min: 40,
    max: 50,
    label: '非常安静',
    description: '图书馆、病房等环境'
  },
  [DecibelRange.QUIET]: {
    min: 50,
    max: 60,
    label: '安静环境',
    description: '办公室、住宅区等环境'
  },
  [DecibelRange.MODERATE]: {
    min: 60,
    max: 70,
    label: '适中环境',
    description: '普通交谈、餐厅等环境'
  },
  [DecibelRange.NOISY]: {
    min: 70,
    max: 80,
    label: '嘈杂环境',
    description: '交通道路、商场等环境'
  },
  [DecibelRange.HIGH]: {
    min: 80,
    max: 85,
    label: '高分贝',
    description: '长期暴露可能损伤听力'
  },
  [DecibelRange.VERY_HIGH]: {
    min: 85,
    max: 90,
    label: '很高分贝',
    description: '需要听力保护'
  },
  [DecibelRange.EXTREME]: {
    min: 90,
    max: 120,
    label: '极端分贝',
    description: '立即听力损伤风险'
  }
};