/**
 * 噪音暴露统计组件 - 改进版本
 * 采用分层设计：基础信息 + 扩展功能
 * 优化了视觉层次和交互体验
 */

import { ExposureData } from '../../models/ExposureData';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';

interface Exposure {
  timeRange: string,
  exposure: number
}

@ComponentV2
export struct ExposureContent {
  @Local exposureData: ExposureData = new ExposureData();
  @Local isLoading: boolean = true;
  @Local isVisible: boolean = false;
  @Local hasError: boolean = false;
  @Local errorMessage: string = '';
  @Local private isExpanded: boolean = false;
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();
  private updateTimer: number | null = null;

  aboutToAppear(): void {
    this.isVisible = true;
    this.loadExposureData();
    this.startAutoUpdate();
  }

  aboutToDisappear(): void {
    this.isVisible = false;
    this.stopAutoUpdate();
  }

  /**
   * 加载暴露数据
   * 只在组件可见时执行
   */
  private async loadExposureData(): Promise<void> {
    if (!this.isVisible) {
      return;
    }

    this.isLoading = true;
    this.hasError = false;
    this.errorMessage = '';

    try {
      this.exposureData = await this.exposureService.calculateTodayExposure();
    } catch (error) {
      console.error('加载暴露数据失败:', error);
      this.hasError = true;
      this.errorMessage = '数据加载失败，请检查网络连接';
      this.exposureData = new ExposureData(0, '8小时', 0, 0);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 手动重试加载数据
   */
  private async retryLoadData(): Promise<void> {
    await this.loadExposureData();
  }

  /**
   * 启动自动更新
   * 只在组件可见时运行
   */
  private startAutoUpdate(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
    }

    this.updateTimer = setInterval(() => {
      if (this.isVisible) {
        this.loadExposureData();
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
   * 构建增强版暴露剂量环状进度条
   * 优化视觉效果和动画
   */
  @Builder
  private buildEnhancedProgressRing(percentage: number, color: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      // 背景环 - 更细的线条
      Circle({ width: 80, height: 80 })
        .stroke($r('sys.color.background_tertiary'))
        .strokeWidth(6)
        .fill(Color.Transparent)

      // 进度环 - 添加动画效果
      Circle({ width: 80, height: 80 })
        .stroke(color)
        .strokeWidth(6)
        .fill(Color.Transparent)
        .opacity(percentage > 0 ? 1 : 0)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseOut
        })

      // 中心文本 - 优化字体层次
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(`${Math.round(percentage)}%`)
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))

        Text($r('app.string.exposure_dose_label'))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(80)
    .height(80)
  }

  /**
   * 构建健康评级组件
   */
  @Builder
  private buildHealthRating() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_info'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor(this.exposureData.getExposureColor())

      Text($r('app.string.health_rating_label'))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.exposureData.getExposureColor())

      Text(this.exposureData.getHealthRating())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.exposureData.getExposureColor())
        .fontWeight(FontWeight.Medium)
    }
  }

  /**
   * 构建增强版数据卡片
   * 添加阴影和悬停效果
   */
  @Builder
  private buildEnhancedDataCard(title: Resource, value: string | number, subtitle: Resource) {

    Column({ space: DesignConstants.SPACING_XS }) {
      // 主数值 - 突出显示
      Text(`${value}`)
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      // 标题 - 次要信息
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      // 副标题 - 补充信息
      if (subtitle) {
        Text(subtitle)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
          .textAlign(TextAlign.Center)
      }
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .animation({
      duration: DesignConstants.ANIMATION_DURATION_SM,
      curve: Curve.EaseInOut
    })
  }

  /**
   * 构建扩展面板
   * 包含详细数据和专业功能
   */
  @Builder
  private buildExpandableSection() {
    Column() {
      // 面板标题和切换按钮
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('详细数据')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()

        // 展开/折叠按钮
        Image(this.isExpanded ? $r('app.media.ic_arrow_right') : $r('app.media.ic_arrow_right'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        Throttle.click(() => this.isExpanded = !this.isExpanded)
      })

      // 可折叠内容
      if (this.isExpanded) {
        Column({ space: DesignConstants.SPACING_MD }) {
          // 详细数据表格
          this.buildDetailedDataTable()

          // 趋势图表占位
          this.buildTrendChartPlaceholder()

          // 专业设置占位
          this.buildProfessionalSettingsPlaceholder()
        }
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseInOut
        })
      }
    }
  }

  /**
   * 构建详细数据表格
   */
  @Builder
  private buildDetailedDataTable() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 表格标题
      Text('时间分段暴露数据')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      // 模拟数据行
      ForEach([{ timeRange: '08:00-12:00', exposure: 35 },
        { timeRange: '12:00-16:00', exposure: 45 },
        { timeRange: '16:00-20:00', exposure: 60 }], (segment: Exposure) => {
        Row({ space: DesignConstants.SPACING_MD }) {
          Text(segment.timeRange)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text(`${segment.exposure}%`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.getExposureColor(segment.exposure))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
      })
    }
  }

  /**
   * 构建趋势图表占位
   */
  @Builder
  private buildTrendChartPlaceholder() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('24小时暴露趋势')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      // 图表占位区域
      Column()
        .width('100%')
        .height(120)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }
  }

  /**
   * 构建专业设置占位
   */
  @Builder
  private buildProfessionalSettingsPlaceholder() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业参数设置')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      // 设置项占位
      Column({ space: DesignConstants.SPACING_SM }) {
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('自定义阈值')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text('85 dB')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }

        Row({ space: DesignConstants.SPACING_MD }) {
          Text('监测标准')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text('国家标准')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
  }

  build() {
    // 主内容区域 - 优化布局结构
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 核心指标区 - 居中显示
        Column({ space: DesignConstants.SPACING_MD }) {
          this.buildEnhancedProgressRing(
            this.exposureData.exposurePercentage,
            this.exposureData.getExposureColor()
          )

          this.buildHealthRating()
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 24, bottom: 16 })

        // 关键数据网格 - 3列响应式布局
        GridRow({ columns: { sm: 1, md: 2, lg: 3 }, gutter: DesignConstants.SPACING_MD }) {
          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildEnhancedDataCard(
              $r('app.string.remaining_safe_time_label'),
              this.exposureData.remainingSafeTime,
              $r('app.string.based_on_national_standard')
            )
          }

          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildEnhancedDataCard(
              $r('app.string.today_peak_label'),
              `${this.exposureData.todayPeak} dB`,
              $r('app.string.highest_noise_level')
            )
          }

          GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
            this.buildEnhancedDataCard(
              $r('app.string.today_average_label'),
              `${this.exposureData.todayAverage} dB`,
              $r('app.string.average_noise_level')
            )
          }
        }
        .margin({ bottom: 24 })

        // 扩展区域 - 可折叠面板
        this.buildExpandableSection()
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
}