/**
 * 警报历史详情页（优化版）
 * 支持时间筛选和严重程度可视化
 */

import { AlertHistoryService } from '../../services/AlertHistoryService';
import {
  AlertRecord,
  AlertSummary,
  AlertSeverity
} from '../../models/AlertRecord';
import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertDetailPageBuilder, AlertDetailPageParams } from './AlertDetailPage';

const TAG = 'AlertHistoryNavigation';
const DOMAIN = 0xFF00;

// 时间筛选类型
enum TimeRangeType {
  TODAY = 0,
  YESTERDAY = 1,
  LAST_7_DAYS = 2,
  LAST_30_DAYS = 3
}

// 时间范围配置
interface TimeRangeConfig {
  label: string;
  type: TimeRangeType;
}

const TIME_RANGE_CONFIGS: TimeRangeConfig[] = [
  { label: '今日', type: TimeRangeType.TODAY },
  { label: '昨日', type: TimeRangeType.YESTERDAY },
  { label: '近7天', type: TimeRangeType.LAST_7_DAYS },
  { label: '近30天', type: TimeRangeType.LAST_30_DAYS }
];

// 时间范围返回类型
interface TimeRangeResult {
  startTime: number;
  endTime: number;
}

/**
 * 警报记录数据源
 */
class AlertRecordDataSource implements IDataSource {
  private records: AlertRecord[] = [];
  private listeners: DataChangeListener[] = [];

  setData(records: AlertRecord[]): void {
    this.records = records;
    this.notifyDataReload();
  }

  addData(records: AlertRecord[]): void {
    const startIndex = this.records.length;
    this.records.push(...records);
    this.notifyDataAdd(startIndex);
  }

  totalCount(): number {
    return this.records.length;
  }

