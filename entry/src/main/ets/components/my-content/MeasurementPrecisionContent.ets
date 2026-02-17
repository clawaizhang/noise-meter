import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import {
  AudioCalibrationProps,
  AudioCalibrationSettingsBuilder
} from '../../pages/settings/AudioCalibrationNavigation';
import {
  FrequencyWeightingDialogBuilder,
  FrequencyWeightingDialogParams,
} from '../frequency-weighting/FrequencyWeightingDialog';
import {
  TimeWeightingDialogBuilder, TimeWeightingDialogParams,
} from '../time-weighting/TimeWeightingDialog';
import { isProMember } from '../membership/PremiumLockViews';

/**
 * 测量精度设置内容组件
 * 采用设置项列表样式，点击修改按钮弹出对应弹窗
 */
@ComponentV2
export struct MeasurementPrecisionContent {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 顶部说明
        this.buildHeaderTip()

        // 校准设置项
        this.buildCalibrationItem()

        // 频率加权设置项
        this.buildFrequencyWeightingItem()

        // 分析模式设置项
        this.buildAnalysisModeItem()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(DesignConstants.SPACING_MD)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 顶部提示
  @Builder
  private buildHeaderTip() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_info'))
        .width(18)
        .height(18)
        .fillColor($r('sys.color.font_secondary'))

      Text('这些设置会影响测量结果的准确性')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 校准设置项
  @Builder
  private buildCalibrationItem() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 主内容行
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Row() {
          Image($r('app.media.ic_calibration'))
            .width(22)
            .height(22)
            .fillColor($r('sys.color.icon_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 内容区
        Column({ space: 4 }) {
          Text('声级校准')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          // 当前状态
          Text(this.getCalibrationStatusText())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.getCalibrationStatusColor())
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 修改按钮
        Button('去校准')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_emphasize'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            Throttle.click(() => {
              this.openCalibrationDialog();
            });
          })
      }
      .width('100%')

      // 说明文字
      Text('使用标准声级校准器（如94dB/114dB）对设备进行校准，以提高测量精度。未校准的设备可能存在±3dB的误差。')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 频率加权设置项 - 所有用户都可点击进入弹框
  @Builder
  private buildFrequencyWeightingItem() {
    this.buildFrequencyWeightingContent()
  }

  // 频率加权内容
  @Builder
  private buildFrequencyWeightingContent() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 主内容行
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Row() {
          Image($r('app.media.ic_frequency_weighting'))
            .width(22)
            .height(22)
            .fillColor($r('sys.color.icon_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 内容区
        Column({ space: 4 }) {
          Text('频率加权')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          // 当前状态
          Text(this.getWeightingDisplayName(this.pk.weighting_type))
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_emphasize'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 修改按钮
        Button('修改')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_emphasize'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            Throttle.click(() => {
              this.openFrequencyWeightingDialog();
            });
          })
      }
      .width('100%')

      // 说明文字（灰色，和其他卡片一致）
      Text('模拟人耳对不同频率声音的响应。A计权适用于环境噪声测量。')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 分析模式设置项 - 所有用户都可点击进入弹框
  @Builder
  private buildAnalysisModeItem() {
    this.buildAnalysisModeContent()
  }

  // 分析模式内容
  @Builder
  private buildAnalysisModeContent() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 主内容行
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Row() {
          Image($r('app.media.ic_time_weighting'))
            .width(22)
            .height(22)
            .fillColor($r('sys.color.icon_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        // 内容区
        Column({ space: 4 }) {
          Text('分析模式')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          // 当前状态
          Text(this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode))
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_emphasize'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 修改按钮
        Button('修改')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_emphasize'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            Throttle.click(() => {
              this.openAnalysisModeDialog();
            });
          })
      }
      .width('100%')

      // 说明文字
      Text('选择适合您测量场景的分析模式。快速/慢速/脉冲为专业预设模式，也可自定义FFT、更新间隔等底层参数进行精细调整。')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // ==================== 打开弹窗方法 ====================

  // 打开校准弹窗
  private openCalibrationDialog(): void {
    let calibrationDialog: InfSheet;
    let props: AudioCalibrationProps = {
      onSave: () => {
        calibrationDialog.dismiss();
      },
      onClose: () => {
        calibrationDialog.dismiss();
      }
    }
    calibrationDialog = DialogHub.getSheet()
      .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AudioCalibrationSettingsBuilder), props)
      .build();
    calibrationDialog.show();
  }

  // 打开频率加权弹窗
  private openFrequencyWeightingDialog(): void {
    let frequencyDialog: InfSheet;
    let param: FrequencyWeightingDialogParams = {
      currentWeighting: this.pk.weighting_type,
      onSettingsApplied: (selectedWeighting: WeightingType) => {
        // 设置已应用
        console.info('频率加权已更新:', selectedWeighting);
      },
      onClose: () => {
        frequencyDialog?.dismiss();
      }
    }
    frequencyDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(FrequencyWeightingDialogBuilder), param)
      .build();
    frequencyDialog.show();
  }

  // 打开分析模式弹窗
  private openAnalysisModeDialog(): void {
    let timeDialog: InfSheet;
    let param: TimeWeightingDialogParams = {
      currentMode: this.pk.audio_analysis_mode,
      onSettingsApplied: (selectedMode: AudioAnalysisMode) => {
        // 设置已应用
        console.info('分析模式已更新:', selectedMode);
      },
      onClose: () => {
        timeDialog?.dismiss();
      }
    }
    timeDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(TimeWeightingDialogBuilder), param)
      .build();
    timeDialog.show();
  }

  // ==================== 辅助方法 ====================

  private getCalibrationStatusText(): string {
    const value = this.pk.calibration_value || 0;
    if (value !== 0) {
      return `已校准 ${value > 0 ? '+' : ''}${value}dB`;
    }
    return '未校准，建议校准以提高精度';
  }

  private getCalibrationStatusColor(): Resource {
    const value = this.pk.calibration_value || 0;
    return value !== 0 ? $r('sys.color.font_emphasize') : $r('sys.color.font_secondary');
  }

  private getWeightingDisplayName(weighting: WeightingType): string {
    switch (weighting) {
      case WeightingType.A:
        return 'A计权 - 模拟人耳感知';
      case WeightingType.C:
        return 'C计权 - 低频响应更平坦';
      case WeightingType.Z:
        return 'Z计权 - 平坦频率响应';
      default:
        return 'A计权';
    }
  }

  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速(F) - 125ms响应，适合实时测量';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速(S) - 1000ms响应，读数更稳定';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲(I) - 35ms响应，捕获短时噪声';
      case AudioAnalysisMode.CUSTOM_TIME_WEIGHTING:
        return '自定义模式';
      default:
        return '快速(F)';
    }
  }
}
