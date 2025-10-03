import { DecibelRecord } from '../../models/DecibelRecord';
import { InputDialog } from '../decibel-meter/InputDialog';

@ComponentV2
export struct BasicInfo {
  @Param selectedRecord: DecibelRecord | null = null
  @Event commentChange: (comment: string) => void = () => {
  }; //正确用法
  @Local comment: string = ''

  aboutToAppear(): void {
    this.comment = this.selectedRecord!.comment
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Text('检测时间')
          .layoutWeight(3)
        Text(new Date(this.selectedRecord!.timestamp).toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: false
        }))
          .layoutWeight(5)
        Text(`共${(this.selectedRecord!.duration / 1000).toFixed(1)}秒`)
          .layoutWeight(2)
      }

      if (this.selectedRecord!.location) {
        Row() {
          Text('检测位置')
            .layoutWeight(3)
          Text(this.selectedRecord!.location)
            .layoutWeight(7)
            .textOverflow({ overflow: TextOverflow.None })
        }
      }

      // 添加备注显示区域
      Row() {
        Text('备注')
          .layoutWeight(3)
        Text(this.comment === '' ? '点击添加备注' : this.comment)
          .layoutWeight(7)
          .textOverflow({ overflow: TextOverflow.None })
          .focusable(true)
          .accessibilityDescription('备注输入区域')
          .animation({
            curve: Curve.EaseOut
          })
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(4)
          .padding(4)
          .id('pleaseEditTheComments')
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
    }
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
  }
}