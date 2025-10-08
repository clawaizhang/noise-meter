import { DesignConstants } from "../../constants/DesignConstants"
import { PreferenceKeys } from "../../models/PreferenceKeys";
import { PersistenceV2 } from "@kit.ArkUI";
import { MembershipLevel } from "../../services/MembershipManager";
import {
  MembershipAgreementDialogBuilder, MembershipAgreementDialogProps
} from "./MembershipAgreementDialog";
import { DialogHub } from "@hadss/dialoghub";
import { MembershipRewardService } from "../../services/MembershipRewardService";
import { ContinuousUsageManager } from "../../services/ContinuousUsageManager";
import { Debounce } from "../../utils/Debounce";

// 价格方案接口
interface PricingPlan {
  type: 'monthly' | 'yearly' | 'lifetime';
  price: number;
  originalPrice?: number;
  discount?: string;
  isRecommended: boolean;
  features: string[];
}

// 功能对比接口
interface FeatureComparison {
  feature: string;
  freeVersion: string;
  proVersion: string;
  isHighlight: boolean;
}

interface Plans {
  selected: PricingPlan;
  current: PricingPlan
}

@ComponentV2
export struct UpgradeContent {
  @Param @Require featureName: string; // 功能名称
  @Param @Require featureDesc: string; // 功能描述
  @Param @Require icon: Resource; // 功能图标
  // 新增参数
  @Param pricingPlans: PricingPlan[] = [];
  @Param featureComparison: FeatureComparison[] = [];
  @Param onUpgrade: () => void = () => {
  };
  @Param onLater: () => void = () => {
  };
  @Param showTrialOption: boolean = false;
  @Local selectedPlan: PricingPlan | null = null;
  @Local purchaseState: 'idle' | 'loading' | 'success' | 'error' = 'idle';
  // 会员状态管理
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  aboutToAppear() {
    // 默认选中推荐方案
    const recommendedPlan = this.pricingPlans.find(plan => plan.isRecommended);
    if (recommendedPlan) {
      this.selectedPlan = recommendedPlan;
    }

  }

  // 升级到专业版
  private async upgradeToPro(): Promise<void> {
    try {
      this.purchaseState = 'loading';
      // 模拟支付成功后的状态更新
      this.pk.member_ship.level = MembershipLevel.PRO;
      this.pk.member_ship.expiryDate = Date.now() + 30 * 24 * 60 * 60 * 1000; // 30天
      this.pk.member_ship.isTrial = false;
      this.pk.member_ship.trialDays = 0;
      this.pk.member_ship.purchaseDate = Date.now();

      this.purchaseState = 'success';
      console.info('[会员管理] 已升级到专业版');
    } catch (error) {
      this.purchaseState = 'error';
      console.error('[会员管理] 升级失败:', error);
      throw new Error('[会员管理] 升级失败');
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      if (this.pk.member_ship.can()) {
        // 显示已解锁界面
        this.buildUnlockedHeader()
        this.buildUnlockedBenefits()
        this.buildMembershipInfo()
        // this.buildUnlockedActions()  // 暂时隐藏管理订阅和续费按钮
      } else {
        // 显示升级界面（原有逻辑）
        this.buildHeader()

        // 2. 权益展示区
        this.buildBenefitsSection()

        // 3. 价格方案区（暂时隐藏）
        // if (this.pricingPlans.length > 0) {
        //   this.buildPricingSection()
        // }

        // 5. 操作按钮区
        this.buildActionSection()
      }

      // 购买状态显示（保持不变）
      this.buildPurchaseStatus()
    }
    .padding(DesignConstants.SPACING_LG)
    .width('100%')
  }

