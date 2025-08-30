import { DialogContainer } from '../../components/common/DialogContainer';
import { DecibelService, NoiseLevel } from '../../services/DecibelService';

const noiseLevels = DecibelService.getNoiseLevels();

@ComponentV2
export struct NoiseLevelDialog {
  @Builder
  ContentBuilder() {
    Column() {
      Text('噪音等级说明')
        .fontSize(20)
        .fontColor($r('app.color.divider'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 });

      Scroll() {
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
          ForEach(noiseLevels, (item: NoiseLevel) => {
            GridCol({ span: 1 }) {
              Column() {
                Text(item.range)
                  .fontSize(16)
                  .fontColor(item.color)
                  .fontWeight(FontWeight.Bold)
                  .margin({ right: 8 });

                Text(item.level)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ right: 8 });

                Text(item.description)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .lineHeight(16)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.background_secondary'))
            .borderRadius(12)
            .shadow({ radius: 2, color: '#33000000', offsetY: 2 })
            .margin({ bottom: 8 });
          });
        }
      }.scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
  }

  build() {
    DialogContainer({
      ContentBuilder: this.ContentBuilder
    }
    )
  }
}

@Builder
export function NoiseLevelDialogBuilder() {
  NoiseLevelDialog()
}