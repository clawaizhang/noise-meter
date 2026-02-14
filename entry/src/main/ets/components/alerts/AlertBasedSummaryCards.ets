/**
 * 今日警报概况卡片组件
 * 用于主页显示今日警报统计数据
 */

import { AlertHistoryService } from '../../services/AlertHistoryService';
import { AlertSummary } from '../../models/AlertRecord';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertsContentBuilder } from './AlertsContent';

const TAG = 'AlertBasedSummaryCards';
const DOMAIN = 0xFF00;

@ComponentV2
export struct AlertBasedSummaryCards {
  // 服务实例
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();

  // UI状态
  @Local private isLoading: boolean = true;
  @Local private refreshTimer: number = 0;
  @Local private errorMessage: string = '';

  // 数据显示状态 - 使用简单类型确保响应式更新
  @Local private displayCount: number = 0;
  @Local private displayPeak: number = 0;
  @Local private displayDuration: number = 0;
  @Local private lastUpdateTime: string = '--:--';

  async aboutToAppear(): Promise<void> {
    hilog.info(DOMAIN, TAG, '组件挂载，准备加载数据');
    await this.initializeAndLoad();
  }

  aboutToDisappear(): void {
    this.stopRefreshTimer();
  }

  /**
   * 初始化并加载数据
   */
  private async initializeAndLoad(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 等待服务初始化完成
      const initialized = await this.alertHistoryService.initialize();
      hilog.info(DOMAIN, TAG, `服务初始化: ${initialized ? '成功' : '失败'}`);

      if (!initialized) {
        this.errorMessage = '服务初始化失败';
        return;
      }

      // 加载数据
      await this.loadData();

      // 启动定时刷新
      this.startRefreshTimer();
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `初始化失败: ${errMsg}`);
      this.errorMessage = `初始化失败: ${errMsg}`;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载数据
   */
  private async loadData(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '开始获取今日警报摘要...');

      // 获取今日警报摘要
      const summary: AlertSummary = await this.alertHistoryService.getTodaySummary();

      // 更新显示状态 - 使用简单类型变量
      this.displayCount = summary.todayCount;
      this.displayPeak = summary.peakDecibel;
      this.displayDuration = summary.todayDuration;
      this.lastUpdateTime = this.formatTime(new Date());

