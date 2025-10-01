/**
 * 频率加权预览面板组件
 * 用于显示频率加权模式的实时预览信息，包括参数对比和响应特性
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { FrequencyResponseChartComponent } from './FrequencyResponseChartComponent';

@ComponentV2
export struct FrequencyPreviewPanel {
  @Param @Require currentWeighting: WeightingType; // 当前计权类型
  @Param @Require selectedWeighting: WeightingType; // 选中的计权类型

  // 构建响应曲线预览
  @Builder
  private buildResponseCurve() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 使用频率响应曲线组件
      FrequencyResponseChartComponent({ selectedWeighting: this.selectedWeighting })
        .width('100%')
        .height(160)

      // 曲线说明
      Text(this.getCurveDescription())
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
        .margin({ top: DesignConstants.SPACING_SM })

    }
    .width('100%')
  }

  // 获取曲线描述
  private getCurveDescription(): string {
    switch (this.selectedWeighting) {
      case WeightingType.A:
        return 'A计权：模拟人耳听觉特性，对低频和高频进行衰减，适合环境噪声评估';
      case WeightingType.C:
        return 'C计权：对低频衰减较少，适合高声压级噪声测量和机械噪声分析';
      case WeightingType.Z:
        return 'Z计权：平坦频率响应，无频率加权，适合声学研究和原始数据分析';
      default:
        return '';
    }
  }

  // 构建计权类型对比信息
  @Builder
  private buildWeightingComparison() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('计权类型对比')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      if (this.currentWeighting === this.selectedWeighting) {
        Text('当前已选择此计权类型')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.confirm'))
          .alignSelf(ItemAlign.Start)
      } else {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('当前:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(FrequencyWeightingConstants.getWeightingDisplayName(this.currentWeighting))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)

          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.font_secondary'))
            .margin({ left: DesignConstants.SPACING_XS, right: DesignConstants.SPACING_XS })

          Text('选择:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(FrequencyWeightingConstants.getWeightingDisplayName(this.selectedWeighting))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Bold)
        }
        .alignSelf(ItemAlign.Start)
      }

      // 简要描述
      Text(this.getBriefDescription())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
        .margin({ top: DesignConstants.SPACING_SM })

    }
    .width('100%')
  }

  // 获取简要描述
  private getBriefDescription(): string {
    switch (this.selectedWeighting) {
      case WeightingType.A:
        return '模拟人耳听觉特性，适合环境噪声和职业健康监测';
      case WeightingType.C:
        return '对低频衰减较少，适合工业噪声和机械振动分析';
      case WeightingType.Z:
        return '平坦响应，适合声学研究和设备校准';
      default:
        return '';
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 计权类型对比信息
      this.buildWeightingComparison()

      // 响应曲线预览
      this.buildResponseCurve()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}