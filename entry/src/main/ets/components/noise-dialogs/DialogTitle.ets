import { DecibelRecord } from "../../models/DecibelRecord";

const TAG = 'DialogTitle';
const DOMAIN = 0x0000;

@Builder
export function DialogTitleBuilder(
  selectedRecord: DecibelRecord,
  closeDialog: () => void,
  onShare: () => Promise<void>
) {
  Row() {
    Row() {
      Text('噪音检测报告')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      if (selectedRecord!.isFavorite) {
        Image($r('app.media.ic_favorite'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.icon_accent'))
          .margin({ left: 8 })
      }
    }

    Blank()
    Button() {
      Image($r('app.media.ic_share'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.icon_primary'))
    }
    .type(ButtonType.Circle)
    .backgroundColor(Color.Transparent)
    .onClick(onShare)
    .margin({ right: 8 })

    Button() {
      Image($r('app.media.ic_close'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.icon_primary'))
    }
    .type(ButtonType.Circle)
    .backgroundColor(Color.Transparent)
    .onClick(closeDialog)
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 12 })
}