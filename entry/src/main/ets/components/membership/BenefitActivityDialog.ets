/**
 * 福利活动弹窗组件
 * 显示7天签到领福利活动
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { MembershipRewardService, BenefitSignResult } from '../../services/MembershipRewardService';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { Throttle } from '../../utils/Debounce';

export interface BenefitActivityDialogProps {
  onDismiss: () => void;
}

@Builder
export function BenefitActivityDialogBuilder(props: BenefitActivityDialogProps) {
  BenefitActivityDialog({ onDismiss: props.onDismiss });
}

@ComponentV2
export struct BenefitActivityDialog {
  @Param onDismiss: () => void = () => {};
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local dialog?: InfSheet;
  private membershipRewardService: MembershipRewardService = MembershipRewardService.getInstance(this.pk);

  aboutToAppear(): void {
    // 初始化福利活动
    if (!this.pk.benefit_activity_data.hasBenefitActivity) {
      this.membershipRewardService.initBenefitActivity();
    }
  }

  /**
   * 执行签到
   */
  private handleSign(): void {
    try {
      const result = this.membershipRewardService.signBenefitActivity();

      // 关闭当前弹窗
      if (this.dialog) {
        this.dialog.dismiss();
      }

      // 显示签到结果弹窗
      this.showSignResultDialog(result);
    } catch (error) {
      console.error(`[福利活动] 签到失败: ${error}`);
    }
  }

  /**
   * 显示签到结果弹窗
   * @param result 签到结果
   */
  private showSignResultDialog(result: BenefitSignResult): void {
    if (result.bonusReward > 0) {
      // 显示加成弹窗
      this.showBonusRewardDialog(result);
    } else {
      // 显示普通签到成功弹窗
      this.showSignSuccessDialog(result);
    }
  }

  /**
   * 显示签到成功弹窗
   * @param result 签到结果
   */
  private showSignSuccessDialog(result: BenefitSignResult): void {
    const props: SignSuccessDialogProps = {
      day: result.day,
      rewardDays: result.baseReward,
      totalRewardDays: result.totalRewardDays,
      isCompleted: result.isCompleted,
      onDismiss: () => {}
    };

    const dialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '签到成功' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SignSuccessDialogBuilder), props)
      .build();
    dialog.show();
  }

  /**
   * 显示加成奖励弹窗
   * @param result 签到结果
   */
  private showBonusRewardDialog(result: BenefitSignResult): void {
    const props: BonusRewardDialogProps = {
      day: result.day,
      baseReward: result.baseReward,
      bonusReward: result.bonusReward,
      totalRewardDays: result.totalRewardDays,
      isCompleted: result.isCompleted,
      onDismiss: () => {}
    };

    const dialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '恭喜获得加成奖励！' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(BonusRewardDialogBuilder), props)
      .build();
    props.onDismiss = () => {
      // 显示签到成功弹窗
      dialog.dismiss();
    };
    dialog.show();
    dialog.updateContent(props);
  }

  /**
   * 检查今日是否已签到
   * @returns 是否已签到
   */
  private get isTodaySigned(): boolean {
    return this.membershipRewardService.isTodaySignedForBenefit();
  }

  /**
   * 获取今日基础奖励
   * @returns 基础奖励天数
   */
  private get todayBaseReward(): number {
    const currentStreak = this.pk.benefit_activity_data.currentStreak;
    const nextDay = currentStreak + 1;
    const baseRewards: Record<number, number> = {
      1: 25,
      2: 25,
      3: 25,
      4: 25,
      5: 25,
      6: 25,
      7: 30
    };
    return baseRewards[nextDay] || 30;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 主标题
      Text('🎁 连续签到领福利 🎁')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 副标题
      Text('保底180天，最高可得1095天会员')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 签到进度
      this.buildSignProgress()

      // 签到按钮区域
      if (!this.isTodaySigned) {
        this.buildSignButton()
      } else {
        this.buildSignedTip()
      }

      // 活动说明
      this.buildActivityDescription()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
  }

  /**
   * 构建签到进度
   */
  @Builder
  private buildSignProgress() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 签到格
      Row({ space: DesignConstants.SPACING_XS }) {
        ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
          Column({ space: DesignConstants.SPACING_XS }) {
            // 天数
            Text(`${day}`)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor(this.getDayTextColor(day))
              .fontWeight(FontWeight.Medium)

            // 奖励天数
            Text(`${this.getDayReward(day)}天`)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor(this.getDayTextColor(day))
          }
          .width('100%')
          .height(60)
          .backgroundColor(this.getDayBackgroundColor(day))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }, (day: number) => `${day}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  /**
   * 构建签到按钮
   */
  @Builder
  private buildSignButton() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text(`今日可领取：${this.todayBaseReward}天 + 随机加成`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Button('立即签到')
        .width('100%')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.warning'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.handleSign();
          });
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  /**
   * 构建已签到提示
   */
  @Builder
  private buildSignedTip() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('今日已签到')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('明日再来签到吧')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  /**
   * 构建活动说明
   */
  @Builder
  private buildActivityDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_XS }) {
        Text('📢')
          .fontSize(DesignConstants.FONT_SIZE_SM)

        Text('活动说明')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      Column({ space: DesignConstants.SPACING_XS }) {
        Text('• 连续签到7天，保底180天会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('• 每次签到额外获得0-130天随机奖励')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('• 最高可得1095天会员（3年）')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('• 奖励自动叠加到会员有效期')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('• 每人限参与一次')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 获取天数对应的奖励
   * @param day 天数
   * @returns 奖励天数
   */
  private getDayReward(day: number): number {
    const baseRewards: Record<number, number> = {
      1: 25,
      2: 25,
      3: 25,
      4: 25,
      5: 25,
      6: 25,
      7: 30
    };
    return baseRewards[day] || 30;
  }

  /**
   * 获取天数对应的文本颜色
   * @param day 天数
   * @returns 颜色资源
   */
  private getDayTextColor(day: number): Resource {
    const currentStreak = this.pk.benefit_activity_data.currentStreak;
    if (day <= currentStreak) {
      return $r('sys.color.font_on_primary');
    }
    return $r('sys.color.font_tertiary');
  }

  /**
   * 获取天数对应的背景颜色
   * @param day 天数
   * @returns 颜色资源
   */
  private getDayBackgroundColor(day: number): Resource {
    const currentStreak = this.pk.benefit_activity_data.currentStreak;
    if (day <= currentStreak) {
      return $r('sys.color.confirm');
    }
    return $r('sys.color.comp_background_primary');
  }
}

// 签到成功弹窗属性
export interface SignSuccessDialogProps {
day: number;
rewardDays: number;
totalRewardDays: number;
isCompleted: boolean;
onDismiss: () => void;
}

@Builder
export function SignSuccessDialogBuilder(props: SignSuccessDialogProps) {
SignSuccessDialog({ onDismiss: props.onDismiss, day: props.day, rewardDays: props.rewardDays,
  totalRewardDays: props.totalRewardDays, isCompleted: props.isCompleted });
}

@ComponentV2
export struct SignSuccessDialog {
@Param @Require day: number = 0;
@Param @Require rewardDays: number = 0;
@Param @Require totalRewardDays: number = 0;
@Param @Require isCompleted: boolean = false;
@Param onDismiss: () => void = () => {};

build() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 标题
    Text('🎉 签到成功！ 🎉')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'))
      .textAlign(TextAlign.Center)
      .width('100%')

    // 礼物图标
    Text('🎁')
      .fontSize(48)
      .textAlign(TextAlign.Center)
      .width('100%')

    // 奖励信息
    Text(`获得 ${this.rewardDays}天 专业版会员`)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor($r('sys.color.confirm'))
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .width('100%')

    // 累计信息
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(`已连续签到 ${this.day} 天`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Text(`累计获得 ${this.totalRewardDays}天 会员`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')

    // 完成提示
    if (!this.isCompleted) {
      Text(`再签到${7 - this.day}天，保底180天会员`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.warning'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }

    // 确定按钮
    Button('确定')
      .width('100%')
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .backgroundColor($r('sys.color.brand'))
      .fontColor($r('sys.color.font_on_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        this.onDismiss();
      })
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}
}

// 加成奖励弹窗属性
export interface BonusRewardDialogProps {
day: number;
baseReward: number;
bonusReward: number;
totalRewardDays: number;
isCompleted: boolean;
onDismiss: () => void;
}

@Builder
export function BonusRewardDialogBuilder(props: BonusRewardDialogProps) {
BonusRewardDialog({ onDismiss: props.onDismiss, day: props.day, baseReward: props.baseReward,
  bonusReward: props.bonusReward, totalRewardDays: props.totalRewardDays, isCompleted: props.isCompleted });
}

@ComponentV2
export struct BonusRewardDialog {
@Param @Require day: number = 0;
@Param @Require baseReward: number = 0;
@Param @Require bonusReward: number = 0;
@Param @Require totalRewardDays: number = 0;
@Param @Require isCompleted: boolean = false;
@Event onDismiss: () => void = () => {};

build() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 标题
    Text('✨ 恭喜获得加成奖励！ ✨')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.brand'))
      .textAlign(TextAlign.Center)
      .width('100%')

    // 星星图标
    Text('⭐')
      .fontSize(48)
      .textAlign(TextAlign.Center)
      .width('100%')

    // 奖励信息
    Column({ space: DesignConstants.SPACING_SM }) {
      Text(`基础奖励：${this.baseReward}天 会员`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text(`额外加成：+${this.bonusReward}天 会员`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.brand'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')

      Text(`今日总计：${this.baseReward + this.bonusReward}天 会员`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.confirm'))
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')

    // 累计信息
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(`已连续签到 ${this.day} 天`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Text(`累计获得 ${this.totalRewardDays}天 会员`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')

    // 确定按钮
    Button('太棒了')
      .width('100%')
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .backgroundColor($r('sys.color.brand'))
      .fontColor($r('sys.color.font_on_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        this.onDismiss();
      })
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}
}

// 完成奖励弹窗属性
export interface CompletionRewardDialogProps {
totalRewardDays: number;
onDismiss: () => void;
onExperience?: () => void;
}

@Builder
export function CompletionRewardDialogBuilder(props: CompletionRewardDialogProps) {
CompletionRewardDialog({ onDismiss: props.onDismiss, onExperience: props.onExperience, totalRewardDays: props.totalRewardDays });
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
