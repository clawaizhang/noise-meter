import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';

@Builder
function DecibelHistoryBuilder() {
  NoiseInfoDialog()
}

@ComponentV2
export struct NoiseInfoDialog {
  @Consumer(navigationStack) pageStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Text('【噪音级别定义】')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)

            .margin({ bottom: 16 })

          Row() {
            Column() {
              Text('安静环境')

                .fontColor($r('app.color.divider'))
              Text('如：图书馆、夜深人静')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('0-30分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('低噪音环境')

                .fontColor($r('app.color.divider'))
              Text('如：安静办公室、轻声细语')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('30-50分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('普通室内环境')

                .fontColor($r('app.color.divider'))
              Text('如：普通谈话、电视声音')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('50-60分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('正常交谈环境')

                .fontColor($r('app.color.divider'))
              Text('如：正常交谈、办公环境')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('60-70分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('嘈杂环境')

                .fontColor($r('app.color.divider'))
              Text('如：繁忙街道、餐厅内')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('70-80分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('很吵环境')

                .fontColor($r('app.color.divider'))
              Text('如：地铁内、大声说话')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('80-90分贝')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('高噪音环境')

                .fontColor($r('app.color.divider'))
              Text('如：工地施工、火车经过')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text('90分贝以上')

                .fontColor($r('app.color.divider'))
            }
            .alignItems(HorizontalAlign.End)
          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary')).margin({ bottom: 16 })

          Text('【噪音影响】')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)

            .margin({ top: 8, bottom: 16 })

          Row() {
            Column() {
              Text('70分贝以下')

                .fontColor($r('app.color.divider'))
              Text('一般不会对人体产生明显影响')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

          }

          .padding({ bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('70-80分贝')

                .fontColor($r('app.color.divider'))
              Text('长期处于该环境可能会感到烦躁')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('80-90分贝')

                .fontColor($r('app.color.divider'))
              Text('长期处于该环境可能会导致听力损伤')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

          }

          .padding({ top: 12, bottom: 12 })

          Divider().color($r('app.color.text_secondary'))

          Row() {
            Column() {
              Text('90分贝以上')

                .fontColor($r('app.color.divider'))
              Text('可能会对听力造成损害，建议采取防护措施')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)

          }

          .padding({ top: 12, bottom: 12 })

          Button('我知道了')

            .height(40)
            .backgroundColor($r('app.color.primary'))
            .fontColor($r('app.color.white'))
            .margin({ top: 16 })
            .onClick(() => {
              Throttle.click(() => {
                this.pageStack.pop();
              });
            })
        }
        .padding(16)
        .backgroundColor($r('app.color.background_secondary'))
        .borderRadius(16)
        .width('90%')
      }

    }
    .backgroundColor('rgba(0,0,0,0.7)')
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
  }
} 