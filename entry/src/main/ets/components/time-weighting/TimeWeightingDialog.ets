/**
 * 时间计权模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { AcousticExplanationComp } from './AcousticExplanation';
import { TechnicalParamsDisplay } from './TechnicalParamsDisplay';
import { PreviewPanel } from './PreviewPanel';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onConfirm: (mode: AudioAnalysisMode) => void; // 确认回调
  @Param @Require onCancel: () => void; // 取消回调
  @Local selectedMode!: AudioAnalysisMode; // 选中的模式
  @Local hoveredMode: AudioAnalysisMode | null = null; // 悬停的模式

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

  // 构建固定顶部选项卡
  @Builder
  private buildFixedTabs() {
    // 选项卡容器
    Row({ space: 0 }) {
      ForEach(TimeWeightingConstants.getAvailableModes(), (mode: AudioAnalysisMode) => {
        // 选项卡内容
        Row({ space: DesignConstants.SPACING_SM }) {
          // 模式图标
          Image(TimeWeightingConstants.getModeIcon(mode))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(this.selectedMode === mode ?
            $r('sys.color.font_on_primary') :
              (this.hoveredMode === mode ?
              $r('sys.color.interactive_active') :
              $r('sys.color.font_primary')))

          // 模式名称
          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[mode])
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(this.selectedMode === mode ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.selectedMode === mode ?
            $r('sys.color.font_on_primary') :
              (this.hoveredMode === mode ?
              $r('sys.color.interactive_active') :
              $r('sys.color.font_primary')))
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .height(56)
        .backgroundColor(this.selectedMode === mode ?
        $r('sys.color.interactive_active') :
          (this.hoveredMode === mode ?
          $r('sys.color.comp_background_secondary') :
          $r('sys.color.comp_background_primary')))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .padding(DesignConstants.SPACING_MD)
        .onClick(() => {
          this.handleModeSelect(mode);
        })
        .onHover((isHover: boolean) => {
          if (isHover) {
            this.hoveredMode = mode;
          } else {
            this.hoveredMode = null;
          }
        })
      })
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin(16)
    .borderRadius(16)
    .height(56)
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
      Button('取消', { type: ButtonType.Capsule })
        .layoutWeight(1)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .border({
          width: DesignConstants.BORDER_WIDTH_SM,
          color: $r('sys.color.comp_border_color'),
          style: BorderStyle.Solid
        })
        .onClick(() => {
          this.handleCancel();
        })
        .height(56)

      // 确认按钮
      Button('确认选择', { type: ButtonType.Capsule })
        .layoutWeight(1)
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .backgroundColor(this.currentMode !== this.selectedMode ?
        $r('sys.color.interactive_active') :
        $r('sys.color.comp_background_tertiary'))
        .enabled(this.currentMode !== this.selectedMode)
        .onClick(() => {
          this.handleConfirm();
        })
        .height(56)

    }
    .width('100%')
    .padding(8)
    .borderRadius(8)
  }

  build() {
    Column({ space: 8 }) {
      this.buildFixedTabs()
      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 预览区域
          this.buildPreviewArea()

          // 详细信息区域
          this.buildDetailArea()

        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_secondary'))
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)

      // 操作按钮区域
      this.buildActionButtons()
    }
    .width('100%')
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