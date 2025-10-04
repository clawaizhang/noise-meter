# UpgradeContent组件状态检测实现指南

## 实现概述

修改现有的 [`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets:1) 组件，使其能够根据用户的会员状态动态显示不同的界面内容。

## 核心修改点

### 1. 添加会员状态检测逻辑

**当前问题：** 组件没有检测用户当前的会员状态，总是显示升级界面。

**解决方案：** 在组件中添加会员状态检测和界面切换逻辑。

### 2. 修改组件状态管理

**需要添加的状态变量：**
```typescript
@Local isUnlocked: boolean = false;
@Local expiryDate: number = 0;
@Local daysRemaining: number = 0;
@Local membershipType: string = 'free';
```

### 3. 实现界面切换逻辑

**构建函数修改：**
```typescript
build() {
  Column({ space: DesignConstants.SPACING_MD }) {
    if (this.isUnlocked) {
      // 显示已解锁界面
      this.buildUnlockedHeader()
      this.buildUnlockedBenefits()
      this.buildMembershipInfo()
      this.buildUnlockedActions()
    } else {
      // 显示升级界面（原有逻辑）
      this.buildHeader()
      this.buildBenefitsSection()
      if (this.pricingPlans.length > 0) {
        this.buildPricingSection()
      }
      this.buildActionSection()
    }
  }
  .padding(DesignConstants.SPACING_LG)
  .width('100%')
}
```

## 具体实现步骤

### 步骤1：添加状态检测方法

在 `aboutToAppear()` 方法中添加会员状态检测：

```typescript
aboutToAppear() {
  // 检测会员状态
  this.checkMembershipStatus();
  
  // 默认选中推荐方案（仅对免费用户）
  if (!this.isUnlocked) {
    const recommendedPlan = this.pricingPlans.find(plan => plan.isRecommended);
    if (recommendedPlan) {
      this.selectedPlan = recommendedPlan;
    }
  }
}

// 检测会员状态
private checkMembershipStatus(): void {
  const membership = this.pk.member_ship;
  
  // 检查是否是专业版且未过期
  this.isUnlocked = membership.level === MembershipLevel.PRO && 
                   membership.expiryDate > Date.now();
  
  if (this.isUnlocked) {
    this.expiryDate = membership.expiryDate;
    this.daysRemaining = this.calculateDaysRemaining(membership.expiryDate);
    this.membershipType = membership.isTrial ? 'trial' : 'pro';
  }
}

// 计算剩余天数
private calculateDaysRemaining(expiryDate: number): number {
  const now = Date.now();
  const diff = expiryDate - now;
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
}
```

### 步骤2：创建已解锁界面构建器

添加新的构建器方法来显示已解锁状态：

```typescript
// 已解锁头部区域
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

// 有效期徽章
@Builder
private buildExpiryBadge() {
  Row({ space: DesignConstants.SPACING_XS }) {
    Image($r('app.media.ic_calendar'))
      .width(DesignConstants.ICON_SIZE_SM)
      .height(DesignConstants.ICON_SIZE_SM)
      .fillColor($r('sys.color.font_secondary'))

    Text(`有效期至 ${this.formatDate(this.expiryDate)}`)
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
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

### 步骤3：修改已解锁功能展示

```typescript
// 已解锁功能展示
@Builder
private buildUnlockedBenefits() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('已解锁的专业功能')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    // 功能网格布局
    Column({ space: DesignConstants.SPACING_SM }) {
      // 第一行
      Row({ space: DesignConstants.SPACING_MD }) {
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_frequency_weighting'),
          '多频率加权',
          'A/C/Z计权模式'
        )
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_audio_analysis'),
          '音频分析',
          '快速/慢速/脉冲'
        )
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_alarm'),
          '智能警报',
          '基于时段提醒'
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 第二行
      Row({ space: DesignConstants.SPACING_MD }) {
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_settings'),
          '自定义模式',
          'FFT参数自定义'
        )
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_history'),
          '历史报告',
          '趋势分析可视化'
        )
        this.buildUnlockedBenefitItem(
          $r('app.media.ic_vip'),
          '无广告',
          '纯净使用环境'
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

// 已解锁功能项（带对勾标记）
@Builder
private buildUnlockedBenefitItem(icon: Resource, title: string, desc: string) {
  Column({ space: DesignConstants.SPACING_XS }) {
    // 对勾标记
    Row({ space: 2 }) {
      Image($r('app.media.ic_favorite'))
        .width(12)
        .height(12)
        .fillColor($r('sys.color.confirm'))
      
      Image(icon)
        .width(DesignConstants.ICON_SIZE_MD - 4)
        .height(DesignConstants.ICON_SIZE_MD - 4)
        .fillColor($r('sys.color.ohos_id_color_palette1'))
    }

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
  .backgroundColor($r('sys.color.background_secondary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  .width(100)
  .height(80)
}
```

### 步骤4：添加会员信息卡片

```typescript
// 会员信息卡片
@Builder
private buildMembershipInfo() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('会员信息')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    // 信息列表
    Column({ space: DesignConstants.SPACING_SM }) {
      this.buildInfoItem('会员类型', this.membershipType === 'trial' ? '试用版' : '专业版')
      this.buildInfoItem('购买日期', this.formatDate(this.pk.member_ship.purchaseDate))
      this.buildInfoItem('到期时间', this.formatDate(this.expiryDate))
      this.buildInfoItem('剩余天数', `${this.daysRemaining}天`)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)

    // 自动续费状态
    if (this.membershipType === 'pro') {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('自动续费：开启')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
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
```

### 步骤5：修改操作按钮区

```typescript
// 已解锁状态操作按钮
@Builder
private buildUnlockedActions() {
  Column({ space: DesignConstants.SPACING_MD }) {
    // 主要操作按钮
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('管理订阅')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.handleManageSubscription();
        })

      Button('续费升级')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.ohos_id_color_palette1'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.handleRenewUpgrade();
        })
    }
    .width('100%')

    // 辅助操作
    Button('查看使用指南')
      .width('100%')
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .backgroundColor($r('sys.color.transparent'))
      .fontColor($r('sys.color.ohos_id_color_palette1'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .border({
        width: DesignConstants.BORDER_WIDTH_SM,
        color: $r('sys.color.ohos_id_color_palette1')
      })
      .onClick(() => {
        this.handleViewGuide();
      })
  }
  .width('100%')
  .padding({
    top: DesignConstants.SPACING_LG
  })
}
```

### 步骤6：添加工具方法

```typescript
// 日期格式化
private formatDate(timestamp: number): string {
  if (!timestamp) return '--';
  
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  return `${year}-${month}-${day}`;
}

// 处理管理订阅
private handleManageSubscription(): void {
  // 跳转到订阅管理页面
  console.info('[会员管理] 跳转到订阅管理');
  // TODO: 实现订阅管理跳转逻辑
}

// 处理续费升级
private handleRenewUpgrade(): void {
  // 显示续费选项
  console.info('[会员管理] 显示续费选项');
  // TODO: 实现续费升级逻辑
}

// 处理查看指南
private handleViewGuide(): void {
  // 跳转到使用指南
  console.info('[会员管理] 跳转到使用指南');
  // TODO: 实现指南跳转逻辑
}
```

## 测试要点

### 功能测试
1. **免费用户**：显示完整的升级界面
2. **专业版用户**：显示已解锁界面
3. **试用期用户**：显示试用状态
4. **过期用户**：显示升级界面

### 界面测试
1. **布局适配**：不同屏幕尺寸下的显示效果
2. **颜色主题**：深色/浅色模式适配
3. **交互响应**：按钮点击和状态切换

## 注意事项

1. **向后兼容**：确保现有功能不受影响
2. **性能优化**：避免不必要的状态检测
3. **错误处理**：处理会员状态获取失败的情况
4. **国际化**：支持多语言显示

通过以上修改，[`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets:1) 组件将能够根据用户的会员状态智能显示相应的界面内容，提升用户体验。