  // 头部区域构建
  @Builder
  private buildHeader() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 应用图标和标题
      Row({ space: DesignConstants.SPACING_SM }) {
        if (this.icon) {
          Image(this.icon)
            .width(DesignConstants.ICON_SIZE_XL)
            .height(DesignConstants.ICON_SIZE_XL)
            .fillColor($r('sys.color.brand'))
        }

        Text(this.featureName)
          .fontSize(DesignConstants.FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      // 副标题
      Text(this.featureDesc)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .width('100%')

      // 会员徽章
      this.buildPremiumBadge()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 权益展示区构建
  @Builder
  private buildBenefitsSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('专业版权益')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 权益水平网格布局
      Column({ space: DesignConstants.SPACING_SM }) {
        // 第一行：3个权益项
        Row({ space: DesignConstants.SPACING_MD }) {
          this.buildCompactBenefitItem(
            $r('app.media.ic_frequency_weighting'),
            '多频率加权',
            'A/C/Z计权模式'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_audio_analysis'),
            '音频分析',
            '快速/慢速/脉冲'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_alarm'),
            '智能警报',
            '基于时段提醒'
          )
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 第二行：3个权益项
        Row({ space: DesignConstants.SPACING_MD }) {
          this.buildCompactBenefitItem(
            $r('app.media.ic_settings'),
            '自定义模式',
            'FFT参数自定义'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_history'),
            '自动保存',
            '数据实时保存'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_vip'),
            '更多功能',
            '持续功能更新'
          )
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 价格方案区构建
  @Builder
  private buildPricingSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('选择方案')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 价格方案横向对比
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.pricingPlans, (plan: PricingPlan) => {
          this.buildPricingCard({ selected: this.selectedPlan!, current: plan })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 操作按钮区构建
  @Builder
  private buildActionSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 试用选项（暂时隐藏）
      // if (this.showTrialOption) {
      //   Row({ space: DesignConstants.SPACING_SM }) {
      //     Text('7天免费试用')
      //       .fontSize(DesignConstants.FONT_SIZE_MD)
      //       .fontColor($r('sys.color.confirm'))
      //
      //     Text('试用结束后自动续费')
      //       .fontSize(DesignConstants.FONT_SIZE_SM)
      //       .fontColor($r('sys.color.font_tertiary'))
      //   }
      //   .width('100%')
      //   .justifyContent(FlexAlign.Center)
      // }

      // 操作按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('稍后再说')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            Debounce.click(() => {
              this.onLater();
            });
          })

        Button('免费体验')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.brand'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .enabled(this.purchaseState === 'idle')
          .onClick(() => {
            Debounce.click(() => {
              this.handleFreeExperience();
            })
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG
    })
  }

  // 构建价格方案卡片
  @Builder
  private buildPricingCard(plans: Plans) {

    Column({ space: 2 }) {
      // 推荐标签
      if (plans.current.isRecommended) {
        Text('最受欢迎')
          .fontSize(10)
          .fontColor($r('sys.color.white'))
          .backgroundColor($r('sys.color.brand'))
          .borderRadius(4)
          .padding({
            left: 4,
            right: 4,
            top: 1,
            bottom: 1
          })
          .alignSelf(ItemAlign.Start)
      }

      // 方案类型和价格
      Column({ space: 1 }) {
        Text(this.getPlanTypeText(plans.current.type))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Row({ space: 2 }) {
          if (plans.current.type === 'monthly') {
            // 月度方案显示0元，原价6元划掉
            Text('¥0')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.brand'))

            Text(`¥${plans.current.price}`)
              .fontSize(12)
              .fontColor($r('sys.color.font_tertiary'))
              .decoration({ type: TextDecorationType.LineThrough })
          } else {
            // 其他方案正常显示
            Text(`¥${plans.current.price}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.brand'))

            if (plans.current.originalPrice) {
              Text(`¥${plans.current.originalPrice}`)
                .fontSize(12)
                .fontColor($r('sys.color.font_tertiary'))
                .decoration({ type: TextDecorationType.LineThrough })
            }
          }
        }

        // 月均价格计算（年度方案）
        if (plans.current.type === 'yearly') {
          Text(`¥${Math.round(plans.current.price / 12 * 10) / 10}/月`)
            .fontSize(10)
            .fontColor($r('sys.color.font_secondary'))
        }

        if (plans.current.discount) {
          Text(plans.current.discount)
            .fontSize(10)
            .fontColor($r('sys.color.confirm'))
        }
      }
      .width('100%')

      // 方案描述
      Column({ space: 1 }) {
        if (plans.current.type === 'monthly') {
          Text('最灵活')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
          Text('首月零元免费试用')
            .fontSize(10)
            .fontColor($r('sys.color.confirm'))
          Text('试用结束后自动续费')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
        } else if (plans.current.type === 'yearly') {
          Text('最划算')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        } else if (plans.current.type === 'lifetime') {
          Text('永久拥有')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
      }
      .width('100%')
      .margin({ top: 4 })

      // 选择指示器
      if (plans.selected?.type === plans.current.type) {
        Row({ space: 2 }) {
          Image($r('app.media.ic_favorite'))
            .width(12)
            .height(12)
            .fillColor($r('sys.color.brand'))

          Text('已选择')
            .fontSize(10)
            .fontColor($r('sys.color.brand'))
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .padding(DesignConstants.SPACING_MD)
    .border({
      width: plans.selected?.type === plans.current.type ?
        DesignConstants.BORDER_WIDTH_MD :
        DesignConstants.BORDER_WIDTH_SM,
      color: plans.selected?.type === plans.current.type ?
        $r('sys.color.confirm') :
        $r('sys.color.comp_divider')
    })
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .backgroundColor(
      plans.selected?.type === plans.current.type ?
        $r('sys.color.confirm') :
        $r('sys.color.comp_background_primary')
    )
    .width('30%')
    .height(150)
    .onClick(() => {
      this.selectedPlan = plans.current;
    })
  }

  // 构建紧凑权益项（水平布局使用）
  @Builder
  private buildCompactBenefitItem(icon: Resource, title: string, desc: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(icon)
        .width(DesignConstants.ICON_SIZE_MD)
        .height(DesignConstants.ICON_SIZE_MD)
        .fillColor($r('sys.color.brand'))

      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(desc)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width(100)
    .height(80)
  }

  // 构建会员徽章
  @Builder
  private buildPremiumBadge() {
    Row({ space: DesignConstants.SPACING_XS }) {
      Image($r('app.media.ic_vip'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor($r('sys.color.icon'))

      Text('专业版')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
    }
    .padding({
      left: DesignConstants.SPACING_SM,
      right: DesignConstants.SPACING_SM,
      top: 4,
      bottom: 4
    })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .alignSelf(ItemAlign.Start)
  }

  // 获取方案类型文本
  private getPlanTypeText(type: string): string {
    switch (type) {
      case 'monthly':
        return '月度方案';
      case 'yearly':
        return '年度方案';
      case 'lifetime':
        return '永久方案';
      default:
        return '专业方案';
    }
  }

  // 计算剩余天数
  private calculateDaysRemaining(): number {
    const membership = this.pk.member_ship;
    const now = Date.now();
    const diff = membership.expiryDate - now;
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
  }

  // 日期格式化
  private formatDate(timestamp: number): string {
    if (!timestamp || timestamp === 0) {
      return '--';
    }

    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  }

  // 处理管理订阅
  private handleManageSubscription(): void {
    console.info('[会员管理] 跳转到订阅管理');
    // TODO: 实现订阅管理跳转逻辑
  }

  // 处理续费升级
  private handleRenewUpgrade(): void {
    console.info('[会员管理] 显示续费选项');
    // TODO: 实现续费升级逻辑
  }

  // 处理免费体验逻辑
  private handleFreeExperience(): void {
    // 检查用户是否已同意协议
    if (this.pk.has_agreed_membership_reward) {
      // 用户已同意，直接进入会员奖励流程
      console.info('[会员管理] 用户已同意协议，直接进入会员奖励');
      this.handleAgreementAgree();
      return;
    }

    // 关闭当前升级对话框
    this.onLater();
    // 使用DialogHub显示会员协议对话框
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

  // 处理升级逻辑（保留原有逻辑，但暂时不使用）
  private async handleUpgrade() {
    try {
      await this.upgradeToPro();
      this.purchaseState = 'success';
      console.info('购买成功，方案类型:', this.selectedPlan?.type);

      // 延迟执行回调
      setTimeout(() => {
        this.onUpgrade();
      }, 1500);
    } catch (error) {
      this.purchaseState = 'error';
      console.error('购买失败:', error);

      // 3秒后重置状态
      setTimeout(() => {
        this.purchaseState = 'idle';
      }, 3000);
    }
  }

  // 处理会员协议同意
  private handleAgreementAgree = () => {
    // 记录用户同意状态
    this.pk.has_agreed_membership_reward = true;
    console.info('[会员管理] 用户已同意会员奖励计划协议，同意状态已记录');

    // 应用会员奖励
    const membershipRewardService = MembershipRewardService.getInstance();
    const continuousUsageManager = ContinuousUsageManager.getInstance();
    const consecutiveDays = continuousUsageManager.getConsecutiveDays();
    membershipRewardService.applyMembershipReward(consecutiveDays);

    // 这里可以添加其他逻辑，比如显示欢迎提示等
  }
  // 处理会员协议取消
  private handleAgreementCancel = () => {
    console.info('[会员管理] 用户取消了会员奖励计划协议');
  }

  // 已解锁头部区域构建
  @Builder
  private buildUnlockedHeader() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 成功图标和标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_XL)
          .height(DesignConstants.ICON_SIZE_XL)
          .fillColor($r('sys.color.confirm'))

        Text('专业版已解锁')
          .fontSize(DesignConstants.FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.confirm'))
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      // 副标题
      Text('您已成功解锁所有专业功能')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .width('100%')

      // 有效期徽章
      this.buildExpiryBadge()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 有效期徽章构建
  @Builder
  private buildExpiryBadge() {
    Row({ space: DesignConstants.SPACING_XS }) {
      Image($r('app.media.ic_history'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor($r('sys.color.font_secondary'))

      Text(`有效期至 ${this.formatDate(this.pk.member_ship.expiryDate)}`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding({
      left: DesignConstants.SPACING_SM,
      right: DesignConstants.SPACING_SM,
      top: 4,
      bottom: 4
    })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .alignSelf(ItemAlign.Start)
  }

  // 已解锁功能展示
  @Builder
  private buildUnlockedBenefits() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('已解锁的专业功能')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 直接复用现有的权益网格布局
      Column({ space: DesignConstants.SPACING_SM }) {
        Row({ space: DesignConstants.SPACING_MD }) {
          this.buildCompactBenefitItem(
            $r('app.media.ic_frequency_weighting'),
            '多频率加权',
            'A/C/Z计权模式'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_audio_analysis'),
            '音频分析',
            '快速/慢速/脉冲'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_alarm'),
            '智能警报',
            '基于时段提醒'
          )
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row({ space: DesignConstants.SPACING_MD }) {
          this.buildCompactBenefitItem(
            $r('app.media.ic_settings'),
            '自定义模式',
            'FFT参数自定义'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_save'),
            '自动保存',
            '数据实时保存'
          )
          this.buildCompactBenefitItem(
            $r('app.media.ic_meter'),
            '更多功能',
            '持续功能更新'
          )
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 会员信息卡片
  @Builder
  private buildMembershipInfo() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('会员信息')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Column({ space: DesignConstants.SPACING_SM }) {
        this.buildInfoItem('购买日期', this.formatDate(this.pk.member_ship.purchaseDate))
        this.buildInfoItem('到期时间', this.formatDate(this.pk.member_ship.expiryDate))
        this.buildInfoItem('剩余天数', `${this.calculateDaysRemaining()}天`)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 信息项构建器
  @Builder
  private buildInfoItem(label: string, value: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      Text(`${label}：`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)

      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  // 已解锁操作按钮
  @Builder
  private buildUnlockedActions() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('管理订阅')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.handleManageSubscription();
          })

        Button('续费升级')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.brand'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.handleRenewUpgrade();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG
    })
  }

  // 购买状态显示
  @Builder
  private buildPurchaseStatus() {
    if (this.purchaseState === 'loading') {
      Row({ space: DesignConstants.SPACING_SM }) {
        LoadingProgress()
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .color($r('sys.color.brand'))

        Text('正在处理购买...')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
    } else if (this.purchaseState === 'success') {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_favorite'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.confirm'))

        Text('购买成功！')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.confirm'))
          .fontWeight(FontWeight.Medium)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
    } else if (this.purchaseState === 'error') {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_close'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.warning'))

        Text('购买失败，请重试')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.alert'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
    }
  }
}

// 构建器函数和接口定义
@Builder
export function UpgradeContentBuilder(props: UpgradeContentProps) {
  UpgradeContent({
    featureName: props.featureName,
    featureDesc: props.featureDesc,
    icon: props.icon,
    pricingPlans: props.pricingPlans,
    featureComparison: props.featureComparison,
    onUpgrade: props.onUpgrade,
    onLater: props.onLater,
    showTrialOption: props.showTrialOption
  })
}

export interface UpgradeContentProps {
  featureName: string;
  featureDesc: string;
  icon: Resource;
  pricingPlans?: PricingPlan[];
  featureComparison?: FeatureComparison[];
  onUpgrade?: () => void;
  onLater?: () => void;
  showTrialOption?: boolean;
}

// 默认价格方案配置
export const defaultPricingPlans: PricingPlan[] = [
  {
    type: 'monthly',
    price: 6,
    isRecommended: false,
    features: [
      '所有专业功能',
      '月度更新支持',
      '灵活选择'
    ]
  },
  {
    type: 'yearly',
    price: 58,
    originalPrice: 72, // 6 * 12 = 72
    discount: '节省20%',
    isRecommended: true,
    features: [
      '所有专业功能',
      '年度更新支持',
      '价格优惠',
      '最受欢迎'
    ]
  },
  {
    type: 'lifetime',
    price: 88,
    isRecommended: false,
    features: [
      '所有专业功能',
      '永久使用',
      '最佳性价比',
      '一次购买永久拥有'
    ]
  }
];