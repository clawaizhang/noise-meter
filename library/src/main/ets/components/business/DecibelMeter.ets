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
  @State meterWidth: number = 300;
  @State meterHeight: number = 150;

  build() {
    Column() {
      // 分贝值显示
      Text(this.currentDecibel.toFixed(1) + ' dB')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 分贝计表盘
      Stack() {
        // 背景圆弧
        Shape() {
          Path()
            .width(this.meterWidth)
            .height(this.meterHeight)
            .commands('M 0 ' + this.meterHeight + ' A ' + this.meterHeight + ' ' + this.meterHeight + ' 0 0 1 ' + this.meterWidth + ' ' + this.meterHeight)
            .stroke('#E0E0E0')
            .strokeWidth(10)
            .fill('none')
        }

        // 当前值指示器
        Shape() {
          Path()
            .width(this.meterWidth)
            .height(this.meterHeight)
            .commands('M 0 ' + this.meterHeight + ' A ' + this.meterHeight + ' ' + this.meterHeight + ' 0 0 1 ' + 
              (this.meterWidth * (this.currentDecibel / this.maxDecibel)) + ' ' + this.meterHeight)
            .stroke('#007DFF')
            .strokeWidth(10)
            .fill('none')
        }

        // 刻度值
        Row() {
          Text(this.minDecibel + '')
            .fontSize(12)
            .fontColor('#999999')
          Blank()
          Text(this.maxDecibel + '')
            .fontSize(12)
            .fontColor('#999999')
        }
        .width(this.meterWidth)
        .position({ y: this.meterHeight + 20 })
      }
      .width(this.meterWidth)
      .height(this.meterHeight + 40)
    }
  }
} 