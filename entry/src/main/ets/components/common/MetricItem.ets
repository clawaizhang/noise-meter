import { LengthUnit } from "@kit.ArkUI"
import { DesignConstants } from "../../constants/DesignConstants"

@ComponentV2
export struct MetricItem {
  @Param @Require icon: Resource
  @Param @Require value: string
  @Param @Require label: Resource
  @Param iconSize?: number = DesignConstants.METRIC_ITEM.ICON_SIZE
  @Param valueSize?: number = DesignConstants.METRIC_ITEM.VALUE_SIZE
  @Param labelSize?: number = DesignConstants.METRIC_ITEM.LABEL_SIZE
  @Param valueColor?: ResourceColor = $r('app.color.text_primary')
  @Param labelColor?: ResourceColor = $r('app.color.text_secondary')
  @Param fontWeight?: FontWeight = FontWeight.Medium
  @Param @Require onClickItem: () => void

  @Local isPressed: boolean = false

  build() {
    Column({ space: DesignConstants.METRIC_ITEM.SPACING }) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
      Text(this.value)
        .fontSize(this.valueSize)
        .fontWeight(this.fontWeight)
        .fontColor(this.valueColor)
      Text(this.label)
        .fontSize(this.labelSize)
        .fontColor(this.labelColor)
    }
    .padding(DesignConstants.METRIC_ITEM.PADDING)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.METRIC_ITEM.BORDER_RADIUS)
    .width(DesignConstants.METRIC_ITEM.WIDTH)
    .height(DesignConstants.METRIC_ITEM.HEIGHT)
    .opacity(this.isPressed ? DesignConstants.OPACITY_PRESSED : 1)
    .scale({ x: this.isPressed ? 0.95 : 1, y: this.isPressed ? 0.95 : 1 })
    .onClick(() => {
      if (this.onClickItem) {
        this.onClickItem()
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
  }
}