/**
 * 增强型手动校准组件
 * 提供可视化滑动条、预设点和实时反馈
 */

import { CALIBRATION_COLORS, CALIBRATION_CONFIG } from '../../constants/CalibrationConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct EnhancedManualCalibration {
  @Param @Require calibrationValue: number = 0;           // 当前校准值
  @Param @Require onValueChange: (value: number) => void; // 值变化回调

  @Local private isDragging: boolean = false;             // 是否正在拖拽
  @Local private showValueTip: boolean = false;           // 是否显示数值提示

  // 检查是否为预设点
  private isPresetValue(value: number): boolean {
    return CALIBRATION_CONFIG.PRESET_VALUES.includes(value);
  }

  // 获取最接近的预设点
  private getNearestPresetValue(value: number): number {
    const presets = CALIBRATION_CONFIG.PRESET_VALUES;
    return presets.reduce((prev, curr) => {
      return Math.abs(curr - value) < Math.abs(prev - value) ? curr : prev;
    });
  }

  // 构建预设点标记
  @Builder
  private buildPresetMarks() {
    Row({ space: 0 }) {
      ForEach(CALIBRATION_CONFIG.PRESET_VALUES, (preset: number) => {
        Column({ space: 4 }) {
          // 预设点标记
          Circle({ width: 6, height: 6 })
            .fill(this.isPresetValue(this.calibrationValue) && this.calibrationValue === preset ?
              CALIBRATION_COLORS.PRIMARY :
              $r('sys.color.font_tertiary'))
          
          // 预设值标签
          Text(preset.toString())
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      })
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_SM })
  }

  // 构建数值显示
  @Builder
  private buildValueDisplay() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('当前校准值:')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))

      Text(`${this.calibrationValue.toFixed(1)}dB`)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor(CALIBRATION_COLORS.PRIMARY)
        .fontWeight(FontWeight.Bold)
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })

      // 预设点指示
      if (this.isPresetValue(this.calibrationValue)) {
        Text('预设点')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(CALIBRATION_COLORS.SUCCESS)
          .backgroundColor($r('sys.color.background_emphasize'))
          .borderRadius(DesignConstants.BORDER_RADIUS_XS)
          .padding({
            left: DesignConstants.SPACING_SM,
            right: DesignConstants.SPACING_SM,
            top: 2,
            bottom: 2
          })
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  // 构建快速操作按钮
  @Builder
  private buildQuickActions() {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 快速重置按钮
      Button('重置为0', { type: ButtonType.Normal })
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          this.onValueChange(0);
        })

      // 吸附到预设点按钮
      Button('吸附预设点', { type: ButtonType.Normal })
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor(CALIBRATION_COLORS.PRIMARY)
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .height(32)
        .layoutWeight(1)
        .onClick(() => {
          const nearestPreset = this.getNearestPresetValue(this.calibrationValue);
          this.onValueChange(nearestPreset);
        })
    }
    .width('100%')
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题区域
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_calibration'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text('手动校准')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text('精确调整')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 数值显示
      this.buildValueDisplay()

      // 增强型滑动条
      Column({ space: DesignConstants.SPACING_SM }) {
        Slider({
          value: this.calibrationValue,
          min: CALIBRATION_CONFIG.MIN_CALIBRATION_VALUE,
          max: CALIBRATION_CONFIG.MAX_CALIBRATION_VALUE,
          step: 0.1,
          style: SliderStyle.InSet
        })
          .blockColor(CALIBRATION_COLORS.PRIMARY)
          .trackColor($r('sys.color.background_secondary'))
          .selectedColor(CALIBRATION_COLORS.PRIMARY)
          .showTips(true)
          .onChange((value: number) => {
            this.onValueChange(value);
          })
          .onDragStart(() => {
            this.isDragging = true;
            this.showValueTip = true;
          })
          .onDragEnd(() => {
            this.isDragging = false;
            this.showValueTip = false;
            
            // 拖拽结束时自动吸附到最近的预设点
            const nearestPreset = this.getNearestPresetValue(this.calibrationValue);
            if (Math.abs(this.calibrationValue - nearestPreset) <= 1) {
              this.onValueChange(nearestPreset);
            }
          })
          .height(24)
          .trackThickness(24)
          .blockSize({
            width: 24,
            height: 24
          })

        // 预设点标记
        this.buildPresetMarks()
      }

      // 快速操作按钮
      this.buildQuickActions()

      // 说明文本
      Text('手动调整麦克风灵敏度，确保测量精度。建议在安静环境中进行校准。')
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