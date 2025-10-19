/**
 * 增强版噪音暴露统计组件
 * 支持多国家标准和分贝区间统计
 * 提供完整的暴露剂量可视化方案
 * 平衡专业性与易用性的设计
 */

import { ExposureData } from '../../models/ExposureData';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { DesignConstants } from '../../constants/DesignConstants';
import { NoiseExposureStandard, DecibelRange, DecibelRangeConfigs, StandardConfigs } from '../../constants/ExposureStandardConstants';
import common from '@ohos.app.ability.common';

// 分贝区间统计数据
interface DecibelRangeStats {
  range: DecibelRange;
  duration: string;
  percentage: number;
}

// 进度环配置接口
interface ProgressRingConfig {
  percentage: number;
  color: Resource;
}

// 数据卡片配置接口
interface DataCardConfig {
  title: string;
  value: string;
  subtitle: string;
}

// 分贝分析面板配置接口
interface DecibelAnalysisConfig {
  stats: DecibelRangeStats[];
}

@ComponentV2
export struct EnhancedExposureContent {
  @Local selectedStandard: NoiseExposureStandard = NoiseExposureStandard.INDUSTRIAL;
  @Local exposureData: ExposureData = new ExposureData();
  @Local decibelRangeStats: DecibelRangeStats[] = [];
  @Local isLoading: boolean = true;
  @Local isVisible: boolean = false;
  @Local hasError: boolean = false;
  @Local errorMessage: string = '';
  @Local isStandardSelectorOpen: boolean = false;
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
      const decibelRangeStatsPromise = this.exposureService.calculateDecibelRangeStats();

      const exposureData = await exposureDataPromise;
      const decibelRangeStats = await decibelRangeStatsPromise;

