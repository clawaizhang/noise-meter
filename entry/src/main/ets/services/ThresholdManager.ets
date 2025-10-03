/**
 * 阈值管理器服务
 * 实现分层架构的阈值管理逻辑
 */

import { DayNightTime } from '../constants/AlertsConstants';
import {
  CUSTOM_THRESHOLD_CONFIG,
  DEFAULT_THRESHOLD_CONFIG,
  DEFAULT_TIME_SCHEDULING_CONFIG,
  PRESET_THRESHOLDS,
  PresetType,
  THRESHOLD_CALCULATION_RULES,
  ThresholdConfig,
  TimeSchedulingConfig
} from '../models/ThresholdConfig';
import { PersistenceV2 } from '@kit.ArkUI';

interface ThresholdValidation {
  isValid: boolean;
  errors: string[];
}

export class ThresholdManager {
  private static  currentConfig: ThresholdConfig;
  private static  timeSchedulingConfig: TimeSchedulingConfig = new TimeSchedulingConfig(
    DEFAULT_TIME_SCHEDULING_CONFIG.daytimeStart,
    DEFAULT_TIME_SCHEDULING_CONFIG.daytimeEnd,
    DEFAULT_TIME_SCHEDULING_CONFIG.nighttimeStart,
    DEFAULT_TIME_SCHEDULING_CONFIG.nighttimeEnd
  );

  // 获取当前配置
  static setCurrentConfig(config:ThresholdConfig): ThresholdConfig {
    return ThresholdManager.currentConfig = config;
  }

  // 选择环境类型
  static selectPreset(presetType: PresetType): void {
    let preset = PRESET_THRESHOLDS.find(p => p.type === presetType);
    if (!preset) {
      preset = CUSTOM_THRESHOLD_CONFIG;
    }

    ThresholdManager.currentConfig.currentPreset = presetType;
    
    // 预设环境类型，设置基准阈值
    ThresholdManager.currentConfig.baseThreshold = preset.baseValue;

    // 自动计算时段调度阈值
    if (ThresholdManager.currentConfig.timeSchedulingEnabled) {
      const thresholds = ThresholdManager.calculateTimeSchedulingThresholds(preset.baseValue);
      ThresholdManager.currentConfig.daytimeThreshold = thresholds.daytime;
      ThresholdManager.currentConfig.nighttimeThreshold = thresholds.nighttime;
    } else {
      // 如果时段调度未启用，使用基准阈值
      ThresholdManager.currentConfig.daytimeThreshold = preset.baseValue;
      ThresholdManager.currentConfig.nighttimeThreshold = preset.baseValue;
    }

    ThresholdManager.currentConfig.lastModified = Date.now();
  }

  // 设置时段调度启用状态
  static setTimeSchedulingEnabled(enabled: boolean): void {
    ThresholdManager.currentConfig.timeSchedulingEnabled = enabled;

    if (enabled && ThresholdManager.currentConfig.currentPreset !== PresetType.CUSTOM) {
      // 在预设环境类型下启用时段调度，重新计算阈值
      const thresholds = ThresholdManager.calculateTimeSchedulingThresholds(ThresholdManager.currentConfig.baseThreshold);
      ThresholdManager.currentConfig.daytimeThreshold = thresholds.daytime;
      ThresholdManager.currentConfig.nighttimeThreshold = thresholds.nighttime;
    } else if (!enabled) {
      // 禁用时段调度，使用基准阈值
      ThresholdManager.currentConfig.daytimeThreshold = ThresholdManager.currentConfig.baseThreshold;
      ThresholdManager.currentConfig.nighttimeThreshold = ThresholdManager.currentConfig.baseThreshold;
    }

    ThresholdManager.currentConfig.lastModified = Date.now();
  }

