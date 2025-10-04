
# UpgradeContent 组件实现指南

## 组件重构方案

基于现有UpgradeContent组件，进行以下重构：

### 1. 扩展组件参数

```typescript
// 新增参数定义
export interface UpgradeContentProps {
  featureName: string;
  featureDesc: string;
  icon: Resource;
  
  // 新增参数
  pricingPlans?: PricingPlan[];
  featureComparison?: FeatureComparison[];
  onUpgrade?: () => void;
  onLater?: () => void;
  showTrialOption?: boolean;
}

interface PricingPlan {
  type: 'monthly' | 'yearly' | 'lifetime';
  price: number;
  originalPrice?: number;
  discount?: string;
  isRecommended: boolean;
  features: string[];
}

interface FeatureComparison {
  feature: string;
  freeVersion: string;
  proVersion: string;
  isHighlight: boolean;
}
```

### 2. 组件结构优化

```typescript
@ComponentV2
export struct UpgradeContent {
  @Param @Require featureName: string;
  @Param @Require featureDesc: string;
  @Param @Require icon: Resource;
  
  // 新增可选参数
  @Param pricingPlans: PricingPlan[] = [];
  @Param featureComparison: FeatureComparison[] = [];
  @Param onUpgrade: () => void = () => {};
  @Param onLater: () => void = () => {};
  @Param showTrialOption: boolean = false;
  
  @State selectedPlan: PricingPlan | null = null;

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
}
```

## 具体实现模块

### 1. 头部区域实现

```typescript
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
```

### 2. 权益展示区实现

```typescript
@Builder
private buildBenefitsSection() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('专业版权益')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)
    
    // 权益网格布局
    Grid() {
      // 多频率加权
      this.buildBenefitItem(
        $r('app.media.ic_frequency_weighting'),
        '多频率加权',
        'A/C/Z计权模式，满足不同场景需求'
      )
      
      // 多时间加权
      this.buildBenefitItem(
        $r('app.media.ic_time_weighting'),
        '多时间加权',
        '快速/慢速/脉冲响应，精准测量'
      )
      
      // 智能警报
      this.buildBenefitItem(
        $r('app.media.ic_alarm'),
        '智能时段警报',
        '基于时间段的智能提醒系统'
      )
      
      // 数据导出
      this.buildBenefitItem(
        $r('app.media.ic_share'),
        '专业数据导出',
        'CSV/PDF格式，支持专业分析'
      )
      
      // 统计分析
      this.buildBenefitItem(
        $r('app.media.ic_stats'),
        '高级统计分析',
        '趋势分析、报告生成功能'
      )
      
      // 无广告
      this.buildBenefitItem(
        $r('app.media.ic_vip'),
        '无广告体验',
        '纯净使用环境，专注测量'
      )
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr')
    .columnsGap(DesignConstants.SPACING_MD)
    .rowsGap(DesignConstants.SPACING_MD)
  }
  .width('100%')
  .padding({
    top: DesignConstants.SPACING_LG,
    bottom: DesignConstants.SPACING_LG
  })
}
```

### 3. 价格方案区实现

```typescript
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
      this.buildPricingCard(plan)
    })
  }
  .width('100%')
  .padding({
    top: DesignConstants.SPACING_LG,
    bottom: DesignConstants.SPACING_LG
  })
}

@Builder
private buildPricingCard(plan: PricingPlan) {
  const isSelected = this.selectedPlan?.type === plan.type;
  
  Column({ space: DesignConstants.SPACING_SM }) {
    // 推荐标签
    if (plan.isRecommended) {
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
        Text(this.getPlanTypeText(plan.type))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Row({ space: DesignConstants.SPACING_XS }) {
          Text(`¥${plan.price}`)
            .fontSize(DesignConstants.FONT_SIZE_2XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_palette1'))
          
          if (plan.originalPrice) {
            Text(`¥${plan.originalPrice}`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.text_tertiary'))
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }
        
        if (plan.discount) {
          Text(plan.discount)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.success'))
        }
      }
      .layoutWeight(1)
      
      // 选择指示器
      if (isSelected) {
        Image($r('app.media.ic_favorite'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.ohos_id_color_palette1'))
      }
    }
    .width('100%')
    
    // 功能列表
    Column({ space: DesignConstants.SPACING_XS }) {
      ForEach(plan.features, (feature: string) => {
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_favorite'))
            .width(DesignConstants.ICON_SIZE_XS)
            .height(DesignConstants.ICON_SIZE_XS)
            .fillColor($r('sys.color.success'))
          
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
    width: isSelected ? 
      DesignConstants.BORDER_WIDTH_MD : 
      DesignConstants.BORDER_WIDTH_SM,
    color: isSelected ? 
      $r('sys.color.ohos_id_color_palette1') : 
      $r('sys.color.border_primary')
  })
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .backgroundColor(
    isSelected ? 
    $r('sys.color.background_secondary') : 
    $r('sys.color.background_primary')
  )
  .onClick(() => {
    this.selectedPlan = plan;
  })
}
```

### 4. 功能对比区实现

```typescript
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
        color: $r('sys.color.divider')
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
```

### 5. 操作按钮区实现

```typescript
@Builder
private buildActionSection() {
  Column({ space: DesignConstants.SPACING_MD }) {
    // 试用选项
    if (this.showTrialOption) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('7天免费试用')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.success'))
        
        Text('试用结束后自动续费')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.text_tertiary'))
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
        .enabled(this.selectedPlan !== null)
        .onClick(() => {
          if (this.selectedPlan) {
            this.onUpgrade();
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
```

## 辅助方法

```typescript
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
      .fillColor($r('sys.color.icon_favorite'))
    
    Text('专业版')
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.icon_favorite'))
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
```

## 使用示例

```typescript
// 在DialogHub中使用
UpgradeContent({
  featureName: '频率加权模式',
  featureDesc: '解锁A/C/Z计权等专业功能',
  icon: $r('app.media.ic_frequency_weighting'),
  pricingPlans: [
    {
      type: 'monthly',
      price: 15,
      isRecommended: false,
      features: ['所有专业功能', '月度更新']
    },
    {
      type: 'yearly',
      price: 128,
      originalPrice: 180,
      discount: '节省28%',
      isRecommended: true,
      features: ['所有