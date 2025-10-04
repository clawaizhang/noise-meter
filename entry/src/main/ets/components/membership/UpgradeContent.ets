import { DesignConstants } from "../../constants/DesignConstants"

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

// 权益项接口
interface BenefitItem {
  icon: Resource;
  title: string;
  description: string;
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

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 1. 头部区域
      this.buildHeader()

      // 2. 权益展示区
      this.buildBenefitsSection()

      // 3. 价格方案区
      if (this.pricingPlans.length > 0) {
        this.buildPricingSection()
      }

      // 4. 功能对比区
      if (this.featureComparison.length > 0) {
        this.buildComparisonSection()
      }

      // 5. 操作按钮区
      this.buildActionSection()
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
            .fillColor($r('sys.color.ohos_id_color_palette1'))
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

      // 权益网格布局
      Column({ space: 16 }) {
        // 多频率加权
        this.buildBenefitItem(
          $r('app.media.ic_frequency_weighting'),
          '多频率加权',
          'A/C/Z计权模式，满足不同场景需求'
        )

        // 音频分析模式
        this.buildBenefitItem(
          $r('app.media.ic_audio_analysis'),
          '音频分析模式',
          '快速/慢速/脉冲响应，精准音频分析'
        )

        // 智能警报
        this.buildBenefitItem(
          $r('app.media.ic_alarm'),
          '智能时段警报',
          '基于时间段的智能提醒系统'
        )

        // 自定义模式
        this.buildBenefitItem(
          $r('app.media.ic_settings'),
          '自定义模式',
          'FFT参数自定义，个性化测量配置'
        )

        // 历史报告
        this.buildBenefitItem(
          $r('app.media.ic_history'),
          '历史记录报告',
          '完整测量历史，趋势分析可视化'
        )

        // 无广告
        this.buildBenefitItem(
          $r('app.media.ic_vip'),
          '无广告体验',
          '纯净使用环境，专注测量'
        )
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

      // 价格方案列表
      ForEach(this.pricingPlans, (plan: PricingPlan) => {
        this.buildPricingCard({ selected: this.selectedPlan!, current: plan })
      })
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // 功能对比区构建
  @Builder
  private buildComparisonSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('功能对比')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 对比表格
      Column({ space: DesignConstants.SPACING_XS }) {
        // 表头
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('功能特性')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(2)

          Text('免费版')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('专业版')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_palette1'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({
          bottom: DesignConstants.SPACING_SM
        })
        .border({
          width: DesignConstants.BORDER_WIDTH_SM,
          color: $r('sys.color.comp_divider')
        })

