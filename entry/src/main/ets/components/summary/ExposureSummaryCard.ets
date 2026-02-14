/**
 * 暴露统计卡片
 * 专业UI设计展示今日噪音暴露关键指标
 */

import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { ExposureData } from '../../models/ExposureData';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { EnhancedExposureContent } from '../exposure/EnhancedExposureContent';
import { NoiseExposureStandard } from '../../constants/ExposureStandardConstants';
import common from '@ohos.app.ability.common';

const TAG = 'ExposureSummaryCard';
const DOMAIN = 0xFF00;

@ComponentV2
export struct ExposureSummaryCard {
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();

  @Local private isLoading: boolean = true;
  @Local private refreshTimer: number = 0;

  // 显示数据
  @Local private exposurePercent: number = 0;
  @Local private todayPeak: number = 0;
  @Local private todayAverage: number = 0;
  @Local private remainingTime: string = '';

  async aboutToAppear(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.exposureService.setContext(context);
    await this.loadData();
    this.startRefreshTimer();
  }

  aboutToDisappear(): void {
    this.stopRefreshTimer();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const data: ExposureData = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);
      this.exposurePercent = data.exposurePercentage;
      this.todayPeak = data.todayPeak;
      this.todayAverage = data.todayAverage;
      this.remainingTime = data.remainingSafeTime || '';
      hilog.info(DOMAIN, TAG, `加载: 暴露${this.exposurePercent}%, 峰值${this.todayPeak}dB`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  private startRefreshTimer(): void {
    this.stopRefreshTimer();
    this.refreshTimer = setInterval(() => this.refreshData(), 30000);
  }

  private stopRefreshTimer(): void {
    if (this.refreshTimer !== 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
    }
  }

  private async refreshData(): Promise<void> {
    try {
      const data = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);
      this.exposurePercent = data.exposurePercentage;
      this.todayPeak = data.todayPeak;
      this.todayAverage = data.todayAverage;
      this.remainingTime = data.remainingSafeTime || '';
    } catch (error) {
      hilog.error(DOMAIN, TAG, `刷新失败`);
    }
  }

  private openExposureDetail(): void {
    let exposureDialog: InfSheet = DialogHub.getSheet()
      .setStyle({
        title: { title: '暴露统计分析' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ExposureContentBuilder))
      .build();
    exposureDialog.show();
  }

  private getExposureColor(): Resource {
    if (this.exposurePercent < 30) return $r('sys.color.confirm');
    if (this.exposurePercent < 60) return $r('sys.color.warning');
    return $r('sys.color.alert');
  }

  private getExposureStatus(): string {
    if (this.exposurePercent < 30) return '状态良好';
    if (this.exposurePercent < 60) return '轻度暴露';
    if (this.exposurePercent < 100) return '暴露较高';
    return '严重超标';
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 第一行：标题 + 状态标签
      Row() {
        Text('今日噪音暴露')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()

        // 状态标签
        Text(this.getExposureStatus())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.getExposureColor())
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.getExposureColor().toString().replace(']', '') + '15')
          .borderRadius(12)
      }
      .width('100%')

      // 第二行：核心数据展示（三等分布局）
      Row({ space: DesignConstants.SPACING_SM }) {
        // 暴露剂量（左侧，带进度条）
        Column({ space: DesignConstants.SPACING_XS }) {
          // 数值
          Row({ space: 2 }) {
            Text(`${this.exposurePercent}`)
              .fontSize(DesignConstants.FONT_SIZE_3XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getExposureColor())
            Text('%')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ top: 8 })
          }

          // 进度条
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(4)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(2)

            Row()
              .width(`${Math.min(this.exposurePercent, 100)}%`)
              .height(4)
              .backgroundColor(this.getExposureColor())
              .borderRadius(2)
          }
          .width(60)

          Text('暴露剂量')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)

        // 今日峰值（中间）
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: 2 }) {
            Text(this.todayPeak > 0 ? `${this.todayPeak.toFixed(0)}` : '--')
              .fontSize(DesignConstants.FONT_SIZE_3XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            Text('dB')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ top: 8 })
          }

          // 峰值指示条（固定宽度装饰）
          Row()
            .width(40)
            .height(4)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(2)

          Text('今日峰值')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)

        // 安全剩余时间（右侧）
        Column({ space: DesignConstants.SPACING_XS }) {
          if (this.remainingTime !== '') {
            Text(this.remainingTime)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 装饰线
            Row()
              .width(40)
              .height(4)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(2)

            Text('安全剩余')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          } else {
            Text('--')
              .fontSize(DesignConstants.FONT_SIZE_3XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_secondary'))

            Row()
              .width(40)
              .height(4)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(2)

            Text('安全剩余')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')

      // 第三行：查看详情（底部）
      Row() {
        Text('查看详细分析报告')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.brand'))

        Blank()

        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.brand'))
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_XS })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      Throttle.click(() => this.openExposureDetail());
    })
  }
}

@Builder
function ExposureContentBuilder() {
  EnhancedExposureContent()
}
