@Component
export struct WaveformView {
  @Prop waveData: Array<number>
  private containerWidth: number = 0
  @State private waveHeight: number = 100
  @State private lineWidth: number = 1

  build() {
    Row() {
      Polyline()
        .width('100%')
        .height(this.waveHeight)
        .points(this.waveData.map((value, index) => [
          (index / (this.waveData.length - 1)) * this.containerWidth,
          this.waveHeight - value
        ]))
        .stroke(Color.Blue)
        .strokeWidth(this.lineWidth)
        .strokeLineJoin(LineJoinStyle.Round)
        .strokeLineCap(LineCapStyle.Round)
    }
    .width('100%')
    .height(this.waveHeight)
    .backgroundColor('#F5F5F5')
    .margin({ top: 20, bottom: 20 })
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.containerWidth = newArea.width as number
    })
  }
} 