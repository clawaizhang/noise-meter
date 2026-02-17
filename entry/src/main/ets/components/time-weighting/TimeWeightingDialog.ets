/**
 * 音频分析模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { AudioAnalysisConfig, AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { AcousticExplanationComp } from './AcousticExplanation';
import { TechnicalParamsDisplay } from './TechnicalParamsDisplay';
import { PreviewPanel } from './PreviewPanel';
import { ScenarioDisplay } from './ScenarioDisplay';
import { CollapsibleSection } from './CollapsibleSection';
import { EnhancedCustomConfigPanel } from './EnhancedCustomConfigPanel';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { EditableLeftIconType, EditableTitleBar, PersistenceV2, promptAction } from '@kit.ArkUI';
import { isProMember, SettingLockView, BenefitTagItem } from '../membership/PremiumLockViews';
import { MembershipCenterDialog, MembershipCenterDialogProps } from '../membership/MembershipCenterDialog';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

@ComponentV2
export struct TimeWeightingDialog {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式（从外部传入）
  @Param @Require onClose: () => void; // 关闭回调
  @Event onSettingsApplied?: (mode: AudioAnalysisMode) => void; // 设置应用回调
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local tempSelectedMode!: AudioAnalysisMode; // 临时选中的模式
  @Local hoveredMode: AudioAnalysisMode | null = null; // 悬停的模式
  @Local previewMode: AudioAnalysisMode | null = null; // 预览的模式（用于锁定Tab的预览）
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开
  @Local tempCustomModeEnabled: boolean = false; // 临时自定义模式开关状态
  @Local tempCustomConfig: AudioAnalysisConfig = this.pk.custom_audio_config.clone(); // 临时自定义配置
  @Local previewCustomMode: boolean = false; // 是否正在预览自定义模式
  
  // 当前显示的模式（预览优先）
  @Computed
  get displayMode(): AudioAnalysisMode {
    return this.previewMode ?? this.tempSelectedMode;
  }
  
  // 是否显示自定义模式界面（预览或已启用）
  @Computed
  get showCustomModePanel(): boolean {
    return this.tempCustomModeEnabled || this.previewCustomMode;
  }

  aboutToAppear() {
    // 初始化临时状态
    this.tempSelectedMode = this.currentMode;
    this.tempCustomModeEnabled = this.pk.custom_audio_config_enabled;
  }

  // 处理保存操作
  private handleSave() {
    // 应用模式设置
    this.pk.audio_analysis_mode = this.tempSelectedMode;
    // 应用自定义模式设置
    this.pk.custom_audio_config_enabled = this.tempCustomModeEnabled;
    // 应用自定义配置
    this.pk.custom_audio_config.fftSize = this.tempCustomConfig.fftSize;
    this.pk.custom_audio_config.updateInterval = this.tempCustomConfig.updateInterval;
    this.pk.custom_audio_config.smoothingFactor = this.tempCustomConfig.smoothingFactor;
    this.pk.custom_audio_config.windowType = this.tempCustomConfig.windowType;
    this.pk.custom_audio_config.overlap = this.tempCustomConfig.overlap;
    this.pk.custom_audio_config.bufferSize = this.tempCustomConfig.bufferSize;
    
    // 通过回调通知设置已应用
    if (this.onSettingsApplied) {
      this.onSettingsApplied(this.tempSelectedMode);
    }
    
    // 显示保存成功提示，显示具体的设置结果
    const modeName = this.getAnalysisModeDisplayName(this.tempSelectedMode);
    let message = `${modeName}`;
    
    // 如果启用了自定义配置，添加相关信息
    if (this.tempCustomModeEnabled) {
      message += '（自定义配置已启用）';
    }
    
    promptAction.showToast({
      message: message,
      duration: 2000
    });
    
    // 关闭弹窗
    this.onClose();
  }

  // 获取分析模式显示名称
  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速模式';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速模式';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲模式';
      default:
        return '自定义模式';
    }
  }

  // 处理取消操作
  private handleCancel() {
    // 直接关闭弹窗，不应用任何设置
    this.onClose();
  }


  // 处理自定义配置变化
  private handleCustomConfigChange(config: AudioAnalysisConfig) {
    this.tempCustomConfig.fftSize = config.fftSize;
    this.tempCustomConfig.updateInterval = config.updateInterval;
    this.tempCustomConfig.windowType = config.windowType;
    this.tempCustomConfig.smoothingFactor = config.smoothingFactor;
    this.tempCustomConfig.overlap = config.overlap;
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
    Row({ space: DesignConstants.SPACING_MD }) {
      Text('自定义模式')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor((this.previewCustomMode && !isProMember()) ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.showCustomModePanel })
        .enabled(isProMember()) // 免费版禁用，但可点击预览
        .onChange((isOn: boolean) => {
          if (isProMember()) {
            // 专业版：正常切换
            this.handleCustomModeToggle(isOn);
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .backgroundColor((this.previewCustomMode && !isProMember()) ? 'rgba(51, 154, 240, 0.15)' : $r('sys.color.comp_background_primary'))
    .padding(16)
    .borderRadius(16)
    .height(56)
    .onClick(() => {
      // 免费版点击开关进入预览模式
      if (!isProMember()) {
        Throttle.click(() => {
          this.previewCustomMode = true;
        });
      }
    })
  }

  // 构建标准模式选择面板
  @Builder
  private buildStandardModeSelectionPanel() {
    // 选项卡容器
    Row({ space: 0 }) {
      ForEach(TimeWeightingConstants.getAvailableModes(), (mode: AudioAnalysisMode) => {
        // 所有模式都可见，专业模式带锁定标记
        this.buildModeTab(mode)
      })
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin({ left: 16, right: 16, bottom: 16 })
    .borderRadius(16)
    .height(56)
  }
  
  // 构建单个模式选项卡
  @Builder
  private buildModeTab(mode: AudioAnalysisMode) {
    // 专业功能且非会员：显示锁定，点击预览
    if ((mode == AudioAnalysisMode.SLOW_TIME_WEIGHTING || mode == AudioAnalysisMode.IMPULSE_TIME_WEIGHTING) && !isProMember()) {
      Stack({ alignContent: Alignment.TopEnd }) {
        // Tab内容（预览状态高亮）
        this.buildPreviewModeContent(mode, this.previewMode === mode)
        
        // 锁定角标
        Row({ space: 2 }) {
          Image($r('app.media.ic_lock'))
            .width(10)
            .height(10)
            .fillColor('#FF6B6B')
          
          Text('PRO')
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
        }
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .backgroundColor('rgba(255, 255, 255, 0.95)')
        .borderRadius(8)
        .margin({ top: 4, right: 4 })
      }
      .layoutWeight(1)
      .height(56)
      .onClick(() => {
        Throttle.click(() => {
          // 设置预览模式，让用户看到该模式的详细内容
          this.previewMode = mode;
        });
      })
    } else {
      // 免费功能或已解锁：正常可点击
      Stack({ alignContent: Alignment.TopEnd }) {
        this.modeSelect(mode)
      }
      .layoutWeight(1)
      .height(56)
      .onClick(() => {
        Throttle.click(() => {
          this.previewMode = null;
          this.handleModeSelect(mode);
        });
      })
    }
  }
  
  // 构建预览状态的模式内容（高亮显示正在预览）
  @Builder
  private buildPreviewModeContent(mode: AudioAnalysisMode, isPreviewing: boolean) {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 模式图标
      Image(TimeWeightingConstants.getModeIcon(mode))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor(isPreviewing ? $r('sys.color.font_emphasize') : $r('sys.color.font_tertiary'))

      // 模式名称
      Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[mode])
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(isPreviewing ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(isPreviewing ? $r('sys.color.font_emphasize') : $r('sys.color.font_tertiary'))
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(56)
    .backgroundColor(isPreviewing ? 'rgba(51, 154, 240, 0.15)' : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .padding(DesignConstants.SPACING_MD)
  }
  
  // 显示模式解锁弹窗
  private showModeUnlockDialog(mode: AudioAnalysisMode): void {
    let upgradeDialog: InfSheet | null = null;
    let params: ModeUnlockParams = {
      modeName: TimeWeightingConstants.MODE_DISPLAY_NAMES[mode],
      modeDesc: TimeWeightingConstants.MODE_DESCRIPTIONS[mode],
      onUpgrade: () => {
        upgradeDialog?.dismiss();
        this.openMembershipCenter();
      }
    };
    upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: `解锁${TimeWeightingConstants.MODE_DISPLAY_NAMES[mode]}` },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ModeUnlockContentBuilder), params)
      .build();
    upgradeDialog.show();
  }
  
  // 打开会员中心
  private openMembershipCenter(): void {
    let props: MembershipCenterDialogProps = {
      onClose: () => {}
    };
    DialogHub.getSheet()
      .setStyle({
        title: { title: '会员中心' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(MembershipCenterDialogBuilder), props)
      .build()
      .show();
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
      // 实时预览面板（显示预览或选中的模式）
      PreviewPanel({
        currentMode: this.currentMode,
        selectedMode: this.displayMode
      })

      // 场景展示（显示预览或选中的模式）
      ScenarioDisplay({
        selectedMode: this.displayMode
      })
    }
    .width('100%')
  }
  
  // 构建底部解锁引导卡片
  @Builder
  private buildUnlockPromptCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(24)
          .height(24)
          .fillColor('#FFD700')
        
        Text(`解锁${TimeWeightingConstants.MODE_DISPLAY_NAMES[this.previewMode!]}`)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        // 关闭预览按钮
        Button('×')
          .fontSize(20)
          .fontColor($r('sys.color.font_tertiary'))
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .onClick(() => {
            this.previewMode = null;
          })
      }
      .width('100%')
      
      // 功能描述
      Text(`解锁后即可使用${TimeWeightingConstants.MODE_DISPLAY_NAMES[this.previewMode!]}进行专业测量，适用于特定场景。`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
      
      // 权益标签
      Row({ space: DesignConstants.SPACING_SM }) {
        Row({ space: 4 }) {
          Text('🎁')
            .fontSize(12)
          Text('7天免费试用')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
        
        Row({ space: 4 }) {
          Text('⚡')
            .fontSize(12)
          Text('专业测量')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
      }
      .width('100%')
      
      // 解锁按钮
      Button() {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('🔓')
            .fontSize(16)
          Text('0.01元立即试用')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor('#FF6B6B')
      .borderRadius(22)
      .shadow({
        radius: 8,
        color: 'rgba(255, 107, 107, 0.35)',
        offsetX: 0,
        offsetY: 3
      })
      .onClick(() => {
        this.openMembershipCenter();
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.08)'
    })
    .margin({ left: 16, right: 16, bottom: 8 })
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
          selectedMode: this.displayMode
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
          selectedMode: this.displayMode
        })
      }

    }
    .width('100%')
  }
  
  // 构建自定义模式解锁引导卡片
  @Builder
  private buildCustomModeUnlockCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(24)
          .height(24)
          .fillColor('#FFD700')
        
        Text('解锁自定义模式')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        // 关闭预览按钮
        Button('×')
          .fontSize(20)
          .fontColor($r('sys.color.font_tertiary'))
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .onClick(() => {
            this.previewCustomMode = false;
          })
      }
      .width('100%')
      
      // 功能描述
      Text('解锁后即可自定义FFT大小、窗函数类型、更新间隔等专业参数，满足专业测量需求。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
      
      // 权益标签
      Row({ space: DesignConstants.SPACING_SM }) {
        Row({ space: 4 }) {
          Text('🎁')
            .fontSize(12)
          Text('7天免费试用')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
        
        Row({ space: 4 }) {
          Text('⚙️')
            .fontSize(12)
          Text('专业参数')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
      }
      .width('100%')
      
      // 解锁按钮
      Button() {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('🔓')
            .fontSize(16)
          Text('0.01元立即试用')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor('#FF6B6B')
      .borderRadius(22)
      .shadow({
        radius: 8,
        color: 'rgba(255, 107, 107, 0.35)',
        offsetX: 0,
        offsetY: 3
      })
      .onClick(() => {
        this.openMembershipCenter();
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.08)'
    })
    .margin({ left: 16, right: 16, top: 8 })
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
      if (!this.showCustomModePanel) {
        // 标准模式界面
        this.buildStandardModeSelectionPanel()

        // 如果是预览锁定模式，显示解锁引导卡片（在Tab下方、详情上方）
        if (this.previewMode !== null && !isProMember()) {
          this.buildUnlockPromptCard()
        }

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
        Column({ space: DesignConstants.SPACING_MD }) {
          // 如果是预览自定义模式（免费版），显示解锁引导卡片
          if (this.previewCustomMode && !isProMember()) {
            this.buildCustomModeUnlockCard()
          }
          
          Scroll() {
            Column() {
              EnhancedCustomConfigPanel({
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

// ============ 解锁弹窗内容 ============

interface ModeUnlockParams {
  modeName: string;
  modeDesc: string;
  onUpgrade: () => void;
}

@Builder
function ModeUnlockContentBuilder(params: ModeUnlockParams) {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 功能图标和名称
    Column({ space: DesignConstants.SPACING_MD }) {
      Stack() {
        Circle()
          .width(64)
          .height(64)
          .fill('rgba(255, 215, 0, 0.15)')
        
        Text('🔒')
          .fontSize(32)
      }
      
      Text(params.modeName)
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      
      Text(params.modeDesc)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    
    // 试用提示
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('🎁')
        .fontSize(24)
      
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('免费试用7天')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.brand'))
        
        Text('体验期间解锁全部专业功能')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor('rgba(51, 154, 240, 0.1)')
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    
    // 操作按钮
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('稍后再说')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          params.onUpgrade();
        })
      
      Button('0.01元试用')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          params.onUpgrade();
        })
    }
    .width('100%')
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}

@Builder
function MembershipCenterDialogBuilder(props: MembershipCenterDialogProps) {
  MembershipCenterDialog({ onClose: props.onClose })
}