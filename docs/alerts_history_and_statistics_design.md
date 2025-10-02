# 警报历史记录和统计功能设计

## 概述

本文档详细说明如何为噪音警报系统添加历史记录和统计分析功能，帮助用户了解噪音暴露情况。

## 设计目标

1. **记录每次警报事件**：时间、分贝值、阈值、持续时间
2. **提供统计分析**：日/周/月统计、趋势分析
3. **可视化展示**：图表显示警报频率和强度
4. **数据持久化**：使用现有数据库系统存储记录

## 数据模型设计

### 1. 警报记录模型

在现有[`DecibelRecord.ets`](entry/src/main/ets/models/DecibelRecord.ets:1)基础上扩展，或创建新的警报记录模型：

```typescript
// AlertRecord.ets
@ObservedV2
export class AlertRecord {
  @Trace id: number;                    // 记录ID
  @Trace timestamp: number;             // 警报开始时间
  @Trace endTime: number;               // 警报结束时间
  @Trace peakDecibel: number;           // 峰值分贝
  @Trace averageDecibel: number;        // 平均分贝
  @Trace threshold: number;             // 触发阈值
  @Trace duration: number;              // 持续时间(毫秒)
  @Trace location?: string;             // 位置信息
  @Trace environmentType: string;       // 环境类型
  @Trace feedbackTypes: string[];       // 触发的反馈类型

  constructor(
    id: number,
    timestamp: number,
    endTime: number,
    peakDecibel: number,
    averageDecibel: number,
    threshold: number,
    duration: number,
    location?: string,
    environmentType: string = 'unknown',
    feedbackTypes: string[] = []
  ) {
    this.id = id;
    this.timestamp = timestamp;
    this.endTime = endTime;
    this.peakDecibel = peakDecibel;
    this.averageDecibel = averageDecibel;
    this.threshold = threshold;
    this.duration = duration;
    this.location = location;
    this.environmentType = environmentType;
    this.feedbackTypes = feedbackTypes;
  }
}
```

### 2. 统计数据结构

```typescript
// AlertStatistics.ets
export interface AlertStatistics {
  totalAlerts: number;                  // 总警报次数
  totalDuration: number;                // 总警报时长(秒)
  averageDuration: number;              // 平均警报时长
  peakDecibel: number;                  // 历史最高分贝
  averagePeakDecibel: number;           // 平均峰值分贝
  mostFrequentThreshold: number;        // 最常触发的阈值
  timeDistribution: TimeDistribution;   // 时间分布
  dayOfWeekDistribution: number[];      // 星期分布
}

export interface TimeDistribution {
  morning: number;      // 6:00-12:00
  afternoon: number;    // 12:00-18:00  
  evening: number;      // 18:00-24:00
  night: number;       // 0:00-6:00
}

export interface TrendData {
  date: string;         // 日期
  alertCount: number;   // 警报次数
  totalDuration: number; // 总时长
  averageDecibel: number; // 平均分贝
}
```

## 服务层实现

### 1. AlertHistoryService

创建新的服务来管理警报历史记录：

