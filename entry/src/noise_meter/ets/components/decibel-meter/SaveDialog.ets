import promptAction from '@ohos.promptAction';

@CustomDialog
export struct SaveDialog {
  @State comment: string = '';
  controller: CustomDialogController;
  onConfirm?: (comment: string) => void;
  onClose: () => void = ()=>{};

  build() {
    Column() {
      Text('保存记录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      Text('请输入备注(最多64字)')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })

      TextInput({ placeholder: '输入备注...' })
        .width('100%')
        .height(80)
        .maxLength(140)
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.comment = value;
        })

      Row() {
        Button() {
          Text('取消')
            .fontSize(16)
        }
        .width('40%')
        .height(40)
        .backgroundColor('#F0F0F0')
        .onClick(() => {
          this.onClose();
        })

        Button() {
          Text('保存')
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width('40%')
        .height(40)
        .backgroundColor('#4A90E2')
        .margin({ left: 16 })
        .onClick(() => {
          this.onClose();
          this.onConfirm?.(this.comment);
        })
      }
      .width('100%')
      .margin({ top: 16 })
      .justifyContent(FlexAlign.Center)
    }
    .width('80%')
    .padding(16)
  }
}