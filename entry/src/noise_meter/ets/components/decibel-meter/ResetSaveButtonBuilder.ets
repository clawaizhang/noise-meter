@Builder
export function DecibelMeterResetSaveButton(onReset:()=>void,onSave:()=>void) {
  Row() {
    Button({
      type: ButtonType.Capsule,
      stateEffect: true
    }) {
      Row() {
        Image($r('app.media.ic_reset'))
          .width(16)
          .height(16)
          .margin({ right: 4 })
          .fillColor(Color.White)
        Text('重置')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
    }
    .width('30%') // 进一步减小宽度
    .height(42) // 略微降低高度
    .margin({ top: 0, left: 16, right: 8 })
    .backgroundColor('#4A90E2') // 柔和的灰蓝色
    .shadow({
      radius: 4,
      color: '#1A4A90E2', // 轻微阴影
      offsetY: 2
    })
    .onClick(() => {
      onReset();
    })

    Button({
      type: ButtonType.Capsule,
      stateEffect: true
    }) {
      Row() {
        Image($r('app.media.ic_save'))
          .width(16)
          .height(16)
          .margin({ right: 4 })
          .fillColor(Color.White)
        Text('保存')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
    }
    .width('30%') // 进一步减小宽度
    .height(42) // 略微降低高度
    .margin({ top: 0, left: 8, right: 16 })
    .backgroundColor('#1A5A9E') // 深蓝色
    .shadow({
      radius: 4,
      color: '#1A1A5A9E', // 轻微阴影
      offsetY: 2
    })
    .onClick(() => {
      onSave();
    })
  }
  .width('100%')
  .justifyContent(FlexAlign.SpaceBetween)
}