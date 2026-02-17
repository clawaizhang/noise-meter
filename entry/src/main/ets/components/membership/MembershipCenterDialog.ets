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

// 价格方案选项接口
interface PricingOption {
  type: string;
  title: string;
  price: number;
  originalPrice: number | null;
  tag: string;
  tagColor: Resource | string;
  desc: string;
  isRecommended: boolean;
  onClick: () => void;
}

// 功能项接口
interface FeatureItem {
  icon: Resource;
  title: string;
  desc: string;
  highlight: boolean;
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
            this.showAgreementReminder('convert')
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

  // 测量精度功能列表
  @Builder
  buildMeasurementFeatures() {
    this.buildFeatureCategory('🔬 测量精度', [
      { icon: $r('app.media.ic_frequency_weighting'), title: '多频率加权', desc: 'A/C/Z计权模式，符合国际标准', highlight: true },
      { icon: $r('app.media.ic_time_weighting'), title: '音频分析模式', desc: '快速/慢速/脉冲响应', highlight: true },
      { icon: $r('app.media.ic_calibration'), title: '智能自动校准', desc: '自动计算最佳校准值', highlight: true },
      { icon: $r('app.media.ic_settings'), title: '高级FFT参数', desc: '自定义窗函数、采样率', highlight: true }
    ])
  }

  // 数据管理功能列表
  @Builder
  buildDataManagementFeatures() {
    this.buildFeatureCategory('💾 数据管理', [
      { icon: $r('app.media.ic_save'), title: '自动云端保存', desc: '测量数据实时同步云端', highlight: true },
      { icon: $r('app.media.ic_save'), title: '华为账号同步', desc: '换机登录自动恢复数据', highlight: true },
      { icon: $r('app.media.ic_history'), title: '全部历史记录', desc: '免费版仅3条，会员无限制', highlight: true }
    ])
  }

  // 智能功能列表
  @Builder
  buildSmartFeatures() {
    this.buildFeatureCategory('🤖 智能功能', [
      { icon: $r('app.media.ic_alarm'), title: '智能时段警报', desc: '白天/夜间不同阈值提醒', highlight: true },
      { icon: $r('app.media.ic_alarm'), title: '健康影响评估', desc: '专业噪音健康影响计算', highlight: true },
      { icon: $r('app.media.ic_alarm'), title: '暴露量统计', desc: '长期噪音暴露监测', highlight: true }
    ])
  }

