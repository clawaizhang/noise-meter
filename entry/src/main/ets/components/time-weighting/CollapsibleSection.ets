/**
 * 可折叠区域组件
 * 用于实现专业内容的折叠/展开功能
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct CollapsibleSection {
  @Param @Require title: string;                          // 区域标题
  @Param @Require isExpanded: boolean = false;           // 是否展开
  @Param @Require onToggle: () => void;                  // 切换回调
  @BuilderParam content: () => void;                            // 内容区域

  @Local isHovered: boolean = false;                     // 悬停状态

  // 构建标题区域
  @Builder
  private buildHeader() {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text(this.title)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_primary'))
        .layoutWeight(1)

      // 展开/折叠图标
      Image(this.isExpanded ? 
        $r('sys.media.ohos_ic_public_arrow_up') : 
        $r('sys.media.ohos_ic_public_arrow_down'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor($r('app.color.font_secondary'))
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.isHovered ?
      $r('app.color.comp_background_secondary') :
      $r('app.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .onClick(() => {
      Throttle.click(() => {
        this.onToggle();
      });
    })
    .onHover((isHover: boolean) => {
      this.isHovered = isHover;
    })
  }

  // 构建内容区域
  @Builder
  private buildContent() {
    if (this.isExpanded) {
      Column({ space: DesignConstants.SPACING_MD }) {
        if (this.content) {
          this.content()
        }
      }
      .width('100%')
      .padding({ 
        left: DesignConstants.SPACING_MD, 
        right: DesignConstants.SPACING_MD,
        bottom: DesignConstants.SPACING_MD 
      })
      .backgroundColor($r('app.color.comp_background_primary'))
      .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
    }
  }

  build() {
    Column({ space: 0 }) {
      // 标题区域
      this.buildHeader()

      // 内容区域
      this.buildContent()
    }
    .width('100%')
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: 1,
      color: $r('app.color.comp_border_color'),
      style: BorderStyle.Solid
    })
  }
}