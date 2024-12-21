@Component
export struct DBDisplay {
  @Prop currentDB: number
  getDBColor: (db?: number) => string = () => '#4CAF50'
  getNoiseLevel: () => string = () => '安静环境'

  build() {
    Column() {
      Text(`${this.currentDB}`)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDBColor())
      Text('dB')
        .fontSize(20)
        .margin({ top: 5 })
      Text(this.getNoiseLevel())
        .fontSize(16)
        .margin({ top: 10 })
        .fontColor('#666666')
    }
    .margin({ top: 20, bottom: 20 })
  }
} 