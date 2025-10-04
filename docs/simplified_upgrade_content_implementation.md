# 简化版UpgradeContent组件状态检测实现

## 实现概述

基于现有的 `PreferenceKeys` 状态管理，修改 [`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets:1) 组件，使其能够根据会员状态动态显示不同界面。

## 核心修改逻辑

### 使用现有状态变量
直接使用 `this.pk.member_ship` 来检测会员状态，无需添加新的状态变量。

### 界面切换逻辑
```typescript
private get isUnlocked(): boolean {
  const membership = this.pk.member_ship;
  return membership.level === MembershipLevel.PRO && 
         membership.expiryDate > Date.now();
}

private get daysRemaining(): number {
  const membership = this.pk.member_ship;
  const now = Date.now();
  const diff = membership.expiryDate - now;
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
}
```

## 具体实现修改

### 1. 修改主构建函数

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

### 2. 创建已解锁头部区域

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

### 3. 有效期徽章构建器

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

### 4. 已解锁功能展示

```typescript
@Builder
private buildUnlockedBenefits() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('已解锁的专业功能')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    // 复用现有的权益网格布局，但添加对勾标记
    Column({ space: DesignConstants.SPACING_SM }) {
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
```

### 5. 已解锁功能项（带对勾）

```typescript
@Builder
private buildUnlockedBenefitItem(icon: Resource, title: string, desc: string) {
  Column({ space: DesignConstants.SPACING_XS }) {
    // 对勾标记 + 图标
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

### 6. 会员信息卡片

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
      this.buildInfoItem('会员类型', this.pk.member_ship.isTrial ? '试用版' : '专业版')
      this.buildInfoItem('购买日期', this.formatDate(this.pk.member_ship.purchaseDate))
      this.buildInfoItem('到期时间', this.formatDate(this.pk.member_ship.expiryDate))
      this.buildInfoItem('剩余天数', `${this.daysRemaining}天`)
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
```

### 7. 已解锁操作按钮

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

### 8. 添加工具方法

```typescript
// 日期格式化工具方法
private formatDate(timestamp: number): string {
  if (!timestamp || timestamp === 0) return '--';
  
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  return `${year}-${month}-${day}`;
}

// 处理按钮点击
private handleManageSubscription(): void {
  console.info('[会员管理] 跳转到订阅管理');
  // TODO: 实现订阅管理跳转
}

private handleRenewUpgrade(): void {
  console.info('[会员管理] 显示续费选项');
  // TODO: 实现续费升级
}

private handleViewGuide(): void {
  console.info('[会员管理] 跳转到使用指南');
  // TODO: 实现指南跳转
}
```

## 修改总结

### 主要修改点
1. **主构建函数**：添加状态检测和界面切换
2. **已解锁界面**：创建4个新的构建器方法
3. **工具方法**：添加日期格式化和按钮处理

### 不修改的内容
- 原有的升级界面逻辑保持不变
- 购买状态显示逻辑保持不变
- 价格方案选择逻辑保持不变

### 优势
- **最小化修改**：只添加必要的构建器方法
- **复用现有代码**：充分利用现有的状态管理
- **向后兼容**：不影响现有功能
- **清晰分离**：已解锁和升级界面逻辑分离

通过这个简化方案，[`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets:1) 组件将能够智能地根据会员状态显示相应的界面内容。