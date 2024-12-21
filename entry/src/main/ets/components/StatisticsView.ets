@Component
export struct StatisticsView {
  @Prop minDB: number
  @Prop avgDB: number
  @Prop maxDB: number
  getDBColor: (db: number) => string = () => '#4CAF50'

  build() {
    Row() {
      Column() {
        Text('最小值')
          .fontSize(16)
        Text(`${this.minDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.minDB))
      }
      .margin({ right: 40 })

      Column() {
        Text('平均值')
          .fontSize(16)
        Text(`${this.avgDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.avgDB))
      }
      .margin({ right: 40 })

      Column() {
        Text('最大值')
          .fontSize(16)
        Text(`${this.maxDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.maxDB))
      }
    }
    .margin({ top: 20, bottom: 30 })
  }
} 