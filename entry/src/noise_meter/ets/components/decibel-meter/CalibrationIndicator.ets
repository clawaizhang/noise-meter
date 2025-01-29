import { WeightingType } from "../../../../library/ets/constants/WeightingConstants";

interface CalibrationConfig {
  gain: number;
  weightingType: WeightingType;
}

@Builder
export function CalibrationIndicator(config: CalibrationConfig) {
  Row() {
    Text('声级校准:')
      .fontSize(12)
      .fontColor(Color.Gray)

    Text(`${config.gain} ${config.weightingType === WeightingType.A ? 'dB(A)' : config.weightingType === WeightingType.C ? 'dB(C)' : 'dB'}`)
      .fontSize(12)
      .fontColor(Color.Gray)
      .margin({ left: 5 })
  }
  .position({
    x: '65%', // 调整到右侧
    y: '2%'    // 调整到顶部
  })
  .margin({ right: 8 })
  .opacity(0.7)
}