@Component
export struct HeaderTitle {
  build() {
    Row() {
      Text('噪音分贝仪')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
    }
    .margin({ top: 20, bottom: 20 })
  }
} 