@Component
export struct DBDisplay {
  @Prop currentDB: number
  getDBColor: (db?: number) => string = () => '#4CAF50'
  getNoiseLevel: () => string = () => '安静环境'

  build() {
    Column() {
      Row() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
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

            Row() {
              Text(this.currentDB.toFixed(0))
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getDBColor())
              Text('dB')
                .fontSize(16)
                .fontWeight(FontWeight.Normal)
                .fontColor(this.getDBColor())
                .margin({ left: 2, top: 20 })
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Bottom)
            .zIndex(1)
          }
        }
      }
      .margin({ top: 20 })

      Text(this.getNoiseLevel())
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 10 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
} 