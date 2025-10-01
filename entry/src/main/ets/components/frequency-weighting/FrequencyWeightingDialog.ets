/**
 * 频率加权模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { FrequencyAcousticExplanationComp } from './FrequencyAcousticExplanation';
import { FrequencyTechnicalParamsDisplay } from './FrequencyTechnicalParamsDisplay';
import { FrequencyPreviewPanel } from './FrequencyPreviewPanel';

@ComponentV2
export struct FrequencyWeightingDialog {
  @Param @Require currentWeighting: WeightingType; // 当前计权类型（从外部传入）
  @Param @Require onConfirm: (weighting: WeightingType) => void; // 确认回调
  @Param @Require onCancel: () => void; // 取消回调
  @Local selectedWeighting!: WeightingType; // 选中的计权类型
  @Local hoveredWeighting: WeightingType | null = null; // 悬停的计权类型

  aboutToAppear() {
    // 初始化选中计权类型为当前计权类型
    this.selectedWeighting = this.currentWeighting;
  }

  // 处理计权类型选择
  private handleWeightingSelect(weighting: WeightingType) {
    this.selectedWeighting = weighting;
  }

  // 处理确认操作
  private handleConfirm() {
    if (this.onConfirm) {
      this.onConfirm(this.selectedWeighting);
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
      ForEach(FrequencyWeightingConstants.getAvailableWeightings(), (weighting: WeightingType) => {
        // 选项卡内容
        Row({ space: DesignConstants.SPACING_SM }) {
          // 计权类型图标
          Image(FrequencyWeightingConstants.getWeightingIcon(weighting))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor(this.selectedWeighting === weighting ?
            $r('sys.color.font_on_primary') :
              (this.hoveredWeighting === weighting ?
              $r('sys.color.interactive_active') :
              $r('sys.color.font_primary')))

          // 计权类型名称
          Text(FrequencyWeightingConstants.getWeightingDisplayName(weighting))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(this.selectedWeighting === weighting ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.selectedWeighting === weighting ?
            $r('sys.color.font_on_primary') :
              (this.hoveredWeighting === weighting ?
              $r('sys.color.interactive_active') :
              $r('sys.color.font_primary')))
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .height(56)
        .backgroundColor(this.selectedWeighting === weighting ?
        $r('sys.color.interactive_active') :
          (this.hoveredWeighting === weighting ?
          $r('sys.color.comp_background_secondary') :
          $r('sys.color.comp_background_primary')))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .padding(DesignConstants.SPACING_MD)
        .onClick(() => {
          this.handleWeightingSelect(weighting);
        })
        .onHover((isHover: boolean) => {
          if (isHover) {
            this.hoveredWeighting = weighting;
          } else {
            this.hoveredWeighting = null;
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
      FrequencyPreviewPanel({
        currentWeighting: this.currentWeighting,
        selectedWeighting: this.selectedWeighting
      })
      // 技术参数显示
      FrequencyTechnicalParamsDisplay({
        currentWeighting: this.currentWeighting,
        selectedWeighting: this.selectedWeighting
      })
    }
    .width('100%')
  }

  // 构建详细信息区域
  @Builder
  private buildDetailArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 声学解释
      FrequencyAcousticExplanationComp({
        selectedWeighting: this.selectedWeighting
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
        .backgroundColor(this.currentWeighting !== this.selectedWeighting ?
        $r('sys.color.interactive_active') :
        $r('sys.color.comp_background_tertiary'))
        .enabled(this.currentWeighting !== this.selectedWeighting)
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

// 频率加权弹框的Builder版本
@Builder
export function FrequencyWeightingDialogBuilder(param: FrequencyWeightingDialogParams
) {
  FrequencyWeightingDialog({
    currentWeighting: param.currentWeighting,
    onConfirm: param.onConfirm,
    onCancel: param.onCancel
  })
}

export interface FrequencyWeightingDialogParams {
  currentWeighting: WeightingType;
  onConfirm: (weighting: WeightingType) => void;
  onCancel: () => void;
}