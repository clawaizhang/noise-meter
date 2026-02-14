/**
 * 警报历史详情页
 * 展示完整的警报历史记录列表
 */

import { AlertHistoryService } from '../../services/AlertHistoryService';
import { 
  AlertRecord, 
  AlertSummary, 
  AlertSeverity
} from '../../models/AlertRecord';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertDetailPageBuilder, AlertDetailPageParams } from './AlertDetailPage';

const TAG = 'AlertHistoryNavigation';
const DOMAIN = 0xFF00;

/**
 * 警报记录数据源 - 用于 LazyForEach
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
  
  // 服务实例
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();
  
  // 页面状态
  @Local private isLoading: boolean = true;
  @Local private isLoadingMore: boolean = false;
  @Local private hasMoreData: boolean = true;
  @Local private currentPage: number = 1;
  private readonly pageSize: number = 20;
  
  // 数据源
  private dataSource: AlertRecordDataSource = new AlertRecordDataSource();
  
  // 统计数据（独立响应式字段，确保UI刷新）
  @Local private totalCount: number = 0;
  @Local private todayCount: number = 0;
  @Local private peakDecibel: string = '--';
  @Local private severityLow: number = 0;
  @Local private severityMedium: number = 0;
  @Local private severityHigh: number = 0;
  @Local private severityCritical: number = 0;

  aboutToAppear(): void {
    console.info('[AlertHistoryNavigation] 页面加载，开始获取数据');
    this.loadInitialData();
  }

  /**
   * 更新统计字段
   */
  private updateStats(summary: AlertSummary): void {
    console.info(`[AlertHistoryNavigation] 更新统计: total=${summary.totalCount}, today=${summary.todayCount}, peak=${summary.peakDecibel}`);
    this.totalCount = summary.totalCount;
    this.todayCount = summary.todayCount;
    this.peakDecibel = summary.peakDecibel > 0 ? `${summary.peakDecibel.toFixed(0)}dB` : '--';
    this.severityLow = summary.severityDistributionLow;
    this.severityMedium = summary.severityDistributionMedium;
    this.severityHigh = summary.severityDistributionHigh;
    this.severityCritical = summary.severityDistributionCritical;
  }

  /**
   * 加载初始数据
   */
  private async loadInitialData(): Promise<void> {
    this.isLoading = true;
    this.currentPage = 1;
    
    try {
      // 加载统计数据
      console.info('[AlertHistoryNavigation] 开始加载统计数据');
      const summary = await this.alertHistoryService.getTodaySummary();
      console.info(`[AlertHistoryNavigation] 获取到统计: ${JSON.stringify(summary)}`);
      this.updateStats(summary);
      
      // 加载历史记录
      console.info('[AlertHistoryNavigation] 开始加载历史记录');
      const records = await this.loadAlertRecords(1);
      console.info(`[AlertHistoryNavigation] 获取到 ${records.length} 条记录`);
      this.dataSource.setData(records);
      this.hasMoreData = records.length >= this.pageSize;
      
      hilog.info(DOMAIN, TAG, `加载 ${records.length} 条记录，共 ${summary.totalCount} 条`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载数据失败: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '加载失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载警报记录
   */
  private async loadAlertRecords(page: number): Promise<AlertRecord[]> {
    const offset = (page - 1) * this.pageSize;
    return this.alertHistoryService.getRecentAlerts(this.pageSize, offset);
  }

  /**
   * 加载更多数据
   */
  private async loadMoreData(): Promise<void> {
    if (this.isLoadingMore || !this.hasMoreData) {
      return;
    }
    
    this.isLoadingMore = true;
    
    try {
      const nextPage = this.currentPage + 1;
      const records = await this.loadAlertRecords(nextPage);
      
      if (records.length > 0) {
        this.dataSource.addData(records);
        this.currentPage = nextPage;
        this.hasMoreData = records.length >= this.pageSize;
      } else {
        this.hasMoreData = false;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载更多失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoadingMore = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      // 统计概览 - 使用独立的 builder，直接访问 this 字段
      this.buildStatsOverview()
      
      // 记录列表
      this.buildRecordList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  // ========== 统计概览区 ==========

  @Builder
  private buildStatsOverview() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 总统计行 - 三个独立的 builder，确保响应式
      Row({ space: DesignConstants.SPACING_LG }) {
        this.buildTotalCountCard()
        this.buildTodayCountCard()
        this.buildPeakDecibelCard()
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 严重程度分布
      if (this.totalCount > 0) {
        Column({ space: DesignConstants.SPACING_SM }) {
          Text('严重程度分布')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .alignSelf(ItemAlign.Start)

          Row({ space: DesignConstants.SPACING_SM }) {
            this.buildSeverityTag('轻度', this.severityLow, '#4CAF50')
            this.buildSeverityTag('中度', this.severityMedium, '#FF9800')
            this.buildSeverityTag('重度', this.severityHigh, '#F44336')
            this.buildSeverityTag('严重', this.severityCritical, '#9C27B0')
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin({ bottom: DesignConstants.SPACING_MD })
  }

  // 格式化大数字显示（如 12345 → 1.2万）
  private formatLargeNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + '万';
    } else if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }

  // 总记录卡片 - 数字和单位分开显示
  @Builder
  private buildTotalCountCard() {
    Column({ space: 4 }) {
      // 只显示数字，自适应字体
      Text(this.formatLargeNumber(this.totalCount))
        .fontSize(this.totalCount >= 1000 ? 22 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.brand'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
      // 标签+单位
      Row({ space: 2 }) {
        Text('总记录')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text('(次)')
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .height(84)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  // 今日卡片
  @Builder
  private buildTodayCountCard() {
    Column({ space: 4 }) {
      Text(this.formatLargeNumber(this.todayCount))
        .fontSize(this.todayCount >= 1000 ? 22 : 28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.confirm'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
      Row({ space: 2 }) {
        Text('今日')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text('(次)')
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .height(84)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  // 峰值卡片
  @Builder
  private buildPeakDecibelCard() {
    Column({ space: 4 }) {
      Text(this.peakDecibel)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.alert'))
        .maxLines(1)
        .width('100%')
        .textAlign(TextAlign.Center)
      Row({ space: 2 }) {
        Text('峰值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text('(dB)')
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .height(84)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildSeverityTag(label: string, count: number, color: string) {
    if (count > 0) {
      Row({ space: DesignConstants.SPACING_XS }) {
        Circle()
          .width(8)
          .height(8)
          .fill(color)
        Text(`${label} ${count}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .padding({ left: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
      .height(28)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    }
  }

  // ========== 记录列表区 ==========

  @Builder
  private buildRecordList() {
    Stack({ alignContent: Alignment.Top }) {
      // 列表内容
      List({ space: DesignConstants.SPACING_SM }) {
        // 列表头部 - 使用相同的 padding 确保对齐
        ListItem() {
          Row() {
            Text('时间')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('25%')
            Text('持续')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('18%')
            Text('峰值')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width('15%')
            Text('状态')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
        }
        .width('100%')

        // 记录列表 - 使用 LazyForEach
        LazyForEach(this.dataSource, (record: AlertRecord, index: number) => {
          ListItem() {
            this.buildRecordItem(record, index)
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          // 使用相同的 margin 确保对齐
          .margin({ left: 4, right: 4 })
          .onClick(() => {
            this.navigateToDetail(record.id);
          })
        }, (record: AlertRecord) => record.id)

        // 底部加载状态
        if (this.hasMoreData || this.isLoadingMore) {
          ListItem() {
            Row() {
              if (this.isLoadingMore) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                Text('加载中...')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_secondary'))
                  .margin({ left: DesignConstants.SPACING_SM })
              }
            }
            .width('100%')
            .height(48)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
        }

        // 到底提示
        if (!this.hasMoreData && this.dataSource.totalCount() > 0) {
          ListItem() {
            Text('已经到底了')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(DesignConstants.SPACING_MD)
          }
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
      // 上滑加载更多
      .onReachEnd(() => {
        if (!this.isLoadingMore && this.hasMoreData) {
          this.loadMoreData();
        }
      })

      // 加载状态覆盖层
      if (this.isLoading) {
        Column({ space: DesignConstants.SPACING_MD }) {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('加载中...')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.background_primary'))
      }

      // 空状态
      if (!this.isLoading && this.dataSource.totalCount() === 0) {
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
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.background_primary'))
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private buildRecordItem(record: AlertRecord, index: number) {
    Row() {
      // 时间 (25%)
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

      // 持续时间 (18%)
      Text(record.getFormattedDuration())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .width('18%')

      // 峰值分贝 (15%)
      Row({ space: 2 }) {
        Text(`${record.peakDecibel.toFixed(0)}`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getSeverityColor(record.severity))
        Text('dB')
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('15%')

      // 严重程度标签 (自适应剩余空间)
      Row({ space: 4 }) {
        Circle()
          .width(6)
          .height(6)
          .fill(this.getSeverityColor(record.severity))
        Text(AlertRecord.getSeverityText(record.severity))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 格式化时间
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  }

  /**
   * 格式化日期
   */
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

  /**
   * 获取严重程度颜色
   */
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

  /**
   * 跳转到详情页
   */
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
