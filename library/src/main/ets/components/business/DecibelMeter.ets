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

  private getDecibelColor(value: number): string {
    if (value < 60) return '#4CAF50';  // 安全
    if (value < 90) return '#FFC107';  // 警告
    if (value < 100) return '#FF9800'; // 危险
    return '#F44336';                  // 极度危险
  }

  private getDecibelLevel(value: number): string {
    if (value < 30) return '安静';
    if (value < 60) return '正常';
    if (value < 90) return '嘈杂';
    if (value < 100) return '危险';
    return '极度危险';
  }

  build() {
    Column() {
      Text(this.currentDecibel.toFixed(1))
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDecibelColor(this.currentDecibel))
      
      Row() {
        Text('dB')
          .fontSize(20)
          .fontColor('#666666')
        Text(this.getDecibelLevel(this.currentDecibel))
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