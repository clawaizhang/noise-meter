/**
 * 频率加权声学解释组件
 * 用于显示频率加权模式的声学理论解释和应用场景
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { AcousticExplanation,
  ApplicationScenario,
  FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct FrequencyAcousticExplanationComp {
  @Param @Require selectedWeighting: WeightingType;       // 选中的计权类型

  // 构建声学理论解释部分
  @Builder
  private buildAcousticTheory() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('声学理论解释')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 频率响应
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('• 频率响应:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].frequencyResponse)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 人耳模拟特性
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('• 人耳模拟:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].humanEarSimulation)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 标准依据
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('• 标准依据:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].standardReference)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 物理原理
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('• 物理原理:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].physicalPrinciple)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 衰减特性
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('• 衰减特性:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].attenuationCharacteristics)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 构建应用场景部分
  @Builder
  private buildApplicationScenarios() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('适用场景')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 场景列表
      ForEach(FrequencyWeightingConstants.APPLICATION_SCENARIOS[this.selectedWeighting], (scenario: ApplicationScenario, index: number) => {
        Column({ space: DesignConstants.SPACING_XS }) {
          // 场景标题
          Row({ space: DesignConstants.SPACING_XS }) {
            Text('•')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Bold)

            Text(scenario.title)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          // 场景描述
          Text(scenario.description)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .alignSelf(ItemAlign.Start)
            .margin({ left: DesignConstants.SPACING_MD })

          // 实际示例
          Row({ space: DesignConstants.SPACING_XS }) {
            Text('示例:')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .fontWeight(FontWeight.Medium)

            Text(scenario.example)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ left: DesignConstants.SPACING_MD })

        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: index > 0 ? DesignConstants.SPACING_SM : 0 })
      })

    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 声学理论解释
      this.buildAcousticTheory()

      // 应用场景
      this.buildApplicationScenarios()

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}