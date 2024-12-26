import { LocationDisplay, DecibelMeter } from '@ohos/library';

@Entry
@Component
struct Index {
  build() {
    Column() {
      LocationDisplay()
        .margin({ top: 16, bottom: 8 })
      
      DecibelMeter()
    }
    .width('100%')
  }
}