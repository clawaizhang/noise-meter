/**
 * 会员中心弹窗组件
 * 使用 DialogHub 弹窗形式展示会员服务
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { MembershipAgreement } from '../../constants/MembershipAgreement';
import { VipService, VipSource, VipStatus } from '../../services/VipService';
import { common } from '@kit.AbilityKit';
import { PersistenceV2, promptAction } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';

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
  @Local agreedToTerms: boolean = false
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  private vipService: VipService | null = null

  aboutToAppear(): void {
    this.vipService = new VipService(getContext(this) as common.UIAbilityContext, this.pk);
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
          .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG, bottom: DesignConstants.SPACING_LG })
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

  // ========== 状态1: 遗留会员转换 ==========
  @Builder
  buildLegacyConvertCard() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // ===== 核心转化区：一眼看到福利+价格+CTA（无需滚动）=====
      Column({ space: DesignConstants.SPACING_MD }) {
        // 福利标签
        Row() {
          Text('🎁 老用户专属回馈')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor('#B8860B')
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('rgba(255, 215, 0, 0.2)')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignSelf(ItemAlign.Start)

        // 用户贡献（简化显示，避免过长）
        Text(`您已累计获得 ${this.formatDays(this.vipStatus.legacyDays)}会员`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))

        // 核心福利（超大字号，视觉冲击）
        if (this.vipStatus.legacyDays > 1095) {
          Text('👑 永久会员')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')

          Text('终身免费 · 换机恢复')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontColor($r('sys.color.font_secondary'))
        } else {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(`${this.calculateOfferMonths(this.vipStatus.legacyDays)}`)
              .fontSize(56)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B6B')

            Column({ space: 2 }) {
              Text('个月')
                .fontSize(20)
                .fontColor($r('sys.color.font_primary'))

              Text('免费使用')
                .fontSize(14)
                .fontColor($r('sys.color.font_secondary'))
            }
          }
          .alignItems(VerticalAlign.Bottom)

          Text('在线会员 · 换机恢复')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }

        // 价格区域（醒目）
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('¥0.01')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')

          Column({ space: 2 }) {
            Text('限时升级价')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))

            if (this.vipStatus.legacyDays > 1095) {
              Text('原价 ¥99')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_tertiary'))
                .decoration({ type: TextDecorationType.LineThrough })
            } else {
              Text(`价值 ¥${this.calculateOfferMonths(this.vipStatus.legacyDays) * 6}`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_tertiary'))
                .decoration({ type: TextDecorationType.LineThrough })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Bottom)

        // 【核心CTA】立即行动按钮 - 放在第一屏可见区域
        Button() {
          if (this.isConverting) {
            Row({ space: DesignConstants.SPACING_SM }) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
              Text('升级中...')
                .fontSize(DesignConstants.FONT_SIZE_LG)
                .fontColor(Color.White)
            }
          } else {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text(this.vipStatus.legacyDays > 1095 ? '👑' : '💎')
                .fontSize(20)

              Text(this.vipStatus.legacyDays > 1095 ? '立即 0.01 元升级永久会员' : '立即 0.01 元升级')
                .fontSize(DesignConstants.FONT_SIZE_LG)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
          }
        }
        .width('100%')
        .height(52)
        .backgroundColor('#FF6B6B')
        .enabled(!this.isConverting)
        .borderRadius(26)
        .shadow({ radius: 8, color: 'rgba(255, 107, 107, 0.4)', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          if (!this.agreedToTerms) {
            this.showAgreementReminder()
            return
          }
          this.showConvertNotice()
        })

        // 会员协议勾选
        Row({ space: DesignConstants.SPACING_SM }) {
          Checkbox()
            .select(this.agreedToTerms)
            .selectedColor('#339AF0')
            .width(20)
            .height(20)
            .onChange((value: boolean) => {
              this.agreedToTerms = value
            })

          Text() {
            Span('我已阅读并同意 ')
            Span('《会员服务协议》')
              .fontColor('#339AF0')
              .onClick(() => {
                this.showMembershipAgreement()
              })
          }
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .layoutWeight(1)
        }
        .width('100%')

        // 信任背书
        Text('仅需 0.01 元 · 华为支付最低价格')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // ===== 辅助信息：升级对比（可滚动区域，次要信息）=====
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('升级后您将获得')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 对比表格 - 简化显示
        this.buildComparisonRow('数据存储', '本机保存', '云端同步', true)
        this.buildComparisonRow('换机恢复', '无法恢复', '华为账号自动恢复', true)
        this.buildComparisonRow('卸载重装', '会员丢失', '会员保留', true)
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // 取消自动续费说明（订阅会员）
      if (this.vipStatus.legacyDays <= 1095) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_info'))
            .width(16)
            .height(16)
            .fillColor('#339AF0')

          Text(`免费期结束后自动按¥6/月续费，可随时取消`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor('#339AF0')
            .layoutWeight(1)
        }
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor('rgba(51, 154, 240, 0.1)')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .width('100%')
      }
    }
    .width('100%')
  }

  // 格式化天数显示
  private formatDays(days: number): string {
    if (days >= 3650) {
      return `${(days / 365).toFixed(0)}年`
    } else if (days >= 1000) {
      return `${(days / 1000).toFixed(1)}千天`
    }
    return `${days}天`
  }

  // 对比行组件
  @Builder
  buildComparisonRow(label: string, before: string, after: string, isBetter: boolean) {
    Row() {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width(90)

      // 原来的状态 - 划掉表示已过时
      Text(before)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_tertiary'))
        .decoration({ type: TextDecorationType.LineThrough })
        .width('35%')

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))

      Text(after)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(isBetter ? '#51CF66' : $r('sys.color.font_primary'))
        .fontWeight(isBetter ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
    }
    .width('100%')
    .height(36)
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
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .border({ width: 2, color: '#FFD700' })
      .width('100%')

      Text('感谢您长期以来的支持！')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
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
        .backgroundColor($r('sys.color.comp_background_secondary'))
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
        .backgroundColor($r('sys.color.comp_background_secondary'))
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
    .backgroundColor($r('sys.color.comp_background_primary'))
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
          .fontColor($r('sys.color.font_primary'))
        
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

      // 【重要】自动续费提示
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(14)
          .height(14)
          .fillColor($r('sys.color.font_tertiary'))
        
        Text('试用到期前24小时自动续费，可随时取消')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
          .layoutWeight(1)
      }
      .width('100%')

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
    .backgroundColor($r('sys.color.comp_background_primary'))
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
    .backgroundColor($r('sys.color.comp_background_secondary'))
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
        .fontColor($r('sys.color.brand'))
      
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
      Text(`💎 在线会员`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#339AF0')
      
      Text(`老用户福利：${this.calculateOfferMonths(legacyDays)}个月免费使用`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
      
      // 价值说明
      Row({ space: DesignConstants.SPACING_XS }) {
        Text(`价值 ¥${this.calculateOfferMonths(legacyDays) * 6}`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .decoration({ type: TextDecorationType.LineThrough })
        
        Text(' 现在仅需 ¥0.01')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor('#51CF66')
          .fontWeight(FontWeight.Medium)
      }
      
      Text('换设备登录华为账号可恢复会员')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor('#51CF66')
        .margin({ top: DesignConstants.SPACING_XS })
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')

    // 【重要】自动续费提示 - 使用更温和的蓝色
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_info'))
        .width(16)
        .height(16)
        .fillColor('#339AF0')
      
      Text(`免费期结束后自动按¥6/月续费，可随时在系统设置中取消`)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor('#339AF0')
        .layoutWeight(1)
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor('rgba(51, 154, 240, 0.1)')
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
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
    // 根据转换类型构建不同的提示信息
    const isPermanent = this.vipStatus.legacyDays > 1095;
    const offerMonths = this.calculateOfferMonths(this.vipStatus.legacyDays);
    
    const message = isPermanent 
      ? '确认支付 ¥0.01 升级永久会员？\n\n' +
        '升级后您将获得：\n' +
        '• 终身免费使用所有功能\n' +
        '• 换设备登录华为账号自动恢复\n' +
        '• 数据云端同步，永不丢失\n\n' +
        '（0.01元为华为支付系统最低价格）'
      : `确认支付 ¥0.01 升级在线会员？\n\n` +
        `升级后您将获得：\n` +
        `• ${offerMonths}个月免费使用（价值¥${offerMonths * 6}）\n` +
        `• 换设备登录华为账号自动恢复\n` +
        `• 数据云端同步，永不丢失\n\n` +
        `免费期结束后自动按¥6/月续费，可随时取消\n\n` +
        `（0.01元为华为支付系统最低价格）`;
    
    AlertDialog.show({
      title: '确认支付',
      message: message,
      primaryButton: {
        value: '确认支付 0.01 元',
        action: () => {
          this.handleConvert()
        }
      },
      secondaryButton: {
        value: '再想想',
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
      promptAction.showToast({ 
        message: '兑换成功！感谢您的支持',
        duration: 3000
      })
      this.refreshStatus()
    } else {
      promptAction.showToast({ 
        message: result.message,
        duration: 3000
      })
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

  // 提示用户同意协议
  private showAgreementReminder(): void {
    AlertDialog.show({
      title: '请同意会员服务协议',
      message: '为保障您的权益，请先阅读并同意《会员服务协议》后再进行升级。',
      primaryButton: {
        value: '查看协议',
        action: () => {
          this.showMembershipAgreement()
        }
      },
      secondaryButton: {
        value: '稍后再说',
        action: () => {}
      }
    })
  }

  // 显示会员服务协议
  private showMembershipAgreement(): void {
    AlertDialog.show({
      title: '会员服务协议',
      message: MembershipAgreement.AGREEMENT_TEXT,
      primaryButton: {
        value: '同意并继续',
        action: () => {
          this.agreedToTerms = true
          // 同意后直接弹出支付确认
          this.showConvertNotice()
        }
      },
      secondaryButton: {
        value: '我再看看',
        action: () => {}
      }
    })
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
