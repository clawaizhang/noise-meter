/**
 * 音频分析模式卡片组件
 * 用于显示单个音频分析模式的卡片，支持选中状态和点击交互
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

interface TimeWeightingCardStyle {
  backgroundColor: Resource;
  borderColor: Resource;
  borderWidth: number;
  scale: number;
}

interface TitleStyle {
  fontWeight: FontWeight;
  fontColor: Resource;
}

@ComponentV2
export struct TimeWeightingCard {
  @Param @Require mode: AudioAnalysisMode;                    // 当前模式
  @Param @Require selectedMode: AudioAnalysisMode;           // 选中的模式
  @Param @Require modeInfo: AudioAnalysisMode;               // 卡片对应的模式
  @Param @Require onSelect: (mode: AudioAnalysisMode) => void; // 选择回调

  @Local isHovered: boolean = false;               // 悬停状态

  // 获取卡片样式
  private getCardStyle() {
    const isSelected = this.selectedMode === this.modeInfo;
    
    return ({
      backgroundColor: isSelected ?
      $r('sys.color.interactive_active') :
      $r('sys.color.comp_background_primary'),
      borderColor: isSelected ?
      $r('sys.color.interactive_active') :
      $r('sys.color.comp_border_color'),
      borderWidth: isSelected ? 2 : 1,
      scale: this.isHovered && !isSelected ? 1.02 : 1.0
    } as TimeWeightingCardStyle);
  }

  // 获取标题样式
  private getTitleStyle() {
    const isSelected = this.selectedMode === this.modeInfo;
    
    return ({
      fontWeight: isSelected ? FontWeight.Bold : FontWeight.Medium,
      fontColor: isSelected ?
      $r('sys.color.font_on_primary') :
      $r('sys.color.font_primary')
    } as TitleStyle);
  }

  build() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 模式标题和图标
      Row({ space: DesignConstants.SPACING_SM }) {
        // 模式图标
        Image(TimeWeightingConstants.getModeIcon(this.modeInfo))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(this.getTitleStyle().fontColor)

        // 模式名称
        Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[this.modeInfo])
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(this.getTitleStyle().fontWeight)
          .fontColor(this.getTitleStyle().fontColor)
          .layoutWeight(1)

        // 选中指示器
        if (this.selectedMode === this.modeInfo) {
          Image($r('sys.media.ohos_ic_public_select_all'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.font_on_primary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 模式描述
      Text(TimeWeightingConstants.MODE_DESCRIPTIONS[this.modeInfo])
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.selectedMode === this.modeInfo ? $r('sys.color.font_on_primary') :$r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor( this.getCardStyle().backgroundColor)
    .border({
      width:  this.getCardStyle().borderWidth,
      color:  this.getCardStyle().borderColor,
      style: BorderStyle.Solid
    })
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .scale({ x:  this.getCardStyle().scale, y:  this.getCardStyle().scale })
    .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    .onClick(() => {
      this.onSelect(this.modeInfo);
    })
    .onHover((isHover: boolean) => {
      this.isHovered = isHover;
    })
  }
}