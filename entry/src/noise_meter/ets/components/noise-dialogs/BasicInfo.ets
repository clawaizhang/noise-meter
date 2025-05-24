import { DecibelRecord } from "../../../../library/ets/models/DecibelRecord"
import { Theme } from "../../utils/Theme"
import { InputDialog } from "../decibel-meter/InputDialog"

@ComponentV2
export struct BasicInfo {
  @Param selectedRecord: DecibelRecord | null = null
  @Event commentChange: (comment:string)=>void = ()=>{}; //正确用法
  @Local comment:string=''

  aboutToAppear(): void {
    this.comment = this.selectedRecord!.comment
  }

  build() {
    Column() {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Text('检测时间')
          .fontSize(14)
          .fontColor(Theme.getColor('text_secondary'))
          .width('30%')
        Text(new Date(this.selectedRecord!.timestamp).toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: false
        }))
          .fontSize(14)
          .fontColor(Theme.getColor('text_primary'))
          .width('50%')
        Text(`共${(this.selectedRecord!.duration / 1000).toFixed(1)}秒`)
          .fontSize(14)
          .fontColor(Theme.getColor('text_primary'))
          .width('20%')
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.selectedRecord!.location) {
        Row() {
          Text('检测位置')
            .fontSize(14)
            .fontColor(Theme.getColor('text_secondary'))
            .width('30%')
          Text(this.selectedRecord!.location)
            .fontSize(14)
            .fontColor(Theme.getColor('text_primary'))
            .width('70%')
            .textOverflow({ overflow: TextOverflow.None })
        }
        .width('100%')
        .margin({ bottom: 8 })
      }

      // 添加备注显示区域
      Row() {
        Text('备注')
          .fontSize(14)
          .fontColor(Theme.getColor('text_secondary'))
          .width('30%')
        Text(this.comment === '' ? '点击添加备注' : this.comment)
          .fontSize(14)
          .fontColor(Theme.getColor('text_secondary'))
          .backgroundColor(Theme.getColor('background_secondary'))
          .width('70%')
          .textOverflow({ overflow: TextOverflow.None })
          .onClick(() => {
            const dialogController = new CustomDialogController({
              builder: InputDialog({
                title: '添加备注',
                default: this.selectedRecord!.comment,
                onConfirm: (comment: string) => {
                  this.comment = comment;
                  this.commentChange(this.comment);
                },
                onClose: () => {
                  dialogController.close();
                }
              }),
              cancel: () => {
                console.log('Dialog canceled');
              },
              autoCancel: true
            });
            dialogController.open();
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor(Theme.getColor('background_primary'))
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}