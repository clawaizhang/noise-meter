/**
 * 频谱图快捷设置组件
 * 两个32x32按钮，点击弹出原Dialog选择
 */

import { AppStorageV2, PersistenceV2, promptAction } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { FrequencyWeightingDialogBuilder, FrequencyWeightingDialogParams } from '../frequency-weighting/FrequencyWeightingDialog';
import { TimeWeightingDialogBuilder, TimeWeightingDialogParams } from '../time-weighting/TimeWeightingDialog';

@ComponentV2
export struct SpectrumQuickSettings {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 按钮背景色 - 半透明黑色
  private readonly buttonBgColor: string = 'rgba(0, 0, 0, 0.4)';

  private getWeightingText(): string { return this.pk.weighting_type; }

  private getAnalysisModeText(): string {
    switch (this.pk.audio_analysis_mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING: return '快';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING: return '慢';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING: return '脉';
      case AudioAnalysisMode.CUSTOM_TIME_WEIGHTING: return '自';
      default: return '快';
    }
  }

  private getWeightingTextColor(): string {
    switch (this.pk.weighting_type) {
      case WeightingType.A: return '#52C41A';
      case WeightingType.C: return '#1890FF';
      case WeightingType.Z: return '#722ED1';
      default: return '#52C41A';
    }
  }

  private getAnalysisModeTextColor(): string {
    if (this.pk.audio_analysis_mode === AudioAnalysisMode.CUSTOM_TIME_WEIGHTING) return '#FA8C16';
    if (this.pk.audio_analysis_mode === AudioAnalysisMode.FAST_TIME_WEIGHTING) return '#13C2C2';
    return '#1890FF';
  }

  private showWeightingDialog(): void {
    Throttle.click(() => {
      let sheetDialog: InfSheet | null = null;
      
      const params: FrequencyWeightingDialogParams = {
        currentWeighting: this.pk.weighting_type,
        onClose: () => {
          if (sheetDialog) {
            sheetDialog.dismiss();
          }
        },
        onSettingsApplied: (weighting: WeightingType) => {
          if (sheetDialog) {
            sheetDialog.dismiss();
          }
          promptAction.showToast({ message: `${weighting}计权`, duration: 1500 });
        }
      };

      sheetDialog = DialogHub.getSheet()
        .setStyle({
          showClose: false,
          backgroundColor: $r('sys.color.background_secondary')
        })
        .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
        .setComponentTargetId('mainId')
        .setContent(wrapBuilder(FrequencyWeightingDialogBuilder), params)
        .build();
      
      sheetDialog.show();
    });
  }

  private showAnalysisModeDialog(): void {
    Throttle.click(() => {
      let sheetDialog: InfSheet | null = null;
      
      const params: TimeWeightingDialogParams = {
        currentMode: this.pk.audio_analysis_mode,
        onClose: () => {
          if (sheetDialog) {
            sheetDialog.dismiss();
          }
        },
        onSettingsApplied: (mode: AudioAnalysisMode) => {
          if (sheetDialog) {
            sheetDialog.dismiss();
          }
          promptAction.showToast({
            message: TimeWeightingConstants.MODE_DISPLAY_NAMES[mode] || '自定义模式',
            duration: 1500
          });
        }
      };

      sheetDialog = DialogHub.getSheet()
        .setStyle({
          showClose: false,
          backgroundColor: $r('sys.color.background_secondary')
        })
        .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
        .setComponentTargetId('mainId')
        .setContent(wrapBuilder(TimeWeightingDialogBuilder), params)
        .build();
      
      sheetDialog.show();
    });
  }

  build() {
    Row({ space: 8 }) {
      // 计权按钮
      Button() {
        Text(this.getWeightingText())
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getWeightingTextColor())
      }
      .width(32)
      .height(32)
      .backgroundColor(this.buttonBgColor)
      .borderRadius(16)
      .shadow({ radius: 3, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 2 })
      .onClick(() => this.showWeightingDialog())

      // 分析模式按钮
      Button() {
        Text(this.getAnalysisModeText())
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getAnalysisModeTextColor())
      }
      .width(32)
      .height(32)
      .backgroundColor(this.buttonBgColor)
      .borderRadius(16)
      .shadow({ radius: 3, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 2 })
      .onClick(() => this.showAnalysisModeDialog())
    }
    .height(32)
  }
}
