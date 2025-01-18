import { DecibelRecord } from "../../models/DecibelRecord"
import { DecibelService } from "../../../../noise_meter/ets/services/DecibelService"

interface NoiseSegment {
  name: string;
  value: number;
  color: string;
}

interface NoiseDistribution {
  segments: NoiseSegment[];
  values: number[];
}

@ComponentV2
export struct Statistics {
  @Param selectedRecord: DecibelRecord | null = null;
  private decibelService: DecibelService = new DecibelService();
  @Local noiseDistribution: NoiseDistribution = { segments: [], values: [] };

  aboutToAppear() {
    if (this.selectedRecord) {
      this.calculateNoiseDistribution();
    }
  }

  private calculateNoiseDistribution() {
    if (!this.selectedRecord || !this.selectedRecord.decibelValues.length) return;

    const values = this.selectedRecord.decibelValues;
    const levelCounts = new Map<string, number>();
    values.forEach(value => {
      const level = this.decibelService.getDecibelLevel(value);
      levelCounts.set(level, (levelCounts.get(level) || 0) + 1);
    });

    const levelOrder = ['非常安静', '安静', '一般', '吵闹', '非常吵闹', '难以忍受'];
    const segments: NoiseSegment[] = [];
    const total = values.length;

    levelOrder.forEach(level => {
      const count = levelCounts.get(level) || 0;
      if (count > 0) {
        const sampleValue = values.find(v => this.decibelService.getDecibelLevel(v) === level) || 0;
        segments.push({
          name: level,
          value: parseFloat(((count / total) * 100).toFixed(1)),
          color: this.decibelService.getDecibelColor(sampleValue)
        });
      }
    });

    this.noiseDistribution = {
      segments: segments,
      values: segments.map(s => s.value)
    };
  }

  private getOverallNoiseDescription(): string {
    if (!this.noiseDistribution.segments.length) return '';

    // 获取各个噪音级别的占比
    const levels = this.noiseDistribution.segments.reduce((acc, curr) => {
      acc[curr.name] = curr.value;
      return acc;
    }, {} as Record<string, number>);

    // 根据占比生成描述
    let description = '';

    if (levels['难以忍受'] > 10) {
      const areaType = this.getAreaTypeForHighNoise();
      description += `⚠️ 存在危险噪音，超过${areaType}标准，建议立即采取保护措施。\n`;
    }

    if (levels['非常吵闹'] > 20) {
      description += '🔊 噪音水平较高，接近工业区标准，可能影响听力健康。\n';
    }

    if (levels['吵闹'] > 30) {
      description += '🔉 环境较为吵闹，接近商业区标准，可能影响专注力。\n';
    }

    if (levels['一般'] > 40) {
      description += '🗣️ 环境噪音处于正常水平，符合居民区标准。\n';
    }

    if (levels['安静'] > 50) {
      description += '🤫 环境较为安静，达到疗养区标准，适合办公学习。\n';
    }

    if (levels['非常安静'] > 60) {
      description += '🌙 环境非常安静，优于疗养区标准，适合休息。\n';
    }

    return description.trim();
  }

  private getAreaTypeForHighNoise(): string {
    // 根据噪音特征判断具体区域类型
    // 这里需要根据实际数据实现具体逻辑
    // 暂时返回默认值'4a类（交通干线两侧区域）'
    return '4a类（交通干线两侧区域）';
  }

  build() {
    Column() {
      Text('统计数据')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8, top: -16 })

      Text(this.getOverallNoiseDescription())
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Start)
        .width('100%')

      Row() {
        Column() {
          Text('最小值')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.minDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.minDecibel))
            Text(' 分贝')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 4 })
              .alignSelf(ItemAlign.End)
              .margin({ bottom: 4 })
          }

          Text(this.decibelService.getDecibelLevel(this.selectedRecord!.minDecibel))
            .fontSize(12)
            .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.minDecibel))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .height(90)

        Divider()
          .width(1)
          .height(60)
          .backgroundColor('#E0E0E0')
          .margin({ left: 12, right: 12 })

        Column() {
          Text('平均值')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.avgDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
            Text(' 分贝')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 4 })
              .alignSelf(ItemAlign.End)
              .margin({ bottom: 4 })
          }

          Text(this.decibelService.getDecibelLevel(this.selectedRecord!.avgDecibel))
            .fontSize(12)
            .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .height(90)

        Divider()
          .width(1)
          .height(60)
          .backgroundColor('#E0E0E0')
          .margin({ left: 12, right: 12 })

        Column() {
          Text('最大值')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.maxDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
            Text(' 分贝')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 4 })
              .alignSelf(ItemAlign.End)
              .margin({ bottom: 4 })
          }

          Text(this.decibelService.getDecibelLevel(this.selectedRecord!.maxDecibel))
            .fontSize(12)
            .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .height(90)
      }
      .width('100%')

      Divider()
        .width('100%')
        .height(1)
        .backgroundColor('#E0E0E0')
        .margin({ top: 12, bottom: 16 })

      if (this.selectedRecord && this.selectedRecord.decibelValues.length > 0) {
        Column() {
          ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
            Row() {
              Text(segment.name)
                .fontSize(12)
                .fontColor('#333333')
                .width(60)
                .margin({ right: 8 })

              Row()
                .width(`${segment.value * 0.8}%`)
                .height(12)
                .backgroundColor(segment.color)
                .borderRadius(6)
                .margin({ right: 8 })

              Text(`${segment.value}%`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')
            .margin({ bottom: 8 })
            .alignItems(VerticalAlign.Center)
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}