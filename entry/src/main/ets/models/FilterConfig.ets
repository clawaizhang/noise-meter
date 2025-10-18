import { WeightingType } from '../constants/WeightingConstants';
import { DecibelRange } from './DecibelRecord';

/**
 * 分贝范围过滤器配置
 */
@ObservedV2
export class DecibelRangeFilter {
  @Trace presetRanges: DecibelRange[] = [];
  @Trace customMin?: number = undefined;
  @Trace customMax?: number = undefined;

  constructor(presetRanges: DecibelRange[] = [], customMin?: number, customMax?: number) {
    this.presetRanges = presetRanges;
    this.customMin = customMin;
    this.customMax = customMax;
  }
}

/**
 * 状态过滤器配置
 */
@ObservedV2
export class StatusFilter {
  @Trace favoriteOnly: boolean = false;
  @Trace hasAudio: boolean = false;
  @Trace hasLocation: boolean = false;

  constructor(favoriteOnly: boolean = false, hasAudio: boolean = false, hasLocation: boolean = false) {
    this.favoriteOnly = favoriteOnly;
    this.hasAudio = hasAudio;
    this.hasLocation = hasLocation;
  }
}

/**
 * 权重类型过滤器配置
 */
@ObservedV2
export class WeightingFilter {
  @Trace types: WeightingType[] = [];

  constructor(types: WeightingType[] = []) {
    this.types = types;
  }
}

/**
 * 时间范围过滤器配置
 */
@ObservedV2
export class TimeRangeFilter {
  @Trace startTime?: number = undefined;
  @Trace endTime?: number = undefined;

  constructor(startTime?: number, endTime?: number) {
    this.startTime = startTime;
    this.endTime = endTime;
  }
}

/**
 * 文本搜索过滤器配置
 */
@ObservedV2
export class TextSearchFilter {
  @Trace locationKeyword?: string = undefined;
  @Trace commentKeyword?: string = undefined;

  constructor(locationKeyword?: string, commentKeyword?: string) {
    this.locationKeyword = locationKeyword;
    this.commentKeyword = commentKeyword;
  }
}

/**
 * 完整的过滤器配置
 */
@ObservedV2
export class FilterConfig {
  @Trace decibelRange?: DecibelRangeFilter = undefined;
  @Trace status?: StatusFilter = undefined;
  @Trace weighting?: WeightingFilter = undefined;
  @Trace textSearch?: TextSearchFilter = undefined;
  @Trace timeRange?: TimeRangeFilter = undefined;
  @Trace isActive: boolean = false;

  constructor(isActive: boolean = false) {
    this.isActive = isActive;
  }
}

/**
 * 过滤器管理器类
 */
export class FilterManager {
  private currentFilters: FilterConfig;

  constructor() {
    this.currentFilters = new FilterConfig(false);
  }

  /**
   * 获取当前过滤器配置
   */
  getCurrentFilters(): FilterConfig {
    return this.currentFilters;
  }

  /**
   * 更新过滤器配置
   */
  updateFilters(filters: FilterConfig): void {
    this.currentFilters = filters;
  }

  /**
   * 重置所有过滤器
   */
  resetFilters(): void {
    this.currentFilters = new FilterConfig(false);
  }

  /**
   * 检查是否有活跃的过滤器
   */
  hasActiveFilters(): boolean {
    return this.currentFilters.isActive;
  }

  /**
   * 获取活跃过滤器数量
   */
  getActiveFilterCount(): number {
    if (!this.currentFilters.isActive) {
      return 0;
    }

    let count = 0;

    // 分贝范围过滤器
    if (this.currentFilters.decibelRange) {
      if (this.currentFilters.decibelRange.presetRanges.length > 0) {
        count++;
      }
      if (this.currentFilters.decibelRange.customMin !== undefined || 
          this.currentFilters.decibelRange.customMax !== undefined) {
        count++;
      }
    }

    // 状态过滤器
    if (this.currentFilters.status) {
      if (this.currentFilters.status.favoriteOnly) count++;
      if (this.currentFilters.status.hasAudio) count++;
      if (this.currentFilters.status.hasLocation) count++;
    }

    // 权重类型过滤器
    if (this.currentFilters.weighting && this.currentFilters.weighting.types.length > 0) {
      count++;
    }

    // 文本搜索过滤器
    if (this.currentFilters.textSearch) {
      if (this.currentFilters.textSearch.locationKeyword) count++;
      if (this.currentFilters.textSearch.commentKeyword) count++;
    }

    // 时间范围过滤器
    if (this.currentFilters.timeRange) {
      if (this.currentFilters.timeRange.startTime !== undefined ||
          this.currentFilters.timeRange.endTime !== undefined) {
        count++;
      }
    }

    return count;
  }

  /**
   * 获取分贝范围预设的描述
   */
  static getDecibelRangeDescription(range: DecibelRange): string {
    return range.desc;
  }

  /**
   * 获取所有可用的分贝范围预设
   */
  static getAllDecibelRanges(): DecibelRange[] {
    return [
      { min: 0, max: 40, desc: '安静' },
      { min: 40, max: 60, desc: '正常' },
      { min: 60, max: 80, desc: '嘈杂' },
      { min: 80, max: 100, desc: '很吵' },
      { min: 100, max: Infinity, desc: '危险' }
    ];
  }
}