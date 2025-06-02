import { DecibelRecord } from "../../models/DecibelRecord";
import { DecibelService } from "../../services/DecibelService"

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
  @Local noiseDistribution: NoiseDistribution = { segments: [], values: [] };

  aboutToAppear() {
    if (this.selectedRecord) {
      this.calculateNoiseDistribution();
    }
  }

  private calculateNoiseDistribution() {
    if (!this.selectedRecord || !this.selectedRecord.decibelValues.length) {
      return;
    }

    const values = this.selectedRecord.decibelValues;
    const levelCounts = new Map<string, number>();
    values.forEach(value => {
      const level = DecibelService.getDecibelLevel(value);
      levelCounts.set(level, (levelCounts.get(level) || 0) + 1);
    });

    const levelOrder = ['非常安静', '安静', '一般', '吵闹', '非常吵闹', '难以忍受'];
    const segments: NoiseSegment[] = [];
    const total = values.length;

    levelOrder.forEach(level => {
      const count = levelCounts.get(level) || 0;
      if (count > 0) {
        const sampleValue = values.find(v => DecibelService.getDecibelLevel(v) === level) || 0;
        segments.push({
          name: level,
          value: parseFloat(((count / total) * 100).toFixed(1)),
          color: DecibelService.getDecibelColor(sampleValue)
        });
      }
    });

    this.noiseDistribution = {
      segments: segments,
      values: segments.map(s => s.value)
    };
  }

  private getOverallNoiseDescription(): string {
    if (!this.noiseDistribution.segments.length) {
      return '';
    }

    // 获取各个噪音级别的占比
    const levels = this.noiseDistribution.segments.reduce((acc, curr) => {
      acc[curr.name] = curr.value;
      return acc;
    }, {} as Record<string, number>);

    // 根据占比生成描述
    let description = '';

    // 噪音组合
    const combination = this.analyzeNoiseCombination(levels);
    if (combination) {
      description += '🔊 ' + combination;
    }

    if (levels['难以忍受'] > 10) {
      const areaType = this.getAreaTypeForHighNoise();
      description += '，' + `⚠️ 存在危险噪音，超过${areaType}标准，建议立即采取保护措施`;
    }

    if (levels['非常吵闹'] > 20) {
      description += '，' + '🔊 接近工业区标准，可能影响听力健康';
    }

    if (levels['吵闹'] > 30) {
      description += '，' + '🔉 接近商业区标准，可能影响专注力，';
    }

    if (levels['一般'] > 40) {
      description += '，' + '🗣️ 符合居民区标准';
    }

    if (levels['安静'] > 50) {
      description += '，' + '🤫 达到疗养区标准，适合办公学习';
    }

    if (levels['非常安静'] > 60) {
      description += '，' + '🌙 环境非常安静，优于疗养区标准，适合休息';
    }

    // 追加新的分析结果
    description = description.trim();

    // 噪音对人体影响
    const healthImpact = this.analyzeHealthImpact(levels);
    if (healthImpact) {
      description += '，' + healthImpact;
    }

    // 建议
    const recommendations = this.generateRecommendations(levels);
    if (recommendations) {
      description += '，' + '📝 建议：' + recommendations;
    }

    return description + "。";
  }

  private getAreaTypeForHighNoise(): string {
    // 根据噪音特征判断具体区域类型
    // 这里需要根据实际数据实现具体逻辑
    // 暂时返回默认值'4a类（交通干线两侧区域）'
    return '4a类（交通干线两侧区域）';
  }

  // 新增方法：分析主要噪音组合
  private analyzeNoiseCombination(levels: Record<string, number>): string {
    const sortedLevels = Object.entries(levels)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3); // 取占比最高的3个级别

    // 根据组合生成描述
    if (sortedLevels[0][1] > 50) {
      return `环境${sortedLevels[0][0]}，占比${sortedLevels[0][1]}%`;
    } else {
      return `环境${sortedLevels.map(l => `${l[0]}(${l[1]}%)`).join('，')}`;
    }
  }

  // 新增方法：分析噪音持续时间
  private analyzeDuration(record: DecibelRecord): string {
    const duration = record.duration; // 假设record中有duration字段
    if (duration > 3600) {
      return '长时间暴露在高噪音环境中';
    } else if (duration > 1800) {
      return '中等时长暴露在噪音环境中';
    } else {
      return '短时间暴露在噪音环境中';
    }
  }

  // 新增方法：分析噪音对人体的影响
  private analyzeHealthImpact(levels: Record<string, number>): string {
    const impacts: string[] = [];

    if (levels['难以忍受'] > 10) {
      impacts.push('可能导致永久性听力损伤');
      impacts.push('增加心血管疾病风险');
    }

    if (levels['非常吵闹'] > 20) {
      impacts.push('可能导致暂时性听力下降');
      impacts.push('可能引起头痛和疲劳');
    }

    if (levels['吵闹'] > 30) {
      impacts.push('可能影响睡眠质量');
      impacts.push('可能导致注意力不集中');
    }

    if (levels['一般'] > 40) {
      impacts.push('可能影响工作效率');
    }

    if (levels['安静'] > 50) {
      impacts.push('有利于放松和集中注意力');
    }

    if (levels['非常安静'] > 60) {
      impacts.push('有利于深度睡眠和恢复');
    }

    return impacts.length > 0 ? ` ${impacts.join('，')}` : '';
  }

  // 新增方法：生成建议
  private generateRecommendations(levels: Record<string, number>): string {
    const recommendations: string[] = [];

    // 根据噪音组合生成建议
    if (levels['难以忍受'] + levels['非常吵闹'] > 30) {
      recommendations.push('使用降噪耳机或耳塞');
      recommendations.push('考虑安装隔音窗户');
    }

    if (levels['吵闹'] > 40) {
      recommendations.push('在重要时段关闭窗户');
      recommendations.push('考虑使用厚重的窗帘');
    }

    if (levels['一般'] > 60) {
      recommendations.push('在安静时段进行重要工作');
    }

    return recommendations.join('，');
  }

  build() {
    Column() {
      Text(this.getOverallNoiseDescription())
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Start)
        .width('100%')

      Row() {
        Column() {
          Text('最小值')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.minDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.minDecibel))
          }

          Text(DecibelService.getDecibelLevel(this.selectedRecord!.minDecibel))
            .fontSize(12)
            .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.minDecibel))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .height(90)

        Divider()
          .width(1)
          .height(60)
          .backgroundColor($r('app.color.divider'))
          .margin({ left: 12, right: 12 })

        Column() {
          Text('平均值')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.avgDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
          }

          Text(DecibelService.getDecibelLevel(this.selectedRecord!.avgDecibel))
            .fontSize(12)
            .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .height(90)

        Divider()
          .width(1)
          .height(60)
          .backgroundColor($r('app.color.text_primary'))
          .margin({ left: 12, right: 12 })

        Column() {
          Text('最大值')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })
          Row() {
            Text(this.selectedRecord!.maxDecibel.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
          }

          Text(DecibelService.getDecibelLevel(this.selectedRecord!.maxDecibel))
            .fontSize(12)
            .fontColor(DecibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
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
        .backgroundColor($r('app.color.divider'))
        .margin({ top: 12, bottom: 16 })

      if (this.selectedRecord && this.selectedRecord.decibelValues.length > 0) {
        Column() {
          ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
            Row() {
              Text(segment.name)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width(60)
                .margin({ right: 8 })

              Row()
                .width(`${segment.value * 0.7}%`)
                .height(12)
                .backgroundColor(segment.color)
                .borderRadius(6)
                .margin({ right: 8 })

              Text(`${segment.value}%`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
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
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}