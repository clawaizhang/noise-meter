@Component
export struct DBDisplay {
  @Prop currentDB: number
  getDBColor: (db?: number) => string = () => '#4CAF50'
  getNoiseLevel: () => string = () => '安静环境'

  build() {
    Column() {
      // Gauge 部分
      Column() {
        Gauge({ value: this.currentDB / 120 * 100 })
          .width(200)
          .height(200)
          .colors([[0, 0x4CAF50], [0.3, 0x2196F3], [0.6, 0xFFC107], [0.9, 0xFF9800], [1, 0xF44336]])
          .startAngle(210)
          .endAngle(510)
          .strokeWidth(30)
          .zIndex(2)

        Text(this.currentDB.toFixed(0) + ' dB')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor())
          .margin({ top: -120 })
          .zIndex(1)
      }
      .margin({ top: 20, bottom: 40 })  // 增加底部间距

      // 噪音等级显示
      Text(this.getNoiseLevel())
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 20 })  // 增加顶部间距
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
} 