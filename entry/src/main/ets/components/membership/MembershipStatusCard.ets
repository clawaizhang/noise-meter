/**
 * 会员状态卡片组件
 * 集成新版华为IAP会员系统
 */

import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import {
  defaultPricingPlans, UpgradeContentBuilder, UpgradeContentProps
} from './UpgradeContent';
import { Throttle } from '../../utils/Debounce';
import { VipService, VipSource, VipStatus } from '../../services/VipService';
import { common } from '@kit.AbilityKit';

@ComponentV2
export struct MembershipStatusCard {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local vipStatus: VipStatus | null = null;
  @Local isLoading: boolean = true;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  private vipService: VipService | null = null;
  private dialog?: InfSheet;

  aboutToAppear(): void {
    this.vipService = new VipService(getContext(this) as common.UIAbilityContext);
    this.loadVipStatus();
  }

  /**
   * 【新版】加载VIP状态
   */
  async loadVipStatus(): Promise<void> {
    if (!this.vipService) return;
    
    this.isLoading = true;
    await this.vipService.init();
    this.vipStatus = await this.vipService.getVipStatus();
    this.isLoading = false;
  }

  /**
   * 【新版】获取会员状态文本
   */
  @Computed
  get membershipStatusText(): string {
    if (!this.vipStatus) return '基础版';
    
    if (this.vipStatus.isPermanent) {
      return '👑 永久会员';
    } else if (this.vipStatus.source === VipSource.SUBSCRIPTION) {
      const remainingDays = Math.ceil((this.vipStatus.expireTime - Date.now()) / (1000 * 60 * 60 * 24));
      return `💎 订阅会员 · 剩余${remainingDays}天`;
    } else if (this.vipStatus.hasLegacyVoucher) {
      return `🎁 待转换 · ${this.vipStatus.legacyDays}天`;
    } else {
      return '基础版';
    }
  }

  /**
   * 【新版】获取会员状态颜色
   */
  @Computed
  get membershipStatusColor(): Resource {
    if (!this.vipStatus) return $r('sys.color.font_secondary');
    
    if (this.vipStatus.isPermanent || this.vipStatus.source === VipSource.SUBSCRIPTION) {
      return $r('sys.color.confirm');
    } else if (this.vipStatus.hasLegacyVoucher) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.font_secondary');
  }

  /**
   * 【新版】构建会员头部信息
   */
  @Builder
  private buildMembershipHeader() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(this.membershipStatusColor)

        Text('会员状态')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)

      // 会员状态
      Row() {
        Text(this.membershipStatusText)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.membershipStatusColor)
      }
      .alignItems(VerticalAlign.Center)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /**
   * 【新版】构建会员操作区域
   */
  @Builder
  private buildMemberActions() {
    if (!this.vipStatus) {
      // 未加载状态，显示空
      Blank()
    } else if (this.vipStatus.hasLegacyVoucher) {
      // 遗留会员待转换
      Column({ space: DesignConstants.SPACING_SM }) {
        Text(`检测到 ${this.vipStatus.legacyDays} 天历史会员`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        
        Text(this.vipStatus.legacyDays > 1095 ? '可转为永久会员' : '可转为订阅会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.warning'))

        Button('立即转换')
          .width('100%')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.brand'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            Throttle.click(() => {
              this.gotoMembershipCenter();
            });
          })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor('rgba(255, 193, 7, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        Throttle.click(() => {
          this.gotoMembershipCenter();
        });
      })
    } else if (this.vipStatus.isVip) {
      // 已经是会员，显示续费/管理入口
      Row({ space: DesignConstants.SPACING_SM }) {
        if (this.vipStatus.isPermanent) {
          Text('👑 永久会员，无需续费')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.confirm'))
            .layoutWeight(1)
        } else {
          Text(this.vipStatus.autoRenew ? '🔔 已开启自动续费' : '⏰ 手动续期')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
        }

        Button('管理会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.brand'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .onClick(() => {
            Throttle.click(() => {
              this.gotoMembershipCenter();
            });
          })
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_SM })
    } else {
      // 非会员，引导升级
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('🎁 免费试用7天会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Button('立即开通会员')
          .width('100%')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.brand'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            Throttle.click(() => {
              this.gotoMembershipCenter();
            });
          })
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_SM })
    }
  }

  /**
   * 【新版】构建升级提示
   */
  @Builder
  buildUpgradeNotice() {
    if (!this.vipStatus?.isVip && !this.vipStatus?.hasLegacyVoucher) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor('#339AF0')
        
        Text('会员服务已升级，前往查看新方案')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor('#339AF0')
          .layoutWeight(1)
      }
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor('rgba(51, 154, 240, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        Throttle.click(() => {
          this.gotoMembershipCenter();
        });
      })
    } else {
      Blank()
    }
  }

  /**
   * 【私有方法】跳转到会员中心
   */
  private gotoMembershipCenter(): void {
    console.info('[MembershipStatusCard] 跳转到会员中心');
    this.navStack.pushPathByName('MembershipCenter', new Object() as Record<string, Object>);
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
        console.info('[会员管理] 专业版用户查看详情');
        if (this.dialog) {
          this.dialog.dismiss();
        }
      },
      onLater: () => {
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
      this.buildMembershipHeader()
      this.buildMemberActions()
      this.buildUpgradeNotice()
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
      // 点击整个卡片跳转到会员中心
      Throttle.click(() => {
        this.gotoMembershipCenter();
      });
    })
  }
}
