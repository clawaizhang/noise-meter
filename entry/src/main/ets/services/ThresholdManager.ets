/**
 * 阈值管理器服务
 * 实现分层架构的阈值管理逻辑
 */

import { DayNightTime } from '../constants/AlertsConstants';
import {
  PresetType,
  ThresholdConfig,
  TimeSchedulingConfig,
  DEFAULT_THRESHOLD_CONFIG,
  PRESET_THRESHOLDS,
  DEFAULT_TIME_SCHEDULING_CONFIG,
  THRESHOLD_CALCULATION_RULES
} from '../models/ThresholdConfig';

interface ThresholdValidation {
  isValid: boolean;
  errors: string[];
}

export class ThresholdManager {
  private currentConfig: ThresholdConfig = new ThresholdConfig(
    DEFAULT_THRESHOLD_CONFIG.currentPreset,
    DEFAULT_THRESHOLD_CONFIG.timeSchedulingEnabled,
    DEFAULT_THRESHOLD_CONFIG.baseThreshold,
    DEFAULT_THRESHOLD_CONFIG.daytimeThreshold,
    DEFAULT_THRESHOLD_CONFIG.nighttimeThreshold,
    DEFAULT_THRESHOLD_CONFIG.lastModified
  );
  private timeSchedulingConfig: TimeSchedulingConfig = new TimeSchedulingConfig(
    DEFAULT_TIME_SCHEDULING_CONFIG.daytimeStart,
    DEFAULT_TIME_SCHEDULING_CONFIG.daytimeEnd,
    DEFAULT_TIME_SCHEDULING_CONFIG.nighttimeStart,
    DEFAULT_TIME_SCHEDULING_CONFIG.nighttimeEnd
  );

  // 获取当前配置
  getCurrentConfig(): ThresholdConfig {
    return new ThresholdConfig(
      this.currentConfig.currentPreset,
      this.currentConfig.timeSchedulingEnabled,
      this.currentConfig.baseThreshold,
      this.currentConfig.daytimeThreshold,
      this.currentConfig.nighttimeThreshold,
      this.currentConfig.lastModified
    );
  }

  // 选择环境类型
  selectPreset(presetType: PresetType): ThresholdConfig {
    const preset = PRESET_THRESHOLDS.find(p => p.type === presetType);
    if (!preset) {
      return this.getCurrentConfig();
    }

    this.currentConfig.currentPreset = presetType;
    
    if (presetType === PresetType.CUSTOM) {
      // 自定义环境类型，保持当前阈值设置不变
      this.currentConfig.lastModified = Date.now();
      return this.getCurrentConfig();
    }

    // 预设环境类型，设置基准阈值
    this.currentConfig.baseThreshold = preset.baseValue;

    // 自动计算时段调度阈值
    if (this.currentConfig.timeSchedulingEnabled) {
      const thresholds = this.calculateTimeSchedulingThresholds(preset.baseValue);
      this.currentConfig.daytimeThreshold = thresholds.daytime;
      this.currentConfig.nighttimeThreshold = thresholds.nighttime;
    } else {
      // 如果时段调度未启用，使用基准阈值
      this.currentConfig.daytimeThreshold = preset.baseValue;
      this.currentConfig.nighttimeThreshold = preset.baseValue;
    }

    this.currentConfig.lastModified = Date.now();
    return this.getCurrentConfig();
  }

  // 设置时段调度启用状态
  setTimeSchedulingEnabled(enabled: boolean): ThresholdConfig {
    this.currentConfig.timeSchedulingEnabled = enabled;

    if (enabled && this.currentConfig.currentPreset !== PresetType.CUSTOM) {
      // 在预设环境类型下启用时段调度，重新计算阈值
      const thresholds = this.calculateTimeSchedulingThresholds(this.currentConfig.baseThreshold);
      this.currentConfig.daytimeThreshold = thresholds.daytime;
      this.currentConfig.nighttimeThreshold = thresholds.nighttime;
    } else if (!enabled) {
      // 禁用时段调度，使用基准阈值
      this.currentConfig.daytimeThreshold = this.currentConfig.baseThreshold;
      this.currentConfig.nighttimeThreshold = this.currentConfig.baseThreshold;
    }

    this.currentConfig.lastModified = Date.now();
    return this.getCurrentConfig();
  }

  // 设置白天阈值
  setDaytimeThreshold(value: number): ThresholdConfig {
    // 修改时段阈值时，自动切换到自定义环境类型
    if (this.currentConfig.currentPreset !== PresetType.CUSTOM) {
      this.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    this.currentConfig.daytimeThreshold = value;
    this.currentConfig.lastModified = Date.now();
    return this.getCurrentConfig();
  }

  // 设置夜间阈值
  setNighttimeThreshold(value: number): ThresholdConfig {
    // 修改时段阈值时，自动切换到自定义环境类型
    if (this.currentConfig.currentPreset !== PresetType.CUSTOM) {
      this.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    this.currentConfig.nighttimeThreshold = value;
    this.currentConfig.lastModified = Date.now();
    return this.getCurrentConfig();
  }

  // 设置基准阈值
  setBaseThreshold(value: number): ThresholdConfig {
    // 修改基准阈值时，自动切换到自定义环境类型
    if (this.currentConfig.currentPreset !== PresetType.CUSTOM) {
      this.currentConfig.currentPreset = PresetType.CUSTOM;
    }

    this.currentConfig.baseThreshold = value;

    if (this.currentConfig.timeSchedulingEnabled) {
      // 如果时段调度启用，重新计算时段阈值
      const thresholds = this.calculateTimeSchedulingThresholds(value);
      this.currentConfig.daytimeThreshold = thresholds.daytime;
      this.currentConfig.nighttimeThreshold = thresholds.nighttime;
    }

    this.currentConfig.lastModified = Date.now();
    return this.getCurrentConfig();
  }

  // 获取当前有效阈值（基于当前时间）
  getCurrentEffectiveThreshold(): number {
    if (!this.currentConfig.timeSchedulingEnabled) {
      return this.currentConfig.baseThreshold;
    }

    const currentHour = new Date().getHours();
    const isDaytime = currentHour >= this.timeSchedulingConfig.daytimeStart &&
      currentHour < this.timeSchedulingConfig.daytimeEnd;

    return isDaytime ? this.currentConfig.daytimeThreshold : this.currentConfig.nighttimeThreshold;
  }

  // 获取当前时段描述
  getCurrentTimePeriod(): string {
    const currentHour = new Date().getHours();
    const isDaytime = currentHour >= this.timeSchedulingConfig.daytimeStart &&
      currentHour < this.timeSchedulingConfig.daytimeEnd;

    return isDaytime ? '白天' : '夜间';
  }

  // 验证阈值设置的合理性
  validateThresholds(): ThresholdValidation {
    const errors: string[] = [];

    if (this.currentConfig.daytimeThreshold < 30 || this.currentConfig.daytimeThreshold > 120) {
      errors.push('白天阈值应在30-120dB范围内');
    }

    if (this.currentConfig.nighttimeThreshold < 30 || this.currentConfig.nighttimeThreshold > 120) {
      errors.push('夜间阈值应在30-120dB范围内');
    }

    if (this.currentConfig.daytimeThreshold <= this.currentConfig.nighttimeThreshold) {
      errors.push('白天阈值应大于夜间阈值');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }


  // 私有方法：计算时段调度阈值
  private calculateTimeSchedulingThresholds(baseThreshold: number): DayNightTime {
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

// 创建全局阈值管理器实例
export const thresholdManager = new ThresholdManager();