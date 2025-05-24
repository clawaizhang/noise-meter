import promptAction from '@ohos.promptAction';
import { Theme } from '../../utils/Theme';

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
      .width('25%')
      .height(42)
      .margin({ top: 0, left: 32, right: 16 })
      .backgroundColor(Theme.getColor('button_primary'))
      .shadow({
        radius: 4,
        color: Theme.getColor('divider_primary'),
        offsetY: 2
      })
      .onClick(async () => {
        const confirmed = await promptAction.showDialog({
          title: '确认重置',
          message: '确认要重置当前数据吗？此操作不可恢复。',
          buttons: [
            {
              text: '取消',
              color: Theme.getColor('text_secondary')
            },
            {
              text: '确认',
              color: Theme.getColor('button_danger')
            }
          ]
        });
        if (confirmed.index === 1) {
          this.onReset();
        }
      })
  
      // 锁定/解锁按钮（放在中间）
      Button({
        type: ButtonType.Circle,
        stateEffect: true
      }) {
        Image($r('app.media.ic_lock'))
          .width(28)
          .height(28)
      }
      .width(64)
      .height(64)
      .backgroundColor(this.isUILocked ? Theme.getColor('button_secondary') : Theme.getColor('background_secondary'))
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
      .width('25%')
      .height(42)
      .margin({ top: 0, left: 16, right: 32 })
      .backgroundColor(Theme.getColor('button_primary'))
      .shadow({
        radius: 4,
        color: Theme.getColor('divider_primary'),
        offsetY: 2
      })
      .onClick(async () => {
        const confirmed = await promptAction.showDialog({
          title: '确定保存',
          message: '确定要保存当前数据吗？',
          buttons: [
            {
              text: '取消',
              color: Theme.getColor('text_secondary')
            },
            {
              text: '确定',
              color: Theme.getColor('button_primary')
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
  }
}
