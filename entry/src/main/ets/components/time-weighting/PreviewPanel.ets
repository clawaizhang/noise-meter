/**
 * 实时预览面板组件
 * 用于显示时间计权模式的实时预览信息，包括参数对比和响应特性
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { TimeResponseChartComponent } from './TimeResponseChartComponent';

@ComponentV2
export struct PreviewPanel {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式
  @Param @Require selectedMode: AudioAnalysisMode; // 选中的模式

  // 构建响应曲线预览
  @Builder
  private buildResponseCurve() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 使用新的时间响应曲线组件
      TimeResponseChartComponent({ selectedMode: this.selectedMode })
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
    switch (this.selectedMode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速响应特性：对瞬时信号有良好的跟踪能力，适合快速变化的噪声测量';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '平滑响应特性：减少瞬时波动，提供稳定的测量结果，适合稳态噪声';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲响应特性：快速上升缓慢下降，专门优化脉冲信号的检测';
      default:
        return '';
    }
  }

  // 构建模式对比信息
  @Builder
  private buildModeComparison() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('模式对比')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      if (this.currentMode === this.selectedMode) {
        Text('当前已选择此模式')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.confirm'))
          .alignSelf(ItemAlign.Start)
      } else {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('当前:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[this.currentMode])
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

          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[this.selectedMode])
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Bold)
        }
        .alignSelf(ItemAlign.Start)
      }

    }
    .width('100%')
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 模式对比信息
      this.buildModeComparison()

      // 响应曲线预览
      this.buildResponseCurve()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}