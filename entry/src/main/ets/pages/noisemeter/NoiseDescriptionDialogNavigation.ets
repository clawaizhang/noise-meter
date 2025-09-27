import { DialogHub } from '@hadss/dialoghub';
import { DecibelService } from '../../services/DecibelService';
import { NoiseStandardDialogBuilder } from './NoiseStandardDialogNavigation';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

// 对话框构建器
@Builder
export function NoiseDescriptionDialogBuilder(as: AppKeys) {
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
                .fontColor(DecibelService.getDecibelColor(db - 1))
                .width('25%')

              Text(DecibelService.getDecibelDescription(db - 1))
                .fontColor($r('sys.color.font_secondary'))
                .width('75%')
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 2 })
          }
          .backgroundBlurStyle(as.db > db ? BlurStyle.COMPONENT_REGULAR : BlurStyle.NONE)
          .backgroundColor(as.db > db ? DecibelService.getDecibelColor(db - 1) :
          $r('sys.color.comp_background_primary'))
          .padding(12)
          .borderRadius(12)
        })
      }
    }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }
  .backgroundColor($r('sys.color.background_secondary'))
  .title('噪音场景参考')
  .padding(16)
}