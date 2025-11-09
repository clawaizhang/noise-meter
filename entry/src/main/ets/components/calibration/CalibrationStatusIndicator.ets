/**
 * 校准状态指示器组件
 * 显示环形进度、环境噪声水平和实时状态反馈
 */

import { CALIBRATION_COLORS, EnvironmentNoiseLevel } from '../../constants/CalibrationConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct CalibrationStatusIndicator {
  @Param @Require currentDecibel: number = 0;             // 当前声级


  // 获取环境噪声等级
  private getEnvironmentLevel(): EnvironmentNoiseLevel {
    if (this.currentDecibel < 20) {
      return EnvironmentNoiseLevel.EXCELLENT;
    } else if (this.currentDecibel < 25) {
      return EnvironmentNoiseLevel.GOOD;
    } else if (this.currentDecibel < 30) {
      return EnvironmentNoiseLevel.FAIR;
    } else {
      return EnvironmentNoiseLevel.POOR;
    }
  }

  // 获取环境颜色
  private getEnvironmentColor(): Resource {
    const level = this.getEnvironmentLevel();
    switch (level) {
      case EnvironmentNoiseLevel.EXCELLENT:
        return CALIBRATION_COLORS.SUCCESS;
      case EnvironmentNoiseLevel.GOOD:
        return $r('sys.color.ohos_id_color_palette5'); // 浅绿色
      case EnvironmentNoiseLevel.FAIR:
        return CALIBRATION_COLORS.WARNING;
      default:
        return CALIBRATION_COLORS.ERROR;
    }
  }

  // 获取环境描述
  private getEnvironmentDescription(): string {
    const level = this.getEnvironmentLevel();
    switch (level) {
      case EnvironmentNoiseLevel.EXCELLENT:
        return '环境优秀';
      case EnvironmentNoiseLevel.GOOD:
        return '环境良好';
      case EnvironmentNoiseLevel.FAIR:
        return '环境一般';
      default:
        return '环境嘈杂';
    }
  }


  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 环境噪声指示器
      Stack({ alignContent: Alignment.Center }) {
        // 环境噪声环
        Circle({ width: 80, height: 80 })
          .stroke(this.getEnvironmentColor())
          .strokeWidth(8)
          .fill(Color.Transparent)

        // 中心数值
        Column({ space: 2 }) {
          Text(`${this.currentDecibel.toFixed(1)}`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Text('dB')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
      }

      // 环境描述
      Text(this.getEnvironmentDescription())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.getEnvironmentColor())
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(CALIBRATION_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}