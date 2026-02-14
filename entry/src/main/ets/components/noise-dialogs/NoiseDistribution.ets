import { DecibelRecord } from '../../models/DecibelRecord';
import { DecibelService } from '../../services/DecibelService';
import { DesignConstants } from '../../constants/DesignConstants';

interface NoiseSegment {
  name: string;
  count: number;
  percentage: number;
  color: Resource;
}

interface NoiseLevelDef {
  name: string;
  max: number;
}

/**
 * 噪音分布统计组件
 * 展示噪音级别分布条形图
 */
@ComponentV2
export struct NoiseDistribution {
  @Param selectedRecord: DecibelRecord | null = null;

  @Computed
  get distributionData(): NoiseSegment[] {
    if (!this.selectedRecord?.decibelValues?.length) {
      return [];
    }

    const values = this.selectedRecord.decibelValues;
    const total = values.length;

    // 定义噪音级别
    const levels: NoiseLevelDef[] = [
      { name: '非常安静', max: 30 },
      { name: '安静', max: 40 },
      { name: '一般', max: 50 },
      { name: '吵闹', max: 60 },
      { name: '很吵', max: 70 },
      { name: '极吵', max: 9999 }
    ];

    // 统计各级别数量
    const segments: NoiseSegment[] = [];
    let currentMin = 0;

    levels.forEach(level => {
      const count = values.filter(v => v >= currentMin && v < level.max).length;
      if (count > 0) {
        const sampleValue = values.find(v => v >= currentMin && v < level.max) || 0;
        segments.push({
          name: level.name,
          count: count,
          percentage: parseFloat(((count / total) * 100).toFixed(1)),
          color: DecibelService.getDecibelColor(sampleValue)
        });
      }
      currentMin = level.max;
    });

    return segments.sort((a, b) => b.percentage - a.percentage);
  }

  @Computed
  get analysisConclusion(): string {
    const data = this.distributionData;
    if (data.length === 0) return '暂无数据';

    const mainSegment = data[0];
    const total = this.selectedRecord!.decibelValues.length;
    const highNoiseCount = this.selectedRecord!.decibelValues.filter(v => v >= 70).length;
    const highNoisePercent = ((highNoiseCount / total) * 100).toFixed(1);

    let conclusion = '';

    // 主要环境特征
    if (mainSegment.percentage > 50) {
      conclusion += `整体${mainSegment.name}，占比${mainSegment.percentage}%`;
    } else {
      const top2 = data.slice(0, 2);
      conclusion += `主要为${top2.map(d => d.name).join('和')}`;
    }

    // 高噪音提示
    if (highNoiseCount > 0 && parseFloat(highNoisePercent) > 20) {
      conclusion += `，有${highNoisePercent}%时间较吵`;
    }

    return conclusion;
  }

  // 高噪音持续时间（秒）
  @Computed
  get highNoiseDuration(): number {
    const values = this.selectedRecord?.decibelValues ?? [];
    const highNoiseCount = values.filter(v => v >= 70).length;
    const totalDuration = this.selectedRecord?.duration ?? 0;
    if (values.length === 0) return 0;
    return Math.round((highNoiseCount / values.length) * totalDuration);
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_stats_bold'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('音量分布')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 分析结论
      Text(this.analysisConclusion)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 分布条形图（只显示前3个）
      Column({ space: DesignConstants.SPACING_SM }) {
        ForEach(this.distributionData.slice(0, 3), (segment: NoiseSegment, index) => {
          this.DistributionBar(segment)
        })
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_SM })

      // 数据摘要（带说明）
      Column({ space: DesignConstants.SPACING_SM }) {
        // 采样次数说明
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('数据采集')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
          Blank()
          Text(`${this.selectedRecord?.decibelValues?.length ?? 0}次`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        
        Text('检测过程中采集数据的次数')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
          .width('100%')

        Divider()
          .color($r('sys.color.comp_background_secondary'))
          .margin({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })

        // 高噪音时长说明
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('高音量时长')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
          Blank()
          Text(`${this.highNoiseDuration}秒`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highNoiseDuration > 10 ? $r('app.color.health_bad') : $r('sys.color.font_primary'))
        }
        .width('100%')
        
        Text('音量超过70dB的持续时间（超过70dB可能损伤听力）')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
          .width('100%')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  DistributionBar(segment: NoiseSegment) {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 级别名称
      Text(segment.name)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width(50)

      // 进度条
      Stack({ alignContent: Alignment.Start }) {
        // 背景
        Row()
          .width('100%')
          .height(6)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(3)

        // 进度
        Row()
          .width(`${segment.percentage}%`)
          .height(6)
          .backgroundColor(segment.color)
          .borderRadius(3)
      }
      .layoutWeight(1)
      .height(6)

      // 百分比
      Text(`${segment.percentage}%`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(segment.color)
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(24)
    .alignItems(VerticalAlign.Center)
  }
}
