import promptAction from '@ohos.promptAction';

@ComponentV2
export struct ActionPanel {
  @Param isUILocked: boolean = false;
  @Event onReset: () => void;
  @Event onSave: () => void;
  @Event lockToggle: () => void;

  build() {
    Column() {
      // 操作按钮
      Row() {
        // 重置按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_reset'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor('#F0F0F0')
        .accessibilityDescription('重置当前数据')
        .onClick(async () => {
          const confirmed = await promptAction.showDialog({
            title: '确认重置',
            message: '确认要重置当前数据吗？此操作不可恢复。',
            buttons: [
              {
                text: '取消',
                color: '#666666'
              },
              {
                text: '确认',
                color: '#FF4444'
              }
            ]
          });
          if (confirmed.index === 1) {
            this.onReset();
          }
        })

        // 锁定按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_lock'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor(this.isUILocked ? '#E0E0E0' : '#F5F5F5')
        .accessibilityDescription(this.isUILocked ? '解锁界面' : '锁定界面')
        .onClick(() => {
          this.lockToggle();
        })

        // 保存按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_save'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .width(40)
        .height(40)
        .backgroundColor('#F0F0F0')
        .accessibilityDescription('保存当前数据')
        .onClick(async () => {
          const confirmed = await promptAction.showDialog({
            title: '确定保存',
            message: '确定要保存当前数据吗？',
            buttons: [
              {
                text: '取消',
                color: '#666666'
              },
              {
                text: '确定',
                color: '#4A90E2'
              }
            ]
          });
          if (confirmed.index === 1) {
            this.onSave();
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 24, right: 24, top: 8, bottom: 8 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .margin({ top: 8 })
  }
}