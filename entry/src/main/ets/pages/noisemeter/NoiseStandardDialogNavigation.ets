import { NoiseStandards } from '../../constants/NoiseStandardConstants';
import { AppKeys } from '../../models/AppKeys';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DecibelService } from '../../services/DecibelService';
import { curves } from '@kit.ArkUI';

@Builder
function buildNoiseStandardCard(standard: NoiseStandard, ak: AppKeys) {
  Column({ space: 8 }) {
    // 标题
    Text(standard.typeName)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.font_primary'));

    // 白天分贝
    Row() {
      Text('白天')
        .fontSize(16)
        .fontColor($r('app.color.font_secondary'));
      Text(`${standard.dayLimit} dB`)
        .fontColor(DecibelService.getDecibelColor(standard.dayLimit))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 });

      Text('夜间')
        .fontSize(16)
        .fontColor($r('app.color.font_secondary')).margin({ left: 16 });
      Text(`${standard.nightLimit} dB`)
        .fontColor(DecibelService.getDecibelColor(standard.nightLimit))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 });
    };

    Text(standard.description)
      .fontSize(14)
      .fontColor($r('app.color.font_secondary'));

  }
  .padding(16)
  .width('100%')
  .backgroundBlurStyle(ak.uiDisplayState.displayDb < standard.dayLimit ? BlurStyle.COMPONENT_ULTRA_THIN : BlurStyle.NONE)
  .backgroundColor(ak.uiDisplayState.displayDb < standard.dayLimit ? $r('app.color.comp_background_primary') :
  $r('app.color.warning'))
  .borderRadius(16)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Builder
export function NoiseStandardDialogBuilder(ak: AppKeys) {
  NavDestination() {
    Scroll() {
      Column({ space: 8 }) {
        buildNoiseStandardCard(NoiseStandards[0], ak)
        buildNoiseStandardCard(NoiseStandards[1], ak)
        buildNoiseStandardCard(NoiseStandards[2], ak)
        buildNoiseStandardCard(NoiseStandards[3], ak)
        buildNoiseStandardCard(NoiseStandards[4], ak)
        buildNoiseStandardCard(NoiseStandards[5], ak)
      }
    }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '噪音参考标准', sub: '白天：6:00-22:00，夜间：22:00-6:00' })
  .padding(16)
  .backgroundColor($r('app.color.background_secondary'))
}
