@Component
export struct WaveformView {
  @Prop waveData: Array<number>

  build() {
    Row() {
      Polyline({ width: '100%', height: 100 })
        .points(this.waveData.map((value, index) => [
          index * (300 / this.waveData.length),
          100 - value
        ]))
        .stroke(Color.Blue)
        .strokeWidth(2)
    }
    .width('100%')
    .height(100)
    .backgroundColor('#F5F5F5')
    .margin({ top: 20, bottom: 20 })
  }
} 