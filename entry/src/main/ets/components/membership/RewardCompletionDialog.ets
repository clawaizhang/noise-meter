/**
 * 奖励完成弹窗组件
 * 用户完成使用时显示的庆祝弹窗
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { Throttle } from '../../utils/Debounce';
import { CommentService } from '../../services/CommentService';
import { common } from '@kit.AbilityKit';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2 } from '@kit.ArkUI';

interface RewardCompletionDialogProps {
  consecutiveDays: number;
  rewardDays: number;
  expiryDate: number;
  showRewardDialog: boolean;
  onClose: () => void;
}

@Builder
export function RewardComplationBuilder(props: RewardCompletionDialogProps) {
  RewardCompletionDialog({
    consecutiveDays: props.consecutiveDays,
    rewardDays: props.rewardDays,
    expiryDate: props.expiryDate,
    showRewardDialog: props.showRewardDialog,
    onClose: props.onClose
  })
}

@ComponentV2
export struct RewardCompletionDialog {
  @Param @Require consecutiveDays: number;
  @Param @Require rewardDays: number;
  @Param @Require expiryDate: number;
  @Param @Require showRewardDialog: boolean;
  @Event onClose: () => void;

  @Local pk: PreferenceKeys = AppStorageV2.connect(PreferenceKeys)!;

  // 显示评论对话框
  private showCommentDialog = () => {
    Throttle.click(async () => {
      try {
        const context = getContext(this) as common.UIAbilityContext;
        const commentService = CommentService.getInstance();
        await commentService.showCommentDialog(context);
        console.info('评论对话框显示成功');
      } catch (error) {
        console.error(`显示评论对话框失败: ${error instanceof Error ? error.message : String(error)}`);
        // 可以在这里添加用户友好的错误提示
      }
    });
  }

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

  /**
   * 显示"不再提示"确认对话框
   */
  private showNoShowConfirm() {
    AlertDialog.show({
      title: '确认不再提示',
      message: '关闭后将不再显示此奖励弹框，您可以在设置中重新开启',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('用户取消不再提示');
        }
      },
      secondaryButton: {
        value: '确认',
        action: () => {
          this.pk.show_reward_dialog = false;
          console.info('用户选择不再显示奖励弹框');
        }
      }
    });
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

      // 按钮区域
      Column({ space: DesignConstants.SPACING_MD }) {
        // 确定按钮 - 主按钮
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

        // 五星好评按钮 - 次要按钮（轮廓样式）
        Button('⭐ 五星好评')
          .width('100%')
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.brand'))
          .border({
            width: DesignConstants.BORDER_WIDTH_MD,
            color: $r('sys.color.brand'),
            radius: DesignConstants.BORDER_RADIUS_MD
          })
          .onClick(() => {
            Throttle.click(() => {
            this.showCommentDialog();
            });
          })
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_LG })

      // "不再提示"文字链接
      Text('不再提示')
        .fontSize(12)
        .fontColor($r('sys.color.font_tertiary'))
        .margin({ top: 8 })
        .onClick(() => {
          Throttle.click(() => {
            this.showNoShowConfirm();
          });
        })
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
 * @param showRewardDialog 是否显示奖励弹框
 */
export function showRewardCompletionDialog(
  consecutiveDays: number,
  rewardDays: number,
  expiryDate: number,
  showRewardDialog: boolean
): void {
  let props: RewardCompletionDialogProps = {
    consecutiveDays,
    rewardDays,
    expiryDate,
    showRewardDialog,
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