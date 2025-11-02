/**
 * 频率加权场景展示组件
 * 用于显示频率加权模式的适用场景，面向普通用户
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { ApplicationScenario, FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct FrequencyScenarioDisplay {
  @Param @Require selectedWeighting: WeightingType;       // 选中的计权类型

  // 构建场景展示
  @Builder
  private buildScenarios() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('适用场景')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 场景列表
      ForEach(FrequencyWeightingConstants.APPLICATION_SCENARIOS[this.selectedWeighting], (scenario: ApplicationScenario, index) => {
        Row({ space: DesignConstants.SPACING_SM }) {
          // 场景图标
          Image($r('sys.media.ohos_ic_public_select_all'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.confirm'))
            .margin({ right: DesignConstants.SPACING_XS })

          // 场景描述
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(scenario.title)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)

            Text(scenario.description)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .alignSelf(ItemAlign.Start)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding({ 
          top: index > 0 ? DesignConstants.SPACING_SM : 0,
          bottom: DesignConstants.SPACING_XS 
        })
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      this.buildScenarios()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}