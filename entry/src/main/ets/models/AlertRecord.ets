/**
 * 警报记录数据模型
 * 定义警报历史记录的数据结构和相关类型
 */

/**
 * 警报记录状态
 */
export enum AlertRecordStatus {
  ACTIVE = 'active',       // 进行中
  COMPLETED = 'completed', // 已完成
  CANCELLED = 'cancelled'  // 已取消
}

/**
 * 警报严重程度
 */
export enum AlertSeverity {
  LOW = 1,      // 轻度 (超过阈值 < 5dB)
  MEDIUM = 2,   // 中度 (超过阈值 5-15dB)
  HIGH = 3,     // 重度 (超过阈值 15-25dB)
  CRITICAL = 4  // 严重 (超过阈值 > 25dB)
}

/**
 * 警报类型
 */
export enum AlertType {
  INSTANT_PEAK = 'instant_peak',         // 瞬时峰值警报
  CONTINUOUS_EXPOSURE = 'continuous_exposure', // 持续暴露警报
  THRESHOLD_BREACH = 'threshold_breach'  // 阈值突破警报
}

/**
 * 数据库值类型定义
 */
export interface DbValues {
  id: string;
  startTime: number;
  endTime: number;
  duration: number;
  peakDecibel: number;
  avgDecibel: number;
  minDecibel: number;
  threshold: number;
  location: string | null;
  latitude: number | null;
  longitude: number | null;
  alertType: string;
  status: string;
  severity: number;
  extraData: string | null;
  createdAt: number;
  updatedAt: number;
}

/**
 * 严重程度分布
 */
export interface SeverityDistribution {
  low: number;
  medium: number;
  high: number;
  critical: number;
}

/**
 * 警报记录初始化参数接口
 */
export interface AlertRecordInit {
  id?: string;
  startTime?: number;
  endTime?: number;
  duration?: number;
  peakDecibel?: number;
  avgDecibel?: number;
  minDecibel?: number;
  threshold?: number;
  location?: string;
  latitude?: number;
  longitude?: number;
  alertType?: AlertType;
  status?: AlertRecordStatus;
  severity?: AlertSeverity;
  extraData?: string;
  createdAt?: number;
  updatedAt?: number;
}

/**
 * 警报记录数据模型
 */
@ObservedV2
export class AlertRecord {
  // 主键ID (UUID)
  @Trace id: string = '';
  
  // 时间信息
  @Trace startTime: number = 0;  // 警报开始时间戳(毫秒)
  @Trace endTime: number = 0;    // 警报结束时间戳(毫秒)
  @Trace duration: number = 0;   // 持续时长(秒)
  
  // 分贝数据
  @Trace peakDecibel: number = 0;  // 峰值分贝
  @Trace avgDecibel: number = 0;   // 平均分贝
  @Trace minDecibel: number = 0;   // 最低分贝
  @Trace threshold: number = 0;    // 触发阈值
  
  // 位置信息
  @Trace location: string = '';        // 位置描述
  @Trace latitude: number = 0;        // 纬度
  @Trace longitude: number = 0;       // 经度
  
  // 分类信息
  @Trace alertType: AlertType = AlertType.THRESHOLD_BREACH;
  @Trace status: AlertRecordStatus = AlertRecordStatus.COMPLETED;
  @Trace severity: AlertSeverity = AlertSeverity.LOW;
  
  // 扩展数据 (JSON字符串存储)
  @Trace extraData: string = '';
  
  // 创建时间和更新时间
  @Trace createdAt: number = 0;
  @Trace updatedAt: number = 0;

  constructor(init?: AlertRecordInit) {
    if (init) {
      if (init.id !== undefined) this.id = init.id;
      if (init.startTime !== undefined) this.startTime = init.startTime;
      if (init.endTime !== undefined) this.endTime = init.endTime;
      if (init.duration !== undefined) this.duration = init.duration;
      if (init.peakDecibel !== undefined) this.peakDecibel = init.peakDecibel;
      if (init.avgDecibel !== undefined) this.avgDecibel = init.avgDecibel;
      if (init.minDecibel !== undefined) this.minDecibel = init.minDecibel;
      if (init.threshold !== undefined) this.threshold = init.threshold;
      if (init.location !== undefined) this.location = init.location;
      if (init.latitude !== undefined) this.latitude = init.latitude;
      if (init.longitude !== undefined) this.longitude = init.longitude;
      if (init.alertType !== undefined) this.alertType = init.alertType;
      if (init.status !== undefined) this.status = init.status;
      if (init.severity !== undefined) this.severity = init.severity;
      if (init.extraData !== undefined) this.extraData = init.extraData;
      if (init.createdAt !== undefined) this.createdAt = init.createdAt;
      if (init.updatedAt !== undefined) this.updatedAt = init.updatedAt;
    }
  }

  /**
   * 计算严重程度
   */
  public static calculateSeverity(peakDecibel: number, threshold: number): AlertSeverity {
    const diff = peakDecibel - threshold;
    if (diff >= 25) return AlertSeverity.CRITICAL;
    if (diff >= 15) return AlertSeverity.HIGH;
    if (diff >= 5) return AlertSeverity.MEDIUM;
    return AlertSeverity.LOW;
  }