      hilog.info(DOMAIN, TAG, `数据加载成功: 次数=${this.displayCount}, 峰值=${this.displayPeak}dB, 时长=${this.displayDuration}s`);
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `加载数据失败: ${errMsg}`);
      this.errorMessage = `加载失败: ${errMsg}`;
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(date: Date): string {
    const hours = date.getHours().toString().padStart(2, '0');
    const mins = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${mins}`;
  }

  /**
   * 启动自动刷新定时器
   */
  private startRefreshTimer(): void {
    this.stopRefreshTimer();

    this.refreshTimer = setInterval(() => {
      hilog.info(DOMAIN, TAG, '定时刷新触发');
      this.refreshData();
    }, 5000);

    hilog.info(DOMAIN, TAG, '定时刷新已启动 (5秒间隔)');
  }

  /**
   * 停止刷新定时器
   */
  private stopRefreshTimer(): void {
    if (this.refreshTimer !== 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
      hilog.info(DOMAIN, TAG, '定时刷新已停止');
    }
  }

  /**
   * 刷新数据
   */
  private async refreshData(): Promise<void> {
    try {
      const summary: AlertSummary = await this.alertHistoryService.getTodaySummary();

      // 只有当数据变化时才更新
      if (summary.todayCount !== this.displayCount ||
          summary.peakDecibel !== this.displayPeak ||
          summary.todayDuration !== this.displayDuration) {
        this.displayCount = summary.todayCount;
        this.displayPeak = summary.peakDecibel;
        this.displayDuration = summary.todayDuration;
        this.lastUpdateTime = this.formatTime(new Date());
        hilog.info(DOMAIN, TAG, `数据已更新: 次数=${this.displayCount}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `刷新数据失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 打开警报中心
   */
  private openAlertCenter(): void {
    hilog.info(DOMAIN, TAG, '打开警报中心');
    let alertDialog: InfSheet = DialogHub.getSheet()
      .setStyle({
        title: { title: '警报中心' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsContentBuilder))
      .build();
    alertDialog.show();
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row() {
        Text('🚨 今日警报概况')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()

        // 查看详情按钮
        Row({ space: DesignConstants.SPACING_XS }) {
          Text('查看详情')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.brand'))

          Image($r('app.media.ic_arrow_right'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.brand'))
        }
      }
      .width('100%')

      // 数据卡片行
      Row({ space: DesignConstants.SPACING_MD }) {
        // 警报次数
        this.buildStatCard(
          '警报次数',
          `${this.displayCount}`,
          '次',
          this.displayCount > 0 ? $r('sys.color.alert') : $r('sys.color.font_primary'),
          this.displayCount > 0 ? '⚠️ 有超标' : '✅ 正常'
        )

        // 今日峰值
        this.buildStatCard(
          '今日峰值',
          this.displayPeak > 0 ? `${this.displayPeak.toFixed(0)}` : '0',
          'dB',
          this.getPeakColor(this.displayPeak),
          this.getPeakStatus(this.displayPeak)
        )

        // 累计时长
        this.buildStatCard(
          '累计时长',
          this.getDurationMainText(this.displayDuration),
          this.getDurationUnit(this.displayDuration),
          $r('sys.color.font_primary'),
          this.displayCount > 0 ? '需关注' : '无警报'
        )
      }
      .width('100%')

      // 空数据提示
      if (!this.isLoading && this.displayCount === 0 && this.errorMessage === '') {
        Row({ space: DesignConstants.SPACING_XS }) {
          // 勾选图标
          Stack() {
            Circle()
              .width(16)
              .height(16)
              .fill($r('sys.color.confirm'))
            Text('✓')
              .fontSize(10)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .width(16)
          .height(16)

          Text('今日暂无警报，环境噪音控制良好')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.confirm'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor('rgba(76, 175, 80, 0.1)') // 10% 透明度绿色
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }

      // 错误提示
      if (this.errorMessage !== '') {
        Row({ space: DesignConstants.SPACING_XS }) {
          // 警告图标
          Stack() {
            Circle()
              .width(16)
              .height(16)
              .fill($r('sys.color.alert'))
            Text('!')
              .fontSize(10)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
          .width(16)
          .height(16)

          Text(this.errorMessage)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.alert'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor('rgba(244, 67, 54, 0.1)') // 10% 透明度红色
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }

      // 底部信息行
      Row() {
        // 加载指示器
        if (this.isLoading) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color($r('sys.color.font_tertiary'))
        }

        Blank()

        // 最后更新时间
        Text(`更新于 ${this.lastUpdateTime}`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      Throttle.click(() => this.openAlertCenter());
    })
  }

  /**
   * 统计卡片
   */
  @Builder
  private buildStatCard(title: string, value: string, unit: string, valueColor: Resource, subtitle: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Row({ space: 2 }) {
        Text(value)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(valueColor)

        Text(unit)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(valueColor)
          .margin({ bottom: 2 })
      }

      Text(subtitle)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_emphasize'))
    }
    .layoutWeight(1)
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  /**
   * 获取峰值颜色
   */
  private getPeakColor(peakDb: number): Resource {
    if (peakDb >= 90) {
      return $r('sys.color.alert');
    } else if (peakDb >= 80) {
      return $r('sys.color.warning');
    } else if (peakDb >= 70) {
      return $r('sys.color.confirm');
    }
    return $r('sys.color.font_primary');
  }

  /**
   * 获取峰值状态文本
   */
  private getPeakStatus(peakDb: number): string {
    if (peakDb >= 90) {
      return '极高风险';
    } else if (peakDb >= 80) {
      return '高风险';
    } else if (peakDb >= 70) {
      return '中等风险';
    }
    return '安全范围';
  }

  /**
   * 获取时长主文本
   */
  private getDurationMainText(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    if (minutes >= 60) {
      return `${Math.floor(minutes / 60)}`;
    }
    return `${minutes}`;
  }

  /**
   * 获取时长单位
   */
  private getDurationUnit(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    if (minutes >= 60) {
      return '小时';
    }
    return '分钟';
  }
}
