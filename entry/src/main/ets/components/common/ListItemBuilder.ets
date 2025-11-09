import { Throttle } from '../../utils/Debounce'

/**
 * 通用列表项 Builder 组件
 * 用于创建统一的列表项布局，包含图标、标题和右侧箭头
 */
@Builder
export function ListItemBuilder(
  icon: Resource,
  title: string,
  onClick: () => void,
  marginTop: number = 12,
  showArrow: boolean = true
) {
  ListItem() {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor($r('app.color.brand'))
        .margin({ right: 12 })

      // 标题文本
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.font_primary'))
        .layoutWeight(1)

      // 右侧箭头（可选）
      if (showArrow) {
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.font_secondary'))
      }
    }
    .width('100%')
    .height(56)
    .padding({
      left: 16,
      right: 16
    })
    .alignItems(VerticalAlign.Center)
  }
  .borderRadius(16)
  .backgroundColor($r('app.color.comp_background_primary'))
  .margin({
    top: marginTop,
    left: 16,
    right: 16
  })
  .onClick(() => {
    Throttle.click(() => {
      onClick()
    })
  })
}