  /**
   * 获取严重程度的显示文本
   */
  public static getSeverityText(severity: AlertSeverity): string {
    switch (severity) {
      case AlertSeverity.LOW: return '轻度';
      case AlertSeverity.MEDIUM: return '中度';
      case AlertSeverity.HIGH: return '重度';
      case AlertSeverity.CRITICAL: return '严重';
      default: return '未知';
    }
  }

  /**
   * 获取严重程度的颜色
   */
  public static getSeverityColor(severity: AlertSeverity): Resource {
    switch (severity) {
      case AlertSeverity.LOW: return $r('sys.color.confirm');
      case AlertSeverity.MEDIUM: return $r('sys.color.warning');
      case AlertSeverity.HIGH: return $r('sys.color.alert');
      case AlertSeverity.CRITICAL: return $r('sys.color.alert');
      default: return $r('sys.color.font_secondary');
    }
  }

  /**
   * 获取警报类型的显示文本
   */
  public static getAlertTypeText(type: AlertType): string {
    switch (type) {
      case AlertType.INSTANT_PEAK: return '瞬时峰值';
      case AlertType.CONTINUOUS_EXPOSURE: return '持续暴露';
      case AlertType.THRESHOLD_BREACH: return '阈值突破';
      default: return '未知';
    }
  }

  /**
   * 格式化持续时间为可读文本
   */
  @Computed
  public get getFormattedDuration(): string {
    // 0秒显示为"<1秒"，表示持续时间小于1秒
    if (this.duration === 0) {
      return '<1秒';
    }
    const mins = Math.floor(this.duration / 60);
    const secs = this.duration % 60;
    if (mins > 0) {
      return `${mins}分${secs}秒`;
    }
    return `${secs}秒`;
  }

  /**
   * 格式化开始时间为可读文本
   */
  public getFormattedStartTime(): string {
    const date = new Date(this.startTime);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 获取完整日期时间文本
   */
  public getFormattedDateTime(): string {
    const date = new Date(this.startTime);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${month}月${day}日 ${hours}:${minutes}`;
  }

  /**
   * 转换为数据库存储格式
   */
  public toDbValues(): DbValues {
    return {
      id: this.id,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.duration,
      peakDecibel: this.peakDecibel,
      avgDecibel: this.avgDecibel,
      minDecibel: this.minDecibel,
      threshold: this.threshold,
      location: this.location || null,
      latitude: this.latitude || null,
      longitude: this.longitude || null,
      alertType: this.alertType,
      status: this.status,
      severity: this.severity,
      extraData: this.extraData || null,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  /**
   * 从数据库结果集创建实例
   */
  public static fromResultSet(result: DbValues): AlertRecord {
    const record = new AlertRecord();
    record.id = result.id;
    record.startTime = result.startTime;
    record.endTime = result.endTime;
    record.duration = result.duration;
    record.peakDecibel = result.peakDecibel;
    record.avgDecibel = result.avgDecibel;
    record.minDecibel = result.minDecibel;
    record.threshold = result.threshold;
    record.location = result.location || '';
    record.latitude = result.latitude || 0;
    record.longitude = result.longitude || 0;
    record.alertType = result.alertType as AlertType;
    record.status = result.status as AlertRecordStatus;
    record.severity = result.severity as AlertSeverity;
    record.extraData = result.extraData || '';
    record.createdAt = result.createdAt;
    record.updatedAt = result.updatedAt;
    return record;
  }
}

/**
 * 警报统计摘要
 */
@ObservedV2
export class AlertSummary {
  @Trace totalCount: number = 0;           // 总次数
  @Trace totalDuration: number = 0;        // 总时长(秒)
  @Trace peakDecibel: number = 0;          // 最高峰值
  @Trace avgDecibel: number = 0;           // 平均峰值
  @Trace todayCount: number = 0;           // 今日次数
  @Trace todayDuration: number = 0;        // 今日时长
  @Trace mostFrequentHour: number = -1;    // 最常发生时段
  @Trace severityDistributionLow: number = 0;
  @Trace severityDistributionMedium: number = 0;
  @Trace severityDistributionHigh: number = 0;
  @Trace severityDistributionCritical: number = 0;

  /**
   * 获取今日时长的格式化文本
   */
  public getFormattedTodayDuration(): string {
    const mins = Math.floor(this.todayDuration / 60);
    const secs = this.todayDuration % 60;
    if (mins > 0) {
      return `${mins}分${secs}秒`;
    }
    return `${secs}秒`;
  }

  /**
   * 获取总时长的格式化文本
   */
  public getFormattedTotalDuration(): string {
    const hours = Math.floor(this.totalDuration / 3600);
    const mins = Math.floor((this.totalDuration % 3600) / 60);
    if (hours > 0) {
      return `${hours}小时${mins}分钟`;
    }
    return `${mins}分钟`;
  }
}

/**
 * 警报查询条件
 */
export interface AlertQueryOptions {
  startTime?: number;           // 开始时间
  endTime?: number;             // 结束时间
  alertType?: AlertType;        // 警报类型
  severity?: AlertSeverity;     // 严重程度
  status?: AlertRecordStatus;   // 记录状态
  limit?: number;               // 限制数量
  offset?: number;              // 偏移量
  orderBy?: string;
  orderDirection?: string;
}

/**
 * 警报历史分页结果
 */
export interface AlertHistoryPage {
  records: AlertRecord[];
  total: number;
  hasMore: boolean;
}
