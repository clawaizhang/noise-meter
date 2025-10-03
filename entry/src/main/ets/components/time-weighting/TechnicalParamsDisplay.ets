/**
 * 技术参数显示组件
 * 用于显示音频分析模式的技术参数，支持参数对比
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

// 参数变化指示类型
enum ParamChangeType {
  INCREASE = 'increase',    // 增加
  DECREASE = 'decrease',    // 减少
  SAME = 'same'             // 相同
}

// 参数项接口
interface ParamItem {
  label: string;           // 参数标签
  value: number;           // 参数值
  unit: string;            // 参数单位
  changeType: ParamChangeType; // 变化类型
}

@ComponentV2
export struct TechnicalParamsDisplay {
  @Param @Require currentMode: AudioAnalysisMode;        // 当前模式
  @Param @Require selectedMode: AudioAnalysisMode;       // 选中的模式

  // 获取参数变化类型
  private getParamChangeType(currentValue: number, newValue: number): ParamChangeType {
    if (currentValue === newValue) {
      return ParamChangeType.SAME;
    }
    return newValue > currentValue ? ParamChangeType.INCREASE : ParamChangeType.DECREASE;
  }

  // 获取参数变化颜色
  private getChangeColor(changeType: ParamChangeType): Resource {
    switch (changeType) {
      case ParamChangeType.INCREASE:
        return $r('sys.color.warning');
      case ParamChangeType.DECREASE:
        return $r('sys.color.confirm');
      default:
        return $r('sys.color.font_secondary');
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
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)

      // 参数值
      Text(`${param.value}${param.unit}`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
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
    const currentParams = TimeWeightingConstants.TECHNICAL_PARAMS[this.currentMode];
    const selectedParams = TimeWeightingConstants.TECHNICAL_PARAMS[this.selectedMode];

    return [
      {
        label: 'FFT大小',
        value: selectedParams.fftSize,
        unit: '',
        changeType: this.getParamChangeType(currentParams.fftSize, selectedParams.fftSize)
      },
      {
        label: '更新间隔',
        value: selectedParams.updateInterval,
        unit: 'ms',
        changeType: this.getParamChangeType(currentParams.updateInterval, selectedParams.updateInterval)
      },
      {
        label: '频率分辨率',
        value: selectedParams.frequencyResolution,
        unit: 'Hz',
        changeType: this.getParamChangeType(currentParams.frequencyResolution, selectedParams.frequencyResolution)
      },
      {
        label: '时间分辨率',
        value: selectedParams.timeResolution,
        unit: 'ms',
        changeType: this.getParamChangeType(currentParams.timeResolution, selectedParams.timeResolution)
      },
      {
        label: '重叠率',
        value: Math.round(selectedParams.overlapRate * 100),
        unit: '%',
        changeType: this.getParamChangeType(currentParams.overlapRate * 100, selectedParams.overlapRate * 100)
      },
      {
        label: '缓冲区',
        value: selectedParams.bufferSize,
        unit: '字节',
        changeType: this.getParamChangeType(currentParams.bufferSize, selectedParams.bufferSize)
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
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        if (this.currentMode !== this.selectedMode) {
          Text('与当前模式对比')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 参数网格
      GridRow({
        columns: { sm: 2, md: 3 },
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

      // 窗函数信息
      if (this.currentMode !== this.selectedMode) {
        Row({ space: DesignConstants.SPACING_XS }) {
          Text('窗函数:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(TimeWeightingConstants.TECHNICAL_PARAMS[this.selectedMode].windowType)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: DesignConstants.SPACING_SM })
      }

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}