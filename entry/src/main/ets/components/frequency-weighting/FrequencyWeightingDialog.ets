/**
 * 频率加权模式选择弹框
 * 主弹框组件，集成所有子组件并提供完整的交互体验
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { FrequencyAcousticExplanationComp } from './FrequencyAcousticExplanation';
import { FrequencyTechnicalParamsDisplay } from './FrequencyTechnicalParamsDisplay';
import { FrequencyPreviewPanel } from './FrequencyPreviewPanel';
import { FrequencyScenarioDisplay } from './FrequencyScenarioDisplay';
import { CollapsibleSection } from '../time-weighting/CollapsibleSection';
import { isProMember } from '../membership/PremiumLockViews';
import { MembershipCenterDialog, MembershipCenterDialogProps } from '../membership/MembershipCenterDialog';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { EditableLeftIconType, EditableTitleBar, PersistenceV2, promptAction } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';

@ComponentV2
export struct FrequencyWeightingDialog {
  @Param @Require currentWeighting: WeightingType; // 当前计权类型（从外部传入）
  @Event onClose: () => void; // 关闭回调
  @Event onSettingsApplied?: (weighting: WeightingType) => void; // 设置应用回调
  @Local tempSelectedWeighting!: WeightingType; // 临时选中的计权类型
  @Local hoveredWeighting: WeightingType | null = null; // 悬停的计权类型
  @Local previewWeighting: WeightingType | null = null; // 预览的计权类型（用于锁定Tab的预览）
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  
  // 当前显示的计权类型（预览优先）
  @Computed
  get displayWeighting(): WeightingType {
    return this.previewWeighting ?? this.tempSelectedWeighting;
  }

  // 初始状态 - 用于检测是否有修改
  private initialWeighting: WeightingType = this.currentWeighting;

  aboutToAppear() {
    // 初始化选中计权类型为当前计权类型
    this.tempSelectedWeighting = this.currentWeighting;
    this.initialWeighting = this.currentWeighting;
    this.previewWeighting = null;
  }

  // 处理保存操作
  private handleSave() {
    // 应用计权类型设置
    this.pk.weighting_type = this.tempSelectedWeighting;
    
    // 通过回调通知设置已应用
    if (this.onSettingsApplied) {
      this.onSettingsApplied(this.tempSelectedWeighting);
    }
    
    // 显示保存成功提示
    const weightingName = this.getWeightingDisplayName(this.tempSelectedWeighting);
    promptAction.showToast({
      message: `${weightingName}模式`,
      duration: 2000
    });
    
    // 关闭弹窗
    this.onClose();
  }

  // 处理取消操作
  private handleCancel() {
    // 直接关闭弹窗，不应用任何设置
    this.onClose();
  }

  // 获取计权类型显示名称
  private getWeightingDisplayName(weighting: WeightingType): string {
    switch (weighting) {
      case WeightingType.A:
        return 'A计权';
      case WeightingType.C:
        return 'C计权';
      case WeightingType.Z:
        return 'Z计权';
      default:
        return '未知';
    }
  }

  // 处理计权类型选择 - 只更新临时状态
  private handleWeightingSelect(weighting: WeightingType) {
    this.tempSelectedWeighting = weighting;
    // 移除立即应用新设置的逻辑
  }

  // 构建固定顶部选项卡
  @Builder
  private buildFixedTabs() {
    // 选项卡容器
    Row({ space: 0 }) {
      // A计权 - 免费功能
      this.buildWeightingTab(WeightingType.A, 'A计权', '模拟人耳对声音的感知,适合评估环境噪声', false)

      // C计权 - 专业功能
      this.buildWeightingTab(WeightingType.C, 'C计权', '对低频响应更好,适合评估高声压级噪声', true)

      // Z计权 - 专业功能
      this.buildWeightingTab(WeightingType.Z, 'Z计权', '零频率计权,适合声学分析和研究', true)
    }
    .width('92%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .margin(16)
    .borderRadius(16)
    .height(56)
  }

  // 构建单个计权类型选项卡
  @Builder
  private buildWeightingTab(weighting: WeightingType, displayName: string, description: string, isPremium: boolean) {
    // 所有Tab都可见，但专业功能带锁定标记
    if (isPremium && !isProMember()) {
      // 专业功能且非会员：显示锁定状态，点击预览（不切换实际选择）
      Stack({ alignContent: Alignment.TopEnd }) {
        // Tab内容（预览状态高亮，否则置灰）
        this.buildPreviewTabContent(weighting, displayName, this.previewWeighting === weighting)
        
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
          // 设置预览模式，让用户看到该计权的详细内容
          this.previewWeighting = weighting;
        });
      })
    } else {
      // 免费功能或已解锁：正常可点击，清除预览
      Stack({ alignContent: Alignment.TopEnd }) {
        this.buildTabContent(weighting, displayName)
      }
      .layoutWeight(1)
      .height(56)
      .onClick(() => {
        Throttle.click(() => {
          this.previewWeighting = null;
          this.handleWeightingSelect(weighting);
        });
      })
    }
  }
  
  // 构建预览状态的Tab内容（高亮显示正在预览）
  @Builder
  private buildPreviewTabContent(weighting: WeightingType, displayName: string, isPreviewing: boolean) {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 计权类型图标
      Image(FrequencyWeightingConstants.getWeightingIcon(weighting))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor(isPreviewing ? $r('sys.color.font_emphasize') : $r('sys.color.font_tertiary'))

      // 计权类型名称
      Text(displayName)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(isPreviewing ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(isPreviewing ? $r('sys.color.font_emphasize') : $r('sys.color.font_tertiary'))
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .backgroundColor(isPreviewing ? 'rgba(51, 154, 240, 0.15)' : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .padding(DesignConstants.SPACING_MD)
  }
  
  // 显示计权解锁弹窗
  private showWeightingUnlockDialog(featureName: string, featureDesc: string): void {
    let upgradeDialog: InfSheet | null = null;
    let params: WeightingUnlockParams = {
      featureName: featureName,
      featureDesc: featureDesc,
      onUpgrade: () => {
        upgradeDialog?.dismiss();
        // 打开会员中心
        this.openMembershipCenter();
      }
    };
    upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: `解锁${featureName}` },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(WeightingUnlockContentBuilder), params)
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

  // 构建选项卡内容（纯展示，点击由外层处理）
  @Builder
  private buildTabContent(weighting: WeightingType, displayName: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 计权类型图标
      Image(FrequencyWeightingConstants.getWeightingIcon(weighting))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor(this.tempSelectedWeighting === weighting ?
        $r('sys.color.font_on_primary') :
          (this.hoveredWeighting === weighting ?
          $r('sys.color.interactive_active') :
          $r('sys.color.font_primary')))

      // 计权类型名称
      Text(displayName)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(this.tempSelectedWeighting === weighting ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.tempSelectedWeighting === weighting ?
        $r('sys.color.font_on_primary') :
          (this.hoveredWeighting === weighting ?
          $r('sys.color.interactive_active') :
          $r('sys.color.font_primary')))
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .backgroundColor(this.tempSelectedWeighting === weighting ?
    $r('sys.color.interactive_active') :
      (this.hoveredWeighting === weighting ?
      $r('sys.color.comp_background_secondary') :
      $r('sys.color.comp_background_primary')))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .padding(DesignConstants.SPACING_MD)
  }

  // 构建主要内容区域（面向普通用户）
  @Builder
  private buildPrimaryContentArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 实时预览面板（显示预览或选中的计权）
      FrequencyPreviewPanel({
        currentWeighting: this.currentWeighting,
        selectedWeighting: this.displayWeighting
      })

      // 场景展示（显示预览或选中的计权）
      FrequencyScenarioDisplay({
        selectedWeighting: this.displayWeighting
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
        
        Text(`解锁${this.getWeightingDisplayName(this.previewWeighting!)}`)
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
            this.previewWeighting = null;
          })
      }
      .width('100%')
      
      // 功能描述
      Text(`解锁后即可使用${this.getWeightingDisplayName(this.previewWeighting!)}模式进行专业测量，符合国际标准。`)
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
          Text('🌍')
            .fontSize(12)
          Text('国际标准')
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
        FrequencyTechnicalParamsDisplay({
          currentWeighting: this.currentWeighting,
          selectedWeighting: this.displayWeighting
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
        FrequencyAcousticExplanationComp({
          selectedWeighting: this.displayWeighting
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
        title: '频率加权模式',
        isSaveIconRequired: true,
        onSave: () => {
          this.handleSave();
        },
        onCancel: () => {
          this.handleCancel();
        }
      })

      // 固定选项卡区域
      this.buildFixedTabs()

      // 如果是预览锁定模式，显示解锁引导卡片（在Tab下方、详情上方）
      if (this.previewWeighting !== null && !isProMember()) {
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
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .justifyContent(FlexAlign.Start)
  }
}

// 频率加权弹框的Builder版本
@Builder
export function FrequencyWeightingDialogBuilder(param: FrequencyWeightingDialogParams
) {
  FrequencyWeightingDialog({
    currentWeighting: param.currentWeighting,
    onSettingsApplied: param.onSettingsApplied,
    onClose: param.onClose
  })
}

export interface FrequencyWeightingDialogParams {
  currentWeighting: WeightingType;
  onClose: () => void;
  onSettingsApplied?: (weighting: WeightingType) => void; // 新增：设置应用回调
}

// ============ 解锁弹窗内容 ============

interface WeightingUnlockParams {
  featureName: string;
  featureDesc: string;
  onUpgrade: () => void;
}

@Builder
function WeightingUnlockContentBuilder(params: WeightingUnlockParams) {
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
      
      Text(params.featureName)
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      
      Text(params.featureDesc)
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