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
import { FrequencyScenarioDisplay } from './FrequencyScenarioDisplay';
import { CollapsibleSection } from '../time-weighting/CollapsibleSection';
import { PremiumFeature } from '../membership/PremiumFeature';

@ComponentV2
export struct FrequencyWeightingDialog {
  @Param @Require currentWeighting: WeightingType; // 当前计权类型（从外部传入）
  @Param @Require onWeightingChange: (weighting: WeightingType) => void; // 计权类型变化回调
  @Param @Require onClose: () => void; // 关闭回调
  @Local selectedWeighting!: WeightingType; // 选中的计权类型
  @Local hoveredWeighting: WeightingType | null = null; // 悬停的计权类型
  @Local isTechnicalParamsExpanded: boolean = false; // 技术参数是否展开
  @Local isAcousticTheoryExpanded: boolean = false; // 声学原理是否展开

  aboutToAppear() {
    // 初始化选中计权类型为当前计权类型
    this.selectedWeighting = this.currentWeighting;
  }

  // 处理计权类型选择 - 即时生效
  private handleWeightingSelect(weighting: WeightingType) {
    this.selectedWeighting = weighting;
    // 立即应用新设置
    if (this.onWeightingChange) {
      this.onWeightingChange(weighting);
    }
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
    if (isPremium) {
      // 专业功能，使用PremiumFeature包装
      PremiumFeature({
        featureName: displayName,
        featureDesc: description
      }) {
        this.buildTabContent(weighting, displayName)
      }
    } else {
      // 免费功能，直接构建
      this.buildTabContent(weighting, displayName)
    }
  }

  // 构建选项卡内容
  @Builder
  private buildTabContent(weighting: WeightingType, displayName: string) {
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
      Text(displayName)
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
  }

  // 构建主要内容区域（面向普通用户）
  @Builder
  private buildPrimaryContentArea() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 实时预览面板
      FrequencyPreviewPanel({
        currentWeighting: this.currentWeighting,
        selectedWeighting: this.selectedWeighting
      })

      // 场景展示
      FrequencyScenarioDisplay({
        selectedWeighting: this.selectedWeighting
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
        FrequencyTechnicalParamsDisplay({
          currentWeighting: this.currentWeighting,
          selectedWeighting: this.selectedWeighting
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
          selectedWeighting: this.selectedWeighting
        })
      }
    }
    .width('100%')
  }

  build() {
    Column({ space: 8 }) {
      this.buildFixedTabs()
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
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)

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
    onWeightingChange: param.onWeightingChange,
    onClose: param.onClose
  })
}

export interface FrequencyWeightingDialogParams {
  currentWeighting: WeightingType;
  onWeightingChange: (weighting: WeightingType) => void;
  onClose: () => void;
}