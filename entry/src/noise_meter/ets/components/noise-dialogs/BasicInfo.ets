import { DecibelRecord } from "../../../../library/ets/models/DecibelRecord"

@Builder
export function BasicInfoBuilder(selectedRecord: DecibelRecord) {
  Column() {
    Text('基本信息')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .alignSelf(ItemAlign.Start)
      .margin({ bottom: 12 })

    Row() {
      Text('检测时间')
        .fontSize(14)
        .fontColor('#666666')
        .width('30%')
      Text(new Date(selectedRecord!.timestamp).toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      }))
        .fontSize(14)
        .fontColor('#333333')
        .width('70%')
    }
    .width('100%')
    .margin({ bottom: 8 })

    Row() {
      Text('检测时长')
        .fontSize(14)
        .fontColor('#666666')
        .width('30%')
      Text(`${(selectedRecord!.duration / 1000).toFixed(1)}秒`)
        .fontSize(14)
        .fontColor('#333333')
        .width('70%')
    }
    .width('100%')
    .margin({ bottom: 8 })

    if (selectedRecord!.location) {
      Row() {
        Text('检测位置')
          .fontSize(14)
          .fontColor('#666666')
          .width('30%')
        Text(selectedRecord!.location)
          .fontSize(14)
          .fontColor('#333333')
          .width('70%')
          .textOverflow({ overflow: TextOverflow.None })
      }
      .width('100%')
      .margin({ bottom: 8 })
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