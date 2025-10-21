/**
 * 数据处理状态模型
 * 负责后台数据处理，不触发UI刷新
 */
export class DataProcessingState {
  // 实时分贝值（原始数据）
  processingDb: number = 0;

  // 频谱数据（原始数据）
  processingSpectrumData: Float32Array= new Float32Array(0);

  // 峰值频率（原始数据）
  processingPeakFreq: number = 0;

  // 统计数据
  statisticsData: StatisticsData = new StatisticsData();

  // 是否在后台运行
  isBackground: boolean = false;

  // 新增：警报状态（现在只作为状态标记，持续时间由状态机管理）
  alertState: AlertState = new AlertState();

  constructor() {
    // 不再需要独立的持续时间计时器
  }

}

/**
 * 警报状态对象（简化版本，现在只作为状态标记）
 * 警报状态和持续时间由 AlertStateMachine 管理
 */
export class AlertState {
  // 警报是否激活（只读状态标记）
  isActive: boolean = false;

  constructor() {
    // 不再需要持续时间管理
  }

  /**
   * 触发警报（设置状态标记）
   */
  triggerAlert(): void {
    this.isActive = true;
  }

  /**
   * 解除警报（清除状态标记）
   */
  clearAlert(): void {
    this.isActive = false;
  }

  /**
   * 重置警报状态
   */
  reset(): void {
    this.isActive = false;
  }
}

/**
 * 统计数据对象
 */
export class StatisticsData {
  // 最小分贝值
  minDb: number = 0;

  // 最大分贝值
  maxDb: number = 0;

  // 平均分贝值
  avgDb: number = 0;

  // 测量时长（秒）
  duration: number = 0;

  // 测量开始时间
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