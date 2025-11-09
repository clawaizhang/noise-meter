import { DecibelService } from '../services/DecibelService';
import { DataProcessingState } from './DataProcessingState';
import { PreferenceKeys } from './PreferenceKeys';

/**
 * 警报显示状态对象（UI专用）
 */
@ObservedV2
export class DisplayAlertState {
  // 显示警报状态
  @Trace
  isActive: boolean = false;

  // 显示持续时间（毫秒）
  duration: number = 0;

  // 格式化后的持续时间字符串
  @Trace
  formattedDuration: string = '0秒';

  constructor() {
    this.updateFormattedDuration();
  }

  /**
   * 更新格式化持续时间
   */
  updateFormattedDuration(): void {
    this.formattedDuration = this.formatDuration(this.duration);
  }

  /**
   * 格式化持续时间
   */
  private formatDuration(duration: number): string {
    const seconds = Math.floor(duration / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`;
    } else if (minutes > 0) {
      return `${minutes}分钟${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }

  /**
   * 重置显示状态
   */
  reset(): void {
    this.isActive = false;
    this.duration = 0;
    this.formattedDuration = '0秒';
  }
}

/**
 * 统计数据对象
 */
@ObservedV2
export class UiStatisticsData {
  // 最小分贝值
  @Trace
  minDb: number = 0;

  // 最大分贝值
  @Trace
  maxDb: number = 0;

  // 平均分贝值
  @Trace
  avgDb: number = 0;

  // 测量时长（秒）
  @Trace
  duration: number = 0;

  // 测量开始时间
  @Trace
  startTime: number = 0;

  // 增量计算字段
  private runningSum: number = 0;           // 累加和
  private count: number = 0;                // 数据点数量
  private currentMin: number = Number.MAX_VALUE;  // 当前最小值
  private currentMax: number = Number.MIN_VALUE;  // 当前最大值

  constructor() {
    this.startTime = Date.now();
    this.resetIncremental();
  }

  /**
   * 更新统计数据（增量计算版本）
   */
  updateStatistics(currentDb: number, values: number[]): void {
    // 处理空数组情况
    if (values.length === 0) {
      this.minDb = currentDb;
      this.maxDb = currentDb;
      this.avgDb = currentDb;
      return;
    }

    // 增量计算：只使用当前值，忽略历史values数组
    this.updateStatisticsIncremental(currentDb);

    // 更新持续时间
    this.duration = Number(((Date.now() - this.startTime) / 1000).toFixed(1));
  }

  /**
   * 增量统计计算方法
   */
  private updateStatisticsIncremental(newValue: number): void {
    // 更新平均值（累加和计数）
    if (this.count === 0) {
      this.runningSum = newValue;
      this.count = 1;
      this.avgDb = newValue;
    } else {
      this.runningSum += newValue;
      this.count++;
      this.avgDb = Math.round(this.runningSum / this.count);
    }

    // 更新最小值
    if (this.count === 1) {
      this.currentMin = newValue;
    } else {
      this.currentMin = Math.min(this.currentMin, newValue);
    }
    this.minDb = this.currentMin;

    // 更新最大值
    if (this.count === 1) {
      this.currentMax = newValue;
    } else {
      this.currentMax = Math.max(this.currentMax, newValue);
    }
    this.maxDb = this.currentMax;
  }

  /**
   * 重置统计数据（完全重置）
   */
  reset(): void {
    this.minDb = 0;
    this.maxDb = 0;
    this.avgDb = 0;
    this.duration = 0;
    this.startTime = Date.now();
    this.resetIncremental();
  }

  /**
   * 重置增量统计状态
   */
  resetIncremental(): void {
    this.runningSum = 0;
    this.count = 0;
    this.currentMin = 0;
    this.currentMax = 0;
  }
}

/**
 * UI显示状态模型
 * 负责UI显示状态，前后台切换时控制UI更新
 */
@ObservedV2
export class UIDisplayState {
  // 显示分贝值（UI专用）
  @Trace displayDb: number = 0;
  
  // 前一个分贝值（用于趋势计算）
  @Trace previousDb: number = 0;

  @Trace displayDescription: string = '几乎无声';
  @Trace displayColor: Resource = $r('sys.color.confirm');

  // 显示频谱数据（UI专用）
  @Trace displaySpectrumData: Float32Array = new Float32Array();

  // 显示时域波形数据（UI专用）
  @Trace displayTimeDomainData: number[] = [];

  // 显示峰值频率（UI专用）
  @Trace displayPeakFreq: number = 0;

  // 显示统计数据
  @Trace displayStatistics: UiStatisticsData = new UiStatisticsData();

  // 显示统计分布数据（用于直方图）
  @Trace displayStatisticsDistribution: number[] = [];


  // UI更新状态
  @Trace isUIUpdatesEnabled: boolean = true;

  // 时间显示相关属性
  @Trace timeDisplay: string = '';
  recordingStartTime: number = Date.now();
  @Trace currentTime: number = Date.now();

  constructor() {
  }

  /**
   * 更新时间显示
   * @param pk 偏好设置
   */
  updateTimeDisplay(pk: PreferenceKeys): void {
    if (!this.isUIUpdatesEnabled) {
      return; // 后台时不更新显示
    }

    let elapsed = this.currentTime - this.recordingStartTime;
    let minutes = Math.floor(elapsed / 60000);
    let seconds = Math.floor((elapsed % 60000) / 1000);
    
    if (!pk.auto_save_enabled) {
      // 显示已录制时长（从录音开始时间计算）
      this.timeDisplay = `${minutes}:${seconds.toString().padStart(2, '0')}`;
      return;
    }

    // 计算剩余时间
    const intervalMs = pk.auto_save_interval * 60 * 1000;
    const remaining = Math.max(0, intervalMs - elapsed);

    if (remaining <= 0) {
      this.timeDisplay = '即将自动保存';
      console.info('即将自动保存');
      return;
    }

    minutes = Math.floor(remaining / 60000);
    seconds = Math.floor((remaining % 60000) / 1000);

    this.timeDisplay = `${minutes}:${seconds.toString().padStart(2, '0')} 后自动保存`;

    console.info(`剩余时间：${minutes}分${seconds}秒`);
  }

  /**
   * 更新录音开始时间
   * @param startTime 录音开始时间戳
   */
  updateRecordingStartTime(startTime: number): void {
    this.recordingStartTime = startTime;
  }

  /**
   * 更新当前时间
   * @param currentTime 当前时间戳
   */
  updateCurrentTime(currentTime: number): void {
    this.currentTime = currentTime;
  }

  /**
   * 从数据处理状态同步到UI显示状态
   */
  syncFromProcessingState(processingState: DataProcessingState): void {
    if (!this.isUIUpdatesEnabled) {
      return;
    }

    // 更新前一个分贝值
    this.previousDb = this.displayDb;

    // 同步分贝值
    this.displayDb = processingState.processingDb;
    this.displayDescription = DecibelService.getDecibelDescription(this.displayDb);
    this.displayColor = DecibelService.getDecibelColor(this.displayDb);

    // 同步频谱数据（直接赋值，因为都是Float32Array类型）
    if (processingState.processingSpectrumData.length > 0) {
      this.displaySpectrumData = processingState.processingSpectrumData.slice(); // 使用slice创建副本
    }

    // 同步峰值频率
    this.displayPeakFreq = processingState.processingPeakFreq;

    // 同步统计数据
    this.displayStatistics.minDb = processingState.statisticsData.minDb;
    this.displayStatistics.maxDb = processingState.statisticsData.maxDb;
    this.displayStatistics.avgDb = processingState.statisticsData.avgDb;
    this.displayStatistics.duration = processingState.statisticsData.duration;
    this.displayStatistics.startTime = processingState.statisticsData.startTime;

    // 更新统计分布数据（用于直方图）
    this.updateStatisticsDistribution(this.displayDb);


  }

  /**
   * 更新统计分布数据
   */
  private updateStatisticsDistribution(currentDb: number): void {
    // 初始化分布数组（10个分贝区间：0-10, 10-20, ..., 90-100, 100+）
    if (this.displayStatisticsDistribution.length === 0) {
      this.displayStatisticsDistribution = new Array(11).fill(0);
    }

    // 计算分贝值对应的区间索引
    const dbIndex = Math.min(Math.floor(currentDb / 10), 10);
    
    // 增加对应区间的计数
    if (dbIndex >= 0 && dbIndex < this.displayStatisticsDistribution.length) {
      this.displayStatisticsDistribution[dbIndex]++;
    }
    
    console.debug(`[统计分布] 更新分布数据: ${currentDb}dB -> 区间${dbIndex}, 分布: [${this.displayStatisticsDistribution.join(', ')}]`);
  }

  /**
   * 暂停UI更新
   */
  pauseUIUpdates(): void {
    this.isUIUpdatesEnabled = false;
  }

  /**
   * 恢复UI更新
   */
  resumeUIUpdates(): void {
    this.isUIUpdatesEnabled = true;
  }


  /**
   * 重置显示状态
   */
  reset(): void {
    this.displayDb = 0;
    this.displaySpectrumData = new Float32Array();
    this.displayPeakFreq = 0;
    this.displayStatistics.reset();
    this.displayStatisticsDistribution = [];
    this.timeDisplay = '';
    this.recordingStartTime = Date.now();
    this.currentTime = Date.now();
    this.isUIUpdatesEnabled = true;
  }
}
