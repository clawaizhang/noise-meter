/**
 * 时间计权模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { TimeWeightingCard } from './TimeWeightingCard';
import { AcousticExplanationComp } from './AcousticExplanation';
import { TechnicalParamsDisplay } from './TechnicalParamsDisplay';
import { PreviewPanel } from './PreviewPanel';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onConfirm: (mode: AudioAnalysisMode) => void; // 确认回调
  @Param @Require onCancel: () => void; // 取消回调
  @Local selectedMode!: AudioAnalysisMode; // 选中的模式

  aboutToAppear() {
    // 初始化选中模式为当前模式
    this.selectedMode = this.currentMode;
  }

  // 处理模式选择
  private handleModeSelect(mode: AudioAnalysisMode) {
    this.selectedMode = mode;
  }

  // 处理确认操作
  private handleConfirm() {
    if (this.onConfirm) {
      this.onConfirm(this.selectedMode);
    }
  }

  // 处理取消操作
  private handleCancel() {
    if (this.onCancel) {
      this.onCancel();
    }
  }

  // 构建模式选择区域
  @Builder
  private buildModeSelection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 模式卡片网格
      GridRow({
        columns: { sm: 1, md: 3 },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: { x: DesignConstants.SPACING_MD, y: DesignConstants.SPACING_MD }
      }) {
        ForEach(TimeWeightingConstants.getAvailableModes(), (mode: AudioAnalysisMode) => {
          GridCol({ span: 1 }) {
            TimeWeightingCard({
              mode: this.currentMode,
              selectedMode: this.selectedMode,
              modeInfo: mode,
              onSelect: (selectedMode: AudioAnalysisMode) => {
                this.handleModeSelect(selectedMode);
              }
            })
          }
        })
      }
      .width('100%')

    }
    .width('100%')
  }

  // 构建预览区域
  @Builder
  private buildPreviewArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 实时预览面板
      PreviewPanel({
        currentMode: this.currentMode,
        selectedMode: this.selectedMode
      })
      // 技术参数显示
      TechnicalParamsDisplay({
        currentMode: this.currentMode,
        selectedMode: this.selectedMode
      })
    }
    .width('100%')
  }

  // 构建详细信息区域
  @Builder
  private buildDetailArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 声学解释
      AcousticExplanationComp({
        selectedMode: this.selectedMode
      })

    }
    .width('100%')
  }

  // 构建操作按钮区域
  @Builder
  private buildActionButtons() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 取消按钮
      Button('取消', { type: ButtonType.Normal })
        .layoutWeight(1)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.handleCancel();
        })

      // 确认按钮
      Button('确认选择', { type: ButtonType.Capsule })
        .layoutWeight(1)
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .enabled(this.currentMode !== this.selectedMode)
        .onClick(() => {
          this.handleConfirm();
        })

    }
    .width('100%')
    .height(48)
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 模式选择区域
      this.buildModeSelection()

      // 分隔线
      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_border_color'))
        .margin({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })

      // 预览区域
      this.buildPreviewArea()

      // 分隔线
      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_border_color'))
        .margin({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })

      // 详细信息区域
      this.buildDetailArea()

      // 操作按钮区域
      this.buildActionButtons()

    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

// 时间计权弹框的Builder版本
@Builder
export function TimeWeightingDialogBuilder(param: TimeWeightingDialogParams
) {
  TimeWeightingDialog({
    currentMode: param.currentMode,
    onConfirm: param.onConfirm,
    onCancel: param.onCancel
  })
}

export interface TimeWeightingDialogParams {
  currentMode: AudioAnalysisMode;
  onConfirm: (mode: AudioAnalysisMode) => void;
  onCancel: () => void;
}