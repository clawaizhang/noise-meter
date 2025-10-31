/**
 * 统一健康影响主界面
 * 整合警报和影响功能的最终界面，提供完整的健康风险评估和监测
 */

import { HealthImpactData, HealthRiskLevel, SpecialNoiseDetection, SpecialNoiseType, DEFAULT_HEALTH_IMPACT_DATA } from "../../models/HealthImpactData";
import { HealthRiskDisplay } from "./HealthRiskDisplay";
import { SpecialNoiseCard } from "./SpecialNoiseCard";


@ComponentV2
export struct UnifiedHealthImpactDashboard {
  @Local private healthData: HealthImpactData = DEFAULT_HEALTH_IMPACT_DATA;
  @Local private currentDecibel: number = 65.5;
  @Local private minDecibel: number = 45.2;
  @Local private avgDecibel: number = 62.8;
  @Local private maxDecibel: number = 85.7;
  @Local private noiseDescription: string = '正常交谈水平';
  @Local private specialNoises: SpecialNoiseDetection[] = [];

  aboutToAppear(): void {
    // 初始化模拟数据
    this.initializeMockData();
  }

  /**
   * 初始化模拟数据用于测试界面显示
   */
  private initializeMockData(): void {
    // 创建特殊噪音检测数据
    const impulseNoise = new SpecialNoiseDetection(
      SpecialNoiseType.IMPULSE,
      25,
      150,
      0
    );

    const lowFrequencyNoise = new SpecialNoiseDetection(
      SpecialNoiseType.LOW_FREQUENCY,
      65,
      30000,
      125
    );

    const combinedNoise = new SpecialNoiseDetection(
      SpecialNoiseType.COMBINED,
      45,
      7200000, // 2小时
      0
    );

    this.specialNoises = [impulseNoise, lowFrequencyNoise, combinedNoise];

    // 更新健康影响数据
    this.healthData.update(35, this.currentDecibel, impulseNoise);
  }

  /**
   * 获取分贝值对应的颜色
   */
  private getDecibelColor(): Resource {
    if (this.currentDecibel < 60) {
      return $r('sys.color.confirm'); // 绿色
    } else if (this.currentDecibel < 80) {
      return $r('sys.color.warning'); // 黄色
    } else if (this.currentDecibel < 100) {
      return $r('sys.color.alert'); // 橙色
    } else {
      return $r('sys.color.alert'); // 红色
    }
  }

  /**
   * 获取噪音描述
   */
  private getNoiseDescription(decibel: number): string {
    if (decibel < 30) return '非常安静';
    if (decibel < 50) return '安静环境';
    if (decibel < 60) return '轻声交谈';
    if (decibel < 70) return '正常交谈';
    if (decibel < 80) return '较吵环境';
    if (decibel < 90) return '吵闹环境';
    if (decibel < 100) return '非常吵闹';
    return '危险噪音';
  }

  /**
   * 渲染实时噪音监测区
   */
  @Builder
  private renderRealTimeMonitor() {
    Column({ space: 16 }) {
      // 主分贝显示区域
      Row({ space: 16 }) {
        // 麦克风图标
        Column({ space: 4 }) {
          Image($r('app.media.ic_mic'))
            .width(24)
            .height(24)
            .fillColor($r('sys.color.icon_primary'))
          Text('实时')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Center)

        // 分贝数值和描述
        Column({ space: 4 }) {
          Text(`${this.currentDecibel.toFixed(1)} dB`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getDecibelColor())

          Text(this.noiseDescription)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height(60)

      // 统计数据行
      Row({ space: 24 }) {
        Column({ space: 2 }) {
          Text('最小')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.minDecibel.toFixed(1)}dB`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text('平均')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.avgDecibel.toFixed(1)}dB`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text('最大')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.maxDecibel.toFixed(1)}dB`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
    .onClick(() => {
      console.log('实时噪音监测区被点击');
      // 这里可以添加跳转到详细实时数据页面的逻辑
    })
  }

  /**
   * 渲染特殊噪音检测区 - 使用SpecialNoiseCard组件
   */
  @Builder
  private renderSpecialNoiseDetection() {
    Column({ space: 12 }) {
      // 标题行
      Row({ space: 8 }) {
        Image($r('app.media.ic_filter'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.icon_primary'))
        Text('特殊噪音检测')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 使用SpecialNoiseCard组件显示特殊噪音检测结果
      Column({ space: 12 }) {
        ForEach(this.specialNoises, (noise: SpecialNoiseDetection) => {
          SpecialNoiseCard({ specialNoiseDetection: noise })
        })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
  }


  /**
   * 渲染快速操作卡片区
   */
  @Builder
  private renderQuickActions() {
    Column({ space: 12 }) {
      // 标题行
      Row({ space: 8 }) {
        Image($r('app.media.ic_atom'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.icon_primary'))
        Text('快速操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 操作卡片网格
      Row({ space: 12 }) {
        // 历史趋势卡片
        Column({ space: 8 }) {
          Image($r('app.media.ic_history'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.icon_primary'))
          Text('历史趋势')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
          Text('查看分析')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .padding(12)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .borderRadius(12)
        .border({
          width: 1,
          color: $r('sys.color.comp_border_color')
        })
        .width('23%')
        .height(80)
        .onClick(() => {
          console.log('历史趋势卡片被点击');
          // 这里可以添加跳转到历史趋势页面的逻辑
        })

        // 警报设置卡片
        Column({ space: 8 }) {
          Image($r('app.media.ic_alarm'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.icon_primary'))
          Text('警报设置')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
          Text('个性化')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .padding(12)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .borderRadius(12)
        .border({
          width: 1,
          color: $r('sys.color.comp_border_color')
        })
        .width('23%')
        .height(80)
        .onClick(() => {
          console.log('警报设置卡片被点击');
          // 这里可以添加打开警报设置弹窗的逻辑
        })

        // 健康报告卡片
        Column({ space: 8 }) {
          Image($r('app.media.ic_document_edit'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.icon_primary'))
          Text('健康报告')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
          Text('生成报告')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .padding(12)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .borderRadius(12)
        .border({
          width: 1,
          color: $r('sys.color.comp_border_color')
        })
        .width('23%')
        .height(80)
        .onClick(() => {
          console.log('健康报告卡片被点击');
          // 这里可以添加生成健康报告的逻辑
        })

        // 场景建议卡片
        Column({ space: 8 }) {
          Image($r('app.media.ic_info'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.icon_primary'))
          Text('场景建议')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
          Text('智能推荐')
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Center)
        }
        .padding(12)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(12)
        .border({
          width: 1,
          color: $r('sys.color.comp_border_color')
        })
        .width('23%')
        .height(80)
        .onClick(() => {
          console.log('场景建议卡片被点击');
          // 这里可以添加显示场景建议的逻辑
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 健康影响等级展示区 - 使用现有组件
        HealthRiskDisplay({ healthData: this.healthData })

        // 实时噪音监测区
        this.renderRealTimeMonitor()

        // 特殊噪音检测区
        this.renderSpecialNoiseDetection()

        // 快速操作卡片区
        this.renderQuickActions()
      }
      .padding(16)
      .width('100%')
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}