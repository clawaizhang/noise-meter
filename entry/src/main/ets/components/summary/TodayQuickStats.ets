/**
 * 今日速览组件
 * 单行展示今日关键数据摘要
 */

import { AlertHistoryService } from '../../services/AlertHistoryService';
import { AlertSummary } from '../../models/AlertRecord';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { ExposureData } from '../../models/ExposureData';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertsContentBuilder } from '../alerts/AlertsContent';
import { NoiseExposureStandard } from '../../constants/ExposureStandardConstants';
import common from '@ohos.app.ability.common';

const TAG = 'TodayQuickStats';
const DOMAIN = 0xFF00;

@ComponentV2
export struct TodayQuickStats {
  // 服务实例
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();

  // 状态
  @Local private isLoading: boolean = true;
  @Local private refreshTimer: number = 0;

  // 警报数据
  @Local private alertCount: number = 0;
  @Local private alertPeak: number = 0;

  // 暴露数据
  @Local private exposurePercent: number = 0;

  async aboutToAppear(): Promise<void> {
    // 设置暴露服务上下文
    const context = getContext(this) as common.UIAbilityContext;
    this.exposureService.setContext(context);

    await this.loadData();
    this.startRefreshTimer();
  }

  aboutToDisappear(): void {
    this.stopRefreshTimer();
  }

  /**
   * 加载数据
   */
  private async loadData(): Promise<void> {
    this.isLoading = true;

    try {
      // 初始化并加载警报数据
      await this.alertHistoryService.initialize();
      const alertSummary: AlertSummary = await this.alertHistoryService.getTodaySummary();
      this.alertCount = alertSummary.todayCount;
      this.alertPeak = alertSummary.peakDecibel;

      // 加载暴露数据
      const exposureData: ExposureData = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);
      this.exposurePercent = exposureData.exposurePercentage;

      hilog.info(DOMAIN, TAG, `数据加载: 警报${this.alertCount}次, 峰值${this.alertPeak}dB, 暴露${this.exposurePercent}%`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 启动刷新定时器
   */
  private startRefreshTimer(): void {
    this.refreshTimer = setInterval(() => {
      this.refreshData();
    }, 10000); // 10秒刷新
  }

  /**
   * 停止刷新定时器
   */
  private stopRefreshTimer(): void {
    if (this.refreshTimer !== 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
    }
  }

  /**
   * 刷新数据
   */
  private async refreshData(): Promise<void> {
    try {
      const alertSummary = await this.alertHistoryService.getTodaySummary();
      const exposureData = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);

      this.alertCount = alertSummary.todayCount;
      this.alertPeak = alertSummary.peakDecibel;
      this.exposurePercent = exposureData.exposurePercentage;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `刷新失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 打开警报中心
   */
  private openAlertCenter(): void {
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

  /**
   * 获取警报次数颜色
   */
  private getAlertCountColor(): Resource {
    if (this.alertCount === 0) {
      return $r('sys.color.confirm');
    } else if (this.alertCount <= 3) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.alert');
  }

  /**
   * 获取暴露颜色
   */
  private getExposureColor(): Resource {
    if (this.exposurePercent < 30) {
      return $r('sys.color.confirm');
    } else if (this.exposurePercent < 60) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.alert');
  }

  build() {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 左侧标题
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('📊')
          .fontSize(DesignConstants.FONT_SIZE_MD)

        Text('今日速览')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }

      // 中间数据（横向排列）
      Row({ space: DesignConstants.SPACING_MD }) {
        // 警报次数
        this.buildStatItem('警报', `${this.alertCount}次`, this.getAlertCountColor())

        // 分隔线
        Column()
          .width(1)
          .height(20)
          .backgroundColor($r('sys.color.comp_divider'))

        // 峰值
        this.buildStatItem('峰值', this.alertPeak > 0 ? `${this.alertPeak.toFixed(0)}dB` : '--', $r('sys.color.font_primary'))

        // 分隔线
        Column()
          .width(1)
          .height(20)
          .backgroundColor($r('sys.color.comp_divider'))

        // 暴露
        this.buildStatItem('暴露', `${this.exposurePercent}%`, this.getExposureColor())
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 右侧箭头
      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      Throttle.click(() => this.openAlertCenter());
    })
  }

  /**
   * 统计项
   */
  @Builder
  private buildStatItem(label: string, value: string, valueColor: Resource) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(valueColor)

      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
    }
  }
}
