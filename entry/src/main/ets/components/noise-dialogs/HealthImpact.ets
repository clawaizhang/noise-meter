import { DecibelRecord } from '../../models/DecibelRecord';
import { DesignConstants } from '../../constants/DesignConstants';

/**
 * 健康影响评估组件
 * 展示噪音对健康的影响等级和建议措施
 */
@ComponentV2
export struct HealthImpact {
  @Param selectedRecord: DecibelRecord | null = null;

  // 风险等级
  @Computed
  get riskLevel(): 'low' | 'moderate' | 'high' | 'extreme' {
    const avg = this.selectedRecord?.avgDecibel ?? 0;
    const max = this.selectedRecord?.maxDecibel ?? 0;
    
    if (max >= 90 || avg >= 80) return 'extreme';
    if (max >= 80 || avg >= 70) return 'high';
    if (max >= 70 || avg >= 60) return 'moderate';
    return 'low';
  }

  @Computed
  get riskLevelText(): string {
    const level = this.riskLevel;
    if (level === 'low') return '低风险';
    if (level === 'moderate') return '中等风险';
    if (level === 'high') return '高风险';
    return '极高风险';
  }

  @Computed
  get riskLevelColor(): Resource {
    const level = this.riskLevel;
    if (level === 'low') return $r('app.color.health_good');
    if (level === 'moderate') return $r('app.color.decibel_normal');
    if (level === 'high') return $r('app.color.decibel_noisy');
    return $r('app.color.health_bad');
  }

  // 健康影响描述
  @Computed
  get healthImpacts(): string[] {
    const avg = this.selectedRecord?.avgDecibel ?? 0;
    const max = this.selectedRecord?.maxDecibel ?? 0;
    const impacts: string[] = [];

    if (max >= 90) {
      impacts.push('可能损伤听力');
      impacts.push('影响心血管健康');
    } else if (max >= 80) {
      impacts.push('可能暂时影响听力');
      impacts.push('可能引起头痛疲劳');
    } else if (max >= 70) {
      impacts.push('可能影响睡眠');
      impacts.push('可能影响注意力');
    } else if (avg >= 60) {
      impacts.push('可能影响工作效率');
    }

    if (impacts.length === 0) {
      impacts.push('环境噪音良好');
      impacts.push('对健康无明显影响');
    }

    return impacts;
  }

  // 建议措施
  @Computed
  get recommendations(): string[] {
    const avg = this.selectedRecord?.avgDecibel ?? 0;
    const max = this.selectedRecord?.maxDecibel ?? 0;
    const recs: string[] = [];

    if (max >= 90) {
      recs.push('立即佩戴耳塞');
      recs.push('尽快离开环境');
    } else if (max >= 80) {
      recs.push('建议佩戴耳塞');
      recs.push('控制停留时间');
    } else if (avg >= 70) {
      recs.push('重要时段关窗');
      recs.push('使用白噪音助眠');
    } else if (avg >= 60) {
      recs.push('安静时段做重要工作');
      recs.push('适当休息放松');
    } else {
      recs.push('环境适宜，无需防护');
      recs.push('保持良好习惯');
    }

    return recs;
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_smile'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('健康影响')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 风险等级和影�在一行
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧：风险等级
        Column({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_smile'))
            .width(40)
            .height(40)
            .fillColor(this.riskLevelColor)
          
          Text(this.riskLevelText)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.riskLevelColor)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor($r('sys.color.comp_background_secondary'))
            .borderRadius(8)
        }
        .width(80)
        .justifyContent(FlexAlign.Center)

        // 右侧：影响列表（最多显示2条）
        Column({ space: DesignConstants.SPACING_SM }) {
          ForEach(this.healthImpacts.slice(0, 2), (impact: string, index) => {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('•')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor(this.riskLevelColor)
              Text(impact)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 建议措施（最多显示2条）
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('建议')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        ForEach(this.recommendations.slice(0, 2), (rec: string, index) => {
          Row({ space: DesignConstants.SPACING_SM }) {
            Image($r('app.media.ic_save'))
              .width(DesignConstants.ICON_SIZE_SM)
              .height(DesignConstants.ICON_SIZE_SM)
              .fillColor($r('app.color.health_good'))
            Text(rec)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
          }
          .width('100%')
          .padding(DesignConstants.SPACING_SM)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
}
