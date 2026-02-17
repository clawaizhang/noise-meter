/**
 * 增强版噪音暴露统计组件
 * 支持多国家标准和分贝区间统计
 * 提供完整的暴露剂量可视化方案
 * 平衡专业性与易用性的设计
 */

import { ExposureData } from '../../models/ExposureData';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { DesignConstants } from '../../constants/DesignConstants';
import {
  NoiseExposureStandard,
  DecibelRange,
  DecibelRangeConfigs,
  StandardConfigs
} from '../../constants/ExposureStandardConstants';
import common from '@ohos.app.ability.common';
import { SettingLockView, isProMember, BenefitTagItem } from '../membership/PremiumLockViews';
import promptAction from '@ohos.promptAction';
import { Throttle } from '../../utils/Debounce';

// 分贝区间统计数据
@ObservedV2
class DecibelRangeStats {
  @Trace
  range: DecibelRange = DecibelRange.VERY_QUIET;
  @Trace
  duration: string = '';
  @Trace
  percentage: number =  0;
  @Trace
  exposureColor?: Resource;
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
  @Local selectedStandard: NoiseExposureStandard = NoiseExposureStandard.SOCIAL;
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
  @Computed
  private get ExposureColor(): Resource {
    if (this.exposureData.exposurePercentage < 30) {
      return $r('app.color.health_good'); // 绿色 - 安全
    } else if (this.exposureData.exposurePercentage < 60) {
      return $r('app.color.health_warning'); // 黄色 - 警告
    } else if (this.exposureData.exposurePercentage < 100) {
      return $r('app.color.health_bad'); // 红色 - 危险
    } else {
      return $r('sys.color.alert'); // 深红色 - 严重超标
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

          }

          Text(StandardConfigs[this.selectedStandard].description)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))

          // 标准参数说明
          Text(`基准值: ${StandardConfigs[this.selectedStandard].baseLimit}dB | 时长: ${StandardConfigs[this.selectedStandard].baseDuration >=
            24 * 60 * 60 * 1000 ? '24小时' : '8小时'}`)
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
        Throttle.click(() => {
        this.isStandardSelectorOpen = !this.isStandardSelectorOpen;
        });
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

                  }

                  Text(StandardConfigs[standard].code)
                    .fontSize(DesignConstants.FONT_SIZE_XS)
                    .fontColor($r('sys.color.font_secondary'))

                  // 标准参数
                  Text(`基准: ${StandardConfigs[standard].baseLimit}dB | 时长: ${StandardConfigs[standard].baseDuration >=
                    24 * 60 * 60 * 1000 ? '24小时' : '8小时'}`)
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
              if (standard === NoiseExposureStandard.WORKPLACE) {
                Text('• 适用场景：工厂、车间、建筑工地等职业环境')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              } else if (standard === NoiseExposureStandard.ENVIRONMENTAL) {
                Text('• 适用场景：街道、公园、社区等室外环境')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              } else if (standard === NoiseExposureStandard.SOCIAL) {
                Text('• 适用场景：住宅、办公室、学校等室内环境')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_tertiary'))
              }
            }
            .width('100%')
            .padding(DesignConstants.SPACING_MD)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_MD)
            .onClick(() => {
              Throttle.click(() => {
              this.selectedStandard = standard;
              this.isStandardSelectorOpen = false;
              this.loadAllData();
              });
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

  // 标准选择器（锁定预览版）
  @Builder
  private buildStandardSelectorLocked() {
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

      // 标准选择按钮（禁用状态预览）
      Row({ space: DesignConstants.SPACING_MD }) {
        Column({ space: DesignConstants.SPACING_XS }) {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('职业标准')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
          }

          Text('工作场所噪音暴露评估')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))

          // 标准参数说明
          Text('基准值: 85dB | 时长: 8小时')
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
        .stroke($r('sys.color.comp_background_tertiary'))
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
      Throttle.click(() => {
      this.refreshData();
      });
    })
  }

  /**
   * 显示数据保存提示信息
   */
  private showDataSaveHint(): void {
    promptAction.showToast({
      message: '噪音影响程度基于已保存的历史记录计算',
      duration: 3000
    });
  }

  /**
   * 构建核心指标区 - 统一卡片版
   * 将噪音影响程度、今日最高噪音和今日平均噪音合并为一张卡片
   */
  @Builder
  private buildCoreMetrics() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 顶部：噪音影响程度环形进度条和信息图标
      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: DesignConstants.SPACING_SM }) {
          this.buildEnhancedProgressRing({
            percentage: this.exposureData.exposurePercentage,
            color: this.ExposureColor
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 信息图标 - 右上角
        Image($r('app.media.ic_info'))
          .width(20)
          .height(20)
          .fillColor($r('sys.color.font_secondary'))
          .margin({ top: DesignConstants.SPACING_XS, right: DesignConstants.SPACING_XS })
          .onClick(() => {
            Throttle.click(() => {
            this.showDataSaveHint();
            });
          })
      }
      .width('100%')

      // 底部：剩余安全时间和健康状态描述
      Column({ space: DesignConstants.SPACING_MD }) {
        // 剩余安全时间
        if (this.exposureData.remainingSafeTime) {
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(this.exposureData.remainingSafeTime)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.ExposureColor)
              .textAlign(TextAlign.Center)

            Text('还能安全待多久')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Center)
          }
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
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 中部：今日最高噪音和今日平均噪音并排显示
      Row({ space: DesignConstants.SPACING_MD }) {
        // 今日峰值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.exposureData.todayPeak.toFixed(1)} dB`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
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
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)

        // 今日平均值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.exposureData.todayAverage.toFixed(1)} dB`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
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
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }
      .width('100%')



    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
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
                .width(`${stat.percentage}%`)
                .height(8)
                .backgroundColor(stat.exposureColor)
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
                .fontColor(stat.exposureColor)
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
      })
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
        if (isProMember()) {
          // 专业版：正常显示
          this.buildStandardSelector()
        } else {
          // 免费版：显示置灰的选择器 + 底部锁定提示
          SettingLockView({
            params: {
              featureId: 'noise_impact',
              featureName: '噪音影响程度',
              featureDesc: '专业噪音影响评估，了解噪音对健康的潜在风险',
              benefitTags: [
                { icon: '🎁', text: '7天免费试用' } as BenefitTagItem,
                { icon: '📊', text: '健康评估' } as BenefitTagItem
              ],
              trialPrice: '0.01元立即试用',
              onUpgrade: () => {
                // 升级回调
              }
            }
          }) {
            // 置灰的选择器预览
            this.buildStandardSelectorLocked()
          }
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
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}