
@CustomDialog
export struct InputDialog {
  @State comment: string = '';
  title:string = '';
  default:string = '';
  controller: CustomDialogController;
  onConfirm?: (comment: string) => void;
  onClose: () => void = ()=>{};

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      TextArea({ placeholder: '请输入备注(最多64字)', text: this.default })
        .width('100%')
        .height(80)
        .maxLength(140)
        .defaultFocus(true)
        .enableKeyboardOnFocus(true)
        .enterKeyType(EnterKeyType.Go)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .onChange((value: string) => {
          this.comment = value;
          if (value.length > 64) {
            this.comment = value.substring(0, 64);
          }
        })

      Row() {
        Button() {
          Text('取消')
            .fontSize(16)
        }
        .width('40%')
        .height(40)
        .backgroundColor($r('app.color.button_primary'))
        .onClick(() => {
          this.onClose();
        })

        Button() {
          Text('保存')
            .fontSize(16)
            .fontColor($r('app.color.white'))
        }
        .width('40%')
        .height(40)
        .backgroundColor($r('app.color.button_primary'))
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