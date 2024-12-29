import { DecibelMeter } from '@ohos/library';

@Component
export struct NoiseDecibel {
  build() {
    Column() {
      DecibelMeter()
    }
    .width('100%')
  }
} 