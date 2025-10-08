/**
 * 奖励完成弹窗组件
 * 用户完成使用时显示的庆祝弹窗
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { Throttle } from '../../utils/Debounce';

interface RewardCompletionDialogProps {
  consecutiveDays: number;
  rewardDays: number;
  expiryDate: number;
  onClose: () => void;
}

@Builder
export function RewardComplationBuilder(props: RewardCompletionDialogProps) {
  RewardCompletionDialog({
    consecutiveDays: props.consecutiveDays,
    rewardDays: props.rewardDays,
    expiryDate: props.expiryDate,
    onClose: props.onClose
  })
}

@ComponentV2
export struct RewardCompletionDialog {
  @Param @Require consecutiveDays: number;
  @Param @Require rewardDays: number;
  @Param @Require expiryDate: number;
  @Event onClose: () => void;

  /**
   * 格式化日期
   * @param timestamp 时间戳
   * @returns 格式化日期字符串
   */
  private formatDate(timestamp: number): string {
    if (!timestamp || timestamp === 0) {
      return '--';
    }
    const date = new Date(timestamp);
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  /**
   * 获取里程碑描述
   * @returns 里程碑描述
   */
  private getMilestoneDescription(): string {
    if (this.consecutiveDays === 3) {
      return '🎉 恭喜达成3天里程碑！';
    } else if (this.consecutiveDays === 7) {
      return '🎊 恭喜达成7天里程碑！';
    } else if (this.consecutiveDays === 10) {
      return '🏆 恭喜达成10天里程碑！';
    } else if (this.consecutiveDays === 15) {
      return '🌟 恭喜达成15天里程碑！';
    } else if (this.consecutiveDays === 30) {
      return '💎 恭喜达成30天里程碑！';
    } else {
      return '🎉 恭喜完成今日使用！';
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 庆祝图标
      Image($r('app.media.ic_favorite'))
        .width(64)
        .height(64)
        .fillColor($r('sys.color.confirm'))
        .margin({ top: DesignConstants.SPACING_XL })

      // 标题
      Text(this.getMilestoneDescription())
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      // 奖励信息卡片
      Column({ space: DesignConstants.SPACING_MD }) {
        // 连续天数
        Row() {
          Text('连续使用')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text(`${this.consecutiveDays}天`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.warning'))
        }
        .width('100%')

        // 获得奖励
        Row() {
          Text('获得奖励')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text(`${this.rewardDays}天专业会员`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.confirm'))
        }
        .width('100%')

        // 会员到期
        Row() {
          Text('会员到期')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          Text(this.formatDate(this.expiryDate))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .border({
        width: DesignConstants.BORDER_WIDTH_SM,
        color: $r('sys.color.comp_border_color')
      })
      .width('100%')

      // 提示文字
      Text('继续坚持使用，解锁更多会员天数！')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 确定按钮
      Button('确定')
        .width('100%')
        .height(48)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .backgroundColor($r('sys.color.confirm'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.onClose();
          });
        })
        .margin({ top: DesignConstants.SPACING_LG })
    }
    .padding(DesignConstants.SPACING_LG)
    .width('100%')
  }
}

/**
 * 显示奖励完成弹窗
 * @param consecutiveDays 连续天数
 * @param rewardDays 奖励天数
 * @param expiryDate 会员到期时间
 */
export function showRewardCompletionDialog(
  consecutiveDays: number,
  rewardDays: number,
  expiryDate: number
): void {
  let props: RewardCompletionDialogProps = {
    consecutiveDays,
    rewardDays,
    expiryDate,
    onClose: () => {
      dialog.dismiss();
    }
  }
  const dialog = DialogHub.getSheet()
    .setStyle({
      backgroundColor: $r('sys.color.background_secondary'),
      title: { title: '奖励完成' }
    })
    .setConfig({
      scrollSizeMode: ScrollSizeMode.CONTINUOUS
    })
    .setComponentTargetId('mainId')
    .setContent(wrapBuilder(RewardComplationBuilder), props)
    .build();

  dialog.show();
}