  getData(index: number): AlertRecord {
    return this.records[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  notifyDataAdd(startIndex: number): void {
    this.listeners.forEach(listener => {
      for (let i = startIndex; i < this.records.length; i++) {
        listener.onDataAdd(i);
      }
    });
  }
}

@Builder
export function AlertHistoryNavigationBuilder() {
  AlertHistoryNavigation()
}

@ComponentV2
export struct AlertHistoryNavigation {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();

  // 页面状态
  @Local private isLoading: boolean = true;
  @Local private currentTimeRange: TimeRangeType = TimeRangeType.TODAY;

  // 数据源
  private dataSource: AlertRecordDataSource = new AlertRecordDataSource();

  // 统计数据
  @Local private alertCount: number = 0;
  @Local private peakDecibel: number = 0;
  @Local private totalDuration: number = 0;

  // 严重程度分布
  @Local private severityLow: number = 0;
  @Local private severityMedium: number = 0;
  @Local private severityHigh: number = 0;
  @Local private severityCritical: number = 0;

  async aboutToAppear(): Promise<void> {
    hilog.info(DOMAIN, TAG, '页面加载，初始化数据');
    // 确保数据清零
    this.clearStats();
    // 延迟一点确保 UI 初始化完成
    setTimeout(() => {
      this.loadDataForTimeRange(this.currentTimeRange);
    }, 100);
  }

  /**
   * 获取时间范围的起止时间
   */
  private getTimeRange(rangeType: TimeRangeType): TimeRangeResult {
    const now = new Date();
    const endTime = now.getTime();
    let startTime: number = 0;

    switch (rangeType) {
      case TimeRangeType.TODAY:
        const today = new Date(now);
        today.setHours(0, 0, 0, 0);
        startTime = today.getTime();
        break;

      case TimeRangeType.YESTERDAY:
        const yesterday = new Date(now);
        yesterday.setDate(yesterday.getDate() - 1);
        yesterday.setHours(0, 0, 0, 0);
        const yesterdayEnd = new Date(yesterday);
        yesterdayEnd.setHours(23, 59, 59, 999);
        return { startTime: yesterday.getTime(), endTime: yesterdayEnd.getTime() };

      case TimeRangeType.LAST_7_DAYS:
        const last7Days = new Date(now);
        last7Days.setDate(last7Days.getDate() - 6);
        last7Days.setHours(0, 0, 0, 0);
        startTime = last7Days.getTime();
        break;

      case TimeRangeType.LAST_30_DAYS:
        const last30Days = new Date(now);
        last30Days.setDate(last30Days.getDate() - 29);
        last30Days.setHours(0, 0, 0, 0);
        startTime = last30Days.getTime();
        break;

      default:
        const defaultStart = new Date(now);
        defaultStart.setHours(0, 0, 0, 0);
        startTime = defaultStart.getTime();
    }

    return { startTime: startTime, endTime: endTime };
  }

  /**
   * 加载指定时间范围的数据
   */
  private async loadDataForTimeRange(rangeType: TimeRangeType): Promise<void> {
    this.isLoading = true;
    this.currentTimeRange = rangeType;

    // 先清空数据，强制UI刷新
    this.clearStats();

    try {
      // 初始化服务
      await this.alertHistoryService.initialize();

      const timeRange = this.getTimeRange(rangeType);
      hilog.info(DOMAIN, TAG, `加载${TIME_RANGE_CONFIGS[rangeType].label}数据: ${timeRange.startTime} - ${timeRange.endTime}`);

      // 加载记录列表（先加载列表，再计算统计）
      const records = await this.alertHistoryService.queryAlertRecords({
        startTime: timeRange.startTime,
        endTime: timeRange.endTime,
        orderBy: 'startTime',
        orderDirection: 'DESC'
      });
      hilog.info(DOMAIN, TAG, `记录列表: ${records.length}条`);
      
      // 手动计算统计数据（避免 AlertSummary 响应式问题）
      this.calculateStatsFromRecords(records);
      
      // 设置列表数据
      this.dataSource.setData(records);

    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载数据失败: ${error instanceof Error ? error.message : String(error)}`);
      promptAction.showToast({ message: '加载失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 清空统计数据（强制刷新）
   */
  private clearStats(): void {
    this.alertCount = 0;
    this.peakDecibel = 0;
    this.totalDuration = 0;
    this.severityLow = 0;
    this.severityMedium = 0;
    this.severityHigh = 0;
    this.severityCritical = 0;
  }

  /**
   * 从记录列表计算统计数据
   */
  private calculateStatsFromRecords(records: AlertRecord[]): void {
    const count = records.length;
    
    if (count === 0) {
      hilog.info(DOMAIN, TAG, '无记录，统计数据为0');
      return;
    }

    // 计算统计数据
    let totalDuration = 0;
    let maxDecibel = 0;
    let severityLow = 0;
    let severityMedium = 0;
    let severityHigh = 0;
    let severityCritical = 0;

    for (const record of records) {
      totalDuration += record.duration;
      
      if (record.peakDecibel > maxDecibel) {
        maxDecibel = record.peakDecibel;
      }

      // 严重程度分布
      if (record.severity === AlertSeverity.LOW) {
        severityLow++;
      } else if (record.severity === AlertSeverity.MEDIUM) {
        severityMedium++;
      } else if (record.severity === AlertSeverity.HIGH) {
        severityHigh++;
      } else if (record.severity === AlertSeverity.CRITICAL) {
        severityCritical++;
      }
    }

    // 直接更新状态（不使用 setTimeout）
    this.alertCount = count;
    this.peakDecibel = maxDecibel;
    this.totalDuration = totalDuration;
    this.severityLow = severityLow;
    this.severityMedium = severityMedium;
    this.severityHigh = severityHigh;
    this.severityCritical = severityCritical;

    hilog.info(DOMAIN, TAG, `计算完成: count=${count}, peak=${maxDecibel}, duration=${totalDuration}`);
    hilog.info(DOMAIN, TAG, `严重度: L=${severityLow}, M=${severityMedium}, H=${severityHigh}, C=${severityCritical}`);
  }

  /**
   * 获取总记录数
   */
  private getTotalSeverityCount(): number {
    return this.severityLow + this.severityMedium + this.severityHigh + this.severityCritical;
  }

  /**
   * 获取严重程度百分比
   */
  private getSeverityPercentage(count: number): number {
    const total = this.getTotalSeverityCount();
    if (total === 0) return 0;
    return Math.round((count / total) * 100);
  }

  /**
   * 获取洞察文案
   */
  private getInsightText(): string {
    const total = this.getTotalSeverityCount();
    if (total === 0) {
      return '该时段无警报记录，环境良好 ✓';
    }

    const highAndCritical = this.severityHigh + this.severityCritical;
    if (highAndCritical === 0) {
      return '以轻中度为主，整体风险可控 ✓';
    }

    if (this.severityCritical > 0) {
      return `发现${this.severityCritical}次严重警报！请立即采取防护措施 🔴`;
    }

    if (this.severityHigh > 0) {
      return `有${this.severityHigh}次重度警报，建议加强防护 ⚠️`;
    }

    return '整体可控，继续保持良好习惯';
  }

  build() {
    Column({ space: 0 }) {
      // 时间筛选 Tab 栏
      this.buildTimeRangeTabs()

      // 数据概览区
      this.buildStatsOverview()

      // 严重程度分布条形图
      this.buildSeverityChart()

      // 记录列表
      this.buildRecordList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  /**
   * 时间筛选 Tab 栏
   */
  @Builder
  private buildTimeRangeTabs() {
    Row({ space: DesignConstants.SPACING_SM }) {
      ForEach(TIME_RANGE_CONFIGS, (config: TimeRangeConfig) => {
        Column() {
          Text(config.label)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(this.currentTimeRange === config.type ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.currentTimeRange === config.type ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.currentTimeRange === config.type ? $r('sys.color.brand').toString().replace(']', '') + '15' : 'transparent')
        .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
        .onClick(() => {
          if (this.currentTimeRange !== config.type) {
            this.loadDataForTimeRange(config.type);
          }
        })
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  /**
   * 数据概览区
   */
  @Builder
  private buildStatsOverview() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 三卡片统计 - 直接在 build 中使用状态变量
      Row({ space: DesignConstants.SPACING_SM }) {
        // 警报次数卡片
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: 2 }) {
            Text(`${this.alertCount}`)
              .fontSize(DesignConstants.FONT_SIZE_2XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.alertCount > 0 ? $r('sys.color.brand') : $r('sys.color.font_primary'))

            Text('次')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor(this.alertCount > 0 ? $r('sys.color.brand') : $r('sys.color.font_primary'))
              .opacity(0.8)
              .margin({ top: 4 })
          }

          Text('警报次数')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)

        // 最高峰值卡片
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: 2 }) {
            Text(this.peakDecibel > 0 ? `${this.peakDecibel.toFixed(0)}` : '--')
              .fontSize(DesignConstants.FONT_SIZE_2XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.peakDecibel >= 80 ? $r('sys.color.alert') : $r('sys.color.font_primary'))

            Text('dB')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor(this.peakDecibel >= 80 ? $r('sys.color.alert') : $r('sys.color.font_primary'))
              .opacity(0.8)
              .margin({ top: 4 })
          }

          Text('最高峰值')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)

        // 累计时长卡片
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: 2 }) {
            Text(this.formatDuration(this.totalDuration))
              .fontSize(DesignConstants.FONT_SIZE_2XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))

            Text(this.getDurationUnit(this.totalDuration))
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .opacity(0.8)
              .margin({ top: 4 })
          }

          Text('累计时长')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  /**
   * 严重程度分布条形图（横向堆叠条形图）
   */
  @Builder
  private buildSeverityChart() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Text('严重程度分布')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      if (this.getTotalSeverityCount() === 0) {
        // 无数据状态
        Column({ space: DesignConstants.SPACING_SM }) {
          Text('📝')
            .fontSize(32)
          Text('该时段无警报记录')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column({ space: DesignConstants.SPACING_MD }) {
          // 堆叠条形图
          Column({ space: 0 }) {
            // 背景条
            Row() {
              // 轻度
              if (this.severityLow > 0) {
                Column()
                  .layoutWeight(this.severityLow)
                  .height(24)
                  .backgroundColor('#4CAF50')
                  .borderRadius({ topLeft: 12, bottomLeft: 12 })
              }

              // 中度
              if (this.severityMedium > 0) {
                Column()
                  .layoutWeight(this.severityMedium)
                  .height(24)
                  .backgroundColor('#FF9800')
              }

              // 重度
              if (this.severityHigh > 0) {
                Column()
                  .layoutWeight(this.severityHigh)
                  .height(24)
                  .backgroundColor('#F44336')
              }

              // 严重
              if (this.severityCritical > 0) {
                Column()
                  .layoutWeight(this.severityCritical)
                  .height(24)
                  .backgroundColor('#9C27B0')
                  .borderRadius({ topRight: 12, bottomRight: 12 })
              }
            }
            .width('100%')
            .height(24)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(12)
          }
          .width('100%')

          // 图例列表
          Row({ space: DesignConstants.SPACING_LG }) {
            this.buildLegendItem('轻度', this.severityLow, '#4CAF50')
            this.buildLegendItem('中度', this.severityMedium, '#FF9800')
            this.buildLegendItem('重度', this.severityHigh, '#F44336')
            this.buildLegendItem('严重', this.severityCritical, '#9C27B0')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)

          // 洞察文案
          Text(this.getInsightText())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: DesignConstants.SPACING_SM })
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin({ bottom: DesignConstants.SPACING_MD })
  }

  /**
   * 构建图例项
   */
  @Builder
  private buildLegendItem(label: string, count: number, color: string) {
    Row({ space: DesignConstants.SPACING_XS }) {
      Circle()
        .width(8)
        .height(8)
        .fill(color)

      Column({ space: 0 }) {
        Text(`${count}次`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)

        Text(`${label} ${this.getSeverityPercentage(count)}%`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
  }

  /**
   * 记录列表
   */
  @Builder
  private buildRecordList() {
    Column({ space: 0 }) {
      // 列表头部
      Row() {
        Text(`详细记录 (${this.alertCount}条)`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()

        if (this.isLoading) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color($r('sys.color.font_tertiary'))
        }
      }
      .width('100%')
      .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_SM })

      // 列表内容
      List({ space: DesignConstants.SPACING_SM }) {
        // 表头
        ListItem() {
          Row() {
            Text('时间')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('25%')
            Text('持续')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('20%')
            Text('峰值')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('20%')
            Text('状态')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
        }

        // 记录列表
        LazyForEach(this.dataSource, (record: AlertRecord) => {
          ListItem() {
            this.buildRecordItem(record)
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .margin({ left: 4, right: 4 })
          .onClick(() => {
            this.navigateToDetail(record.id);
          })
        }, (record: AlertRecord) => record.id)

        // 空状态
        if (!this.isLoading && this.alertCount === 0) {
          ListItem() {
            Column({ space: DesignConstants.SPACING_MD }) {
              Text('📝')
                .fontSize(48)
              Text('暂无警报记录')
                .fontSize(DesignConstants.FONT_SIZE_LG)
                .fontColor($r('sys.color.font_secondary'))
              Text('环境良好，继续保持！')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            }
            .width('100%')
            .padding(DesignConstants.SPACING_XL)
            .alignItems(HorizontalAlign.Center)
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 记录项
   */
  @Builder
  private buildRecordItem(record: AlertRecord) {
    Row() {
      // 时间
      Column({ space: 2 }) {
        Text(this.formatTime(record.startTime))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Text(this.formatDate(record.startTime))
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('25%')
      .alignItems(HorizontalAlign.Start)

      // 持续时间
      Text(record.getFormattedDuration())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .width('20%')

      // 峰值
      Row({ space: 2 }) {
        Text(`${record.peakDecibel.toFixed(0)}`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getSeverityColor(record.severity))
        Text('dB')
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('20%')

      // 严重程度
      Row({ space: 4 }) {
        Circle()
          .width(6)
          .height(6)
          .fill(this.getSeverityColor(record.severity))
        Text(AlertRecord.getSeverityText(record.severity))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  // ========== 工具方法 ==========

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return '今天';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return '昨天';
    } else {
      return `${date.getMonth() + 1}/${date.getDate()}`;
    }
  }

  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    if (minutes >= 60) {
      return `${Math.floor(minutes / 60)}`;
    }
    return `${minutes}`;
  }

  private getDurationUnit(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    if (minutes >= 60) {
      return '小时';
    }
    return '分钟';
  }

  private getSeverityColor(severity: AlertSeverity): string {
    switch (severity) {
      case AlertSeverity.LOW:
        return '#4CAF50';
      case AlertSeverity.MEDIUM:
        return '#FF9800';
      case AlertSeverity.HIGH:
        return '#F44336';
      case AlertSeverity.CRITICAL:
        return '#9C27B0';
      default:
        return '#999999';
    }
  }

  private navigateToDetail(alertId: string): void {
    let detailDialog: InfSheet = DialogHub.getSheet()
      .setStyle({
        title: { title: '警报详情' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertDetailPageBuilder), { alertId } as AlertDetailPageParams)
      .build();
    detailDialog.show();
  }
}
