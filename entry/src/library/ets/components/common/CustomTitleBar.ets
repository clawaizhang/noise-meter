interface TitleButton {
  text?: string;
  icon?: Resource;
  onClick: () => void;
}

@ComponentV2
export struct CustomTitleBar {
  @Param @Require title: string|Resource
  @Param buttons?: TitleButton[] = []

  build() {
    Stack() {
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.buttons && this.buttons.length > 0) {
        Row() {
          Blank()
          ForEach(this.buttons, (button:TitleButton, index) => {
            Button() {
              if (button.icon) {
                Image(button.icon)
                  .width(20)
                  .height(20)
                  .margin({ right: 4 })
              }
              else if (button.text) {
                Text(button.text)
                  .fontSize(14)
                  .fontColor('#666666')
                  .textAlign(TextAlign.Center)
              }
            }
            .height(32)
            .width(56)
            .backgroundColor('#EEEEEE')
            .padding({ left: 12, right: 12 })
            .borderRadius(16)
            .onClick(button.onClick)
            .margin({ right: index < (this.buttons?.length ?? 0) - 1 ? 8 : 0 })
          })
        }
        .width('100%')
        .height(56)
        .padding({ right: 16 })
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor('#F5F5F5')
  }
} 