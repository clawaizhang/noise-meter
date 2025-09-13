import { common } from '@kit.AbilityKit';
import { DialogContainer } from '../../components/common/DialogContainer';
import { NoiseStandardCardBuilder } from '../../components/noise-dialogs/NoiseStandardCard';
import { NoiseStandards } from '../../constants/NoiseStandardConstants';
import { NoiseStandard } from '../../models/NoiseStandard';

@ComponentV2
export struct NoiseStandardDialog {
  build() {
    Column() {
      DialogContainer({
        ContentBuilder: this.StandardCardBuilder
      })
    }
  }

  @Builder
  StandardCardBuilder() {
    Column({space: 8}) {
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Center,
        alignContent: FlexAlign.Center
      }) {
        Text('噪音参考标准')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)

        Text('（白天：6:00-22:00，夜间：22:00-6:00）')

          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
      }

      Scroll() {
        GridRow({
          columns: {
            xs: 1,
            sm: 1,
            md: 2,
            lg: 2,
            xl: 3,
            xxl: 3
          }, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16
        }) {
          ForEach(NoiseStandards, (standard: NoiseStandard, index: number) => {
            GridCol({ span: 1 }) {
              NoiseStandardCardBuilder(standard, getContext(this) as common.UIAbilityContext)
            }
          }
          )
        }.margin({ bottom: 16 })
      }.scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

    }
  }
}

@Builder
export function NoiseStandardDialogBuilder() {
  NoiseStandardDialog()
}
