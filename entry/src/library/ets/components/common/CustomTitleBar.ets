interface TitleButton {
  text: string;
  onClick: () => void;
}

@ComponentV2
export struct CustomTitleBar {
  @Param @Require title: string|Resource
  @Param rightButton?: TitleButton | null = null

  build() {
    Stack() {
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.rightButton) {
        Row() {
          Blank()
          Button() {
            Text(this.rightButton.text)
              .fontSize(14)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
          }
          .height(32)
          .width(56)
          .backgroundColor('#EEEEEE')
          .padding({ left: 12, right: 12 })
          .borderRadius(16)
          .onClick(this.rightButton.onClick)
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