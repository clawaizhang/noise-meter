@ComponentV2
export struct ResetSaveButton {
  @Param isUILocked: boolean = false;
  @Event onReset: () => void;
  @Event onSave: () => void;
  @Event lockToggle: () => void;

  build() {
    Row() {
      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Row() {
          Image($r('app.media.ic_reset'))
            .width(14)
            .height(14)
            .margin({ right: 4 })
            .fillColor(Color.White)
          Text('重置')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('20%')
      .height(36)
      .margin({ top: 0, left: 32, right: 16 })
      .backgroundColor('#4A90E2')
      .shadow({
        radius: 4,
        color: '#1A4A90E2',
        offsetY: 2
      })
      .onClick(() => {
        this.onReset();
      })
  
      // 锁定/解锁按钮（放在中间）
      Button({
        type: ButtonType.Circle,
        stateEffect: true
      }) {
        Image(this.isUILocked ? $r('app.media.ic_lock') : $r('app.media.ic_unlock'))
          .width(28)
          .height(28)
      }
      .width(56)
      .height(56)
      .backgroundColor(this.isUILocked ? '#E0E0E0' : '#F5F5F5')
      .onClick(this.lockToggle)
  
      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Row() {
          Image($r('app.media.ic_save'))
            .width(14)
            .height(14)
            .margin({ right: 4 })
            .fillColor(Color.White)
          Text('保存')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('20%')
      .height(36)
      .margin({ top: 0, left: 16, right: 32 })
      .backgroundColor('#1A5A9E') // 深蓝色
      .shadow({
        radius: 4,
        color: '#1A1A5A9E', // 轻微阴影
        offsetY: 2
      })
      .onClick(() => {
        this.onSave();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}