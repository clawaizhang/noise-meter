/**
 * 增强模式选择面板
 * 提供更直观的用户友好的模式选择界面
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

interface TitleStyle {
  fontWeight: FontWeight;
  fontColor: Resource;
}

interface CardStyle {
  backgroundColor: Resource;
  borderColor: Resource;
  borderWidth: number;
  scale: number;
}

@ComponentV2
export struct EnhancedModeSelectionPanel {
  @Param @Require currentMode: AudioAnalysisMode;        // 当前模式
  @Param @Require selectedMode: AudioAnalysisMode;       // 选中的模式
  @Param @Require onModeSelect: (mode: AudioAnalysisMode) => void; // 模式选择回调

  @Local hoveredMode: AudioAnalysisMode | null = null;   // 悬停的模式

  // 获取模式卡片样式
  private getCardStyle(mode: AudioAnalysisMode) {
    const isSelected = this.selectedMode === mode;
    const isHovered = this.hoveredMode === mode;
    
    return ({
      backgroundColor: isSelected ?
      $r('sys.color.interactive_active') :
      $r('sys.color.comp_background_primary'),
      borderColor: isSelected ?
      $r('sys.color.interactive_active') :
      $r('sys.color.comp_border_color'),
      borderWidth: isSelected ? 2 : 1,
      scale: isHovered && !isSelected ? 1.02 : 1.0
    } as CardStyle);
  }

  // 获取标题样式
  private getTitleStyle(mode: AudioAnalysisMode) {
    const isSelected = this.selectedMode === mode;
    
    return ({
      fontWeight: isSelected ? FontWeight.Bold : FontWeight.Medium,
      fontColor: isSelected ?
      $r('sys.color.font_on_primary') :
      $r('sys.color.font_primary')
    } as TitleStyle);
  }

  // 构建单个模式卡片
  @Builder
  private buildModeCard(mode: AudioAnalysisMode) {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 模式图标和标题
      Row({ space: DesignConstants.SPACING_SM }) {
        // 模式图标
        Image(TimeWeightingConstants.getModeIcon(mode))
          .width(DesignConstants.ICON_SIZE_LG)
          .height(DesignConstants.ICON_SIZE_LG)
          .fillColor(this.getTitleStyle(mode).fontColor)

        // 模式名称
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[mode])
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(this.getTitleStyle(mode).fontWeight)
            .fontColor(this.getTitleStyle(mode).fontColor)

          Text(TimeWeightingConstants.MODE_DESCRIPTIONS[mode])
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.selectedMode === mode ? 
              $r('sys.color.font_on_primary') : 
              $r('sys.color.font_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        // 选中指示器
        if (this.selectedMode === mode) {
          Image($r('sys.media.ohos_ic_public_select_all'))
            .width(DesignConstants.ICON_SIZE_MD)
            .height(DesignConstants.ICON_SIZE_MD)
            .fillColor($r('sys.color.font_on_primary'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(this.getCardStyle(mode).backgroundColor)
    .border({
      width: this.getCardStyle(mode).borderWidth,
      color: this.getCardStyle(mode).borderColor,
      style: BorderStyle.Solid
    })
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .scale({ x: this.getCardStyle(mode).scale, y: this.getCardStyle(mode).scale })
    .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    .onClick(() => {
      this.onModeSelect(mode);
    })
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.hoveredMode = mode;
      } else {
        this.hoveredMode = null;
      }
    })
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Text('选择时间计权模式')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 模式卡片列表
      Column({ space: DesignConstants.SPACING_MD }) {
        ForEach(TimeWeightingConstants.getAvailableModes(), (mode: AudioAnalysisMode) => {
          this.buildModeCard(mode)
        })
      }
      .width('100%')

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}