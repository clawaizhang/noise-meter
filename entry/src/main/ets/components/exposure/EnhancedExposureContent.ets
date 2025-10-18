/**
 * 增强版噪音暴露统计组件
 * 支持多国家标准和分贝区间统计
 * 提供完整的暴露剂量可视化方案
 */

import { ExposureData } from '../../models/ExposureData';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { DesignConstants } from '../../constants/DesignConstants';
import { NoiseExposureStandard, DecibelRange, StandardConfigs, DecibelRangeConfigs } from '../../constants/ExposureStandardConstants';
import { Throttle } from '../../utils/Debounce';
import common from '@ohos.app.ability.common';

// 多标准暴露数据
interface MultiStandardExposureData {
  standard: NoiseExposureStandard;
  exposurePercentage: number;
  remainingSafeTime: string;
  complianceStatus: 'safe' | 'warning' | 'danger';
}

// 分贝区间统计数据
interface DecibelRangeStats {
  range: DecibelRange;
  duration: number;
  percentage: number;
}

@ComponentV2
export struct EnhancedExposureContent {
  @Local exposureData: ExposureData = new ExposureData();
  @Local multiStandardData: MultiStandardExposureData[] = [];
  @Local decibelRangeStats: DecibelRangeStats[] = [];
  @Local selectedStandard: NoiseExposureStandard = NoiseExposureStandard.INDUSTRIAL;
  @Local isLoading: boolean = true;
  @Local isVisible: boolean = false;
  @Local hasError: boolean = false;
  @Local errorMessage: string = '';
  @Local private showStandardComparison: boolean = false;
  @Local private showDecibelAnalysis: boolean = false;
  
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();
  private updateTimer: number | null = null;

  aboutToAppear(): void {
    this.isVisible = true;

    // 设置ExposureStatisticsService的上下文
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.exposureService.setContext(context);

    this.loadAllData();
    this.startAutoUpdate();
  }

  aboutToDisappear(): void {
    this.isVisible = false;
    this.stopAutoUpdate();
  }

  /**
   * 加载所有数据
   */
  private async loadAllData(): Promise<void> {
    if (!this.isVisible) {
      return;
    }

    this.isLoading = true;
    this.hasError = false;
    this.errorMessage = '';

    try {
      // 并行加载所有数据
      const exposureDataPromise = this.exposureService.calculateTodayExposure(this.selectedStandard);
      const multiStandardDataPromise = this.exposureService.calculateMultiStandardExposure();
      const decibelRangeStatsPromise = this.exposureService.calculateDecibelRangeStats();
      
      const exposureData = await exposureDataPromise;
      const multiStandardData = await multiStandardDataPromise;
      const decibelRangeStats = await decibelRangeStatsPromise;

      exposureData.copyTo(this.exposureData);
      this.multiStandardData.length = 0;
      multiStandardData.forEach((data: MultiStandardExposureData) => this.multiStandardData.push(data))
      this.decibelRangeStats.length = 0;
      decibelRangeStats.forEach((data: DecibelRangeStats) => this.decibelRangeStats.push(data))
    } catch (error) {
      console.error('加载暴露数据失败:', error);
      this.hasError = true;
      this.errorMessage = '数据加载失败，请检查网络连接';
      new ExposureData(0, '8小时', 0, 0).copyTo(this.exposureData);
      this.multiStandardData = [];
      this.decibelRangeStats = [];
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 切换标准
   */
  private async onStandardChange(standard: NoiseExposureStandard): Promise<void> {
    this.selectedStandard = standard;
    await this.loadAllData();
  }

  /**
   * 启动自动更新
   */
  private startAutoUpdate(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
    }

    this.updateTimer = setInterval(() => {
      if (this.isVisible) {
        this.loadAllData();
      }
    }, 30000); // 每30秒更新一次
  }

  /**
   * 停止自动更新
   */
  private stopAutoUpdate(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
  }

  /**
   * 获取暴露颜色
   */
  private getExposureColor(percentage: number): Resource {
    if (percentage <= 50) {
      return $r('app.color.health_good');
    }
    if (percentage <= 80) {
      return $r('app.color.health_warning');
    }
    return $r('app.color.health_bad');
  }

  /**
   * 获取分贝区间颜色
   */
  private getRangeColor(range: DecibelRange): Resource {
    if (range === DecibelRange.VERY_QUIET || range === DecibelRange.QUIET) {
      return $r('app.color.health_good');
    } else if (range === DecibelRange.MODERATE || range === DecibelRange.NOISY) {
      return $r('app.color.health_warning');
    } else if (range === DecibelRange.HIGH || range === DecibelRange.VERY_HIGH) {
      return $r('app.color.health_bad');
    } else {
      return $r('app.color.health_bad'); // 使用health_bad替代health_danger
    }
  }

  /**
   * 构建标准选择器
   */
  @Builder
  private buildStandardSelector() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('选择标准')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)

