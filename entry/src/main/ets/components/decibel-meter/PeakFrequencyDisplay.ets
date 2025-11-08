import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import { SpectrumDataProcessor } from './SpectrumDataProcessor';

/**
 * 峰值信息接口
 */
export interface PeakInfo {
  frequency: number;
  dbValue: number;
}

/**
 * 峰值频率显示组件
 * 可复用的组件，用于在图表中显示峰值频率信息
 */
@ComponentV2
export struct PeakFrequencyDisplay {
  @Param peakInfo: PeakInfo | null = null;
  @Param positionX: string = '95%';
  @Param positionY: string = '8%';

  build() {
    if (this.peakInfo && this.peakInfo.frequency > 0) {
      Column() {
        Text(`峰值频率`)
          .fontSize(UnifiedChartStyle.FONT_SIZES.value)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .opacity(0.8)
        Text(`${UnifiedChartStyle.formatFrequency(this.peakInfo.frequency)}`)
          .fontSize(UnifiedChartStyle.FONT_SIZES.value)
          .fontColor(SpectrumDataProcessor.getDbColor(this.peakInfo.dbValue))
          .fontWeight(FontWeight.Bold)
        Text(`${UnifiedChartStyle.formatDecibel(this.peakInfo.dbValue)}`)
          .fontSize(UnifiedChartStyle.FONT_SIZES.value)
          .fontColor(SpectrumDataProcessor.getDbColor(this.peakInfo.dbValue))
      }
      .alignItems(HorizontalAlign.End)
      .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
      .padding({ left: UnifiedChartStyle.SPACING.sm, right: UnifiedChartStyle.SPACING.sm, top: 4, bottom: 4 })
      .borderRadius(UnifiedChartStyle.BORDER_RADIUS.small)
      .position({ x: this.positionX, y: this.positionY })
      .translate({ x: '-50%' })
      .zIndex(10) // 确保在最上层
    }
  }
}