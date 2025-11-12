import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import { SpectrumDataProcessor, PeakInfo } from './SpectrumDataProcessor';

/**
 * 多峰值频率显示组件
 * 可复用的组件，用于在图表中显示多个峰值频率信息
 */
@ComponentV2
export struct MultiplePeakFrequencyDisplay {
  @Param peakInfos: PeakInfo[] = [];
  @Param positionX: string = '86%';
  @Param positionY: string = '15%';

  build() {
    if (this.peakInfos && this.peakInfos.length > 0) {
      Column({ space: 4 }) {
        Text(`峰值频率`)
          .fontSize(UnifiedChartStyle.FONT_SIZES.value)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .opacity(0.8)
          .alignSelf(ItemAlign.End)
        
        // 显示每个峰值
        ForEach(this.peakInfos, (peakInfo: PeakInfo, index?: number) => {
          Row({ space: 8 }) {
            // 峰值编号
            Text(`#${index! + 1}`)
              .fontSize(UnifiedChartStyle.FONT_SIZES.value - 2)
              .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
              .opacity(0.7)
              .width(20)
              .textAlign(TextAlign.End)
            
            // 峰值信息
            Column({ space: 2 }) {
              Text(`${UnifiedChartStyle.formatFrequency(peakInfo.frequency)}`)
                .fontSize(UnifiedChartStyle.FONT_SIZES.value)
                .fontColor(SpectrumDataProcessor.getDbColor(peakInfo.dbValue))
                .fontWeight(FontWeight.Bold)
              
              Text(`${UnifiedChartStyle.formatDecibel(peakInfo.dbValue)}`)
                .fontSize(UnifiedChartStyle.FONT_SIZES.value - 2)
                .fontColor(SpectrumDataProcessor.getDbColor(peakInfo.dbValue))
                .opacity(0.8)
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
        })
      }
      .alignItems(HorizontalAlign.End)
      .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
      .padding({ left: UnifiedChartStyle.SPACING.sm, right: UnifiedChartStyle.SPACING.sm, top: 6, bottom: 6 })
      .borderRadius(UnifiedChartStyle.BORDER_RADIUS.small)
      .position({ x: this.positionX, y: this.positionY })
      .translate({ x: '-50%' })
      .zIndex(10) // 确保在最上层
    }
  }
}