@Component
export struct WaveformView {
  @Prop waveData: Array<number>
  private containerWidth: number = 0
  @State private waveHeight: number = 100
  @State private lineWidth: number = 1
  private readonly axisPadding: number = 30

  build() {
    Column() {
      Row() {
        // Y轴刻度
        Column() {
          Text('100')
            .fontSize(12)
            .fontColor('#666666')
          Blank()
          Text('50')
            .fontSize(12)
            .fontColor('#666666')
          Blank()
          Text('0')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width(25)
        .height(this.waveHeight)
        .alignItems(HorizontalAlign.End)
        .margin({ right: 5 })

        // 波形图区域
        Stack() {
          // 网格线
          Column() {
            ForEach([0, 1, 2], () => {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor('#EEEEEE')
              Blank()
            })
          }
          .width('100%')
          .height('100%')

          // 波形图
          Polyline()
            .width('100%')
            .height('100%')
            .points(this.waveData.map((value, index) => [
              index * (this.containerWidth - this.axisPadding) / (this.waveData.length - 1),
              this.waveHeight - value
            ]))
            .stroke(Color.Blue)
            .strokeWidth(this.lineWidth)
            .strokeLineJoin(LineJoinStyle.Round)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width('100%')
        .height(this.waveHeight)
      }
      .width('100%')
      .height(this.waveHeight)
      .backgroundColor('#F5F5F5')

      // X轴刻度
      Row() {
        Text('3s')
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text('2s')
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text('1s')
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text('0s')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .height(20)
      .padding({ left: this.axisPadding, right: 10 })
    }
    .margin({ top: 20, bottom: 20 })
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.containerWidth = newArea.width as number
    })
  }
} 