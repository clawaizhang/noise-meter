# 主页组件设计规范

## 概述
为噪音检测应用添加主页Tab，作为应用的概览页面，显示当前分贝值并提供功能导航入口。

## 组件结构

### 1. 主页主组件 - HomePageContent.ets
**位置**: `entry/src/main/ets/components/home/HomePageContent.ets`

```typescript
@ComponentV2
export struct HomePageContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  
  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 顶部状态区
        this.buildStatusHeader()
        
        // 核心分贝显示区
        this.buildDecibelDisplay()
        
        // 功能入口卡片区
        this.buildFunctionCards()
      }
      .padding(DesignConstants.SPACING_MD)
    }
  }
}
```

### 2. 顶部状态区组件
**功能**: 显示时间、环境质量评级、会员状态

```typescript
@Builder
private buildStatusHeader() {
  Row() {
    // 当前时间
    Column() {
      Text(this.currentTime)
        .fontSize(DesignConstants.FONT_SIZE_MD)
      Text(this.currentDate)
        .fontSize(DesignConstants.FONT_SIZE_SM)
    }
    
    Blank()
    
    // 环境质量评级
    Column() {
      Text(this.environmentQuality)
        .fontSize(DesignConstants.FONT_SIZE_MD)
      Text('环境质量')
        .fontSize(DesignConstants.FONT_SIZE_SM)
    }
    
    Blank()
    
    // 会员状态
    Column() {
      Text(this.membershipStatus)
        .fontSize(DesignConstants.FONT_SIZE_MD)
      Text('会员状态')
        .fontSize(DesignConstants.FONT_SIZE_SM)
    }
  }
  .width('100%')
  .padding(DesignConstants.SPACING_MD)
}
```

### 3. 核心分贝显示区组件
**功能**: 大字体显示当前分贝值，包含分贝等级描述

```typescript
@Builder
private buildDecibelDisplay() {
  Column({ space: DesignConstants.SPACING_SM }) {
    // 大字体分贝值
    Text(`${this.ak.uiDisplayState.displayDb}dB`)
      .fontSize(64)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.decibelColor)
    
    // 分贝等级描述
    Text(this.decibelDescription)
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontColor($r('sys.color.font_secondary'))
  }
  .width('100%')
  .padding(DesignConstants.SPACING_XL)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_XL)
}
```

### 4. 功能入口卡片组件
**功能**: 4个等宽卡片，提供功能导航

```typescript
@Builder
private buildFunctionCards() {
  GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
    // 仪表盘入口
    GridCol({ span: 1 }) {
      this.buildFunctionCard({
        title: '仪表盘',
        icon: $r('app.media.ic_meter'),
        description: '完整噪音检测',
        onTap: () => { this.switchToTab(1) } // 切换到仪表盘Tab
      })
    }
    
    // 警报入口
    GridCol({ span: 1 }) {
      this.buildFunctionCard({
        title: '警报',
        icon: $r('app.media.ic_alarm'),
        description: '噪音警报管理',
        onTap: () => { this.switchToTab(2) } // 切换到警报Tab
      })
    }
    
    // 影响入口
    GridCol({ span: 1 }) {
      this.buildFunctionCard({
        title: '影响',
        icon: $r('app.media.i_solar_radar_outline'),
        description: '暴露统计分析',
        onTap: () => { this.switchToTab(3) } // 切换到影响Tab
      })
    }
    
    // 历史记录入口
    GridCol({ span: 1 }) {
      this.buildFunctionCard({
        title: '历史',
        icon: $r('app.media.ic_history'),
        description: '检测记录查看',
        onTap: () => { this.navStack.pushPathByName('DecibelHistory', null) }
      })
    }
  }
}

@Builder
private buildFunctionCard(config: FunctionCardConfig) {
  Column({ space: DesignConstants.SPACING_SM }) {
    Image(config.icon)
      .width(32)
      .height(32)
      .fillColor($r('sys.color.icon_primary'))
    
    Text(config.title)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
    
    Text(config.description)
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
  }
  .width('100%')
  .padding(DesignConstants.SPACING_MD)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .onClick(config.onTap)
}
```

## 接口定义

```typescript
// 功能卡片配置接口
interface FunctionCardConfig {
  title: string;
  icon: Resource;
  description: string;
  onTap: () => void;
}

// 分贝等级描述接口
interface DecibelLevelInfo {
  level: string;
  color: Resource;
  description: string;
}
```

## 计算属性

```typescript
@Computed
get currentTime(): string {
  return new Date().toLocaleTimeString('zh-CN', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}

@Computed
get currentDate(): string {
  return new Date().toLocaleDateString('zh-CN', {
    month: 'long',
    day: 'numeric'
  });
}

@Computed
get environmentQuality(): string {
  const db = this.ak.uiDisplayState.displayDb;
  if (db < 40) return '优秀';
  if (db < 60) return '良好';
  if (db < 80) return '一般';
  return '较差';
}

@Computed
get membershipStatus(): string {
  return this.pk.member_ship.can ? '专业版' : '基础版';
}

@Computed
get decibelColor(): Resource {
  const db = this.ak.uiDisplayState.displayDb;
  if (db < 40) return $r('sys.color.confirm');
  if (db < 60) return $r('sys.color.primary');
  if (db < 80) return $r('sys.color.warning');
  return $r('sys.color.alert');
}

@Computed
get decibelDescription(): string {
  const db = this.ak.uiDisplayState.displayDb;
  if (db < 40) return '非常安静';
  if (db < 60) return '环境舒适';
  if (db < 80) return '有些嘈杂';
  return '噪音较大';
}
```

## 导航集成

需要在 `NoiseMeterNavigation.ets` 中：
1. 添加主页作为第一个Tab (index 0)
2. 调整现有Tab索引
3. 更新菜单项逻辑

## 文件创建清单

需要创建的文件：
- `entry/src/main/ets/components/home/HomePageContent.ets`
- `entry/src/main/ets/components/home/index.ets` (导出文件)

需要修改的文件：
- `entry/src/main/ets/pages/noisemeter/NoiseMeterNavigation.ets`
- `entry/src/main/ets/constants/ProviderConstant.ets` (如果需要)

## 下一步行动

建议切换到Code模式进行实际代码实现。