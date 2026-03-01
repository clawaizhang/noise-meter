/**
 * 会员中心弹窗组件
 * 使用 DialogHub 弹窗形式展示会员服务
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { VipService, VipSource, VipStatus } from '../../services/VipService';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

export interface MembershipCenterDialogProps {
  onClose: () => void;
}

@ComponentV2
export struct MembershipCenterDialog {
  @Param @Require onClose: () => void;
  @Local vipStatus: VipStatus = {
    isVip: false,
    source: VipSource.NONE,
    expireTime: 0,
    isPermanent: false,
    autoRenew: false,
    hasLegacyVoucher: false,
    legacyDays: 0
  }
  @Local isLoading: boolean = true
  @Local isConverting: boolean = false
  private vipService: VipService | null = null

  aboutToAppear(): void {
    this.vipService = new VipService(getContext(this) as common.UIAbilityContext);
    this.vipService.init().then(() => {
      this.refreshStatus()
    })
  }

  async refreshStatus(): Promise<void> {
    if (!this.vipService) return;
    this.isLoading = true
    this.vipStatus = await this.vipService.getVipStatus()
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶部标题栏
      this.buildHeader()

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 100 })
      } else {
        Scroll() {
          Column({ space: DesignConstants.SPACING_LG }) {
            // 根据状态显示不同内容
            if (this.vipStatus.hasLegacyVoucher) {
              this.buildLegacyConvertCard()
            } else if (this.vipStatus.isPermanent) {
              this.buildPermanentCard()
            } else if (this.vipStatus.source === VipSource.SUBSCRIPTION) {
              this.buildSubscriptionCard()
            } else {
              this.buildNonMemberCard()
            }
          }
          .padding(DesignConstants.SPACING_LG)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.onClose()
        })
      
      Text('会员中心')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Blank().width(24)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(Color.White)
  }

  // ========== 状态1: 遗留会员转换 ==========
  @Builder
  buildLegacyConvertCard() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 顶部提示条
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(20)
          .height(20)
          .fillColor('#FF6B6B')
        
        Text('会员数据迁移')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor('#FF6B6B')
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('rgba(255, 107, 107, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_SM)
      .alignSelf(ItemAlign.Start)

      // 大标题
      Column({ space: DesignConstants.SPACING_SM }) {
        Text(this.vipStatus.legacyDays > 1095 ? '👑 终身会员资格' : '💎 升级在线会员')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vipStatus.legacyDays > 1095 ? '#FFD700' : '#339AF0')

        Text(`检测到您有 ${this.vipStatus.legacyDays} 天历史会员`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }

      // 转换方案卡片
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('转换方案')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)

        if (this.vipStatus.legacyDays > 1095) {
          // 永久会员方案
          this.buildConvertOption(
            '永久会员',
            '终身免费使用所有功能\n换设备登录自动恢复',
            '#FFD700',
            '¥0',
            '立即获得永久会员'
          )
        } else {
          // 订阅会员方案
          this.buildSubscriptionOffer(this.vipStatus.legacyDays)
        }
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor(Color.White)
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // 转换按钮
      Button() {
        if (this.isConverting) {
          Row({ space: DesignConstants.SPACING_SM }) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(Color.White)
            Text('转换中...')
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontColor(Color.White)
          }
        } else {
          Text(this.vipStatus.legacyDays > 1095 ? '立即获得永久会员' : '立即零元升级')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.vipStatus.legacyDays > 1095 ? '#FFD700' : '#339AF0')
      .enabled(!this.isConverting)
      .borderRadius(28)
      .onClick(() => {
        this.showConvertNotice()
      })

      // 说明文字
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('升级后数据更安全，换设备不丢失')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
        
        Text('您也可以稍后升级，本地会员可继续使用至到期')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .width('100%')
  }

  // ========== 状态2: 永久会员 ==========
  @Builder
  buildPermanentCard() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // VIP标识
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('👑')
          .fontSize(80)
        
        Text('永久会员')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFD700')
        
        Text('终身尊享所有特权')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }

      // 权益列表
      Column({ space: DesignConstants.SPACING_MD }) {
        this.buildBenefitRow('✓', '所有专业功能', '#51CF66')
        this.buildBenefitRow('✓', '终身免费使用', '#51CF66')
        this.buildBenefitRow('✓', '换设备自动恢复', '#51CF66')
        this.buildBenefitRow('✓', '无需续费', '#51CF66')
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor('rgba(255, 215, 0, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .border({ width: 2, color: '#FFD700' })
      .width('100%')

      Text('感谢您长期以来的支持！')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(Color.White)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // ========== 状态3: 订阅会员 ==========
  @Builder
  buildSubscriptionCard() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 头部状态
      Row({ space: DesignConstants.SPACING_MD }) {
        Image($r('app.media.ic_vip'))
          .width(48)
          .height(48)
          .fillColor('#339AF0')
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('订阅会员')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#339AF0')
          
          Text(`剩余 ${Math.ceil((this.vipStatus.expireTime - Date.now()) / (24 * 60 * 60 * 1000))} 天`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        
        Blank()
      }
      .width('100%')

      // 有效期
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('有效期至')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
        
        Text(this.formatDate(this.vipStatus.expireTime))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignSelf(ItemAlign.Start)

      // 自动续费状态
      if (this.vipStatus.autoRenew) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_favorite'))
            .width(20)
            .height(20)
            .fillColor('#51CF66')
          
          Text('自动续期已开启')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor('#51CF66')
        }
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor('rgba(81, 207, 102, 0.1)')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .width('100%')
      } else {
        Column({ space: DesignConstants.SPACING_SM }) {
          Row({ space: DesignConstants.SPACING_SM }) {
            Image($r('app.media.ic_close'))
              .width(20)
              .height(20)
              .fillColor('#FF6B6B')
            
            Text('自动续期已关闭')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor('#FF6B6B')
          }
          
          Text('到期后可重新订阅')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor('rgba(255, 107, 107, 0.1)')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .width('100%')
      }

      // 管理按钮
      Button('管理订阅')
        .width('100%')
        .height(48)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(24)
        .onClick(() => {
          // TODO: 调用IAP管理订阅
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(Color.White)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // ========== 状态4: 非会员 ==========
  @Builder
  buildNonMemberCard() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 头部
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('💎')
          .fontSize(64)
        
        Text('开通会员')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        
        Text('解锁全部专业功能')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }

      // 功能列表
      Column({ space: DesignConstants.SPACING_MD }) {
        this.buildFeatureRow('多频率加权', 'A/C/Z计权')
        this.buildFeatureRow('音频分析', '快速/慢速/脉冲')
        this.buildFeatureRow('智能警报', '基于时段提醒')
        this.buildFeatureRow('自定义模式', 'FFT参数')
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .width('100%')

      // 试用按钮
      Button('7天免费试用')
        .width('100%')
        .height(56)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .backgroundColor('#339AF0')
        .fontColor(Color.White)
        .borderRadius(28)
        .onClick(() => {
          this.showAgreementThenTrial()
        })

      Text('试用到期后 ¥6/月，可随时取消')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))

      // 其他方案
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('月度 ¥6')
          .layoutWeight(1)
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(24)
          .onClick(() => {
            this.showAgreementThenPurchase('vip_monthly')
          })

        Button('年度 ¥58')
          .layoutWeight(1)
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(24)
          .onClick(() => {
            this.showAgreementThenPurchase('vip_yearly')
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(Color.White)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // ========== 辅助组件 ==========
  @Builder
  buildConvertOption(title: string, desc: string, color: string, price: string, btnText: string) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text(title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      
      Text(desc)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
      
      Text(price)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor('#51CF66')
        .margin({ top: DesignConstants.SPACING_SM })
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(`rgba(${this.hexToRgb(color)}, 0.1)`)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
  }

  @Builder
  buildBenefitRow(icon: string, text: string, color: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text(icon)
        .fontSize(20)
        .fontColor(color)
      
      Text(text)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
    }
    .width('100%')
  }

  @Builder
  buildFeatureRow(title: string, desc: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('✓')
        .fontSize(16)
        .fontColor('#339AF0')
      
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
        
        Text(desc)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      
      Blank()
    }
    .width('100%')
  }

  // 订阅会员方案（遗留会员转换用）
  @Builder
  buildSubscriptionOffer(legacyDays: number) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text(`首${this.calculateOfferMonths(legacyDays)}个月免费`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#339AF0')
      
      this.buildBonusDaysText(legacyDays)
      
      Text(`${this.calculateOfferMonths(legacyDays)}个月后可自主选择续费`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
      
      Text('换设备登录华为账号可恢复')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor('#51CF66')
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor('rgba(51, 154, 240, 0.1)')
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')

    // 价格
    Text('¥0')
      .fontSize(48)
      .fontWeight(FontWeight.Bold)
      .fontColor('#51CF66')
  }

  // 赠送天数文本（条件渲染）
  @Builder
  buildBonusDaysText(legacyDays: number) {
    if (this.calculateOfferMonths(legacyDays) * 30 > legacyDays) {
      Text(`多送 ${this.calculateOfferMonths(legacyDays) * 30 - legacyDays} 天 🎉`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor('#FF6B6B')
    } else {
      Blank().height(0)
    }
  }

  // ========== 业务逻辑 ==========
  showConvertNotice() {
    AlertDialog.show({
      title: '会员服务变更通知',
      message: '原「连续使用送会员」活动已圆满结束，我们全面升级了会员服务体系。' +
               '您的现有 ' + this.vipStatus.legacyDays + ' 天会员将全额保留，' +
               '转换后可享受换设备自动恢复等云服务功能。',
      primaryButton: {
        value: '立即升级',
        action: () => {
          this.handleConvert()
        }
      },
      secondaryButton: {
        value: '稍后再说',
        action: () => {}
      }
    })
  }

  async handleConvert() {
    if (!this.vipService) return;
    this.isConverting = true
    
    const result = await this.vipService.convertLegacyVoucher()
    
    this.isConverting = false
    
    if (result.success) {
      promptAction.showToast({ message: result.message })
      this.refreshStatus()
    } else {
      promptAction.showToast({ message: result.message })
    }
  }

  showAgreementThenTrial() {
    AlertDialog.show({
      title: '会员服务协议',
      message: '欢迎使用噪音检测专业版会员服务！\n\n' +
               '1. 会员服务由华为应用内支付(IAP)提供支持\n' +
               '2. 订阅到期前24小时自动扣费续期\n' +
               '3. 可随时在系统设置中取消自动续费\n' +
               '4. 换设备登录华为账号可恢复会员\n\n' +
               '点击「同意」即表示您已阅读并同意本协议。',
      primaryButton: {
        value: '同意',
        action: () => {
          this.startTrial()
        }
      },
      secondaryButton: {
        value: '不同意',
        action: () => {}
      }
    })
  }

  async startTrial() {
    if (!this.vipService) return;
    const success = await this.vipService.startFreeTrial()
    if (success) {
      promptAction.showToast({ message: '试用已开始' })
      this.refreshStatus()
    } else {
      promptAction.showToast({ message: '开启失败，请重试' })
    }
  }

  showAgreementThenPurchase(productId: string) {
    AlertDialog.show({
      title: '会员服务协议',
      message: '欢迎使用噪音检测专业版会员服务！\n\n' +
               '1. 会员服务由华为应用内支付(IAP)提供支持\n' +
               '2. 订阅到期前24小时自动扣费续期\n' +
               '3. 可随时在系统设置中取消自动续费\n' +
               '4. 换设备登录华为账号可恢复会员\n\n' +
               '点击「同意」即表示您已阅读并同意本协议。',
      primaryButton: {
        value: '同意并购买',
        action: () => {
          this.purchase(productId)
        }
      },
      secondaryButton: {
        value: '不同意',
        action: () => {}
      }
    })
  }

  async purchase(productId: string) {
    if (!this.vipService) return;
    const success = await this.vipService.purchaseSubscription(productId)
    if (success) {
      promptAction.showToast({ message: '订阅成功' })
      this.refreshStatus()
    } else {
      promptAction.showToast({ message: '订阅失败，请重试' })
    }
  }

  calculateOfferMonths(days: number): number {
    if (days <= 89) return 3
    if (days <= 179) return 6
    if (days <= 364) return 12
    if (days <= 729) return 24
    return 36
  }

  formatDate(timestamp: number): string {
    if (timestamp <= 0) return '--'
    const date = new Date(timestamp)
    return date.getFullYear() + '-' + 
           String(date.getMonth() + 1).padStart(2, '0') + '-' + 
           String(date.getDate()).padStart(2, '0')
  }

  hexToRgb(hex: string): string {
    // 简单的hex转rgb，用于rgba背景
    if (hex === '#FFD700') return '255, 215, 0'
    if (hex === '#339AF0') return '51, 154, 240'
    return '0, 0, 0'
  }
}
