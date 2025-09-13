import { DecibelService, NoiseLevel } from '../../services/DecibelService';

const noiseLevels = DecibelService.getNoiseLevels();

@Builder
export function NoiseLevelDialogBuilder() {
  NavDestination() {
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
              .fontColor(item.color)
              .fontWeight(FontWeight.Bold)
              .margin({ right: 8 });

            Text(item.level)

              .margin({ right: 8 });

            Text(item.description)
              .fontSize(12)
              .lineHeight(16)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
        }

        .padding(12)
        .borderRadius(12)
        .shadow({ radius: 2, color: '#33000000', offsetY: 2 })
        .margin({ bottom: 8 });
      });
    }
    .padding(16)
  }.title('噪音等级说明')
}