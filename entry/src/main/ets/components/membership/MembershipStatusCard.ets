/**
 * 会员状态卡片组件
 * 显示会员状态、使用进度和奖励信息
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { ContinuousUsageManager } from '../../services/ContinuousUsageManager';
import { DayReward, MembershipRewardService } from '../../services/MembershipRewardService';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { MembershipAgreementDialogBuilder, MembershipAgreementDialogProps } from './MembershipAgreementDialog';
import {
  defaultPricingPlans, UpgradeContentBuilder, UpgradeContentProps
} from './UpgradeContent';

@ComponentV2
export struct MembershipStatusCard {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local currentSeconds: number = 0;
  @Local progressPercent: number = 0;
  @Local consecutiveDays: number = 0;
  @Local todayReward: number = 0;
  @Local tomorrowReward: number = 0;
  @Local nextMilestone: DayReward | null = null;
  private continuousUsageManager: ContinuousUsageManager = ContinuousUsageManager.getInstance();
  private membershipRewardService: MembershipRewardService = MembershipRewardService.getInstance();
  private dialog?: InfSheet;

  aboutToAppear(): void {
    this.updateMembershipData();
  }

  @Monitor('pk.continuous_usage_data.totalUsageSeconds')
  onUsageSecondsChange(monitor: IMonitor) {
    const seconds = monitor.value<number>()?.now!;
    this.currentSeconds = seconds;
    this.progressPercent = this.calculateProgressPercent(seconds);
  }

  @Monitor('pk.continuous_usage_data.consecutiveDays')
  onConsecutiveDaysChange(monitor: IMonitor) {
    const days = monitor.value<number>()?.now!;
    this.consecutiveDays = days;
    this.updateRewardInfo(days);
  }

  @Monitor('pk.member_ship.level')
  onMembershipLevelChange(monitor: IMonitor) {
    this.updateMembershipData();
  }

  /**
   * 更新会员数据
   */
  private updateMembershipData(): void {
    this.currentSeconds = this.continuousUsageManager.getTodayUsageSeconds();
    this.progressPercent = this.calculateProgressPercent(this.currentSeconds);
    this.consecutiveDays = this.continuousUsageManager.getConsecutiveDays();
    this.updateRewardInfo(this.consecutiveDays);
  }

  /**
   * 更新奖励信息
   * @param consecutiveDays 连续天数
   */
  private updateRewardInfo(consecutiveDays: number): void {
    const rewardInfo = this.membershipRewardService.getCurrentRewardInfo(consecutiveDays);
    this.todayReward = rewardInfo.todayReward;
    this.tomorrowReward = rewardInfo.tomorrowReward;
    this.nextMilestone = rewardInfo.nextMilestone;
  }

  /**
   * 计算进度百分比
   * @param seconds 使用秒数
   * @returns 进度百分比
   */
  private calculateProgressPercent(seconds: number): number {
    return Math.min(100, Math.round((seconds / 60) * 100));
  }

  /**
   * 获取会员状态文本
   * @returns 会员状态文本
   */
  private getMembershipStatusText(): string {
    const membership = this.pk.member_ship;

    if (membership.can()) {
      const remainingDays = Math.ceil((membership.expiryDate - Date.now()) / (1000 * 60 * 60 * 24));
      return `专业版 · 剩余${remainingDays}天`;
    } else {
      return '基础版';
    }
  }

  /**
   * 获取会员状态颜色
   * @returns 颜色资源
   */
  private getMembershipStatusColor(): Resource {
    return this.pk.member_ship.can() ?
    $r('sys.color.confirm') :
    $r('sys.color.font_secondary');
  }

  /**
   * 构建会员头部信息
   */
  @Builder
  private buildMembershipHeader() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(this.getMembershipStatusColor())

        Text('会员状态')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)

      // 会员状态和连续天数
      Row({ space: DesignConstants.SPACING_MD }) {
        Text(this.getMembershipStatusText())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.getMembershipStatusColor())

        Text(`🔥连续${this.consecutiveDays}天`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.warning'))
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .padding({
            left: DesignConstants.SPACING_SM,
            right: DesignConstants.SPACING_SM,
            top: 2,
            bottom: 2
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /**
   * 构建使用进度
   */
  @Builder
  private buildUsageProgress() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 进度标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_time_weighting'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.font_primary'))

        Text('今日使用进度')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      // 进度条
      Stack({ alignContent: Alignment.Start }) {
        // 背景条
        Row()
          .width('100%')
          .height(8)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(4)

        // 进度条 - 从左侧开始增长
        Row()
          .width(`${this.progressPercent}%`)
          .height(8)
          .backgroundColor($r('sys.color.confirm'))
          .borderRadius(4)
      }
      .width('100%')
      .height(8)

      // 进度文字
      Row() {
        if (this.continuousUsageManager.isTodayUsageCompleted()) {
          Text('🎉 今日使用已完成！')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.confirm'))
        } else {
          Text(`已使用 ${this.currentSeconds}/60 秒`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text(`剩余 ${60 - this.currentSeconds} 秒`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
      }
      .width('100%')
    }
    .width('100%')
  }

  /**
   * 构建奖励预览
   */
  @Builder
  private buildRewardPreview() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 奖励标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_favorite'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.font_primary'))

        Text('奖励预告')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      // 今日奖励
      if (!this.continuousUsageManager.isTodayUsageCompleted()) {
        Row() {
          Text('今日奖励：')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text(`${this.todayReward}天会员`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.confirm'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
      }

      // 明日奖励
      Row() {
        Text('明日奖励：')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text(`${this.tomorrowReward}天会员`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.warning'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      // 下一个里程碑
      if (this.nextMilestone) {
        Row() {
          Text(`连续${this.nextMilestone.days}天：`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text(`${this.nextMilestone.reward}天会员`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.brand'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  /**
   * 构建协议提示（用户未同意协议时显示）
   */
  @Builder
  buildAgreementPrompt() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('专业版免费送！')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)

      // 描述
      Text('每天使用APP即可获得专业版会员')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 奖励规则
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('🎁 每日奖励：使用1分钟获得1天会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('🔥 连续奖励：连续使用额外赠送会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text('📱 自动累计：奖励天数自动累加')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 免费体验按钮
      Button('免费体验')
        .width('100%')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.brand'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.showMembershipAgreement();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 显示会员协议对话框
   */
  private showMembershipAgreement(): void {
    // 检查用户是否已同意协议
    if (this.pk.has_agreed_membership_reward) {
      // 用户已同意，直接进入会员奖励流程
      console.info('[会员管理] 用户已同意协议，直接进入会员奖励');
      this.updateMembershipData();
      return;
    }
    
    // 用户未同意，显示协议对话框
    let props: MembershipAgreementDialogProps = {
      onAgree: () => {
        this.handleAgreementAgree();
        dialog.dismiss();
      },
      onCancel: () => {
        this.handleAgreementCancel();
        dialog.dismiss();
      }
    };
    const dialog = DialogHub.getSheet()
      .setComponentTargetId('mainId')
      .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
      .setContent(wrapBuilder(MembershipAgreementDialogBuilder), props)
      .build();
    dialog.show();
  }

  /**
   * 处理会员协议同意
   */
  private handleAgreementAgree = () => {
    // 记录用户同意状态
    this.pk.has_agreed_membership_reward = true;
    console.info('[会员管理] 用户已同意会员奖励计划协议，同意状态已记录');
    
    // 应用会员奖励
    const membershipRewardService = MembershipRewardService.getInstance();
    const consecutiveDays = this.continuousUsageManager.getConsecutiveDays();
    membershipRewardService.applyMembershipReward(consecutiveDays);
    
    // 刷新显示
    this.updateMembershipData();
  }

  /**
   * 处理会员协议取消
   */
  private handleAgreementCancel =() =>  {
    console.info('[会员管理] 用户取消了会员奖励计划协议');
  }

  /**
   * 显示专业版详情
   */
  private showProDetails(): void {
    const props: UpgradeContentProps = {
      featureName: '专业版',
      featureDesc: '您已解锁所有高级功能',
      icon: $r('app.media.ic_vip'),
      pricingPlans: defaultPricingPlans,
      onUpgrade: () => {
        // 专业版用户不需要升级
        console.info('[会员管理] 专业版用户查看详情');
        if (this.dialog) {
          this.dialog.dismiss();
        }
      },
      onLater: () => {
        // 关闭弹窗
        if (this.dialog) {
          this.dialog.dismiss();
        }
      },
      showTrialOption: false
    };

    this.dialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '专业版' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({
        scrollSizeMode: ScrollSizeMode.CONTINUOUS
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(UpgradeContentBuilder), props)
      .build();
    this.dialog.show();
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      if (this.pk.has_agreed_membership_reward) {
        // 用户已同意协议，显示正常的会员状态
        this.buildMembershipHeader()
        this.buildUsageProgress()
        this.buildRewardPreview()
      } else {
        // 用户未同意协议，显示引导提示
        this.buildAgreementPrompt()
      }
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .border({
      width: DesignConstants.BORDER_WIDTH_SM,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
    .onClick(() => {
      // 仅专业版用户可以点击查看详情
      if (this.pk.has_agreed_membership_reward && this.pk.member_ship.can()) {
        this.showProDetails();
      }
    })
  }
}