@Component
export struct WaveformView {
  @Prop waveData: Array<number>
  private containerWidth: number = 0
  @State private waveHeight: number = 100
  @State private lineWidth: number = 1
  private readonly yAxisWidth: number = 30
  private readonly rightPadding: number = 5
  private readonly leftPadding: number = 20
  private readonly yAxisLabels: number[] = [100, 60, 30, 0]

  private getDrawingWidth(): number {
    return this.containerWidth - this.rightPadding - this.leftPadding
  }

  build() {
    Column() {
      Row() {
        Column() {
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
            .padding({ left: this.leftPadding })

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
            .padding({ left: this.leftPadding })

            // 波形图
            Polyline()
              .width('100%')
              .height('100%')
              .points(this.waveData.map((value, index) => [
                this.leftPadding + (this.waveData.length - 1 - index) * this.getDrawingWidth() / (this.waveData.length - 1),
                this.waveHeight - value
              ]).reverse())
              .stroke(Color.Blue)
              .strokeWidth(this.lineWidth)
              .strokeLineJoin(LineJoinStyle.Round)
              .strokeLineCap(LineCapStyle.Round)

            // Y轴刻度
            Column() {
              ForEach(this.yAxisLabels, (value: number) => {
                Text(value.toString())
                  .fontSize(12)
                  .fontColor('#666666')
              })
            }
            .width(this.yAxisWidth)
            .height('100%')
            .position({ x: 0, y: 0 })
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: 5, bottom: 5 })
          }
          .width('100%')
          .height(this.waveHeight)
          .backgroundColor('#F5F5F5')
          .padding({ right: this.rightPadding })

          // X轴刻度
          Row() {
            ForEach([0, 1, 2, 3], (value: number) => {
              Text(value + 's')
                .fontSize(12)
                .fontColor('#666666')
            })
          }
          .width('100%')
          .height(20)
          .padding({ left: this.leftPadding, right: this.rightPadding })
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('90%')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .margin({ top: 20, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.containerWidth = newArea.width as number
    })
  }
} 