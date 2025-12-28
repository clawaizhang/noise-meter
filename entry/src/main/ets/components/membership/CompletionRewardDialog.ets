/**
 * 完成奖励弹窗组件
 * 显示7天签到完成后的奖励
 */

import { DesignConstants } from '../../constants/DesignConstants';

export interface CompletionRewardDialogProps {
  totalRewardDays: number;
  onDismiss: () => void;
  onExperience?: () => void;
}

@Builder
export function CompletionRewardDialogBuilder(props: CompletionRewardDialogProps) {
  CompletionRewardDialog({
    onDismiss: props.onDismiss,
    onExperience: props.onExperience,
    totalRewardDays: props.totalRewardDays
  });
}

@ComponentV2
export struct CompletionRewardDialog {
  @Param @Require totalRewardDays: number = 0;
  @Event onDismiss: () => void = () => {};
  @Event onExperience?: () => void;

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 标题
      Text('🏆 恭喜完成7天签到！ 🏆')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 奖杯图标
      Text('🏆')
        .fontSize(48)
        .textAlign(TextAlign.Center)
        .width('100%')

      // 奖励信息
      Column({ space: DesignConstants.SPACING_SM }) {
        Text(`保底奖励：180天 会员`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`额外加成：+${this.totalRewardDays - 180}天 会员`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.brand'))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(`总计获得：${this.totalRewardDays}天 会员`)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.confirm'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')

      // 感谢信息
      Text('感谢您的支持！')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 按钮区域
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('确定')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.onDismiss();
          })

        if (this.onExperience) {
          Button('立即体验')
            .layoutWeight(1)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .backgroundColor($r('sys.color.brand'))
            .fontColor($r('sys.color.font_on_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_MD)
            .onClick(() => {
              this.onExperience!();
              this.onDismiss();
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
  }
}
