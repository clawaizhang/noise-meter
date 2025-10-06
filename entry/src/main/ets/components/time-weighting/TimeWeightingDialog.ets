/**
 * 音频分析模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { AudioAnalysisConfig, AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { AcousticExplanationComp } from './AcousticExplanation';
import { TechnicalParamsDisplay } from './TechnicalParamsDisplay';
import { PreviewPanel } from './PreviewPanel';
import { ScenarioDisplay } from './ScenarioDisplay';
import { CollapsibleSection } from './CollapsibleSection';
import { CustomConfigPanel } from './CustomConfigPanel';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { EditableLeftIconType, EditableTitleBar, PersistenceV2 } from '@kit.ArkUI';
import { PremiumFeature } from '../membership/PremiumFeature';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onClose: () => void; // 关闭回调
  @Event onSettingsApplied?: (mode: AudioAnalysisMode) => void; // 设置应用回调
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local tempSelectedMode!: AudioAnalysisMode; // 临时选中的模式
  @Local hoveredMode: AudioAnalysisMode | null = null; // 悬停的模式
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开
  @Local tempCustomModeEnabled: boolean = false; // 临时自定义模式开关状态
  @Local tempCustomConfig: AudioAnalysisConfig =
    new AudioAnalysisConfig(this.pk.custom_audio_config.fftSize, this.pk.custom_audio_config.updateInterval,
      this.pk.custom_audio_config.smoothingFactor, this.pk.custom_audio_config.windowType,
      this.pk.custom_audio_config.overlap, this.pk.custom_audio_config.bufferSize); // 临时自定义配置
  // 初始状态 - 用于检测是否有修改
  private initialMode: AudioAnalysisMode = this.currentMode;
  private initialCustomModeEnabled: boolean = false;
  private initialCustomConfig: AudioAnalysisConfig = new AudioAnalysisConfig(this.pk.custom_audio_config.fftSize, this.pk.custom_audio_config.updateInterval,
    this.pk.custom_audio_config.smoothingFactor, this.pk.custom_audio_config.windowType,
    this.pk.custom_audio_config.overlap, this.pk.custom_audio_config.bufferSize);

  aboutToAppear() {
    // 初始化临时状态
    this.tempSelectedMode = this.currentMode;
    this.tempCustomModeEnabled = this.pk.custom_audio_config_enabled;
    this.initialMode = this.currentMode;
    this.initialCustomModeEnabled = this.pk.custom_audio_config_enabled;
  }

  // 处理保存操作
  private handleSave() {
    // 检测是否有修改，有修改则通过回调传递设置
    const hasChanges = this.hasSettingsChanged();
    if (hasChanges && this.onSettingsApplied) {
      this.onSettingsApplied(this.tempSelectedMode);
    }
    // 应用自定义模式设置
    this.pk.custom_audio_config_enabled = this.tempCustomModeEnabled;
    // 应用自定义配置
    this.pk.custom_audio_config.fftSize = this.tempCustomConfig.fftSize;
    this.pk.custom_audio_config.updateInterval = this.tempCustomConfig.updateInterval;
    this.pk.custom_audio_config.smoothingFactor = this.tempCustomConfig.smoothingFactor;
    this.pk.custom_audio_config.windowType = this.tempCustomConfig.windowType;
    this.pk.custom_audio_config.overlap = this.tempCustomConfig.overlap;
    this.pk.custom_audio_config.bufferSize = this.tempCustomConfig.bufferSize;
    // 关闭弹窗
    this.onClose();
  }

  // 处理取消操作
  private handleCancel() {
    // 直接关闭弹窗，不应用任何设置
    this.onClose();
  }

  // 检测设置是否有修改
  private hasSettingsChanged(): boolean {
    return this.tempSelectedMode !== this.initialMode ||
      this.tempCustomModeEnabled !== this.initialCustomModeEnabled ||
    this.hasCustomConfigChanged();
  }

  // 检测自定义配置是否有修改
  private hasCustomConfigChanged(): boolean {
    return this.tempCustomConfig.fftSize !== this.initialCustomConfig.fftSize ||
      this.tempCustomConfig.updateInterval !== this.initialCustomConfig.updateInterval ||
      this.tempCustomConfig.windowType !== this.initialCustomConfig.windowType ||
      this.tempCustomConfig.smoothingFactor !== this.initialCustomConfig.smoothingFactor ||
      this.tempCustomConfig.overlap !== this.initialCustomConfig.overlap;
  }

  // 处理自定义配置变化
  private handleCustomConfigChange(config: AudioAnalysisConfig) {
    this.tempCustomConfig.fftSize = config.fftSize;
    this.tempCustomConfig.updateInterval = config.updateInterval;
    this.tempCustomConfig.windowType = config.windowType;
    this.tempCustomConfig.smoothingFactor = config.smoothingFactor;
    this.tempCustomConfig.overlap = config.overlap;
    this.initialCustomConfig.fftSize = config.fftSize;
  }

  // 处理模式选择 - 只更新临时状态
  private handleModeSelect(mode: AudioAnalysisMode) {
    this.tempSelectedMode = mode;
    // 移除立即应用新设置的逻辑
  }

  // 处理自定义模式开关 - 只更新临时状态
  private handleCustomModeToggle(isEnabled: boolean) {
    this.tempCustomModeEnabled = isEnabled;
    if (isEnabled) {
      // 启用自定义模式
      this.tempSelectedMode = AudioAnalysisMode.CUSTOM_TIME_WEIGHTING;
    } else {
      // 禁用自定义模式，回到快速模式
      this.tempSelectedMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
    }
    // 移除立即应用新设置的逻辑
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

        Toggle({ type: ToggleType.Switch, isOn: this.tempCustomModeEnabled })
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
          Row() {
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
        .fillColor(this.tempSelectedMode === mode ?
        $r('sys.color.font_on_primary') :
          (this.hoveredMode === mode ?
          $r('sys.color.interactive_active') :
          $r('sys.color.font_primary')));

      // 模式名称
      Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[mode])
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(this.tempSelectedMode === mode ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.tempSelectedMode === mode ?
        $r('sys.color.font_on_primary') :
          (this.hoveredMode === mode ?
          $r('sys.color.interactive_active') :
          $r('sys.color.font_primary')));
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(56)
    .backgroundColor(this.tempSelectedMode === mode ?
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
        selectedMode: this.tempSelectedMode
      })

      // 场景展示
      ScenarioDisplay({
        selectedMode: this.tempSelectedMode
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
          selectedMode: this.tempSelectedMode
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
          selectedMode: this.tempSelectedMode
        })
      }

    }
    .width('100%')
  }

  build() {
    Column({ space: 0 }) {
      // 使用EditableTitleBar提供标准的编辑界面标题栏
      EditableTitleBar({
        leftIconStyle: EditableLeftIconType.Cancel,
        title: '音频分析模式',
        isSaveIconRequired: true,
        onSave: () => {
          this.handleSave();
        },
        onCancel: () => {
          this.handleCancel();
        }
      })

      // 自定义模式开关
      Column() {
        this.buildCustomModeSwitch()
      }.padding(16)

      // 根据自定义模式状态显示不同界面
      if (!this.tempCustomModeEnabled) {
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
          .alignItems(HorizontalAlign.Start)
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
      } else {
        // 自定义模式界面
        Scroll() {
          Column() {
            CustomConfigPanel({
              onSelectedChange: () => {
                // 自定义配置面板的更改在保存时应用
                // 这里不需要立即生效
              },
              onConfigChange: (config: AudioAnalysisConfig) => {
                this.handleCustomConfigChange(config);
              }
            })
            Blank()
          }
          .justifyContent(FlexAlign.Start)
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .justifyContent(FlexAlign.Start)
  }
}

// 音频分析弹框的Builder版本
@Builder
export function TimeWeightingDialogBuilder(param: TimeWeightingDialogParams
) {
  TimeWeightingDialog({
    currentMode: param.currentMode,
    onClose: param.onClose,
    onSettingsApplied: param.onSettingsApplied
  })
}

export interface TimeWeightingDialogParams {
  currentMode: AudioAnalysisMode;
  onClose: () => void;
  onSettingsApplied?: (mode: AudioAnalysisMode) => void; // 新增：设置应用回调
}