        // 对比内容
        ForEach(this.featureComparison, (item: FeatureComparison) => {
          this.buildComparisonRow(item)
        })
      }
      .width('100%')
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
      // 试用选项
      if (this.showTrialOption) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('7天免费试用')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.confirm'))

          Text('试用结束后自动续费')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }

      // 操作按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('稍后再说')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.onLater();
          })

        Button('立即升级')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.ohos_id_color_palette1'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .enabled(this.selectedPlan !== null && this.purchaseState === 'idle')
          .onClick(() => {
            if (this.selectedPlan) {
              this.handleUpgrade();
            }
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

    Column({ space: DesignConstants.SPACING_SM }) {
      // 推荐标签
      if (plans.current.isRecommended) {
        Text('最受欢迎')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.white'))
          .backgroundColor($r('sys.color.ohos_id_color_palette1'))
          .borderRadius(DesignConstants.BORDER_RADIUS_XS)
          .padding({
            left: DesignConstants.SPACING_SM,
            right: DesignConstants.SPACING_SM,
            top: 2,
            bottom: 2
          })
          .alignSelf(ItemAlign.Start)
      }

      // 方案类型和价格
      Row({ space: DesignConstants.SPACING_SM }) {
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.getPlanTypeText(plans.current.type))
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Row({ space: DesignConstants.SPACING_XS }) {
            Text(`¥${plans.current.price}`)
              .fontSize(DesignConstants.FONT_SIZE_2XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.ohos_id_color_palette1'))

            if (plans.current.originalPrice) {
              Text(`¥${plans.current.originalPrice}`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_tertiary'))
                .decoration({ type: TextDecorationType.LineThrough })
            }
          }

          if (plans.current.discount) {
            Text(plans.current.discount)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.confirm'))
          }
        }
        .layoutWeight(1)

        // 选择指示器
        if (plans.selected?.type === plans.current.type) {
          Image($r('app.media.ic_favorite'))
            .width(DesignConstants.ICON_SIZE_MD)
            .height(DesignConstants.ICON_SIZE_MD)
            .fillColor($r('sys.color.ohos_id_color_palette1'))
        }
      }
      .width('100%')

      // 功能列表
      Column({ space: DesignConstants.SPACING_XS }) {
        ForEach(plans.current.features, (feature: string) => {
          Row({ space: DesignConstants.SPACING_XS }) {
            Image($r('app.media.ic_favorite'))
              .width(DesignConstants.ICON_SIZE_XS)
              .height(DesignConstants.ICON_SIZE_XS)
              .fillColor($r('sys.color.confirm'))

            Text(feature)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
          }
          .width('100%')
        })
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_SM })
    }
    .padding(DesignConstants.SPACING_MD)
    .border({
      width: plans.selected?.type === plans.current.type ?
      DesignConstants.BORDER_WIDTH_MD :
      DesignConstants.BORDER_WIDTH_SM,
      color: plans.selected?.type === plans.current.type ?
      $r('sys.color.ohos_id_color_palette1') :
      $r('sys.color.comp_divider')
    })
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .backgroundColor(
      plans.selected?.type === plans.current.type ?
      $r('sys.color.background_secondary') :
      $r('sys.color.background_primary')
    )
    .onClick(() => {
      this.selectedPlan = plans.current;
    })
  }

  // 构建权益项
  @Builder
  private buildBenefitItem(icon: Resource, title: string, desc: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(icon)
        .width(DesignConstants.ICON_SIZE_LG)
        .height(DesignConstants.ICON_SIZE_LG)
        .fillColor($r('sys.color.ohos_id_color_palette1'))

      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(desc)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
    .height(120)
  }

  // 构建对比行
  @Builder
  private buildComparisonRow(item: FeatureComparison) {
    Row({ space: DesignConstants.SPACING_MD }) {
      Text(item.feature)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(2)

      Text(item.freeVersion)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text(item.proVersion)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.ohos_id_color_palette1'))
        .fontWeight(item.isHighlight ? FontWeight.Bold : FontWeight.Normal)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_SM,
      bottom: DesignConstants.SPACING_SM
    })
  }

  // 构建会员徽章
  @Builder
  private buildPremiumBadge() {
    Row({ space: DesignConstants.SPACING_XS }) {
      Image($r('app.media.ic_vip'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)

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
    .backgroundColor($r('sys.color.background_secondary'))
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

  // 处理升级逻辑
  private handleUpgrade() {
    this.purchaseState = 'loading';

    // 模拟购买过程
    setTimeout(() => {
      // 这里应该调用实际的购买API
      const success = Math.random() > 0.2; // 80%成功率模拟

      if (success) {
        this.purchaseState = 'success';
        console.info('购买成功，方案类型:', this.selectedPlan?.type);

        // 延迟执行回调
        setTimeout(() => {
          this.onUpgrade();
        }, 1500);
      } else {
        this.purchaseState = 'error';
        console.error('购买失败');

        // 3秒后重置状态
        setTimeout(() => {
          this.purchaseState = 'idle';
        }, 3000);
      }
    }, 2000)
  }

  // 购买状态显示
  @Builder
  private buildPurchaseStatus() {
    if (this.purchaseState === 'loading') {
      Row({ space: DesignConstants.SPACING_SM }) {
        LoadingProgress()
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .color($r('sys.color.ohos_id_color_palette1'))

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

// 默认功能对比配置
export const defaultFeatureComparison: FeatureComparison[] = [
  {
    feature: '频率加权',
    freeVersion: '仅A计权',
    proVersion: 'A/C/Z计权',
    isHighlight: true
  },
  {
    feature: '音频分析',
    freeVersion: '基础模式',
    proVersion: '快速/慢速/脉冲',
    isHighlight: true
  },
  {
    feature: '警报系统',
    freeVersion: '基础警报',
    proVersion: '智能时段警报',
    isHighlight: false
  },
  {
    feature: '自定义设置',
    freeVersion: '不支持',
    proVersion: 'FFT参数自定义',
    isHighlight: true
  },
  {
    feature: '历史报告',
    freeVersion: '基础查看',
    proVersion: '完整趋势分析',
    isHighlight: false
  },
  {
    feature: '广告显示',
    freeVersion: '有广告',
    proVersion: '无广告',
    isHighlight: false
  }
];