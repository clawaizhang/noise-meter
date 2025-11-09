/**
 * 频率加权技术参数显示组件
 * 用于显示频率加权模式的技术参数，支持参数对比
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

// 参数变化指示类型
enum ParamChangeType {
  INCREASE = 'increase', // 增加
  DECREASE = 'decrease', // 减少
  SAME = 'same' // 相同
}

// 参数项接口
interface ParamItem {
  label: string; // 参数标签
  value: string; // 参数值
  changeType: ParamChangeType; // 变化类型
}

@ComponentV2
export struct FrequencyTechnicalParamsDisplay {
  @Param @Require currentWeighting: WeightingType; // 当前计权类型
  @Param @Require selectedWeighting: WeightingType; // 选中的计权类型

  // 获取参数变化类型
  private getParamChangeType(currentValue: string, newValue: string): ParamChangeType {
    if (currentValue === newValue) {
      return ParamChangeType.SAME;
    }
    // 对于频率加权参数，主要判断是否有衰减变化
    if (newValue.includes('无衰减') && !currentValue.includes('无衰减')) {
      return ParamChangeType.INCREASE;
    } else if (currentValue.includes('无衰减') && !newValue.includes('无衰减')) {
      return ParamChangeType.DECREASE;
    }
    return ParamChangeType.SAME;
  }

  // 获取参数变化颜色
  private getChangeColor(changeType: ParamChangeType): Resource {
    switch (changeType) {
      case ParamChangeType.INCREASE:
        return $r('app.color.warning');
      case ParamChangeType.DECREASE:
        return $r('app.color.confirm');
      default:
        return $r('app.color.font_secondary');
    }
  }

  // 获取参数变化图标
  private getChangeIcon(changeType: ParamChangeType): Resource {
    switch (changeType) {
      case ParamChangeType.INCREASE:
        return $r('sys.media.ohos_ic_public_arrow_up');
      case ParamChangeType.DECREASE:
        return $r('sys.media.ohos_ic_public_arrow_down');
      default:
        return $r('sys.media.ohos_ic_public_minus');
    }
  }

  // 构建参数项
  @Builder
  private buildParamItem(param: ParamItem) {
    Row({ space: DesignConstants.SPACING_XS }) {
      // 参数标签
      Text(param.label)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.font_secondary'))
        .layoutWeight(1)

      // 参数值
      Text(param.value)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.font_primary'))
        .fontWeight(FontWeight.Medium)

      // 变化指示器
      if (param.changeType !== ParamChangeType.SAME) {
        Image(this.getChangeIcon(param.changeType))
          .width(DesignConstants.ICON_SIZE_XS)
          .height(DesignConstants.ICON_SIZE_XS)
          .fillColor(this.getChangeColor(param.changeType))
          .margin({ left: DesignConstants.SPACING_XS })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 获取技术参数列表
  private getTechnicalParams(): ParamItem[] {
    const currentParams = FrequencyWeightingConstants.TECHNICAL_PARAMS[this.currentWeighting];
    const selectedParams = FrequencyWeightingConstants.TECHNICAL_PARAMS[this.selectedWeighting];

    return [
      {
        label: '频率范围',
        value: selectedParams.frequencyRange,
        changeType: this.getParamChangeType(currentParams.frequencyRange, selectedParams.frequencyRange)
      },
      {
        label: '低频衰减',
        value: selectedParams.lowFreqAttenuation,
        changeType: this.getParamChangeType(currentParams.lowFreqAttenuation, selectedParams.lowFreqAttenuation)
      },
      {
        label: '高频衰减',
        value: selectedParams.highFreqAttenuation,
        changeType: this.getParamChangeType(currentParams.highFreqAttenuation, selectedParams.highFreqAttenuation)
      },
      {
        label: '平坦响应',
        value: selectedParams.flatResponseRange,
        changeType: this.getParamChangeType(currentParams.flatResponseRange, selectedParams.flatResponseRange)
      },
      {
        label: '参考频率',
        value: `${selectedParams.referenceFreq}Hz`,
        changeType: this.getParamChangeType(
          `${currentParams.referenceFreq}Hz`,
          `${selectedParams.referenceFreq}Hz`
        )
      }
    ];
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Row() {
        Text('技术参数')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .layoutWeight(1)

        if (this.currentWeighting !== this.selectedWeighting) {
          Text('与当前模式对比')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('app.color.font_secondary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 参数网格
      GridRow({
        columns: { sm: 1, md: 2 },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: { x: DesignConstants.SPACING_MD, y: DesignConstants.SPACING_SM }
      }) {
        ForEach(this.getTechnicalParams(), (param: ParamItem, index: number) => {
          GridCol({ span: 1 }) {
            this.buildParamItem(param)
          }
        })
      }
      .width('100%')

      // 标准依据信息
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('标准依据:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.font_secondary'))

        Text(FrequencyWeightingConstants.ACOUSTIC_EXPLANATIONS[this.selectedWeighting].standardReference)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: DesignConstants.SPACING_SM })

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}