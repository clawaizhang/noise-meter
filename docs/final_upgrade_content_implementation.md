# 最终版UpgradeContent组件状态检测实现

## 实现概述

基于现有的 `MembershipStatus.can()` 方法，简洁地修改 [`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets:1) 组件，使其能够根据会员状态动态显示不同界面。

## 核心修改逻辑

### 使用现有的 can() 方法
```typescript
private get isUnlocked(): boolean {
  return this.pk.member_ship.can();
}
```

### 界面切换逻辑
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
    
    // 购买状态显示（保持不变）
    this.buildPurchaseStatus()
  }
  .padding(DesignConstants.SPACING_LG)
  .width('100%')
}
```

## 具体实现修改

### 1. 已解锁头部区域

```typescript
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
```

### 2. 有效期徽章

```typescript
@Builder
private buildExpiryBadge() {
  Row({ space: DesignConstants.SPACING_XS }) {
    Image($r('app.media.ic_calendar'))
      .width(DesignConstants.ICON_SIZE_SM)
      .height(DesignConstants.ICON_SIZE_SM)
      .fillColor($r('sys.color.font_secondary'))

    Text(`有效期至 ${this.formatDate(this.pk.member_ship.expiryDate)}`)
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

### 3. 已解锁功能展示（复用现有布局）

```typescript
@Builder
private buildUnlockedBenefits() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('已解锁的专业功能')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    // 直接复用现有的权益网格布局
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_MD }) {
        this.buildCompactBenefitItem(
          $r('app.media.ic_frequency_weighting'),
          '多频率加权',
          'A/C/Z计权模式'
        )
        this.buildCompactBenefitItem(
          $r('app.media.ic_audio_analysis'),
          '音频分析',
          '快速/慢速/脉冲'
        )
        this.buildCompactBenefitItem(
          $r('app.media.ic_alarm'),
          '智能警报',
          '基于时段提醒'
        )
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row({ space: DesignConstants.SPACING_MD }) {
        this.buildCompactBenefitItem(
          $r('app.media.ic_settings'),
          '自定义模式',
          'FFT参数自定义'
        )
        this.buildCompactBenefitItem(
          $r('app.media.ic_history'),
          '历史报告',
          '趋势分析可视化'
        )
        this.buildCompactBenefitItem(
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
```

### 4. 会员信息卡片

```typescript
@Builder
private buildMembershipInfo() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('会员信息')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    Column({ space: DesignConstants.SPACING_SM }) {
      this.buildInfoItem('购买日期', this.formatDate(this.pk.member_ship.purchaseDate))
      this.buildInfoItem('到期时间', this.formatDate(this.pk.member_ship.expiryDate))
      this.buildInfoItem('剩余天数', `${this.calculateDaysRemaining()}天`)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  .width('100%')
  .padding({
    top: DesignConstants.SPACING_LG,
    bottom: DesignConstants.SPACING_LG
  })
}

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

### 5. 已解锁操作按钮

```typescript
@Builder
private buildUnlockedActions() {
  Column({ space: DesignConstants.SPACING_MD }) {
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
  }
  .width('100%')
  .padding({
    top: DesignConstants.SPACING_LG
  })
}
```

### 6. 添加工具方法

```typescript
// 计算剩余天数
private calculateDaysRemaining(): number {
  const membership = this.pk.member_ship;
  const now = Date.now();
  const diff = membership.expiryDate - now;
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
}

// 日期格式化
private formatDate(timestamp: number): string {
  if (!timestamp || timestamp === 0) return '--';
  
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  return `${year}-${month}-${day}`;
}

// 按钮处理（占位实现）
private handleManageSubscription(): void {
  console.info('[会员管理] 跳转到订阅管理');
}

private handleRenewUpgrade(): void {
  console.info('[会员管理] 显示续费选项');
}
```

## 修改总结

### 主要修改点
1. **状态检测**：使用 `this.pk.member_ship.can()` 方法
2. **界面切换**：在主构建函数中添加条件判断
3. **已解锁界面**：创建4个新的构建器方法
4. **工具方法**：添加日期格式化和天数计算

### 优势
- **极简实现**：只使用现有的 `can()` 方法
- **代码复用**：最大化复用现有组件和布局
- **清晰逻辑**：状态检测和界面切换逻辑清晰
- **向后兼容**：不影响现有功能

### 最终效果
- **免费用户**：看到完整的升级界面
- **专业版用户**：看到"专业版已解锁"状态和会员信息
- **试用期用户**：看到"专业版已解锁"状态和会员信息

这个方案完美解决了您提到的问题：专业版用户不再看到重复的升级界面，而是看到清晰的已解锁状态和会员信息。