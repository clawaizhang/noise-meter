@Component
export struct WaveformView {
  @Prop waveData: Array<number>
  private containerWidth: number = 0
  @State private waveHeight: number = 100
  @State private lineWidth: number = 1
  private readonly axisPadding: number = 30
  private readonly rightPadding: number = 10
  private readonly yAxisLabels: number[] = [100, 60, 30, 0]

  private getDrawingWidth(): number {
    return this.containerWidth - this.axisPadding - this.rightPadding
  }

  build() {
    Column() {
      Row() {
        // Y轴刻度
        Column() {
          ForEach(this.yAxisLabels, (value: number) => {
            Text(value.toString())
              .fontSize(12)
              .fontColor('#666666')
          })
        }
        .width(25)
        .height(this.waveHeight)
        .alignItems(HorizontalAlign.End)
        .margin({ right: 5 })
        .justifyContent(FlexAlign.SpaceBetween)

        // 波形图区域
        Stack() {
          // 水平网格线
          Column() {
            ForEach(this.yAxisLabels, (value: number) => {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor('#EEEEEE')
            })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          // 垂直网格线
          Row() {
            ForEach([0, 1, 2, 3], (value: number) => {
              Column()
                .width(1)
                .height('100%')
                .backgroundColor('#EEEEEE')
            })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          // 波形图
          Polyline()
            .width('100%')
            .height('100%')
            .points(this.waveData.map((value, index) => [
              index * this.getDrawingWidth() / (this.waveData.length - 1),
              this.waveHeight - value
            ]))
            .stroke(Color.Blue)
            .strokeWidth(this.lineWidth)
            .strokeLineJoin(LineJoinStyle.Round)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width('100%')
        .height(this.waveHeight)
        .padding({ right: this.rightPadding })
      }
      .width('100%')
      .height(this.waveHeight)
      .backgroundColor('#F5F5F5')

      // X轴刻度
      Row() {
        ForEach([3, 2, 1, 0], (value: number) => {
          Text(value + 's')
            .fontSize(12)
            .fontColor('#666666')
        })
      }
      .width('100%')
      .height(20)
      .padding({ left: this.axisPadding, right: this.rightPadding })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .margin({ top: 20, bottom: 20 })
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.containerWidth = newArea.width as number
    })
  }
} 