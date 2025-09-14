import { DecibelService } from '../../services/DecibelService';

// 对话框构建器
@Builder
export function NoiseDescriptionDialogBuilder() {
  NavDestination() {
    // 噪音等级列表
    GridRow({
      columns: {
        xs: 1,
        sm: 1,
        md: 2,
        lg: 2,
        xl: 3,
        xxl: 3
      }, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 8
    }) {
      ForEach([110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10], (db: number) => {
        GridCol({ span: 1 }) {
          Row() {
            Text(`${db} dB`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(db - 1))
              .width('25%')

            Text(DecibelService.getDecibelDescription(db - 1))

              .fontColor($r('sys.color.font_secondary'))
              .width('75%')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({
            top: 8,
            bottom: 8,
            left: 12,
            right: 12
          })
          .backgroundColor($r('sys.color.background_secondary'))
          .margin({ bottom: 2 })
        }
      })
    }
  }
  .title('噪音场景参考')
  .padding(16)
}