import { DecibelService } from '../../services/DecibelService';
import { curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

// 对话框构建器
@Builder
export function NoiseDescriptionDialogBuilder(ak: AppKeys) {
  NavDestination() {
    // 噪音等级列表
    Scroll() {
      GridRow({
        columns: 1, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 8
      }) {
        ForEach([110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10], (db: number) => {
          GridCol({ span: 1 }) {
            Row() {
              Text(`${db} dB`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(ak.uiDisplayState.displayColor)
                .width('25%')

              Text(ak.uiDisplayState.displayDescription)
                .fontColor($r('sys.color.font_secondary'))
                .width('75%')
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 2 })
          }
          .backgroundBlurStyle(ak.uiDisplayState.displayDb > db - 10 ? BlurStyle.COMPONENT_REGULAR : BlurStyle.NONE)
          .backgroundColor(ak.uiDisplayState.displayDb > db - 10 ? ak.uiDisplayState.displayColor :
          $r('sys.color.comp_background_primary'))
          .padding(12)
          .borderRadius(12)
          .transition(TransitionEffect.OPACITY.animation({
            curve: curves.springMotion(0.6, 0.8)
          }) // 透明度动画，使用springMotion曲线
            .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
            .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
        })
      }
    }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }
  .backgroundColor($r('sys.color.background_secondary'))
  .title('噪音场景参考')
  .padding(16)
}