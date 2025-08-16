@Extend(Text) function titleTextStyle() {
  .fontSize(20)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text) function cardTitleStyle() {
  .fontSize(16)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text) function cardValueStyle() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text) function gridItemTextStyle() {
  .fontSize(14)
  .fontColor($r('app.color.text_secondary'))
  .margin({ top: 8 })
}

@ComponentV2
export struct DeviceManagerPage {
  build() {
    Column() {
      // 设备状态卡片
      Column() {
        Row() {
          Text('设备状态')
            .cardTitleStyle()
          Blank()
          Text('良好')
            .fontSize(14)
            .fontColor($r('app.color.success'))
        }
        .width('100%')

        Divider()
          .strokeWidth(1)
          .color($r('app.color.divider'))

        Row() {
          Column() {
            Text('存储')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text('64GB/128GB')
              .cardValueStyle()
          }
          .margin({ right: 24 })

          Column() {
            Text('内存')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text('4.2GB/6GB')
              .cardValueStyle()
          }
        }
        .margin({ top: 12 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(12)
      .margin({ top: 8, bottom: 16 })

      // 功能入口网格
      Grid() {
        GridItem() {
          Column() {
            Image($r('app.media.ic_audio_analysis'))
              .width(32)
              .height(32)
            Text('清理加速')
              .gridItemTextStyle()
          }
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_battery'))
              .width(32)
              .height(32)
            Text('电池管理')
              .gridItemTextStyle()
          }
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_storage'))
              .width(32)
              .height(32)
            Text('存储管理')
              .gridItemTextStyle()
          }
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_security'))
              .width(32)
              .height(32)
            Text('安全中心')
              .gridItemTextStyle()
          }
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_security'))
              .width(32)
              .height(32)
            Text('安全中心')
              .gridItemTextStyle()
          }
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_security'))
              .width(32)
              .height(32)
            Text('安全中心')
              .gridItemTextStyle()
          }
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('90%')
      .height(180)
      .margin({ bottom: 16 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}