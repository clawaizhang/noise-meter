interface WavePoint {
  x: number
  y: number
}

@Component
export struct WaveformView {
  @Prop waveData: Array<number>

  build() {
    Row() {
      Polyline({ width: '100%', height: '100%' })
        .points(this.waveData.map((value: number, index: number): WavePoint => {
          return {
            x: index * (100 / this.waveData.length),
            y: 50 - (value * 0.4)
          }
        }))
        .stroke(Color.Blue)
        .strokeWidth(2)
    }
    .width('100%')
    .height(100)
    .backgroundColor('#f5f5f5')
  }
} 