      exposureData.copyTo(this.exposureData);
      this.decibelRangeStats.length = 0;
      decibelRangeStats.forEach((data: DecibelRangeStats) => this.decibelRangeStats.push(data))
    } catch (error) {
      console.error('加载暴露数据失败:', error);
      this.hasError = true;
      this.errorMessage = '数据加载失败，请检查网络连接';
      new ExposureData(0, '8小时', 0, 0).copyTo(this.exposureData);
      this.decibelRangeStats = [];
    } finally {
      this.isLoading = false;
    }
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
    if (percentage < 30) {
      return $r('app.color.health_good');      // 绿色 - 安全
    } else if (percentage < 80) {
      return $r('app.color.health_warning');   // 黄色 - 警告
    } else {
      return $r('app.color.health_bad');       // 红色 - 危险
    }
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
   * 构建标准选择器 - 优化用户体验
   */
  @Builder
  private buildStandardSelector() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标准选择标题和说明
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('选择计算标准')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Text('不同标准适用于不同场景，计算结果会有差异')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 标准选择按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(StandardConfigs[this.selectedStandard].name)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
            
            // 推荐标识
            if (this.selectedStandard === NoiseExposureStandard.INDUSTRIAL) {
              Text('推荐')
                .fontSize(DesignConstants.FONT_SIZE_XS)
                .fontColor($r('sys.color.font_primary'))
                .backgroundColor($r('sys.color.background_primary'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(12)
            }
          }
          
          Text(StandardConfigs[this.selectedStandard].description)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
          
          // 标准参数说明
          Text(`基准值: ${StandardConfigs[this.selectedStandard].baseLimit}dB | 时长: ${StandardConfigs[this.selectedStandard].baseDuration >= 24 * 60 * 60 * 1000 ? '24小时' : '8小时'}`)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .layoutWeight(1)

        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        this.isStandardSelectorOpen = !this.isStandardSelectorOpen;
      })

      // 标准选择下拉菜单
      if (this.isStandardSelectorOpen) {
        Column({ space: DesignConstants.SPACING_XS }) {
          ForEach(Object.values(NoiseExposureStandard), (standard: NoiseExposureStandard) => {
            Column({ space: DesignConstants.SPACING_XS }) {
              Row({ space: DesignConstants.SPACING_MD }) {
                Column({ space: DesignConstants.SPACING_XS }) {
                  Row({ space: DesignConstants.SPACING_SM }) {
                    Text(StandardConfigs[standard].name)
                      .fontSize(DesignConstants.FONT_SIZE_SM)
                      .fontColor($r('sys.color.font_primary'))
                      .fontWeight(FontWeight.Medium)
                    
                    // 推荐标识
                    if (standard === NoiseExposureStandard.INDUSTRIAL) {
                      Text('推荐')
                        .fontSize(DesignConstants.FONT_SIZE_XS)
                        .fontColor($r('sys.color.font_primary'))
                        .backgroundColor($r('sys.color.background_primary'))
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .borderRadius(8)
                    }
                  }
                  
                  Text(StandardConfigs[standard].code)
                    .fontSize(DesignConstants.FONT_SIZE_XS)
                    .fontColor($r('sys.color.font_secondary'))
                  
                  // 标准参数
                  Text(`基准: ${StandardConfigs[standard].baseLimit}dB | 时长: ${StandardConfigs[standard].baseDuration >= 24 * 60 * 60 * 1000 ? '24小时' : '8小时'}`)
                    .fontSize(DesignConstants.FONT_SIZE_XS)
                    .fontColor($r('sys.color.font_tertiary'))
                }
                .layoutWeight(1)

                if (this.selectedStandard === standard) {
                  Image($r('app.media.ic_favorite'))
                    .width(16)
                    .height(16)
                    .fillColor($r('sys.color.font_primary'))
                }
              }
              
              // 计算说明
              if (standard === NoiseExposureStandard.INDUSTRIAL) {
                Text('• 专业计算：每增加3分贝，允许暴露时间减半')
                  .fontSize(DesignConstants.FONT_SIZE_XS)
                  .fontColor($r('sys.color.font_tertiary'))
              } else {
                Text('• 简化计算：基于基准分贝值按比例计算')
                  .fontSize(DesignConstants.FONT_SIZE_XS)
                  .fontColor($r('sys.color.font_tertiary'))
              }
            }
            .width('100%')
            .padding(DesignConstants.SPACING_MD)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_MD)
            .onClick(() => {
              this.selectedStandard = standard;
              this.isStandardSelectorOpen = false;
              this.loadAllData();
            })
          }, (item: NoiseExposureStandard) => item)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .margin({ top: DesignConstants.SPACING_XS })
      }
    }
    .width('100%')
  }

  /**
   * 构建增强版暴露剂量环状进度条
   */
  @Builder
  private buildEnhancedProgressRing(config: ProgressRingConfig) {
    Stack({ alignContent: Alignment.Center }) {
      // 背景环
      Circle({ width: 120, height: 120 })
        .stroke($r('sys.color.background_tertiary'))
        .strokeWidth(10)
        .fill(Color.Transparent)

      // 进度环
      Circle({ width: 120, height: 120 })
        .stroke(config.color)
        .strokeWidth(10)
        .fill(Color.Transparent)
        .opacity(config.percentage > 0 ? 1 : 0)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseOut
        })

      // 中心文本
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(`${config.percentage.toFixed(1)}%`)
          .fontSize(DesignConstants.FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))

        Text('暴露剂量')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(120)
    .height(120)
  }

  /**
   * 构建核心指标区
   */
  @Builder
  private buildCoreMetrics() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 暴露剂量环
      this.buildEnhancedProgressRing({
        percentage: this.exposureData.exposurePercentage,
        color: this.getExposureColor(this.exposureData.exposurePercentage)
      })

      // 剩余安全时间
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.exposureData.remainingSafeTime)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getExposureColor(this.exposureData.exposurePercentage))
          .textAlign(TextAlign.Center)

        Text('剩余安全时间')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }

      // 标准说明
      Text(`${StandardConfigs[this.selectedStandard].name} (${StandardConfigs[this.selectedStandard].code})`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建关键数据网格
   */
  @Builder
  private buildKeyDataGrid() {
    GridRow({ columns: { sm: 1, md: 2, lg: 3 }, gutter: DesignConstants.SPACING_MD }) {
      GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
        this.buildDataCard({
          title: '暴露剂量',
          value: `${this.exposureData.exposurePercentage.toFixed(1)}%`,
          subtitle: '已使用安全剂量'
        })
      }

      GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
        this.buildDataCard({
          title: '今日峰值',
          value: `${this.exposureData.todayPeak.toFixed(1)} dB`,
          subtitle: '最高噪音水平'
        })
      }

      GridCol({ span: { sm: 1, md: 1, lg: 1 } }) {
        this.buildDataCard({
          title: '今日平均值',
          value: `${this.exposureData.todayAverage.toFixed(1)} dB`,
          subtitle: '平均噪音水平'
        })
      }
    }
  }

  /**
   * 构建分贝区间分析面板
   */
  @Builder
  private buildDecibelAnalysisPanel(config: DecibelAnalysisConfig) {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('分贝区间分析')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      ForEach(config.stats, (stat: DecibelRangeStats) => {
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

            Text(stat.duration)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }, (item: DecibelRangeStats, index: number) => index + '')
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
  }

  /**
   * 构建数据卡片
   */
  @Builder
  private buildDataCard(config: DataCardConfig) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(config.value)
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(config.title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Text(config.subtitle)
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

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 1. 标准选择区
        this.buildStandardSelector()

        // 2. 核心指标区
        this.buildCoreMetrics()

        // 3. 关键数据网格
        this.buildKeyDataGrid()

        // 4. 分贝分析面板
        this.buildDecibelAnalysisPanel({
          stats: this.decibelRangeStats
        })
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