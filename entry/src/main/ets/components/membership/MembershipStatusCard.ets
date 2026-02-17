/**
 * 会员状态卡片组件
 * 集成新版华为IAP会员系统 - 弹窗交互
 */

import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { Throttle } from '../../utils/Debounce';
import { VipService, VipSource, VipStatus } from '../../services/VipService';
import { common } from '@kit.AbilityKit';
import { MembershipCenterDialog, MembershipCenterDialogProps } from './MembershipCenterDialog';

@ComponentV2
export struct MembershipStatusCard {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local vipStatus: VipStatus | null = null;
  @Local isLoading: boolean = true;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  private vipService: VipService | null = null;
  private dialog?: InfSheet;

  aboutToAppear(): void {
    this.vipService = new VipService(getContext(this) as common.UIAbilityContext, this.pk);
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
      return '🚀 会员服务可升级';
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
    
    if (this.vipStatus.isPermanent) {
      return $r('sys.color.warning'); // 金色
    } else if (this.vipStatus.source === VipSource.SUBSCRIPTION) {
      return $r('sys.color.brand'); // 品牌蓝
    } else if (this.vipStatus.hasLegacyVoucher) {
      return $r('sys.color.confirm'); // 绿色提示
    }
    return $r('sys.color.font_secondary');
  }

  /**
   * 【新版】构建会员状态卡片 - 4种状态清晰展示
   */
  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 根据4种状态显示不同UI
      if (!this.vipStatus) {
        this.buildLoadingState()
      } else if (this.vipStatus.hasLegacyVoucher) {
        this.buildLegacyVoucherState()
      } else if (this.vipStatus.isPermanent) {
        this.buildPermanentState()
      } else if (this.vipStatus.source === VipSource.SUBSCRIPTION) {
        this.buildSubscriptionState()
      } else {
        this.buildNonMemberState()
      }
    }
    .width('100%')
  }

  // ========== 状态1: 加载中 ==========
  @Builder
  buildLoadingState() {
    Row({ space: DesignConstants.SPACING_SM }) {
      LoadingProgress()
        .width(20)
        .height(20)
      
      Text('加载会员信息...')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ========== 状态2: 遗留会员待转换（福利提示） ==========
  @Builder
  buildLegacyVoucherState() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 主要内容 - 采用上下布局，避免左侧天数过多导致空间不足
      Column({ space: DesignConstants.SPACING_SM }) {
        // 第一行：天数和标题并排（自适应）
        Row({ space: DesignConstants.SPACING_SM }) {
          // 天数使用自适应宽度，根据长度调整
          Text(this.formatDays(this.vipStatus!.legacyDays))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#339AF0')

          Text('「连续使用送会员」奖励')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')

        // 第二行：升级权益（大字号突出）
        if (this.vipStatus!.legacyDays > 1095) {
          Text('👑 0.01 元升级永久会员')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
        } else {
          Text(`💎 0.01 元升级，享 ${this.calculateOfferMonths(this.vipStatus!.legacyDays)} 个月免费`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
        }

        // 第三行：行动按钮（横向展开，更容易点击）
        Button() {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(this.vipStatus!.legacyDays > 1095 ? '👑' : '💎')
              .fontSize(20)

            Text('立即 0.01 元升级')
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)

            Text('→')
              .fontSize(20)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor('#FF6B6B')
        .borderRadius(22)
        .margin({ top: DesignConstants.SPACING_SM })
        .onClick(() => {
          Throttle.click(() => {
            this.showMembershipDialog();
          });
        })
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .border({ width: 1.5, color: 'rgba(255, 107, 107, 0.3)' })
      .shadow({ radius: 8, color: 'rgba(255, 107, 107, 0.1)', offsetX: 0, offsetY: 2 })
      .width('100%')
      .onClick(() => {
        Throttle.click(() => {
          this.showMembershipDialog();
        });
      })
    }
  }

  // 格式化天数显示（超过999显示为X年或简化）
  private formatDays(days: number): string {
    if (days >= 3650) {
      return `${(days / 365).toFixed(0)}年`
    } else if (days >= 1000) {
      return `${(days / 1000).toFixed(1)}千天`
    }
    return `${days}天`
  }

  // 计算兑换月数
  private calculateOfferMonths(days: number): number {
    if (days <= 89) return 3
    if (days <= 179) return 6
    if (days <= 364) return 12
    if (days <= 729) return 24
    return 36
  }

  // ========== 状态3: 永久会员 ==========
  @Builder
  buildPermanentState() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Column() {
        Text('👑')
          .fontSize(36)
      }
      
      // 中间信息
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('永久会员')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFD700')
        
        Text('终身尊享所有特权')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      
      // 右侧标签
      Text('VIP')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(12)
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .border({ width: 2, color: '#FFD700' })
    .width('100%')
    .onClick(() => {
      Throttle.click(() => {
        this.showMembershipDialog();
      });
    })
  }

  // ========== 状态4: 订阅会员 ==========
  @Builder
  buildSubscriptionState() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Column() {
        Text('💎')
          .fontSize(36)
      }
      
      // 中间信息
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('订阅会员')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.brand'))
        
        Text(`剩余 ${Math.ceil((this.vipStatus!.expireTime - Date.now()) / (1000 * 60 * 60 * 24))} 天${this.vipStatus!.autoRenew ? ' · 自动续费' : ''}`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      
      // 右侧按钮
      Button('管理')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.brand'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.showMembershipDialog();
          });
        })
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
    .onClick(() => {
      Throttle.click(() => {
        this.showMembershipDialog();
      });
    })
  }

  // ========== 状态5: 非会员 ==========
  @Builder
  buildNonMemberState() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Column() {
          Text('💎')
            .fontSize(36)
        }
        
        // 中间信息
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('基础版')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          
          Text('开通会员解锁全部功能')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        
        // 右侧按钮
        Button('开通')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.brand'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            Throttle.click(() => {
              this.showMembershipDialog();
            });
          })
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // 试用提示条
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(16)
          .height(16)
          .fillColor('#339AF0')
        
        Text('🎁 免费试用7天会员')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor('#339AF0')
          .layoutWeight(1)
        
        Text('立即领取 >')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor('#339AF0')
      }
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor('rgba(51, 154, 240, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .width('100%')
      .onClick(() => {
        Throttle.click(() => {
          this.showMembershipDialog();
        });
      })
    }
  }

  /**
   * 【核心】显示会员中心弹窗
   */
  private showMembershipDialog(): void {
    let props: MembershipCenterDialogProps = {
      onClose: () => {
        if (this.dialog) {
          this.dialog.dismiss();
        }
        // 刷新状态
        this.loadVipStatus();
      }
    };

    this.dialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '会员中心' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({
        scrollSizeMode: ScrollSizeMode.CONTINUOUS
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(MembershipCenterDialogBuilder), props)
      .build();
    
    this.dialog.show();
  }
}

@Builder
function MembershipCenterDialogBuilder(props: MembershipCenterDialogProps) {
  MembershipCenterDialog({ onClose: props.onClose })
}
