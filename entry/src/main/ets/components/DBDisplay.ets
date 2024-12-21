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
          .colors(new LinearGradient([
            { color: '#64BB5C', offset: 0 },     // 0-30dB 绿色
            { color: '#A4C93B', offset: 0.25 },  // 30-60dB 浅绿
            { color: '#FFD700', offset: 0.5 },   // 60-90dB 黄色
            { color: '#FFA500', offset: 0.75 },  // 90-105dB 橙色
            { color: '#FF4500', offset: 1 }      // 105-120dB 红色
          ]))
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
      .margin({ top: 20, bottom: 40 })

      // 噪音等级显示
      Text(this.getNoiseLevel())
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
} 