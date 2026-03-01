import { DesignConstants } from '../../constants/DesignConstants';

/**
 * 报告水印组件
 * 体现品牌专业性和版本信息
 */
@ComponentV2
export struct ReportWatermark {
  @Param timestamp: number = Date.now();

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}.${String(date.getMonth() + 1).padStart(2, '0')}.${String(date.getDate()).padStart(2, '0')}`;
  }

  build() {
    Column({ space: DesignConstants.SPACING_XS }) {
      // 品牌标识行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_audio_analysis'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.brand'))
        
        Text('静喵-噪音检测分贝仪')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Text('Pro')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.brand'))
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .backgroundColor($r('app.color.primary_container'))
          .borderRadius(4)
      }

      // 版本和生成时间
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('v2.0.0')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
        
        Text('·')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
        
        Text(`${this.formatDateTime(this.timestamp)}`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_LG, bottom: DesignConstants.SPACING_MD })
    .alignItems(HorizontalAlign.Center)
  }
}
