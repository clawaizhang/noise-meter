/**
 * 健康暴露卡片组件
 * 用于主页显示今日噪音暴露统计概览
 * 作为暴露统计详情的入口
 */

import { ExposureData } from '../../models/ExposureData';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { EnhancedExposureContent } from './EnhancedExposureContent';
import common from '@ohos.app.ability.common';
import {
  NoiseExposureStandard,
  StandardConfigs
} from '../../constants/ExposureStandardConstants';

const TAG = 'HealthExposureCard';
const DOMAIN = 0xFF00;

@ComponentV2
export struct HealthExposureCard {
  // 服务实例
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();

  // 状态
  @Local private isLoading: boolean = true;
  @Local private exposureData: ExposureData = new ExposureData();
  @Local private refreshTimer: number = 0;

  aboutToAppear(): void {
    // 设置上下文
    const context = getContext(this) as common.UIAbilityContext;
    this.exposureService.setContext(context);

    this.loadData();
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
      // 使用社交标准作为默认标准
      const data = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);
      this.exposureData = data;

      hilog.info(DOMAIN, TAG, `加载暴露数据: 百分比=${data.exposurePercentage}%, 峰值=${data.todayPeak}dB`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载暴露数据失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 启动自动刷新定时器
   */
  private startRefreshTimer(): void {
    this.refreshTimer = setInterval(() => {
      this.refreshData();
    }, 30000); // 每30秒刷新一次（暴露统计不需要太频繁）
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
      const data = await this.exposureService.calculateTodayExposure(NoiseExposureStandard.SOCIAL);
      this.exposureData = data;
    } catch (error) {
      console.error('[HealthExposureCard] 刷新数据失败:', error);
    }
  }

  /**
   * 打开暴露统计详情页
   */
  private openExposureDetail(): void {
    let exposureDialog: InfSheet = DialogHub.getSheet()
      .setStyle({
        title: { title: '噪音暴露分析' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ExposureContentBuilder))
      .build();
    exposureDialog.show();
  }

  /**
   * 获取暴露状态颜色
   */
  private getExposureColor(): Resource {
    if (this.exposureData.exposurePercentage < 30) {
      return $r('sys.color.confirm'); // 绿色 - 安全
    } else if (this.exposureData.exposurePercentage < 60) {
      return $r('sys.color.warning'); // 黄色 - 警告
    } else if (this.exposureData.exposurePercentage < 100) {
      return $r('sys.color.alert'); // 红色 - 危险
    }
    return $r('sys.color.alert'); // 深红色 - 严重超标
  }

  /**
   * 获取健康状态文本
   */
  private getHealthStatus(): string {
    if (this.exposureData.exposurePercentage < 30) {
      return '状态良好';
    } else if (this.exposureData.exposurePercentage < 60) {
      return '轻度影响';
    } else if (this.exposureData.exposurePercentage < 100) {
      return '影响较高';
    }
    return '严重超标';
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row() {
        Text('📊 今日健康暴露')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()

        // 查看详情按钮
        Row({ space: DesignConstants.SPACING_XS }) {
          Text('详细分析')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.brand'))

          Image($r('app.media.ic_arrow_right'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.brand'))
        }
        .onClick(() => {
          Throttle.click(() => this.openExposureDetail());
        })
      }
      .width('100%')

      // 核心内容区
      Row({ space: DesignConstants.SPACING_LG }) {
        // 左侧：环形进度指示器
        Stack({ alignContent: Alignment.Center }) {
          // 背景环
          Circle({ width: 80, height: 80 })
            .stroke($r('sys.color.comp_background_tertiary'))
            .strokeWidth(8)
            .fill(Color.Transparent)

          // 进度环（简化版，用透明度模拟）
          Circle({ width: 80, height: 80 })
            .stroke(this.getExposureColor())
            .strokeWidth(8)
            .fill(Color.Transparent)
            .opacity(this.exposureData.exposurePercentage > 0 ? 1 : 0.3)

          // 中心内容
          Column({ space: 2 }) {
            Text(`${this.exposureData.exposurePercentage}%`)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getExposureColor())

            Text('暴露剂量')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
        }
        .width(80)
        .height(80)

        // 右侧：关键指标
        Column({ space: DesignConstants.SPACING_SM }) {
          // 健康状态
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('健康状态')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))

            Text(this.getHealthStatus())
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getExposureColor())
          }
          .width('100%')

          // 剩余安全时间
          if (this.exposureData.remainingSafeTime) {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('剩余时间')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))

              Text(this.exposureData.remainingSafeTime)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
            }
            .width('100%')
          }

          // 今日峰值
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('今日峰值')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))

            Text(`${this.exposureData.todayPeak.toFixed(0)}dB`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })

      // 底部提示
      if (this.exposureData.exposurePercentage >= 60) {
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_info'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.alert'))

          Text('噪音暴露较高，建议减少在嘈杂环境的时间')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.alert'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.alert').toString() + '15') // 15% 透明度
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      } else if (this.exposureData.exposurePercentage === 0) {
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_info'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.font_secondary'))

          Text('今日暂无检测数据，开始检测以查看暴露分析')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
      }

      // 加载指示器
      if (this.isLoading) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color($r('sys.color.font_tertiary'))
      }
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

// 暴露内容Builder
@Builder
function ExposureContentBuilder() {
  EnhancedExposureContent()
}
