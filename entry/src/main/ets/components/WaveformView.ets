@Component
export struct WaveformView {
  @Prop waveData: Array<number>
  private containerWidth: number = 0

  build() {
    Row() {
      Polyline({ width: '100%', height: 100 })
        .points(this.waveData.map((value, index) => [
          Math.floor((index / (this.waveData.length - 1)) * this.containerWidth),
          Math.floor(100 - value)
        ]))
        .stroke(Color.Blue)
        .strokeWidth(1)
    }
    .width('100%')
    .height(100)
    .backgroundColor('#F5F5F5')
    .margin({ top: 20, bottom: 20 })
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.containerWidth = newArea.width as number
    })
  }
} 