import { NoiseStandards } from '../../constants/NoiseStandardConstants';
import { AppKeys } from '../../models/AppKeys';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DecibelService } from '../../services/DecibelService';

@Builder
function buildNoiseStandardCard(standard: NoiseStandard, as: AppKeys) {
  Column({ space: 8 }) {
    // 标题
    Text(standard.typeName)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'));

    // 白天分贝
    Row() {
      Text('白天')
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary'));
      Text(`${standard.dayLimit} dB`)
        .fontColor(DecibelService.getDecibelColor(standard.dayLimit))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 });

      Text('夜间')
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary')).margin({ left: 16 });
      Text(`${standard.nightLimit} dB`)
        .fontColor(DecibelService.getDecibelColor(standard.nightLimit))
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 });
    };

    Text(standard.description)
      .fontSize(14)
      .fontColor($r('sys.color.font_secondary'));

  }
  .padding(16)
  .width('100%')
  .backgroundBlurStyle(as.db < standard.dayLimit ? BlurStyle.COMPONENT_ULTRA_THIN : BlurStyle.NONE)
  .backgroundColor(as.db < standard.dayLimit ? $r('sys.color.comp_background_primary') :
  $r('sys.color.warning'))
  .borderRadius(16)
  .alignItems(HorizontalAlign.Start)
}

@Builder
export function NoiseStandardDialogBuilder(as: AppKeys) {
  NavDestination() {
    Scroll() {
      Column({ space: 8 }) {
        buildNoiseStandardCard(NoiseStandards[0], as)
        buildNoiseStandardCard(NoiseStandards[1], as)
        buildNoiseStandardCard(NoiseStandards[2], as)
        buildNoiseStandardCard(NoiseStandards[3], as)
        buildNoiseStandardCard(NoiseStandards[4], as)
        buildNoiseStandardCard(NoiseStandards[5], as)
      }
    }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '噪音参考标准', sub: '白天：6:00-22:00，夜间：22:00-6:00' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}
