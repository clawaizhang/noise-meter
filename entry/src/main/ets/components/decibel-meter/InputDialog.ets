@CustomDialog
export struct InputDialog {
  comment: string = '';
  title: string = '';
  default: string = '';
  controller: CustomDialogController;
  onConfirm?: (comment: string) => void;
  onClose: () => void = () => {
  };

  build() {
    GridRow({
      columns: {
        xs: 1,
        sm: 1,
        md: 2,
        lg: 2,
        xl: 2,
        xxl: 2
      },
      breakpoints: { reference: BreakpointsReference.WindowSize },
      gutter: 8
    }) {
      GridCol({ span: 1 }) {
        Column() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.icon_active'))
            .margin({ bottom: 16 })

          TextArea({ placeholder: '请输入备注(最多64字)', text: this.default })
            .width('100%')
            .height(80)
            .maxLength(140)
            .defaultFocus(true)
            .enableKeyboardOnFocus(true)
            .enterKeyType(EnterKeyType.Go)
            .fontSize(14)
            .fontColor((this.comment.length > 64) ? $r('app.color.error') : $r('app.color.text_primary'))
            .onChange((value: string) => {
              this.comment = value;
              if (value.length > 64) {
                this.comment = value.substring(0, 64);
              }
            })
        }
      }

      GridCol({ span: 1 }) {
        GridRow({ columns: 2 }) {
          GridCol({ span: 1 }) {
            Button() {
              Text('取消')
                .fontSize(16)
            }
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.transparent_white_90'))
            .onClick(() => {
              this.onClose();
            })
          }.padding({bottom: 16})

          GridCol({ span: 1 }) {
            Button() {
              Text('保存')
                .fontSize(16)
                .fontColor($r('app.color.white'))
            }
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.button_primary'))
            .margin({ left: 24 })
            .onClick(() => {
              this.onClose();
              this.onConfirm?.(this.comment);
            })
          }.padding({bottom: 16})
        }
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('90%')
    .padding(16)
  }
}