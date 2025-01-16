
interface CalibrationConfig {
  gain: number;
}

@Builder
export function CalibrationIndicator(config: CalibrationConfig) {
  Row() {
    Text('声级校准:')
      .fontSize(12)
      .fontColor(Color.Gray)

    Text(`${config.gain} dB`)
      .fontSize(12)
      .fontColor(Color.Gray)
      .margin({ left: 5 })
  }
  .position({
    x: '70%', // 调整到右侧
    y: '2%'    // 调整到顶部
  })
  .margin({ right: 8 })
  .opacity(0.7)
}