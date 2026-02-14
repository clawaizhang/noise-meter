import { DecibelRecord } from '../../models/DecibelRecord';
import { DecibelService } from '../../services/DecibelService';
import { DesignConstants } from '../../constants/DesignConstants';

/**
 * 数据概览组件
 * 展示最小值、平均值、最大值、变化幅度四个关键指标
 */
@ComponentV2
export struct DataOverview {
  @Param selectedRecord: DecibelRecord | null = null;

  // 计算变化幅度 (标准差/平均值 * 100)
  @Computed
  get variationRate(): number {
    if (!this.selectedRecord?.decibelValues?.length) return 0;
    const values = this.selectedRecord.decibelValues;
    const avg = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((sum, val) => sum + Math.pow(val - avg, 2), 0) / values.length;
    const stdDev = Math.sqrt(variance);
    return Math.round((stdDev / avg) * 100);
  }

  // 获取变化幅度描述
  @Computed
  get variationDesc(): string {
    const rate = this.variationRate;
    if (rate < 5) return '很平稳';
    if (rate < 10) return '较平稳';
    if (rate < 20) return '有变化';
    if (rate < 30) return '变化大';
    return '变化剧烈';
  }

  @Computed
  get variationColor(): Resource {
    const rate = this.variationRate;
    if (rate < 10) return $r('app.color.health_good');
    if (rate < 20) return $r('app.color.decibel_normal');
    if (rate < 30) return $r('app.color.decibel_noisy');
    return $r('app.color.health_bad');
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_stats'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('数据概览')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 四个关键指标卡片 - 2×2 网格
      GridRow({ columns: 2, gutter: DesignConstants.SPACING_SM }) {
        // 最小值
        GridCol({ span: 1 }) {
          this.MetricCard(
            '最小音量',
            `${this.selectedRecord?.minDecibel ?? 0}`,
            'dB',
            DecibelService.getDecibelLevel(this.selectedRecord?.minDecibel ?? 0),
            DecibelService.getDecibelColor(this.selectedRecord?.minDecibel ?? 0),
            false
          )
        }

        // 平均值（突出显示）
        GridCol({ span: 1 }) {
          this.MetricCard(
            '平均音量',
            `${this.selectedRecord?.avgDecibel ?? 0}`,
            'dB',
            DecibelService.getDecibelLevel(this.selectedRecord?.avgDecibel ?? 0),
            DecibelService.getDecibelColor(this.selectedRecord?.avgDecibel ?? 0),
            true
          )
        }

        // 最大值
        GridCol({ span: 1 }) {
          this.MetricCard(
            '最大音量',
            `${this.selectedRecord?.maxDecibel ?? 0}`,
            'dB',
            DecibelService.getDecibelLevel(this.selectedRecord?.maxDecibel ?? 0),
            DecibelService.getDecibelColor(this.selectedRecord?.maxDecibel ?? 0),
            false
          )
        }

        // 变化幅度（替代波动率）
        GridCol({ span: 1 }) {
          this.MetricCard(
            '变化幅度',
            `${this.variationRate}`,
            '%',
            this.variationDesc,
            this.variationColor,
            false
          )
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  MetricCard(
    label: string,
    value: string,
    unit: string,
    level: string,
    color: Resource,
    highlight: boolean
  ) {
    Column({ space: DesignConstants.SPACING_XS }) {
      // 标签
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))

      // 数值
      Row({ space: 2 }) {
        Text(value)
          .fontSize(highlight ? 28 : 22)
          .fontWeight(highlight ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(color)
        Text(unit)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 4 })
      }

      // 等级标签
      Text(level)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor(color)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(4)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(highlight ? $r('sys.color.comp_background_secondary') : $r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: highlight ? 2 : 0,
      color: color,
      style: BorderStyle.Solid
    })
  }
}
