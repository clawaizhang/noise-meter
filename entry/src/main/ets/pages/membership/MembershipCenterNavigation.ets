import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { VipService, VipSource, VipStatus } from '../../services/VipService';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

export interface MembershipCenterProps {
  onClose?: () => void;
}

@Builder
export function MembershipCenterBuilder(props?: MembershipCenterProps) {
  MembershipCenter({ onClose: props?.onClose })
}

@ComponentV2
export struct MembershipCenter {
  @Event onClose: () => void = () => {};
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
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
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
    NavDestination() {
      Column() {
        this.buildHeader()

        if (this.isLoading) {
          LoadingProgress()
            .width(50)
            .height(50)
            .margin({ top: 100 })
        } else {
          Scroll() {
            Column({ space: 16 }) {
              this.buildMainContent()
            }
            .padding(16)
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Auto)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .onClick(() => {
          if (this.onClose) {
            this.onClose();
          } else {
            this.navStack.pop();
          }
        })
      
      Text('会员中心')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Blank().width(24)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }

  @Builder
  buildMainContent() {
    if (this.vipStatus.hasLegacyVoucher) {
      this.buildLegacyConvertCard()
    } else if (this.vipStatus.source === VipSource.PERMANENT) {
      this.buildPermanentCard()
    } else if (this.vipStatus.source === VipSource.SUBSCRIPTION) {
      this.buildSubscriptionCard()
    } else {
      this.buildNonMemberCard()
    }
  }

  @Builder
  buildLegacyConvertCard() {
    Column({ space: 16 }) {
      Text('⭐ 会员数据迁移')
        .fontSize(12)
        .fontColor('#FF6B6B')
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .backgroundColor('rgba(255, 107, 107, 0.1)')
        .borderRadius(4)
        .alignSelf(ItemAlign.Start)

      Text(this.vipStatus.legacyDays > 1095 ? '👑 终身会员资格' : '💎 升级在线会员')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.vipStatus.legacyDays > 1095 ? '#FFD700' : '#339AF0')

      Text('检测到您有 ' + this.vipStatus.legacyDays + ' 天历史会员')
        .fontSize(16)
        .fontColor('#666')

      Column({ space: 12 }) {
        Text('转换方案')
          .fontSize(14)
          .fontColor('#999')
          .alignSelf(ItemAlign.Start)

        if (this.vipStatus.legacyDays > 1095) {
          Column({ space: 8 }) {
            Text('永久会员')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFD700')
            
            Text('终身免费使用所有功能')
              .fontSize(14)
              .fontColor('#666')
            
            Text('换设备登录自动恢复')
              .fontSize(12)
              .fontColor('#51CF66')
          }
        } else {
          Column({ space: 8 }) {
            Text('首' + this.calculateOfferMonths(this.vipStatus.legacyDays) + '个月免费')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#339AF0')
            
            if (this.calculateOfferMonths(this.vipStatus.legacyDays) * 30 > this.vipStatus.legacyDays) {
              Text('多送 ' + (this.calculateOfferMonths(this.vipStatus.legacyDays) * 30 - this.vipStatus.legacyDays) + ' 天 🎉')
                .fontSize(14)
                .fontColor('#FF6B6B')
            }
            
            Text(this.calculateOfferMonths(this.vipStatus.legacyDays) + '个月后可自主选择续费')
              .fontSize(14)
              .fontColor('#666')
            
            Text('换设备登录华为账号可恢复')
              .fontSize(12)
              .fontColor('#51CF66')
          }
        }

        Text('¥0')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#51CF66')
          .margin({ top: 8 })
      }
      .padding(20)
      .backgroundColor('#f8f8f8')
      .borderRadius(12)
      .width('100%')

      Button() {
        if (this.isConverting) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
            Text('转换中...')
              .fontSize(16)
              .fontColor(Color.White)
          }
        } else {
          Text(this.vipStatus.legacyDays > 1095 ? '立即获得永久会员' : '立即零元升级')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(this.vipStatus.legacyDays > 1095 ? '#FFD700' : '#339AF0')
      .enabled(!this.isConverting)
      .borderRadius(24)
      .onClick(() => {
        this.showConvertNotice()
      })

      Text('升级后数据更安全，换设备不丢失')
        .fontSize(12)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('您也可以稍后升级，本地会员可继续使用至到期')
        .fontSize(11)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('100%')
  }

  @Builder
  buildPermanentCard() {
    Column({ space: 20 }) {
      Text('👑')
        .fontSize(80)

      Text('永久会员')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')

      Text('终身尊享所有特权')
        .fontSize(16)
        .fontColor('#999')

      Column({ space: 12 }) {
        this.buildBenefitRow('✓', '所有专业功能', '#51CF66')
        this.buildBenefitRow('✓', '终身免费使用', '#51CF66')
        this.buildBenefitRow('✓', '换设备自动恢复', '#51CF66')
        this.buildBenefitRow('✓', '无需续费', '#51CF66')
      }
      .padding(20)
      .backgroundColor('rgba(255, 215, 0, 0.1)')
      .borderRadius(12)
      .width('100%')

      Text('感谢您长期以来的支持！')
        .fontSize(14)
        .fontColor('#999')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({ width: 2, color: '#FFD700' })
    .width('100%')
  }

  @Builder
  buildSubscriptionCard() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Image($r('app.media.ic_vip'))
          .width(40)
          .height(40)
          .fillColor('#339AF0')
        
        Column({ space: 4 }) {
          Text('订阅会员')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#339AF0')
          
          Text('剩余 ' + (this.vipStatus.expireTime > 0 ? Math.ceil((this.vipStatus.expireTime - Date.now()) / (24 * 60 * 60 * 1000)) : 0) + ' 天')
            .fontSize(14)
            .fontColor('#999')
        }
      }
      .alignSelf(ItemAlign.Start)

      Column({ space: 4 }) {
        Text('有效期至')
          .fontSize(12)
          .fontColor('#999')
        
        Text(this.formatDate(this.vipStatus.expireTime))
          .fontSize(16)
          .fontColor('#333')
      }
      .alignSelf(ItemAlign.Start)

      if (this.vipStatus.autoRenew) {
        Row({ space: 8 }) {
          Image($r('app.media.ic_favorite'))
            .width(16)
            .height(16)
            .fillColor('#51CF66')
          
          Text('自动续期已开启')
            .fontSize(14)
            .fontColor('#51CF66')
        }
        .alignSelf(ItemAlign.Start)
      } else {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Image($r('app.media.ic_close'))
              .width(16)
              .height(16)
              .fillColor('#FF6B6B')
            
            Text('自动续期已关闭')
              .fontSize(14)
              .fontColor('#FF6B6B')
          }
          
          Text('到期后可重新订阅')
            .fontSize(12)
            .fontColor('#999')
        }
        .alignSelf(ItemAlign.Start)
        .padding(12)
        .backgroundColor('rgba(255, 107, 107, 0.1)')
        .borderRadius(8)
      }

