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

  build() {
    Column() {
      Text('统计数据')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8, top: -16 })

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
        Row() {
          Column() {
            ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
              Row() {
                Row()
                  .width(`${segment.value}%`)
                  .height(8)
                  .backgroundColor(segment.color)
                  .borderRadius(4)
              }
              .width('100%')
              .margin({ bottom: 8 })
            })
          }
          .width(160)
          .height(160)
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ right: 16, top: -16 })

          Column() {
            ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
              Row() {
                Row()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(segment.color)
                  .margin({ right: 8 })
                Text(segment.name)
                  .fontSize(14)
                  .fontColor('#333333')
                  .width(42)
                  .margin({ right: 2 })
                Text(`${segment.value}%`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(40)
                  .textAlign(TextAlign.Start)
              }
              .margin({ bottom: 8 })
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Start)
            })
          }
          .margin({ left: 16, top: -16 })
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
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