```typescript
// AlertHistoryService.ets
export class AlertHistoryService {
  private static instance: AlertHistoryService;
  private context: common.UIAbilityContext;
  private relationalStoreService: RelationalStoreService;
  
  // 数据库表名
  private readonly TABLE_NAME = 'alert_records';
  
  public static getInstance(context: common.UIAbilityContext): AlertHistoryService {
    if (!AlertHistoryService.instance) {
      AlertHistoryService.instance = new AlertHistoryService(context);
    }
    return AlertHistoryService.instance;
  }
  
  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.relationalStoreService = new RelationalStoreService(context);
  }
  
  // 记录警报开始
  public async recordAlertStart(
    decibel: number, 
    threshold: number, 
    location?: string
  ): Promise<number> {
    const record = new AlertRecord(
      Date.now(), // 使用时间戳作为临时ID
      Date.now(),
      0, // endTime为0表示警报进行中
      decibel,
      decibel,
      threshold,
      0,
      location,
      this.getEnvironmentType(decibel),
      this.getActiveFeedbackTypes()
    );
    
    return await this.relationalStoreService.insert(this.TABLE_NAME, record);
  }
  
  // 更新警报结束
  public async recordAlertEnd(
    alertId: number, 
    peakDecibel: number, 
    averageDecibel: number
  ): Promise<void> {
    const endTime = Date.now();
    const record = await this.relationalStoreService.queryById<AlertRecord>(this.TABLE_NAME, alertId);
    
    if (record) {
      record.endTime = endTime;
      record.peakDecibel = peakDecibel;
      record.averageDecibel = averageDecibel;
      record.duration = endTime - record.timestamp;
      
      await this.relationalStoreService.update(this.TABLE_NAME, record);
    }
  }
  
  // 获取警报历史
  public async getAlertHistory(
    startTime?: number, 
    endTime?: number, 
    limit?: number
  ): Promise<AlertRecord[]> {
    let query = `SELECT * FROM ${this.TABLE_NAME} WHERE endTime > 0`;
    
    if (startTime) {
      query += ` AND timestamp >= ${startTime}`;
    }
    if (endTime) {
      query += ` AND timestamp <= ${endTime}`;
    }
    
    query += ` ORDER BY timestamp DESC`;
    
    if (limit) {
      query += ` LIMIT ${limit}`;
    }
    
    return await this.relationalStoreService.query<AlertRecord>(query);
  }
  
  // 获取统计信息
  public async getStatistics(timeRange: 'day' | 'week' | 'month' | 'all'): Promise<AlertStatistics> {
    const now = Date.now();
    let startTime: number;
    
    switch (timeRange) {
      case 'day':
        startTime = now - 24 * 60 * 60 * 1000;
        break;
      case 'week':
        startTime = now - 7 * 24 * 60 * 60 * 1000;
        break;
      case 'month':
        startTime = now - 30 * 24 * 60 * 60 * 1000;
        break;
      default:
        startTime = 0;
    }
    
    const records = await this.getAlertHistory(startTime, now);
    return this.calculateStatistics(records);
  }
  
  // 计算统计信息
  private calculateStatistics(records: AlertRecord[]): AlertStatistics {
    if (records.length === 0) {
      return this.getEmptyStatistics();
    }
    
    const totalDuration = records.reduce((sum, record) => sum + record.duration, 0);
    const peakDecibel = Math.max(...records.map(r => r.peakDecibel));
    const averagePeakDecibel = records.reduce((sum, r) => sum + r.peakDecibel, 0) / records.length;
    
    // 计算阈值频率
    const thresholdCounts = new Map<number, number>();
    records.forEach(record => {
      const count = thresholdCounts.get(record.threshold) || 0;
      thresholdCounts.set(record.threshold, count + 1);
    });
    
    let mostFrequentThreshold = records[0].threshold;
    let maxCount = 0;
    thresholdCounts.forEach((count, threshold) => {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentThreshold = threshold;
      }
    });
    
    // 计算时间分布
    const timeDistribution = this.calculateTimeDistribution(records);
    
    // 计算星期分布
    const dayOfWeekDistribution = this.calculateDayOfWeekDistribution(records);
    
    return {
      totalAlerts: records.length,
      totalDuration: Math.round(totalDuration / 1000), // 转换为秒
      averageDuration: Math.round(totalDuration / records.length / 1000),
      peakDecibel,
      averagePeakDecibel: Math.round(averagePeakDecibel * 10) / 10,
      mostFrequentThreshold,
      timeDistribution,
      dayOfWeekDistribution
    };
  }
  
  // 计算时间分布
  private calculateTimeDistribution(records: AlertRecord[]): TimeDistribution {
    const distribution: TimeDistribution = { morning: 0, afternoon: 0, evening: 0, night: 0 };
    
    records.forEach(record => {
      const hour = new Date(record.timestamp).getHours();
      
      if (hour >= 6 && hour < 12) {
        distribution.morning++;
      } else if (hour >= 12 && hour < 18) {
        distribution.afternoon++;
      } else if (hour >= 18 && hour < 24) {
        distribution.evening++;
      } else {
        distribution.night++;
      }
    });
    
    return distribution;
  }
  
  // 计算星期分布
  private calculateDayOfWeekDistribution(records: AlertRecord[]): number[] {
    const distribution = [0, 0, 0, 0, 0, 0, 0]; // 周日到周六
    
    records.forEach(record => {
      const day = new Date(record.timestamp).getDay(); // 0=周日, 6=周六
      distribution[day]++;
    });
    
    return distribution;
  }
  
  private getEmptyStatistics(): AlertStatistics {
    return {
      totalAlerts: 0,
      totalDuration: 0,
      averageDuration: 0,
      peakDecibel: 0,
      averagePeakDecibel: 0,
      mostFrequentThreshold: 0,
      timeDistribution: { morning: 0, afternoon: 0, evening: 0, night: 0 },
      dayOfWeekDistribution: [0, 0, 0, 0, 0, 0, 0]
    };
  }
  
  // 获取环境类型
  private getEnvironmentType(decibel: number): string {
    if (decibel < 50) return 'quiet';
    if (decibel < 70) return 'normal';
    if (decibel < 85) return 'noisy';
    return 'dangerous';
  }
  
  // 获取活跃的反馈类型
  private getActiveFeedbackTypes(): string[] {
    const types: string[] = [];
    // 这里需要访问PreferenceKeys来获取用户设置
    // 暂时返回空数组，实际实现时需要集成
    return types;
  }
}
```

