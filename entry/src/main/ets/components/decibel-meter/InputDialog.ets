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
        Column({ space: 8 }) {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_emphasize'))

          TextArea({ placeholder: '可选备注(最多64字)', text: this.default })
            .maxLength(140)
            .defaultFocus(true)
            .enterKeyType(EnterKeyType.Go)
            .fontColor((this.comment.length > 64) ? $r('sys.color.alert') : $r('sys.color.font_primary'))
            .onChange((value: string) => {
              this.comment = value;
              if (value.length > 64) {
                this.comment = value.substring(0, 64);
              }
            })
        }
      }

      GridCol({ span: 1 }) {
        GridRow({ columns: { xs: 2, sm: 2, md: 1 }, gutter: 8 }) {
          GridCol({ span: 1 }) {
            Button('取消')
              .height(36)
              .fontColor($r('sys.color.font_secondary'))
              .backgroundColor($r('sys.color.background_tertiary'))
              .onClick(() => {
                this.onClose();
              })
          }

          GridCol({ span: 1 }) {
            Button('保存')
              .height(36)
              .fontColor(Color.White)
              .backgroundColor($r('sys.color.font_emphasize'))
              .onClick(() => {
                this.onClose();
                this.onConfirm?.(this.comment);
              })
          }
        }
      }
    }.padding(16)
  }
}