      Row({ space: DesignConstants.SPACING_SM }) {
        ForEach(Object.values(NoiseExposureStandard), (standard: NoiseExposureStandard) => {
          Button(StandardConfigs[standard].name, { type: ButtonType.Normal })
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.selectedStandard === standard ? 
              $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
            .backgroundColor(this.selectedStandard === standard ? 
              $r('sys.color.comp_background_primary') : $r('sys.color.comp_background_secondary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              Throttle.click(() => this.onStandardChange(standard))
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
  }

  /**
   * 构建增强版暴露剂量环状进度条
   */
  @Builder
  private buildEnhancedProgressRing(percentage: number, color: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      // 背景环
      Circle({ width: 100, height: 100 })
        .stroke($r('sys.color.background_tertiary'))
        .strokeWidth(8)
        .fill(Color.Transparent)

      // 进度环
      Circle({ width: 100, height: 100 })
        .stroke(color)
        .strokeWidth(8)
        .fill(Color.Transparent)
        .opacity(percentage > 0 ? 1 : 0)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseOut
        })

      // 中心文本
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(`${Math.round(percentage)}%`)
          .fontSize(DesignConstants.FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))

        Text($r('app.string.exposure_dose_label'))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(100)
    .height(100)
  }

  /**
   * 构建多标准对比面板
   */
  @Builder
  private buildStandardComparisonPanel() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('标准对比')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      ForEach(this.multiStandardData, (data: MultiStandardExposureData) => {
        Row({ space: DesignConstants.SPACING_MD }) {
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(StandardConfigs[data.standard].name)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)

            Text(StandardConfigs[data.standard].code)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
          .layoutWeight(1)

          Text(`${Math.round(data.exposurePercentage)}%`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(this.getExposureColor(data.exposurePercentage))
            .fontWeight(FontWeight.Bold)

          Text(data.remainingSafeTime)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      })
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
  }

  /**
   * 构建分贝区间分析面板
   */
  @Builder
  private buildDecibelAnalysisPanel() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('分贝区间分析')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      ForEach(this.decibelRangeStats, (stat: DecibelRangeStats) => {
        Row({ space: DesignConstants.SPACING_MD }) {
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(DecibelRangeConfigs[stat.range].label)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)

            Text(DecibelRangeConfigs[stat.range].description)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
          .layoutWeight(1)

          Column({ space: DesignConstants.SPACING_XS }) {
            Text(`${stat.percentage}%`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor(this.getRangeColor(stat.range))
              .fontWeight(FontWeight.Bold)

            Text(this.formatDuration(stat.duration))
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      })
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
  }

  /**
   * 格式化持续时间
   */
  private formatDuration(milliseconds: number): string {
    const minutes = Math.floor(milliseconds / (60 * 1000));
    if (minutes < 60) {
      return `${minutes}分钟`;
    }
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    return `${hours}小时${remainingMinutes}分钟`;
  }

  /**
   * 构建功能切换按钮
   */
  @Builder
  private buildFeatureToggles() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('标准对比', { type: ButtonType.Normal })
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.showStandardComparison ? 
          $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
        .backgroundColor(this.showStandardComparison ? 
          $r('sys.color.comp_background_primary') : $r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onClick(() => {
          Throttle.click(() => this.showStandardComparison = !this.showStandardComparison)
        })

      Button('分贝分析', { type: ButtonType.Normal })
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.showDecibelAnalysis ? 
          $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
        .backgroundColor(this.showDecibelAnalysis ? 
          $r('sys.color.comp_background_primary') : $r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onClick(() => {
          Throttle.click(() => this.showDecibelAnalysis = !this.showDecibelAnalysis)
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 标准选择器
        this.buildStandardSelector()

        // 核心指标区
        Column({ space: DesignConstants.SPACING_MD }) {
          this.buildEnhancedProgressRing(
            this.exposureData.exposurePercentage,
            this.getExposureColor(this.exposureData.exposurePercentage)
          )

          Text(StandardConfigs[this.selectedStandard].name)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 24, bottom: 16 })

        // 关键数据网格
        GridRow({ columns: { sm: 1, md: 2, lg: 3 }, gutter: DesignConstants.SPACING_MD }) {
          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildDataCard(
              '剩余安全时间',
              this.exposureData.remainingSafeTime,
              '基于当前标准'
            )
          }

          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildDataCard(
              '今日峰值',
              `${this.exposureData.todayPeak} dB`,
              '最高噪音水平'
            )
          }

          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildDataCard(
              '今日平均值',
              `${this.exposureData.todayAverage} dB`,
              '平均噪音水平'
            )
          }
        }
        .margin({ bottom: 24 })

        // 功能切换按钮
        this.buildFeatureToggles()

        // 标准对比面板
        if (this.showStandardComparison) {
          this.buildStandardComparisonPanel()
        }

        // 分贝分析面板
        if (this.showDecibelAnalysis) {
          this.buildDecibelAnalysisPanel()
        }
      }
      .padding(24)
      .width('100%')
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  /**
   * 构建数据卡片
   */
  @Builder
  private buildDataCard(title: string, value: string, subtitle: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Text(subtitle)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_tertiary'))
        .textAlign(TextAlign.Center)
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
  }
}