## 集成到现有系统

### 1. 修改DecibelMeter集成警报记录

在[`DecibelMeter.ets`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets:1)中添加警报记录功能：

```typescript
// 添加状态变量
@Local private currentAlertId?: number;
@Local private alertStartTime: number = 0;
@Local private alertPeakDecibel: number = 0;
@Local private alertTotalDecibel: number = 0;
@Local private alertSampleCount: number = 0;

// 在警报触发时记录
private async triggerAlarmFeedback(currentDecibel: number, threshold: number): Promise<void> {
  if (this.isAlarmActive) return;
  
  this.isAlarmActive = true;
  
  // 记录警报开始
  const alertHistoryService = AlertHistoryService.getInstance(getContext() as common.UIAbilityContext);
  this.currentAlertId = await alertHistoryService.recordAlertStart(
    currentDecibel, 
    threshold, 
    this.currentLocation?.address
  );
  
  this.alertStartTime = Date.now();
  this.alertPeakDecibel = currentDecibel;
  this.alertTotalDecibel = currentDecibel;
  this.alertSampleCount = 1;
  
  // 执行反馈...
}

// 在分贝值更新时更新警报统计
@Monitor('as.db')
onDecibelChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    this.handleDecibelChange(currentDecibel);
    
    // 如果警报活跃，更新统计
    if (this.isAlarmActive) {
      this.updateAlertStatistics(currentDecibel);
    }
  }
}

// 更新警报统计
private updateAlertStatistics(currentDecibel: number): void {
  this.alertPeakDecibel = Math.max(this.alertPeakDecibel, currentDecibel);
  this.alertTotalDecibel += currentDecibel;
  this.alertSampleCount++;
}

// 在警报清除时记录结束
private async clearAlarmFeedback(): Promise<void> {
  if (!this.isAlarmActive) return;
  
  this.isAlarmActive = false;
  
  // 记录警报结束
  if (this.currentAlertId) {
    const averageDecibel = this.alertTotalDecibel / this.alertSampleCount;
    const alertHistoryService = AlertHistoryService.getInstance(getContext() as common.UIAbilityContext);
    await alertHistoryService.recordAlertEnd(
      this.currentAlertId,
      this.alertPeakDecibel,
      averageDecibel
    );
    
    this.currentAlertId = undefined;
  }
  
  // 清除统计
  this.alertPeakDecibel = 0;
  this.alertTotalDecibel = 0;
  this.alertSampleCount = 0;
  
  // 停止反馈...
}
```