  // 设置白天阈值
  static setDaytimeThreshold(value: number): void {
    // 修改时段阈值时，自动切换到自定义环境类型
    if (ThresholdManager.currentConfig.currentPreset !== PresetType.CUSTOM) {
      ThresholdManager.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    ThresholdManager.currentConfig.daytimeThreshold = value;
    ThresholdManager.currentConfig.lastModified = Date.now();
  }

  // 设置夜间阈值
  static setNighttimeThreshold(value: number): void {
    // 修改时段阈值时，自动切换到自定义环境类型
    if (ThresholdManager.currentConfig.currentPreset !== PresetType.CUSTOM) {
      ThresholdManager.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    ThresholdManager.currentConfig.nighttimeThreshold = value;
    ThresholdManager.currentConfig.lastModified = Date.now();
  }

  // 设置基准阈值
  static setBaseThreshold(value: number): void {
    // 修改基准阈值时，自动切换到自定义环境类型
    if (ThresholdManager.currentConfig.currentPreset !== PresetType.CUSTOM) {
      ThresholdManager.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    ThresholdManager.currentConfig.baseThreshold = value;

    if (ThresholdManager.currentConfig.timeSchedulingEnabled) {
      // 如果时段调度启用，重新计算时段阈值
      const thresholds = ThresholdManager.calculateTimeSchedulingThresholds(value);
      ThresholdManager.currentConfig.daytimeThreshold = thresholds.daytime;
      ThresholdManager.currentConfig.nighttimeThreshold = thresholds.nighttime;
    }

    ThresholdManager.currentConfig.lastModified = Date.now();
  }

  // 获取当前有效阈值（基于当前时间）
  static getCurrentEffectiveThreshold(): number {
    if (!ThresholdManager.currentConfig.timeSchedulingEnabled) {
      return ThresholdManager.currentConfig.baseThreshold;
    }

    const currentHour = new Date().getHours();
    const isDaytime = currentHour >= ThresholdManager.timeSchedulingConfig.daytimeStart &&
      currentHour < ThresholdManager.timeSchedulingConfig.daytimeEnd;

    return isDaytime ? ThresholdManager.currentConfig.daytimeThreshold : ThresholdManager.currentConfig.nighttimeThreshold;
  }

  // 获取当前时段描述
  static getCurrentTimePeriod(): string {
    const currentHour = new Date().getHours();
    const isDaytime = currentHour >= ThresholdManager.timeSchedulingConfig.daytimeStart &&
      currentHour < ThresholdManager.timeSchedulingConfig.daytimeEnd;

    return isDaytime ? '白天' : '夜间';
  }

  // 验证阈值设置的合理性
  static validateThresholds(): ThresholdValidation {
    const errors: string[] = [];

    if (ThresholdManager.currentConfig.daytimeThreshold < 30 || ThresholdManager.currentConfig.daytimeThreshold > 120) {
      errors.push('白天阈值应在30-120dB范围内');
    }

    if (ThresholdManager.currentConfig.nighttimeThreshold < 30 || ThresholdManager.currentConfig.nighttimeThreshold > 120) {
      errors.push('夜间阈值应在30-120dB范围内');
    }

    if (ThresholdManager.currentConfig.daytimeThreshold <= ThresholdManager.currentConfig.nighttimeThreshold) {
      errors.push('白天阈值应大于夜间阈值');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }


  // 私有方法：计算时段调度阈值
  private static  calculateTimeSchedulingThresholds(baseThreshold: number): DayNightTime {
    const preset = PRESET_THRESHOLDS.find(p => p.baseValue === baseThreshold);
    if (!preset) {
      // 如果不是预设值，使用默认差值
      return {
        daytime: baseThreshold + 10,
        nighttime: baseThreshold - 10
      };
    }

    const rule = THRESHOLD_CALCULATION_RULES.find(r => r.presetType === preset.type);
    if (!rule) {
      return {
        daytime: baseThreshold + 10,
        nighttime: baseThreshold - 10
      };
    }

    return {
      daytime: baseThreshold + rule.daytimeDifference,
      nighttime: baseThreshold + rule.nighttimeDifference
    };
  }
}