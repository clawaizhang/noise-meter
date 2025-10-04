/**
 * 音频分析模式选择弹框
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
import { CustomConfigPanel } from './CustomConfigPanel';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { PremiumFeature } from '../membership/PremiumFeature';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onModeChange: (mode: AudioAnalysisMode) => void; // 模式变化回调
  @Param @Require onClose: () => void; // 关闭回调
  @Local selectedMode!: AudioAnalysisMode; // 选中的模式
  @Local hoveredMode: AudioAnalysisMode | null = null; // 悬停的模式
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

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

  // 处理自定义模式开关
  private handleCustomModeToggle(isEnabled: boolean) {
    this.pk.custom_audio_config_enabled = isEnabled;
    if (isEnabled) {
      // 启用自定义模式
      this.selectedMode = AudioAnalysisMode.CUSTOM_TIME_WEIGHTING;
      if (this.onModeChange) {
        this.onModeChange(AudioAnalysisMode.CUSTOM_TIME_WEIGHTING);
      }
    } else {
      // 禁用自定义模式，回到快速模式
      this.selectedMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
      if (this.onModeChange) {
        this.onModeChange(AudioAnalysisMode.FAST_TIME_WEIGHTING);
      }
    }
  }

  // 构建自定义模式开关
  @Builder
  private buildCustomModeSwitch() {
    PremiumFeature({ featureName: '自定义模式', featureDesc: '自定义所有FFT参数' }) {
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('自定义模式')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.pk.custom_audio_config_enabled })
          .onChange((isOn: boolean) => {
            this.handleCustomModeToggle(isOn);
          })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .backgroundColor($r('sys.color.comp_background_primary'))
      .padding(16)
      .borderRadius(16)
      .height(56)
    }
  }

  // 构建标准模式选择面板
  @Builder
  private buildStandardModeSelectionPanel() {
    // 选项卡容器
    Row({ space: 0 }) {
      ForEach(TimeWeightingConstants.getAvailableModes(), (mode: AudioAnalysisMode) => {
        if (mode == AudioAnalysisMode.SLOW_TIME_WEIGHTING || mode == AudioAnalysisMode.IMPULSE_TIME_WEIGHTING) {
          Row(){
            PremiumFeature({
              featureName: TimeWeightingConstants.MODE_DISPLAY_NAMES[mode],
              featureDesc: TimeWeightingConstants.MODE_DESCRIPTIONS[mode]
            }) {
              this.modeSelect(mode)
            }
          }.layoutWeight(1)
        } else {
          this.modeSelect(mode)
        }
      })
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin({ left: 16, right: 16, bottom: 16 })
    .borderRadius(16)
    .height(56)
  }

  @Builder
  modeSelect(mode: AudioAnalysisMode) {
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
          $r('sys.color.font_primary')));

      // 模式名称
      Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[mode])
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(this.selectedMode === mode ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedMode === mode ?
        $r('sys.color.font_on_primary') :
          (this.hoveredMode === mode ?
          $r('sys.color.interactive_active') :
          $r('sys.color.font_primary')));
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

    }
    .width('100%')
  }

  build() {
    Column({ space: 8 }) {
      // 自定义模式开关
      Column() {
        this.buildCustomModeSwitch()
      }.padding(16)

      // 根据自定义模式状态显示不同界面
      if (!this.pk.custom_audio_config_enabled) {
        // 标准模式界面
        this.buildStandardModeSelectionPanel()

        // 可滚动内容区域
        Scroll() {
          Column({ space: DesignConstants.SPACING_LG }) {
            // 主要内容区域（优先显示）
            this.buildPrimaryContentArea()

            // 可折叠的专业内容区域
            this.buildExpandableProfessionalArea()

          }
          .width('100%')
          .margin({ bottom: 72 })
          .padding(DesignConstants.SPACING_LG)
          .backgroundColor($r('sys.color.background_secondary'))
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      } else {
        // 自定义模式界面
        Scroll() {
          Column() {
            CustomConfigPanel({
              onSelectedChange: () => {
                this.onModeChange(AudioAnalysisMode.CUSTOM_TIME_WEIGHTING);
              }
            })
            Blank()
          }
          .justifyContent(FlexAlign.Start)
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      }

    }
    .width('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

// 音频分析弹框的Builder版本
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