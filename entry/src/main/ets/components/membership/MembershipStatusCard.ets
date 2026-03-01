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

  // ========== 状态2: 遗留会员待转换（重点提示） ==========
  @Builder
  buildLegacyVoucherState() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 顶部红色提示条
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('!')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(20)
          .height(20)
          .backgroundColor('#FF6B6B')
          .borderRadius(10)
          .textAlign(TextAlign.Center)
        
        Text('会员数据迁移')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF6B6B')
        
        Blank()
        
        Text('立即处理 >')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor('#FF6B6B')
      }
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor('rgba(255, 107, 107, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .width('100%')

      // 主要内容
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Column() {
          Text('🎁')
            .fontSize(40)
        }
        
        // 中间信息
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`检测到 ${this.vipStatus!.legacyDays} 天历史会员`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          
          Text(this.vipStatus!.legacyDays > 1095 ? '可转为永久会员' : '可转为订阅会员')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        
        // 右侧按钮
        Button('立即转换')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor('#FF6B6B')
          .fontColor(Color.White)
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
      .border({ width: 2, color: '#FF6B6B' })
      .width('100%')
    }
    .onClick(() => {
      Throttle.click(() => {
        this.showMembershipDialog();
      });
    })
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
        .backgroundColor('rgba(255, 215, 0, 0.2)')
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
        title: { title: '' }, // 弹窗内部有自己的标题
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
