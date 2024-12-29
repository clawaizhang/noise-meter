import { DecibelMeter } from "./DecibelMeter"

@Component
export struct NoiseDecibel {
  build() {
    Column() {
      DecibelMeter()
    }
    .width('100%')
  }
} 