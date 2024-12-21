@Component
export struct DBDisplay {
  @Prop currentDB: number
  getDBColor: (db?: number) => string = () => '#4CAF50'
  getNoiseLevel: () => string = () => '安静环境'

  build() {
    Column() {
      Row() {
        Column() {
          Gauge({ value: this.currentDB / 120 * 100 })
            .width(300)
            .height(300)
            .colors([[0, 0x4CAF50], [0.3, 0x2196F3], [0.6, 0xFFC107], [0.9, 0xFF9800], [1, 0xF44336]])
            .startAngle(210)
            .endAngle(510)
            .strokeWidth(20)

          Text(this.currentDB.toFixed(0) + ' dB')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getDBColor())
            .margin({ top: -160 })
        }
      }
      .margin({ top: 20 })

      Text(this.getNoiseLevel())
        .fontSize(16)
        .margin({ top: 10 })
        .fontColor('#666666')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
} 