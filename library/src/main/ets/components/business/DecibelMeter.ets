import { DecibelService } from '../../services/DecibelService';

/**
 * 分贝计组件
 * @param currentDecibel - 当前分贝值
 * @param maxDecibel - 最大分贝值
 * @param minDecibel - 最小分贝值
 */
@Component
export struct DecibelMeter {
  @Prop currentDecibel: number = 0;
  @State maxDecibel: number = 120;
  @State minDecibel: number = 0;
  private decibelService: DecibelService = new DecibelService();

  build() {
    Column() {
      Text(this.currentDecibel.toFixed(1))
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
      
      Row() {
        Text('dB')
          .fontSize(20)
          .fontColor('#666666')
        Text(this.decibelService.getDecibelLevel(this.currentDecibel))
          .fontSize(16)
          .fontColor('#666666')
          .margin({ left: 8 })
      }
      .margin({ top: 8 })
    }
    .backgroundColor('#F5F5F5')
    .borderRadius(16)
    .width('100%')
    .padding(20)
  }
} 