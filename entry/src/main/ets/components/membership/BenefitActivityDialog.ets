/**
 * 马年抽签活动弹窗组件（春节主题优化版）
 * 包含：春节配色、抽签动画、倒计时、分享功能
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { SpringFestivalConstants, LevelStyle } from '../../constants/SpringFestivalConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { MembershipRewardService, BenefitSignResult, LuckySign } from '../../services/MembershipRewardService';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { Throttle } from '../../utils/Debounce';
import { LuckyDrawAnimation, LuckyDrawAnimationBuilder, LuckyDrawAnimationProps } from './LuckyDrawAnimation';

export interface BenefitActivityDialogProps {
  onDismiss: () => void;
}

@Builder
export function BenefitActivityDialogBuilder(props: BenefitActivityDialogProps) {
  BenefitActivityDialog({ onDismiss: props.onDismiss });
}

@ComponentV2
export struct BenefitActivityDialog {
  @Event onDismiss: () => void = () => {};
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local dialog?: InfSheet;
  private membershipRewardService: MembershipRewardService = MembershipRewardService.getInstance(this.pk);
  
  // 倒计时状态
  @Local private daysRemaining: number = 0;
  @Local private hoursRemaining: number = 0;
  
  // 动画弹窗相关
  private animationDialog?: InfSheet;
  private pendingResult?: BenefitSignResult;

  aboutToAppear(): void {
    // 初始化福利活动
    if (!this.pk.benefit_activity_data.hasBenefitActivity) {
      this.membershipRewardService.initBenefitActivity();
    }
    
    // 计算倒计时
    this.calculateCountdown();
  }
  
  /**
   * 计算活动倒计时
   */
  private calculateCountdown(): void {
    const benefitData = this.pk.benefit_activity_data;
    if (!benefitData.activityExpiryDate) return;
    
    const now = Date.now();
    const remaining = benefitData.activityExpiryDate - now;
    
    if (remaining > 0) {
      this.daysRemaining = Math.floor(remaining / (24 * 60 * 60 * 1000));
      this.hoursRemaining = Math.floor((remaining % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));
    }
  }

  /**
   * 执行签到（触发抽签动画）
   */
  private handleSign(): void {
    try {
      const result = this.membershipRewardService.signBenefitActivity();
      
      // 关闭当前弹窗，显示抽签动画
      if (this.dialog) {
        this.dialog.dismiss();
      }
      
      // 显示抽签动画弹窗
      this.showDrawAnimationDialog(result);
      
    } catch (error) {
      console.error(`[福利活动] 签到失败: ${error}`);
    }
  }
  
  /**
   * 显示抽签动画弹窗
   */
  private showDrawAnimationDialog(result: BenefitSignResult): void {
    if (!result.luckySign) return;
    
    // 保存result供后续使用
    this.pendingResult = result;
    
    // 构建动画组件props（显式类型声明）
    let animationProps: LuckyDrawAnimationProps = {
      luckySign: result.luckySign
    };
    
    // 创建动画弹窗
    this.animationDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '🎋 抽签中...' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(LuckyDrawAnimationBuilder), animationProps)
      .build();
    
    this.animationDialog.show();
    
    // 设置定时器，在动画完成后（约2.3秒）关闭动画弹窗并显示结果
    setTimeout(() => {
      if (this.animationDialog) {
        this.animationDialog.dismiss();
        this.animationDialog = undefined;
      }
      if (this.pendingResult) {
        this.showSignResultDialog(this.pendingResult);
        this.pendingResult = undefined;
      }
    }, 2300);
  }

  /**
   * 显示抽签结果弹窗
   */
  private showSignResultDialog(result: BenefitSignResult): void {
    // 使用局部变量保存dialog引用
    let resultDialog: InfSheet | undefined = undefined;
    
    // 构建props，onDismiss中关闭弹窗
    const props: SignSuccessDialogProps = {
      day: result.day,
      rewardDays: result.baseReward,
      bonusReward: result.bonusReward,
      totalRewardDays: result.totalRewardDays,
      isCompleted: result.isCompleted,
      luckySign: result.luckySign,
      onDismiss: () => {
        if (resultDialog) {
          resultDialog.dismiss();
        }
      },
      onShare: result.isCompleted ? () => {
        if (resultDialog) {
          resultDialog.dismiss();
        }
        this.showSharePoster(result);
      } : undefined
    };
    
    // 创建结果弹窗（在props之后构建，以便props可以引用dialog）
    resultDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: result.bonusReward > 0 ? '🎊 恭喜获得额外奖励！' : '🎋 抽中吉利签！' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SignSuccessDialogBuilder), props)
      .build();
    
    resultDialog.show();
  }
  
  /**
   * 显示分享海报
   */
  private showSharePoster(result: BenefitSignResult): void {
    // TODO: 实现分享海报生成逻辑
    console.info('[福利活动] 显示分享海报');
  }

  /**
   * 检查今日是否已签到
   */
  private get isTodaySigned(): boolean {
    return this.membershipRewardService.isTodaySignedForBenefit();
  }
  
  /**
   * 获取活动完成状态
   */
  private get isCompleted(): boolean {
    return this.pk.benefit_activity_data.benefitActivityCompleted;
  }

  build() {
    Column({ space: SpringFestivalConstants.SPACING_LG }) {
      // 倒计时条（顶部）
      if (!this.isCompleted && this.daysRemaining > 0) {
        this.buildCountdownBar()
      }
      
      // 主标题 - 马年主题
      Column({ space: SpringFestivalConstants.SPACING_SM }) {
        Text('🐎 马年鸿运抽吉签 🐎')
          .fontSize(SpringFestivalConstants.FONT_SIZE_XXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
          .textAlign(TextAlign.Center)
          .width('100%')
        
        // 装饰线
        Row({ space: 8 }) {
          Row()
            .width(40)
            .height(2)
            .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
          
          Text('✦')
            .fontSize(16)
            .fontColor(SpringFestivalConstants.COLOR_GOLD)
          
          Row()
            .width(40)
            .height(2)
            .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')

      // 副标题 - 核心价值主张
      Column({ space: 4 }) {
        Text('100%中签 · 全是吉利签 · 最高可得48天')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width('100%')
        
        Text('连续5天，第5天额外惊喜奖励！')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 签到进度
      this.buildSignProgress()

      // 签到按钮区域
      if (this.isCompleted) {
        this.buildCompletedView()
      } else if (!this.isTodaySigned) {
        this.buildSignButton()
      } else {
        this.buildSignedTip()
      }

      // 活动说明
      this.buildActivityDescription()
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_LG)
    .backgroundColor(SpringFestivalConstants.COLOR_BG_WARM)
  }
  
  /**
   * 构建倒计时条
   */
  @Builder
  private buildCountdownBar() {
    Row() {
      Row({ space: 4 }) {
        Text('⏰')
          .fontSize(14)
        
        Text('活动倒计时')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor(Color.White)
        
        Text(`${this.daysRemaining}天${this.hoursRemaining}小时`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontWeight(FontWeight.Bold)
          .fontColor(SpringFestivalConstants.COLOR_GOLD)
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(8)
    .backgroundColor(SpringFestivalConstants.COLOR_CHINESE_RED)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
  }

  /**
   * 构建签到进度（优化版）
   */
  @Builder
  private buildSignProgress() {
    Column({ space: SpringFestivalConstants.SPACING_SM }) {
      // 进度标题
      Row() {
        Text('📅 签到进度')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Blank()
        
        Text(`${this.pk.benefit_activity_data.currentStreak}/5天`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      
      // 5天进度格
      Row({ space: SpringFestivalConstants.SPACING_XS }) {
        ForEach([1, 2, 3, 4, 5], (day: number) => {
          this.buildDayCard(day)
        }, (day: number) => `${day}`)
      }
      .width('100%')
      
      // 第5天特殊提示
      if (this.pk.benefit_activity_data.currentStreak === 4) {
        Row({ space: 4 }) {
          Text('🎁')
            .fontSize(12)
          
          Text('明天是最后一天，有额外惊喜奖励！')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_MD)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
  }
  
  /**
   * 构建单日卡片
   */
  @Builder
  private buildDayCard(day: number) {
    Column({ space: 2 }) {
      // 天数标识
      Row({ space: 2 }) {
        if (day <= this.pk.benefit_activity_data.currentStreak) {
          Text('✓')
            .fontSize(10)
            .fontColor(Color.White)
        }
        
        Text(`${day}`)
          .fontSize(12)
          .fontColor(day <= this.pk.benefit_activity_data.currentStreak ? Color.White : 
            (day === this.pk.benefit_activity_data.currentStreak + 1 ? SpringFestivalConstants.COLOR_CHINESE_RED : '#999999'))
          .fontWeight(FontWeight.Bold)
      }
      
      // 特殊标识
      if (day === 5) {
        Text('🎁')
          .fontSize(12)
      }
      
      // 状态文字
      Text(day <= this.pk.benefit_activity_data.currentStreak ? '已完成' : 
        (day === this.pk.benefit_activity_data.currentStreak + 1 ? '待抽签' : '待开始'))
        .fontSize(9)
        .fontColor(day <= this.pk.benefit_activity_data.currentStreak ? Color.White : '#999999')
    }
    .layoutWeight(1)
    .height(70)
    .backgroundColor(
      day <= this.pk.benefit_activity_data.currentStreak ? SpringFestivalConstants.COLOR_CHINESE_RED : 
      (day === this.pk.benefit_activity_data.currentStreak + 1 ? SpringFestivalConstants.COLOR_BG_CREAM : '#F5F5F5')
    )
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .border({
      width: day === this.pk.benefit_activity_data.currentStreak + 1 ? 2 : 0,
      color: SpringFestivalConstants.COLOR_GOLD
    })
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建签到按钮（春节主题）
   */
  @Builder
  private buildSignButton() {
    Column({ space: SpringFestivalConstants.SPACING_SM }) {
      Text('🎋 今日吉签等待抽取')
        .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)
        .width('100%')
      
      Button() {
        Row({ space: 8 }) {
          Text('🧧')
            .fontSize(20)
          
          Text('立即抽签')
            .fontSize(SpringFestivalConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width('100%')
      .height(52)
      .backgroundColor(SpringFestivalConstants.COLOR_CHINESE_RED)
      .fontColor(Color.White)
      .borderRadius(SpringFestivalConstants.BORDER_RADIUS_LG)
      .shadow({
        radius: 8,
        color: 'rgba(229, 57, 53, 0.4)',
        offsetY: 4
      })
      .onClick(() => {
        Throttle.click(() => {
          this.handleSign();
        });
      })
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_MD)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
  }

  /**
   * 构建已签到提示
   */
  @Builder
  private buildSignedTip() {
    Column({ space: SpringFestivalConstants.SPACING_SM }) {
      // 今日签到状态
      Row({ space: SpringFestivalConstants.SPACING_XS }) {
        Text('✅')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
        
        Text('今日已抽签')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontColor('#666666')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // 今日奖励信息
      Column({ space: SpringFestivalConstants.SPACING_XS }) {
        Text('今日获得')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width('100%')

        Row({ space: 4 }) {
          Text(`${this.pk.benefit_activity_data.todayReward}`)
            .fontSize(28)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .fontWeight(FontWeight.Bold)

          Text('天会员')
            .fontSize(14)
            .fontColor('#666666')
            .fontWeight(FontWeight.Medium)
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })

      // 累计奖励信息
      Row({ space: 4 }) {
        Text('累计获得')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#999999')

        Text(`${this.pk.benefit_activity_data.totalRewardDays}`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
          .fontWeight(FontWeight.Bold)

        Text('天会员')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#999999')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // 明日提示
      Text('🌙 明日再来抽取新签文')
        .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_MD)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
  }
  
  /**
   * 构建已完成视图
   */
  @Builder
  private buildCompletedView() {
    Column({ space: SpringFestivalConstants.SPACING_MD }) {
      // 成就徽章
      Column({ space: SpringFestivalConstants.SPACING_SM }) {
        Text('🏆')
          .fontSize(48)
        
        Text('马年大吉')
          .fontSize(SpringFestivalConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
        
        Text('已完成5天签到')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#666666')
      }
      
      // 总奖励
      Column({ space: 4 }) {
        Text('累计获得')
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#999999')
        
        Row({ space: 4 }) {
          Text(`${this.pk.benefit_activity_data.totalRewardDays}`)
            .fontSize(36)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .fontWeight(FontWeight.Bold)
          
          Text('天会员')
            .fontSize(16)
            .fontColor('#666666')
        }
      }
      
      // 分享按钮
      Button() {
        Row({ space: 8 }) {
          Text('📤')
            .fontSize(18)
          
          Text('生成分享海报')
            .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
      .fontColor(Color.White)
      .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        // TODO: 生成分享海报
      })
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_MD)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
  }

  /**
   * 构建活动说明
   */
  @Builder
  private buildActivityDescription() {
    Column({ space: SpringFestivalConstants.SPACING_SM }) {
      // 标题
      Row({ space: SpringFestivalConstants.SPACING_XS }) {
        Text('🐎')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
        
        Text('马年鸿运转不停')
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Bold)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      // 核心卖点
      Column({ space: 4 }) {
        this.buildFeatureRow('✅', '100%中签保证', '全是上上签/上签/中签，无空签')
        this.buildFeatureRow('🧧', '吉利数字奖励', '5·6·8·10·12·16·18·28天')
        this.buildFeatureRow('🎁', '第5天额外惊喜', '最高可额外获得20天奖励')
        
        // 奖励梯度
        Column({ space: 2 }) {
          Text('🎯 奖励梯度（第5天有额外加成）')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#999999')
            .margin({ top: 8, bottom: 4 })
          
          Row({ space: 8 }) {
            this.buildRewardTag('28天', '马到成功', SpringFestivalConstants.COLOR_SIGN_SUPREME)
            this.buildRewardTag('18天', '恭喜发财', SpringFestivalConstants.COLOR_SIGN_GOOD)
            this.buildRewardTag('16天', '年年有余', SpringFestivalConstants.COLOR_SIGN_GOOD)
            this.buildRewardTag('...', '更多', '#999999')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')

        // 规则说明
        Column({ space: 2 }) {
          Text('📋 活动规则')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#999999')
            .margin({ top: 8, bottom: 4 })
          
          Text('• 连续5天，每天抽取一支吉签')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#666666')
          
          Text('• 第5天额外随机加成5-20天')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#666666')
          
          Text('• 奖励自动叠加，立即生效')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#666666')
          
          Text('• 马年限定活动，每人限参与一次')
            .fontSize(SpringFestivalConstants.FONT_SIZE_XS)
            .fontColor('#666666')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: 8, bottom: 8, left: 12, right: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(SpringFestivalConstants.SPACING_MD)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    .border({
      width: 1,
      color: SpringFestivalConstants.COLOR_GOLD
    })
  }
  
  /**
   * 构建特性行
   */
  @Builder
  private buildFeatureRow(emoji: string, title: string, desc: string) {
    Row({ space: 4 }) {
      Text(emoji)
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
      
      Text(title)
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
        .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
        .fontWeight(FontWeight.Medium)
      
      Text(desc)
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
        .fontColor('#666666')
    }
    .width('100%')
    .margin({ top: 2 })
  }
  
  /**
   * 构建奖励标签
   */
  @Builder
  private buildRewardTag(days: string, name: string, color: string | number) {
    Column({ space: 2 }) {
      Text(days)
        .fontSize(11)
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
      
      Text(name)
        .fontSize(9)
        .fontColor('#999999')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

// ==================== 抽签成功弹窗 ====================

export interface SignSuccessDialogProps {
  day: number;
  rewardDays: number;
  bonusReward: number;
  totalRewardDays: number;
  isCompleted: boolean;
  onDismiss: () => void;
  luckySign?: LuckySign;
  onShare?: () => void;
}

@Builder
export function SignSuccessDialogBuilder(props: SignSuccessDialogProps) {
  SignSuccessDialog({ 
    onDismiss: props.onDismiss,
    onShare: props.onShare,
    day: props.day,
    rewardDays: props.rewardDays,
    bonusReward: props.bonusReward,
    totalRewardDays: props.totalRewardDays,
    isCompleted: props.isCompleted,
    luckySign: props.luckySign
  });
}

@ComponentV2
export struct SignSuccessDialog {
  @Param @Require day: number = 0;
  @Param @Require rewardDays: number = 0;
  @Param @Require bonusReward: number = 0;
  @Param @Require totalRewardDays: number = 0;
  @Param @Require isCompleted: boolean = false;
  @Param luckySign?: LuckySign = undefined;
  @Param onDismiss: () => void = () => {};
  @Param onShare?: () => void = undefined;

  build() {
    Column({ space: SpringFestivalConstants.SPACING_LG }) {
      // 标题
      Text(this.bonusReward > 0 ? '🎊 喜上加喜！' : '🎋 抽中吉利签！')
        .fontSize(SpringFestivalConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
        .textAlign(TextAlign.Center)
        .width('100%')

      // 签文卡片
      if (this.luckySign) {
        this.buildSignResultCard()
      }

      // 累计信息
      Column({ space: SpringFestivalConstants.SPACING_XS }) {
        Text(`已连续抽签 ${this.day} 天`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor('#666666')

        Text(`累计获得 ${this.totalRewardDays}天 会员`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      // 完成提示或继续提示
      if (this.isCompleted) {
        Column({ space: SpringFestivalConstants.SPACING_SM }) {
          Text('🎉 恭喜完成马年5天抽签！')
            .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
          
          if (this.onShare) {
            Button('生成分享海报')
              .width('100%')
              .height(44)
              .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
              .fontColor(Color.White)
              .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
              .onClick(() => {
                this.onShare?.();
                this.onDismiss();
              })
          }
        }
        .width('100%')
      } else {
        Text(`再抽签${5 - this.day}天，解锁第5天额外惊喜！`)
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width('100%')
      }

      // 确定按钮
      Button('确定')
        .width('100%')
        .height(48)
        .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
        .backgroundColor(SpringFestivalConstants.COLOR_CHINESE_RED)
        .fontColor(Color.White)
        .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.onDismiss();
        })
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_LG)
  }
  
  /**
   * 构建签文结果卡片
   */
  @Builder
  private buildSignResultCard() {
    Column({ space: SpringFestivalConstants.SPACING_MD }) {
      // 等级徽章
      Text(this.luckySign?.level || '中签')
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .backgroundColor(this.getLevelStyle(this.luckySign?.level || '中签').badgeColor)
        .borderRadius(16)
      
      // Emoji
      Text(this.luckySign?.emoji || '🎁')
        .fontSize(56)
      
      // 签文名称
      Text(this.luckySign?.name || '未知签文')
        .fontSize(SpringFestivalConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED_DARK)
      
      // 寓意
      Text(this.luckySign?.meaning || '')
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
      
      // 奖励信息
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Text('签文奖励:')
            .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
            .fontColor('#666666')
          
          Text(`${this.rewardDays}天`)
            .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .fontWeight(FontWeight.Bold)
        }
        
        // 额外奖励（第5天）
        if (this.bonusReward > 0) {
          Row({ space: 4 }) {
            Text('🎁 额外惊喜:')
              .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
              .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
            
            Text(`+${this.bonusReward}天`)
              .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
              .fontColor(SpringFestivalConstants.COLOR_GOLD_DARK)
              .fontWeight(FontWeight.Bold)
          }
          
          Row({ space: 4 }) {
            Text('今日总计:')
              .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
              .fontColor('#666666')
            
            Text(`${this.rewardDays + this.bonusReward}天`)
              .fontSize(24)
              .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(SpringFestivalConstants.SPACING_MD)
      .backgroundColor(SpringFestivalConstants.COLOR_BG_CREAM)
      .borderRadius(SpringFestivalConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(SpringFestivalConstants.SPACING_XL)
    .backgroundColor(Color.White)
    .borderRadius(SpringFestivalConstants.BORDER_RADIUS_XL)
    .border({
      width: 3,
      color: this.getLevelStyle(this.luckySign?.level || '中签').borderColor
    })
    .shadow({
      radius: 12,
      color: this.getLevelStyle(this.luckySign?.level || '中签').shadowColor,
      offsetY: 6
    })
  }
  
  /**
   * 获取等级样式
   */
  private getLevelStyle(level: string): LevelStyle {
    if (level === '上上签') {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_SUPREME,
        badgeColor: '#FFD700',
        shadowColor: 'rgba(255, 215, 0, 0.4)'
      };
    } else if (level === '上签') {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_GOOD,
        badgeColor: '#FF8C00',
        shadowColor: 'rgba(255, 140, 0, 0.3)'
      };
    } else {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_NORMAL,
        badgeColor: '#4169E1',
        shadowColor: 'rgba(65, 105, 225, 0.2)'
      };
    }
  }
}
