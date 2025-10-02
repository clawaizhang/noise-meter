/**
 * 校准状态指示器组件
 * 显示环形进度、环境噪声水平和实时状态反馈
 */

import { CALIBRATION_COLORS, EnvironmentNoiseLevel } from '../../constants/CalibrationConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct CalibrationStatusIndicator {
  @Param @Require calibrationProgress: number = 0;        // 校准进度 0-100
  @Param @Require currentDecibel: number = 0;             // 当前声级
  @Param @Require isCalibrating: boolean = false;         // 是否正在校准

  @Local private animationTime: number = 0;               // 动画时间状态
  private animationInterval?: number;                     // 动画定时器

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

  // 启动动画定时器
  private startAnimation() {
    this.animationInterval = setInterval(() => {
      this.animationTime = Date.now();
    }, 100); // 每100ms更新一次
  }

  // 停止动画定时器
  private stopAnimation() {
    if (this.animationInterval) {
      clearInterval(this.animationInterval);
      this.animationInterval = undefined;
    }
  }

  aboutToAppear() {
    this.startAnimation();
  }

  aboutToDisappear() {
    this.stopAnimation();
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 外环 - 校准进度
      Stack({ alignContent: Alignment.Center }) {
        // 背景环
        Circle({ width: 80, height: 80 })
          .stroke(CALIBRATION_COLORS.BACKGROUND)
          .strokeWidth(8)
          .fill(Color.Transparent)

        // 进度环
        Circle({ width: 80, height: 80 })
          .stroke(CALIBRATION_COLORS.PRIMARY)
          .strokeWidth(8)
          .fill(Color.Transparent)
          .strokeDashArray([this.calibrationProgress * 2.51, 251]) // 2πr ≈ 251
          .rotate({ x: 0, y: 0, z: 1, angle: -90 })
          .animation({
            duration: 300,
            curve: curves.springMotion()
          })

        // 内环 - 环境噪声
        Circle({ width: 60, height: 60 })
          .stroke(this.getEnvironmentColor())
          .strokeWidth(6)
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

      // 状态描述
      Column({ space: DesignConstants.SPACING_XS }) {
        if (this.isCalibrating) {
          Text(`校准中 ${this.calibrationProgress}%`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(CALIBRATION_COLORS.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(CALIBRATION_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}