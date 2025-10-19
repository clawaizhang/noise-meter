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
import { PremiumFeature } from '../membership/PremiumFeature';
import promptAction from '@ohos.promptAction';

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
  @Local isRefreshing: boolean = false; // 刷新状态
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
   * 手动刷新数据
   */
  private async refreshData(): Promise<void> {
    if (this.isRefreshing) {
      return; // 防止重复刷新
    }

    this.isRefreshing = true;

    try {
      await this.loadAllData();
      
      // 刷新完成提示
      promptAction.showToast({
        message: '数据已刷新',
        duration: 1500
      });
      

    } catch (error) {
      console.error('刷新数据失败:', error);

      // 错误提示
      promptAction.showToast({
        message: '刷新失败，请重试',
        duration: 2000
      });
      
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 获取暴露颜色
   * 更新颜色逻辑，支持超过100%的暴露剂量
   */
  private getExposureColor(percentage: number): Resource {
    if (percentage < 30) {
      return $r('app.color.health_good');      // 绿色 - 安全
    } else if (percentage < 60) {
      return $r('app.color.health_warning');   // 黄色 - 警告
    } else if (percentage < 100) {
      return $r('app.color.health_bad');       // 红色 - 危险
    } else {
      return $r('sys.color.alert');            // 深红色 - 严重超标
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
        Text('选择计算方式')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Text('不同场景使用不同的计算标准')
          .fontSize(DesignConstants.FONT_SIZE_MD)
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
            .fontSize(DesignConstants.FONT_SIZE_SM)
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

              // 使用场景说明 - 为每个标准显示适用场景
              if (standard === NoiseExposureStandard.INDUSTRIAL) {
                Text('• 适用场景：办公室、工厂等工作环境')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              } else if (standard === NoiseExposureStandard.ENVIRONMENTAL) {
                Text('• 适用场景：家庭、社区等生活环境')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              } else if (standard === NoiseExposureStandard.OCCUPATIONAL) {
                Text('• 适用场景：关注长期听力健康保护')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              } else if (standard === NoiseExposureStandard.SOCIAL) {
                Text('• 适用场景：日常生活舒适度评估')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
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

      // 中心内容
      Column({ space: DesignConstants.SPACING_XS }) {
        if (this.isRefreshing) {
          // 刷新状态显示旋转图标
          Image($r('app.media.ic_refresh'))
            .width(32)
            .height(32)
            .fillColor($r('sys.color.font_primary'))
            .rotate({
              angle: 360,
              centerX: '50%',
              centerY: '50%'
            })
            .animation({
              duration: 1000,
              curve: Curve.Linear,
              iterations: -1 // 无限循环
            })
        } else {
          // 正常状态显示百分比
          Text(`${config.percentage}%`)
            .fontSize(DesignConstants.FONT_SIZE_3XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
        }

        Text('噪音影响程度')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(120)
    .height(120)
    .onClick(() => {
      this.refreshData();
    })
  }

  /**
   * 构建核心指标区 - 优化版
   * 在圆环下方添加并排的峰值和平均值显示
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
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getExposureColor(this.exposureData.exposurePercentage))
          .textAlign(TextAlign.Center)

        Text('还能安全待多久')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }

      // 健康状态描述
      Column({ space: DesignConstants.SPACING_XS }) {
        if (this.exposureData.exposurePercentage < 30) {
          Text('噪音影响程度很低，继续保持！')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('app.color.health_good'))
            .textAlign(TextAlign.Center)
        } else if (this.exposureData.exposurePercentage < 60) {
          Text('噪音影响程度中等，建议关注环境噪音')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('app.color.health_warning'))
            .textAlign(TextAlign.Center)
        } else if (this.exposureData.exposurePercentage < 100) {
          Text('噪音影响程度较高，建议减少在嘈杂环境的时间')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('app.color.health_bad'))
            .textAlign(TextAlign.Center)
        } else {
          Text('噪音影响严重超标，请立即采取保护措施')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.alert'))
            .textAlign(TextAlign.Center)
        }
      }

      // 并排显示今日峰值和平均值
      Row({ space: DesignConstants.SPACING_MD }) {
        // 今日峰值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.exposureData.todayPeak.toFixed(1)} dB`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)

          Text('今日最高噪音')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)

        // 今日平均值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.exposureData.todayAverage.toFixed(1)} dB`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)

          Text('今日平均噪音')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }
      .width('100%')

    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建关键数据网格 - 优化版
   * 移除重复的暴露剂量卡片，只保留今日峰值和今日平均值
   */
  @Builder
  private buildKeyDataGrid() {
    GridRow({ columns: { sm: 1, md: 2, lg: 2 }, gutter: DesignConstants.SPACING_MD }) {
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
   * 构建分贝区间分析面板 - 优化版
   * 使用水平条形图可视化，添加具体分贝值显示
   */
  @Builder
  private buildDecibelAnalysisPanel(config: DecibelAnalysisConfig) {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('噪音水平分布')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      ForEach(config.stats, (stat: DecibelRangeStats) => {
        Column({ space: DesignConstants.SPACING_XS }) {
          // 区间标签和分贝范围
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(DecibelRangeConfigs[stat.range].label)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)

            Text(`(${DecibelRangeConfigs[stat.range].min}-${DecibelRangeConfigs[stat.range].max}dB)`)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          // 水平条形图
          Row({ space: DesignConstants.SPACING_SM }) {
            // 条形图背景
            Row() {
              // 进度条
              Column()
                .width(`${Math.max(stat.percentage, 5)}%`)
                .height(8)
                .backgroundColor(this.getRangeColor(stat.range))
                .borderRadius(4)
              Blank()
            }
            .justifyContent(FlexAlign.Start)
            .layoutWeight(1)
            .height(8)
            .backgroundColor($r('sys.color.background_tertiary'))
            .borderRadius(4)

            // 百分比和时长
            Row({ space: DesignConstants.SPACING_XS }) {
              Text(`${stat.percentage}%`)
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor(this.getRangeColor(stat.range))
                .fontWeight(FontWeight.Bold)

              Text(stat.duration)
                .fontSize(DesignConstants.FONT_SIZE_XS)
                .fontColor($r('sys.color.font_secondary'))
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 环境描述 - 添加情境化描述
          Row({ space: DesignConstants.SPACING_XS }) {
            Text(DecibelRangeConfigs[stat.range].description)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
            
            // 添加环境比喻
            if (stat.range === DecibelRange.VERY_QUIET) {
              Text('(图书馆环境)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            } else if (stat.range === DecibelRange.QUIET) {
              Text('(办公室环境)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            } else if (stat.range === DecibelRange.MODERATE) {
              Text('(正常交谈)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            } else if (stat.range === DecibelRange.NOISY) {
              Text('(交通噪音)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            } else if (stat.range === DecibelRange.HIGH) {
              Text('(施工工地)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            } else if (stat.range === DecibelRange.VERY_HIGH) {
              Text('(音乐会现场)')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
            }
          }
          .alignSelf(ItemAlign.Start)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }, (item: DecibelRangeStats, index: number) => index + '')
    }
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
        PremiumFeature({ featureName: '噪音暴露统计', featureDesc: '专业噪音暴露统计计算' }) {
          this.buildStandardSelector()
        }

        // 2. 核心指标区（已整合今日峰值和平均值）
        this.buildCoreMetrics()

        // 3. 分贝分析面板
        this.buildDecibelAnalysisPanel({
          stats: this.decibelRangeStats
        })
      }
      .padding(16)
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