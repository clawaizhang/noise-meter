import { DecibelMeter } from '@ohos/library';

@Component
export struct NoiseDecibel {
  build() {
    Column() {
      DecibelMeter()
    }
    .width('100%')
    .padding({ top: 24, bottom: 24, left: 20, right: 20 })
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })
  }
} 