      Button('管理订阅')
        .width('100%')
        .height(44)
        .fontSize(14)
        .backgroundColor('#f0f0f0')
        .fontColor('#333')
        .borderRadius(22)
        .onClick(() => {
          // TODO: 调用IAP管理订阅界面
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('100%')
  }

  @Builder
  buildNonMemberCard() {
    Column({ space: 20 }) {
      Text('💎')
        .fontSize(64)

      Text('开通会员')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text('解锁全部专业功能')
        .fontSize(14)
        .fontColor('#999')

      Column({ space: 12 }) {
        Row({ space: 8 }) {
          this.buildFeatureItem('多频率加权', 'A/C/Z计权')
          this.buildFeatureItem('音频分析', '快速/慢速/脉冲')
          this.buildFeatureItem('智能警报', '基于时段提醒')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')

        Row({ space: 8 }) {
          this.buildFeatureItem('自定义模式', 'FFT参数')
          this.buildFeatureItem('自动保存', '数据实时保存')
          this.buildFeatureItem('更多功能', '持续更新')
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }

      Column({ space: 12 }) {
        Button('7天免费试用')
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#339AF0')
          .fontColor(Color.White)
          .borderRadius(24)
          .onClick(() => {
            this.showAgreementThenTrial()
          })

        Text('试用到期后 ¥6/月，可随时取消')
          .fontSize(12)
          .fontColor('#999')

        Row({ space: 12 }) {
          Button('月度 ¥6')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .backgroundColor('#f0f0f0')
            .fontColor('#333')
            .borderRadius(22)
            .onClick(() => {
              this.showAgreementThenPurchase('vip_monthly')
            })

          Button('年度 ¥58')
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .backgroundColor('#f0f0f0')
            .fontColor('#333')
            .borderRadius(22)
            .onClick(() => {
              this.showAgreementThenPurchase('vip_yearly')
            })
        }
        .width('100%')
      }
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('100%')
  }

  @Builder
  buildBenefitRow(icon: string, text: string, color: string) {
    Row({ space: 8 }) {
      Text(icon)
        .fontSize(16)
        .fontColor(color)
      
      Text(text)
        .fontSize(16)
        .fontColor('#333')
    }
    .width('100%')
  }

  @Builder
  buildFeatureItem(title: string, desc: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
      
      Text(desc)
        .fontSize(11)
        .fontColor('#999')
    }
    .width(100)
    .alignItems(HorizontalAlign.Center)
  }

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
}