### 2. 创建警报历史界面组件

创建新的组件来显示警报历史和统计：

```typescript
// AlertHistoryComponent.ets
@ComponentV2
export struct AlertHistoryComponent {
  @Local private alertRecords: AlertRecord[] = [];
  @Local private statistics: AlertStatistics;
  @Local private selectedTimeRange: 'day' | 'week' | 'month' | 'all' = 'week';
  
  private alertHistoryService: AlertHistoryService;
  
  aboutToAppear() {
    this.alertHistoryService = AlertHistoryService.getInstance(getContext() as common.UIAbilityContext);
    this.loadData();
  }
  
  private async loadData(): Promise<void> {
    this.alertRecords = await this.alertHistoryService.getAlertHistory(undefined, undefined, 50);
    this.statistics = await this.alertHistoryService.getStatistics(this.selectedTimeRange);
  }
  
  @Builder
  private buildStatisticsCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('警报统计')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
      
      GridRow({ columns: 2, gutter: { x: 8, y: 8 } }) {
        GridCol({ span: 1 }) {
          this.buildStatItem('总警报次数', this.statistics.totalAlerts.toString())
        }
        GridCol({ span: 1 }) {
          this.buildStatItem('总警报时长', `${this.statistics.totalDuration}秒`)
        }
        GridCol({ span: 1 }) {
          this.buildStatItem('历史最高分贝', `${this.statistics.peakDecibel}dB`)
        }
        GridCol({ span: 1 }) {
          this.buildStatItem('平均峰值分贝', `${this.statistics.averagePeakDecibel}dB`)
        }
      }
    }
  }
  
  @Builder
  private buildStatItem(title: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding(12)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(8)
  }
  
  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      this.buildStatisticsCard()
      
      // 时间分布图表
      this.buildTimeDistributionChart()
      
      // 警报历史列表
      this.buildAlertHistoryList()
    }
  }
}
```

## 数据库表创建

在现有的数据库初始化中添加警报记录表：

```typescript
// 在RelationalStoreService中添加表创建
private async createAlertRecordsTable(): Promise<void> {
  const sql = `
    CREATE TABLE IF NOT EXISTS alert_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      endTime INTEGER NOT NULL,
      peakDecibel REAL NOT NULL,
      averageDecibel REAL NOT NULL,
      threshold REAL NOT NULL,
      duration INTEGER NOT NULL,
      location TEXT,
      environmentType TEXT,
      feedbackTypes TEXT
    )
  `;
  
  await this.executeSql(sql);
  
  // 创建索引以提高查询性能
  await this.executeSql('CREATE INDEX IF NOT EXISTS idx_alert_timestamp ON alert_records(timestamp)');
  await this.executeSql('CREATE INDEX IF NOT EXISTS idx_alert_threshold ON alert_records(threshold)');
}
```

## 实施计划

### 第一阶段：基础功能
1. 创建数据模型和服务层
2. 集成到DecibelMeter记录警报
3. 测试数据持久化功能

### 第二阶段：统计分析
1. 实现统计计算逻辑
2. 创建统计展示组件
3. 添加时间范围筛选

### 第三阶段：可视化
1. 创建图表组件显示统计数据
2. 实现趋势分析功能
3. 优化用户体验

### 第四阶段：高级功能
1. 添加数据导出功能
2. 实现警报模式识别
3. 添加健康建议功能

这个方案提供了完整的警报历史记录和统计分析功能，帮助用户更好地了解噪音暴露情况。