  // 功能分类展示 - 优化：使用Flex布局替代Grid，避免嵌套滚动冲突
  @Builder
  buildFeatureCategory(categoryTitle: string, features: FeatureItem[]) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 分类标题
      Text(categoryTitle)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 功能网格 - 使用Row+Column替代Grid，性能更好
      Column({ space: DesignConstants.SPACING_SM }) {
        // 第一行
        Row({ space: DesignConstants.SPACING_SM }) {
          this.buildFeatureItem(features[0])
          if (features.length > 1) {
            this.buildFeatureItem(features[1])
          }
        }
        .width('100%')

        // 第二行（如果有）
        if (features.length > 2) {
          Row({ space: DesignConstants.SPACING_SM }) {
            this.buildFeatureItem(features[2])
            if (features.length > 3) {
              this.buildFeatureItem(features[3])
            } else {
              // 占位
              Blank().layoutWeight(1)
            }
          }
          .width('100%')
        }
      }
      .width('100%')
    }
    .width('100%')
  }

  // 功能项构建器 - 优化：简化布局，减少嵌套
  @Builder
  buildFeatureItem(feature: FeatureItem) {
    Column({ space: 2 }) {
      // 图标和NEW标签
      Row() {
        // 使用固定尺寸的图标容器，避免动态计算
        Image(feature.icon)
          .width(24)
          .height(24)
          .fillColor($r('sys.color.brand'))

        if (feature.highlight) {
          Text('NEW')
            .fontSize(9)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })
            .backgroundColor('#FF6B6B')
            .borderRadius(3)
            .margin({ left: 4 })
        }

        Blank()
      }
      .width('100%')
      .height(28)

      // 标题
      Text(feature.title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 描述
      Text(feature.desc)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .height(32)
    }
    .padding(8)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .layoutWeight(1)
    .height(88)
  }

  // 版本对比总结
  @Builder
  buildVersionComparisonSummary() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('基础版 vs 专业版')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 对比表格
      Column({ space: DesignConstants.SPACING_XS }) {
        this.buildComparisonRow('频率加权', '仅A计权', 'A/C/Z计权', true)
        this.buildComparisonRow('分析模式', '仅快速模式', '快/慢/脉冲', true)
        this.buildComparisonRow('历史记录', '仅最近3条', '全部记录无限制', true)
        this.buildComparisonRow('数据存储', '本机保存', '云端同步', true)
        this.buildComparisonRow('换机恢复', '无法恢复', '账号自动恢复', true)
        this.buildComparisonRow('智能警报', '基础警报', '时段智能警报', true)
        this.buildComparisonRow('校准方式', '手动校准', '手动+自动校准', true)
      }
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .width('100%')
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_SM })
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
      // ===== 核心转化区：福利+价格+CTA（第一屏可见）=====
      Column({ space: DesignConstants.SPACING_MD }) {
        // 福利标签
        Row() {
          Text('🎁 新用户专享福利')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor('#339AF0')
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('rgba(51, 154, 240, 0.15)')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignSelf(ItemAlign.Start)

        // 核心福利（超大字号，视觉冲击）
        Column({ space: DesignConstants.SPACING_SM }) {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('7天')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#339AF0')

            Text('试用')
              .fontSize(24)
              .fontColor($r('sys.color.font_primary'))
          }

          Row({ space: DesignConstants.SPACING_SM }) {
            Text('体验价')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))

            Text('¥0.01')
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontColor('#FF6B6B')
              .fontWeight(FontWeight.Bold)

            Text('（华为支付最低价格）')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
          }
        }

        // 权益简介
        Text('试用期间解锁全部专业功能')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))

        // 【核心CTA】立即行动按钮
        Button() {
          if (this.isConverting) {
            Row({ space: DesignConstants.SPACING_SM }) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Color.White)
              Text('开通中...')
                .fontSize(DesignConstants.FONT_SIZE_LG)
                .fontColor(Color.White)
            }
          } else {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('🎁')
                .fontSize(20)

              Text('0.01元立即体验')
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
            this.showAgreementReminder('trial')
            return
          }
          this.showTrialConfirmDialog()
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
        Text('华为应用市场 · 安全支付 · 随时可取消')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // ===== 专业功能展示（分类展示）=====
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('开通会员解锁全部功能')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 测量精度类
        this.buildMeasurementFeatures()

        // 数据管理类
        this.buildDataManagementFeatures()

        // 智能功能类
        this.buildSmartFeatures()

        // 基础版vs专业版对比总结
        this.buildVersionComparisonSummary()
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')

      // ===== 更多方案选择 =====
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('更多方案')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 月度方案
        this.buildMonthlyPlan()

        // 年度方案（推荐）
        this.buildYearlyPlan()
      }
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .width('100%')
    }
    .width('100%')
  }

  // 月度方案构建器
  @Builder
  buildMonthlyPlan() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧：标签+标题+描述
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题
        Text('月度会员')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 描述
        Text('按月订阅，随时取消')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：价格
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('¥6')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))

        Text('/月')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .onClick(() => {
      if (!this.agreedToTerms) {
        this.showAgreementReminder('monthly')
        return
      }
      this.showPurchaseConfirmDialog('vip_monthly', '月度会员', 6)
    })
  }

  // 年度方案构建器
  @Builder
  buildYearlyPlan() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧：标签+标题+描述
      Column({ space: DesignConstants.SPACING_XS }) {
        // 推荐标签
        Text('最受欢迎')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#FF6B6B')
          .borderRadius(4)

        // 标题
        Text('年度会员')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 描述
        Text('相当于 ¥4.8/月')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：价格
      Column({ space: DesignConstants.SPACING_XS }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('¥58')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')

          Text('¥72')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_tertiary'))
            .decoration({ type: TextDecorationType.LineThrough })
        }

        Text('节省 ¥14')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor('#51CF66')
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: 2,
      color: '#FF6B6B'
    })
    .onClick(() => {
      if (!this.agreedToTerms) {
        this.showAgreementReminder('yearly')
        return
      }
      this.showPurchaseConfirmDialog('vip_yearly', '年度会员', 58)
    })
  }

  // 价格方案卡片构建器（保留用于可能的复用）
  @Builder
  buildPricingOptionCard(option: PricingOption) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧：标签+标题+描述
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标签
        Text(option.tag)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(option.isRecommended ? Color.White : $r('sys.color.font_secondary'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(option.isRecommended ? '#FF6B6B' : 'transparent')
          .borderRadius(4)
          .visibility(option.isRecommended ? Visibility.Visible : Visibility.None)

        // 标题
        Text(option.title)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 描述
        Text(option.desc)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：价格
      Column({ space: DesignConstants.SPACING_XS }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text(`¥${option.price}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(option.isRecommended ? '#FF6B6B' : $r('sys.color.font_primary'))

          if (option.originalPrice) {
            Text(`¥${option.originalPrice}`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_tertiary'))
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }

        if (option.originalPrice) {
          Text(`节省 ¥${option.originalPrice - option.price}`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor('#51CF66')
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: option.isRecommended ? 2 : 1,
      color: option.isRecommended ? '#FF6B6B' : $r('sys.color.comp_border_color')
    })
    .onClick(option.onClick)
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

  // ========== 确认对话框 ==========
  
  /**
   * 显示试用确认对话框
   */
  showTrialConfirmDialog() {
    AlertDialog.show({
      title: '确认0.01元体验7天会员',
      message: '您即将以0.01元（华为支付最低价格）体验7天会员服务\n\n' +
               '体验期间您将获得：\n' +
               '• 所有专业功能免费使用\n' +
               '• 数据云端同步，永不丢失\n' +
               '• 换设备登录华为账号可恢复会员\n\n' +
               '体验到期前24小时自动续费¥6/月\n' +
               '可随时在系统设置中取消',
      primaryButton: {
        value: '确认支付 0.01 元',
        action: () => {
          this.startTrial()
        }
      },
      secondaryButton: {
        value: '再想想',
        action: () => {}
      }
    })
  }

  /**
   * 显示购买确认对话框
   */
  showPurchaseConfirmDialog(productId: string, title: string, price: number) {
    const isYearly = productId === 'vip_yearly'
    const message = isYearly
      ? `确认订阅${title}？\n\n` +
        `订阅后您将获得：\n` +
        `• 一整年会员服务（价值¥72）\n` +
        `• 所有专业功能无限制使用\n` +
        `• 数据云端同步，换机自动恢复\n\n` +
        `仅需 ¥${price}（节省¥14）\n` +
        `到期前24小时自动续费，可随时取消`
      : `确认订阅${title}？\n\n` +
        `订阅后您将获得：\n` +
        `• 一整月会员服务\n` +
        `• 所有专业功能无限制使用\n` +
        `• 数据云端同步，换机自动恢复\n\n` +
        `仅需 ¥${price}/月\n` +
        `到期前24小时自动续费，可随时取消`

    AlertDialog.show({
      title: '确认订阅',
      message: message,
      primaryButton: {
        value: `确认支付 ¥${price}`,
        action: () => {
          this.purchase(productId)
        }
      },
      secondaryButton: {
        value: '再想想',
        action: () => {}
      }
    })
  }

  showAgreementThenTrial() {
    // 协议已前置勾选，此方法保留用于兼容
    this.showTrialConfirmDialog()
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
    // 协议已前置勾选，直接显示确认对话框
    const isYearly = productId === 'vip_yearly'
    this.showPurchaseConfirmDialog(productId, isYearly ? '年度会员' : '月度会员', isYearly ? 58 : 6)
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

  // 当前待执行的操作类型
  private pendingAction: 'trial' | 'monthly' | 'yearly' | 'convert' | null = null

  // 提示用户同意协议
  private showAgreementReminder(action: 'trial' | 'monthly' | 'yearly' | 'convert'): void {
    this.pendingAction = action
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
        action: () => {
          this.pendingAction = null
        }
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
          // 根据待执行的操作类型，执行相应的确认对话框
          this.executePendingAction()
        }
      },
      secondaryButton: {
        value: '我再看看',
        action: () => {
          this.pendingAction = null
        }
      }
    })
  }

  // 执行待处理的操作
  private executePendingAction(): void {
    const action = this.pendingAction
    this.pendingAction = null
    
    switch (action) {
      case 'trial':
        this.showTrialConfirmDialog()
        break
      case 'monthly':
        this.showPurchaseConfirmDialog('vip_monthly', '月度会员', 6)
        break
      case 'yearly':
        this.showPurchaseConfirmDialog('vip_yearly', '年度会员', 58)
        break
      case 'convert':
        this.showConvertNotice()
        break
      default:
        // 没有待执行的操作，不做任何事
        break
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
