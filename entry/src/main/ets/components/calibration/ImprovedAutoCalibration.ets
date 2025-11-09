/**
 * 改进的自动校准组件
 * 提供智能环境检测、可视化进度和实时反馈
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { curves, promptAction } from '@kit.ArkUI';
import { CALIBRATION_COLORS } from '../../constants/CalibrationConstants';
import { PremiumFeature } from '../membership/PremiumFeature';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct ImprovedAutoCalibration {
  @Event onStartCalibration: () => void; // 开始校准回调
  @Param @Require calibrationValue: number = 0; // 当前校准值
  @Param @Require isCalibrating: boolean = false; // 是否正在校准
  @Param @Require calibrationProgress: number = 0; // 校准进度
  @Param @Require countdown: number = 0; // 倒计时
  @Param @Require environmentNoise: number = 0; // 环境噪声

  // 检查是否适合校准
  private isSuitableForCalibration(): boolean {
    return this.environmentNoise <= 25; // 只在<=25dB环境中允许自动校准
  }

  // 构建环境检测面板
  @Builder
  private buildEnvironmentCheck() {
    Column({ space: DesignConstants.SPACING_SM }) {
      if (this.environmentNoise < 20) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('sys.media.ohos_ic_public_ok')) // 成功图标
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(CALIBRATION_COLORS.SUCCESS)
          Text('环境非常适合自动校准')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(CALIBRATION_COLORS.SUCCESS)
        }

        Text('当前环境非常安静（<20dB），可获得最佳精度')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.font_secondary'))
      } else if (this.environmentNoise < 25) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('sys.media.ohos_ic_public_ok'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(CALIBRATION_COLORS.SUCCESS)
          Text('环境适合自动校准')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(CALIBRATION_COLORS.SUCCESS)
        }

        Text('当前环境适合自动校准（20-25dB）')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.font_secondary'))
      } else if (this.environmentNoise < 30) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('sys.media.ohos_ic_public_close')) // 警告图标
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(CALIBRATION_COLORS.WARNING)
          Text('环境一般')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(CALIBRATION_COLORS.WARNING)
        }

        Text('建议寻找更安静的环境（当前25-30dB）')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.font_secondary'))
      } else {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('sys.media.ohos_ic_public_close')) // 错误图标
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(CALIBRATION_COLORS.ERROR)
          Text('环境不适合自动校准')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(CALIBRATION_COLORS.ERROR)
        }

        Text('环境嘈杂（>30dB），建议在安静环境中校准')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.font_secondary'))
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.comp_background_primary'))
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
          .stroke($r('app.color.background_secondary'))
          .strokeWidth(6)
          .fill(Color.Transparent)

        // 进度环
        Circle({ width: 60, height: 60 })
          .stroke(CALIBRATION_COLORS.PRIMARY)
          .strokeWidth(6)
          .fill(Color.Transparent)
          .strokeDashArray([this.calibrationProgress * 1.88, 188]) // 2πr ≈ 188
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: -90
          })
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
        Text(`校准中... 剩余 ${Math.ceil(8 - (this.calibrationProgress / 100 * 8))}秒`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.PRIMARY)
      }

      Text('请保持设备稳定，避免发出声音')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_secondary'))
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
        .fontColor($r('app.color.font_primary'))
        .fontWeight(FontWeight.Bold)

      Text('自动校准已完成，测量精度已优化')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.font_secondary'))
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
        .backgroundColor($r('app.color.comp_background_tertiary'))
        .fontColor($r('app.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_LG)
        .height(48)
        .width('100%')
        .onClick(async () => {
          Throttle.click(async () => {
            // 环境检查
            if (!this.isSuitableForCalibration()) {
              const result = await promptAction.showDialog({
                title: '环境嘈杂提示',
                message: '当前环境噪声较高，可能影响校准精度。是否继续？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('app.color.font_secondary')
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
                  color: $r('app.color.font_secondary')
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
          .fillColor($r('app.color.brand'))

        Text('自动校准')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .layoutWeight(1)

        if (!this.isCalibrating && this.calibrationValue !== 0) {
          Text(`${this.calibrationValue.toFixed(1)}dB`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('app.color.font_secondary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 环境检测 - 只在非校准状态下显示
      if (!this.isCalibrating) {
        this.buildEnvironmentCheck()
      }

      // 主按钮区域
      PremiumFeature({ featureName: '自动校准', featureDesc: '自动计算并设置最佳校准值，确保测量准确性。' }) {
        this.buildMainButton()
      }

      // 说明文本
      Text('自动计算并设置最佳校准值，确保测量准确性。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.font_secondary'))
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