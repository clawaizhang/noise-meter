import { DataProcessingState, StatisticsData } from "./DataProcessingState";

/**
 * 警报显示状态对象（UI专用）
 */
@ObservedV2
export class DisplayAlertState {
  // 显示警报状态
  @Trace
  isActive: boolean = false;

  // 显示持续时间（毫秒）
  @Trace
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
 * UI显示状态模型
 * 负责UI显示状态，前后台切换时控制UI更新
 */
@ObservedV2
export class UIDisplayState {
  // 显示分贝值（UI专用）
  @Trace displayDb: number = 0;

  // 显示频谱数据（UI专用）
  @Trace displaySpectrumData: number[] = [];

  // 显示峰值频率（UI专用）
  @Trace displayPeakFreq: number = 0;

  // 显示统计数据
  @Trace displayStatistics: StatisticsData = new StatisticsData();

  // 新增：警报显示状态（UI专用）
  @Trace displayAlertState: DisplayAlertState = new DisplayAlertState();

  // UI更新状态
  @Trace isUIUpdatesEnabled: boolean = true;

  // 最后更新时间
  @Trace lastUpdateTime: number = 0;

  constructor() {
    this.lastUpdateTime = new Date().getTime();
  }

  /**
   * 从数据处理状态同步到UI显示状态
   */
  syncFromProcessingState(processingState: DataProcessingState): void {
    if (!this.isUIUpdatesEnabled) {
      return;
    }

    // 同步分贝值
    this.displayDb = processingState.processingDb;

    // 同步频谱数据（浅拷贝）
    if (processingState.processingSpectrumData.length > 0) {
      this.displaySpectrumData = [...processingState.processingSpectrumData];
    }

    // 同步峰值频率
    this.displayPeakFreq = processingState.processingPeakFreq;

    // 同步统计数据
    this.displayStatistics.minDb = processingState.statisticsData.minDb;
    this.displayStatistics.maxDb = processingState.statisticsData.maxDb;
    this.displayStatistics.avgDb = processingState.statisticsData.avgDb;
    this.displayStatistics.duration = processingState.statisticsData.duration;
    this.displayStatistics.startTime = processingState.statisticsData.startTime;

    // 新增：同步警报状态
    this.displayAlertState.isActive = processingState.alertState.isActive;
    this.displayAlertState.duration = processingState.alertState.currentDuration;
    this.displayAlertState.updateFormattedDuration();

    this.lastUpdateTime = Date.now();
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
    this.displaySpectrumData = [];
    this.displayPeakFreq = 0;
    this.displayStatistics.reset();
    this.displayAlertState.reset();
    this.isUIUpdatesEnabled = true;
    this.lastUpdateTime = new Date().getTime();
  }
}
