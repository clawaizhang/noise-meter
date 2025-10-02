/**
 * 改进的自动校准组件
 * 提供智能环境检测、可视化进度和实时反馈
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { curves, promptAction } from '@kit.ArkUI';
import { CALIBRATION_COLORS, EnvironmentNoiseLevel } from '../../constants/CalibrationConstants';

@ComponentV2
export struct ImprovedAutoCalibration {
  @Param @Require onStartCalibration: () => void;         // 开始校准回调
  @Param @Require calibrationValue: number = 0;           // 当前校准值
  @Param @Require isCalibrating: boolean = false;         // 是否正在校准
  @Param @Require calibrationProgress: number = 0;        // 校准进度
  @Param @Require countdown: number = 0;                  // 倒计时
  @Param @Require environmentNoise: number = 0;           // 环境噪声

  @Local private showEnvironmentCheck: boolean = false;   // 显示环境检查

  // 获取环境建议
  private getEnvironmentAdvice(): string {
    const level = this.getEnvironmentLevel();
    switch (level) {
      case EnvironmentNoiseLevel.EXCELLENT:
        return '环境非常适合校准';
      case EnvironmentNoiseLevel.GOOD:
        return '环境适合校准';
      case EnvironmentNoiseLevel.FAIR:
        return '环境一般，建议寻找更安静的地方';
      default:
        return '环境嘈杂，不适合校准';
    }
  }

  // 获取环境等级
  private getEnvironmentLevel(): EnvironmentNoiseLevel {
    if (this.environmentNoise < 30) {
      return EnvironmentNoiseLevel.EXCELLENT;
    } else if (this.environmentNoise < 40) {
      return EnvironmentNoiseLevel.GOOD;
    } else if (this.environmentNoise < 50) {
      return EnvironmentNoiseLevel.FAIR;
    } else {
      return EnvironmentNoiseLevel.POOR;
    }
  }

  // 检查是否适合校准
  private isSuitableForCalibration(): boolean {
    const level = this.getEnvironmentLevel();
    return level !== EnvironmentNoiseLevel.POOR;
  }

  // 构建环境检测面板
  @Builder
  private buildEnvironmentCheck() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(this.isSuitableForCalibration() ? 
            CALIBRATION_COLORS.SUCCESS : 
            CALIBRATION_COLORS.WARNING)

        Text('环境检测')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(`${this.environmentNoise.toFixed(1)}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }

      Text(this.getEnvironmentAdvice())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)

      if (!this.isSuitableForCalibration()) {
        Text('建议在夜间或安静的房间中进行校准')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(CALIBRATION_COLORS.WARNING)
          .textAlign(TextAlign.Start)
          .alignSelf(ItemAlign.Start)
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ bottom: DesignConstants.SPACING_MD })
  }

  // 构建校准进度显示
  @Builder
  private buildCalibrationProgress() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 进度环
      Stack({ alignContent: Alignment.Center }) {
        // 背景环
        Circle({ width: 60, height: 60 })
          .stroke($r('sys.color.background_secondary'))
          .strokeWidth(6)
          .fill(Color.Transparent)

        // 进度环
        Circle({ width: 60, height: 60 })
          .stroke(CALIBRATION_COLORS.PRIMARY)
          .strokeWidth(6)
          .fill(Color.Transparent)
          .strokeDashArray([this.calibrationProgress * 1.88, 188]) // 2πr ≈ 188
          .rotate({ x: 0, y: 0, z: 1, angle: -90 })
          .animation({
            duration: 200,
            curve: curves.springMotion()
          })

        // 进度文本
        Text(`${this.calibrationProgress}%`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(CALIBRATION_COLORS.PRIMARY)
      }

      // 状态描述
      if (this.countdown > 0) {
        Text(`${this.countdown}秒后开始校准...`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.WARNING)
      } else {
        Text(`校准中... ${8 - this.calibrationProgress}秒`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.PRIMARY)
      }

      Text('请保持设备稳定，避免发出声音')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 构建校准结果
  @Builder
  private buildCalibrationResult() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('sys.media.cheers'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(CALIBRATION_COLORS.SUCCESS)

        Text('校准完成')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(CALIBRATION_COLORS.SUCCESS)
      }

      Text(`新校准值: ${this.calibrationValue.toFixed(1)}dB`)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Bold)

      Text('自动校准已完成，测量精度已优化')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 构建主按钮
  @Builder
  private buildMainButton() {
    if (this.isCalibrating) {
      // 校准中状态
      this.buildCalibrationProgress()
    } else {
      // 准备校准状态
      Button('开始自动校准', { type: ButtonType.Normal })
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(CALIBRATION_COLORS.PRIMARY)
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_LG)
        .height(48)
        .width('100%')
        .onClick(async () => {
          // 环境检查
          if (!this.isSuitableForCalibration()) {
            const result = await promptAction.showDialog({
              title: '环境嘈杂提示',
              message: '当前环境噪声较高，可能影响校准精度。是否继续？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_secondary')
                },
                {
                  text: '继续校准',
                  color: CALIBRATION_COLORS.PRIMARY
                }
              ]
            });

            if (result.index !== 1) {
              return;
            }
          }

          // 开始校准确认
          const confirmResult = await promptAction.showDialog({
            title: '自动校准提示',
            message: '请在安静环境中进行校准，校准过程中请保持设备稳定。',
            buttons: [
              {
                text: '取消',
                color: $r('sys.color.font_secondary')
              },
              {
                text: '开始校准',
                color: CALIBRATION_COLORS.PRIMARY
              }
            ]
          });

          if (confirmResult.index === 1) {
            this.onStartCalibration();
          }
        })
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题区域
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_calibration'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text('自动校准')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        if (!this.isCalibrating && this.calibrationValue !== 0) {
          Text(`${this.calibrationValue.toFixed(1)}dB`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 环境检测
      this.buildEnvironmentCheck()

      // 主按钮区域
      this.buildMainButton()

      // 说明文本
      Text('自动计算并设置最佳校准值，确保测量准确性。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(CALIBRATION_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
    .animation({
      duration: 300,
      curve: curves.springMotion()
    })
  }
}