@Component
export struct StatisticsView {
  @Link minDB: number
  @Link avgDB: number
  @Link maxDB: number
  getDBColor: (db: number) => string = () => '#666666'

  build() {
    Row() {
      Column() {
        Text('最小')
          .fontSize(14)
          .fontColor('#666666')
        Text(this.minDB.toFixed(1))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.minDB))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('平均')
          .fontSize(14)
          .fontColor('#666666')
        Text(this.avgDB.toFixed(1))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.avgDB))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('最大')
          .fontSize(14)
          .fontColor('#666666')
        Text(this.maxDB.toFixed(1))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.maxDB))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(80)
    .backgroundColor('#F5F5F5')
    .borderRadius(16)
    .padding({ top: 16, bottom: 16 })
    .margin({ bottom: 20 })
  }
} 