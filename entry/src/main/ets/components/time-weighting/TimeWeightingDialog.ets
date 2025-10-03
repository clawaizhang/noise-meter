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
import { ScenarioDisplay } from './ScenarioDisplay';
import { CollapsibleSection } from './CollapsibleSection';
import { EnhancedModeSelectionPanel } from './EnhancedModeSelectionPanel';
import { WindowFunctionSettings } from './WindowFunctionSettings';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onModeChange: (mode: AudioAnalysisMode) => void; // 模式变化回调
  @Param @Require onClose: () => void; // 关闭回调
  @Local selectedMode!: AudioAnalysisMode; // 选中的模式
  @Local hoveredMode: AudioAnalysisMode | null = null; // 悬停的模式
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开
  @Local isWindowFunctionExpanded: boolean = false; // 窗函数设置是否展开

  aboutToAppear() {
    // 初始化选中模式为当前模式
    this.selectedMode = this.currentMode;
  }

  // 处理模式选择 - 即时生效
  private handleModeSelect(mode: AudioAnalysisMode) {
    this.selectedMode = mode;
    // 立即应用新设置
    if (this.onModeChange) {
      this.onModeChange(mode);
    }
  }

  // 构建固定顶部选项卡
  @Builder
  private buildModeSelectionPanel() {
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

  // 构建主要内容区域（面向普通用户）
  @Builder
  private buildPrimaryContentArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 实时预览面板
      PreviewPanel({
        currentMode: this.currentMode,
        selectedMode: this.selectedMode
      })

      // 场景展示
      ScenarioDisplay({
        selectedMode: this.selectedMode
      })
    }
    .width('100%')
  }

  // 构建可折叠的专业内容区域
  @Builder
  private buildExpandableProfessionalArea() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 技术参数区域
      CollapsibleSection({
        title: '技术参数',
        isExpanded: this.isTechnicalParamsExpanded,
        onToggle: () => {
          this.isTechnicalParamsExpanded = !this.isTechnicalParamsExpanded;
        }
      }) {
        TechnicalParamsDisplay({
          currentMode: this.currentMode,
          selectedMode: this.selectedMode
        })
      }

      // 声学原理区域
      CollapsibleSection({
        title: '声学原理',
        isExpanded: this.isAcousticTheoryExpanded,
        onToggle: () => {
          this.isAcousticTheoryExpanded = !this.isAcousticTheoryExpanded;
        }
      }) {
        AcousticExplanationComp({
          selectedMode: this.selectedMode
        })
      }

      // 窗函数设置区域（高级设置）
      CollapsibleSection({
        title: '窗函数设置',
        isExpanded: this.isWindowFunctionExpanded,
        onToggle: () => {
          this.isWindowFunctionExpanded = !this.isWindowFunctionExpanded;
        }
      }) {
        WindowFunctionSettings()
      }
    }
    .width('100%')
  }


  build() {
    Column({ space: 8 }) {
      // 模式选择面板
      this.buildModeSelectionPanel()
      
      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 主要内容区域（优先显示）
          this.buildPrimaryContentArea()

          // 可折叠的专业内容区域
          this.buildExpandableProfessionalArea()

        }
        .width('100%')
        .margin({bottom:72})
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_secondary'))
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)

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
    onModeChange: param.onModeChange,
    onClose: param.onClose
  })
}

export interface TimeWeightingDialogParams {
  currentMode: AudioAnalysisMode;
  onModeChange: (mode: AudioAnalysisMode) => void;
  onClose: () => void;
}