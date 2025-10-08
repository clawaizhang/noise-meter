/**
 * 数据处理状态模型
 * 负责后台数据处理，不触发UI刷新
 */
@ObservedV2
export class DataProcessingState {
  // 实时分贝值（原始数据）
  @Trace processingDb: number = 0;

  // 频谱数据（原始数据）
  @Trace processingSpectrumData: Float32Array= new Float32Array(0);

  // 峰值频率（原始数据）
  @Trace processingPeakFreq: number = 0;

  // 统计数据
  @Trace statisticsData: StatisticsData = new StatisticsData();

  // 是否在后台运行
  @Trace isBackground: boolean = false;

  // 新增：警报状态（后台持续计算）
  @Trace alertState: AlertState = new AlertState();

  // 警报持续时间更新定时器
  private alertDurationTimer: number = 0;

  constructor() {
    // 初始化状态
    this.startAlertDurationUpdate();
  }

  /**
   * 启动警报持续时间自动更新
   */
  private startAlertDurationUpdate(): void {
    this.stopAlertDurationUpdate();
    // 每秒更新一次警报持续时间
    this.alertDurationTimer = setInterval(() => {
      if (this.alertState.isActive) {
        this.alertState.updateDuration();
      }
    }, 1000);
  }

  /**
   * 停止警报持续时间更新（如果需要）
   */
  private stopAlertDurationUpdate(): void {
    if (this.alertDurationTimer) {
      clearInterval(this.alertDurationTimer);
      this.alertDurationTimer = 0;
    }
  }

}

/**
 * 警报状态对象（后台持续计算）
 */
@ObservedV2
export class AlertState {
  // 警报是否激活
  @Trace
  isActive: boolean = false;

  // 警报开始时间戳
  @Trace
  startTime: number = 0;

  // 当前持续时间（毫秒）
  @Trace
  currentDuration: number = 0;

  // 最后更新时间
  @Trace
  lastUpdateTime: number = 0;

  constructor() {
    this.lastUpdateTime = Date.now();
  }

  /**
   * 触发警报
   */
  triggerAlert(): void {
    this.isActive = true;
    this.startTime = Date.now();
    this.currentDuration = 0;
    this.lastUpdateTime = Date.now();
  }

  /**
   * 解除警报
   */
  clearAlert(): void {
    this.isActive = false;
    this.currentDuration = Date.now() - this.startTime;
    this.lastUpdateTime = Date.now();
  }

  /**
   * 更新持续时间（后台持续调用）
   */
  updateDuration(): void {
    if (this.isActive) {
      this.currentDuration = Date.now() - this.startTime;
      this.lastUpdateTime = Date.now();
    }
  }

  /**
   * 重置警报状态
   */
  reset(): void {
    this.isActive = false;
    this.startTime = 0;
    this.currentDuration = 0;
    this.lastUpdateTime = Date.now();
  }
}

/**
 * 统计数据对象
 */
@ObservedV2
export class StatisticsData {
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

  constructor() {
    this.startTime = Date.now();
  }

  /**
   * 更新统计数据
   */
  updateStatistics(currentDb:number,values: number[]): void {

    if (values.length === 0) {
      this.minDb = currentDb;
      this.maxDb = currentDb;
      this.avgDb = currentDb;
    } else {
      this.minDb = Math.min(...values);
      this.maxDb = Math.max(...values);
      this.avgDb = Math.round(values.reduce((sum, val) => sum + val, 0) / values.length);
    }

    this.duration = Number(((Date.now() - this.startTime) / 1000).toFixed(1));
  }

  /**
   * 重置统计数据
   */
  reset(): void {
    this.minDb = 0;
    this.maxDb = 0;
    this.avgDb = 0;
    this.duration = 0;
    this.startTime = Date.now();
  }
}