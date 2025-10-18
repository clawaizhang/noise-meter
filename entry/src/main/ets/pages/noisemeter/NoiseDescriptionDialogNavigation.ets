import { curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

interface DecibelDescription {
  description: string;
  db: number;
  color: Resource
}

const decibelDescriptions: DecibelDescription[] = [
  { description: '喷气发动机', db: 140, color: $r('app.color.decibel_unbearable') },
  { description: '飞机起飞', db: 130, color: $r('app.color.decibel_very_noisy') },
  { description: '摇滚音乐会', db: 110, color: $r('app.color.decibel_very_noisy') },
  { description: '建筑工地', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '地铁列车', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '重型卡车', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '繁忙的街道', db: 80, color: $r('app.color.decibel_noisy') },
  { description: '繁忙的餐厅', db: 70, color: $r('app.color.decibel_normal') },
  { description: '普通对话', db: 60, color: $r('app.color.decibel_normal') },
  { description: '安静的办公室', db: 50, color: $r('app.color.decibel_quiet') },
  { description: '安静的图书馆', db: 40, color: $r('app.color.decibel_quiet') },
  { description: '耳语声', db: 30, color: $r('app.color.decibel_very_quiet') },
  { description: '安静的录音室', db: 20, color: $r('app.color.decibel_very_quiet') },
  { description: '几乎无声', db: 10, color: $r('app.color.decibel_very_quiet') },
]

// 对话框构建器
@Builder
export function NoiseDescriptionDialogBuilder(ak: AppKeys) {
  NavDestination() {
    // 噪音等级列表
    Scroll() {
      GridRow({
        columns: 1, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 8
      }) {
        ForEach(decibelDescriptions, (dd: DecibelDescription) => {
          GridCol({ span: 1 }) {
            Row() {
              Text(`${dd.db} dB`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(dd.color)
                .width('25%')

              Text(dd.description)
                .fontColor($r('sys.color.font_secondary'))
                .width('75%')
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 2 })
          }
          .backgroundBlurStyle(ak.uiDisplayState.displayDb > dd.db - 10 ? BlurStyle.COMPONENT_REGULAR : BlurStyle.NONE)
          .backgroundColor(ak.uiDisplayState.displayDb > dd.db - 10 ? dd.color :
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