import { ResponsiveLayout, LayoutMode } from '../../utils/ResponsiveLayout';

// 状态级别枚举
enum StatusLevel {
  GOOD = 'good',
  WARNING = 'warning',
  DANGER = 'danger'
}

// 状态阈值配置接口
export interface StatusThresholds {
  warning: number;      // 警告阈值
  danger: number;       // 危险阈值
}

// 卡片配置接口
export interface CardConfig {
  type: string;         // 卡片类型
  title: string;          // 标题
  subtitle?: string;      // 副标题（可选）
  value: number;          // 当前值
  maxValue?: number;      // 最大值（可选，用于计算百分比）
  unit?: string;          // 单位（可选）
  icon?: Resource;        // 图标资源（可选）
  progressType?: string;  // 进度条类型
  color?: ResourceColor;  // 自定义颜色（可选）
  statusThresholds?: StatusThresholds; // 状态阈值配置（可选）
}

// 响应式尺寸配置接口
interface ResponsiveSizes {
  cardHeight: number;     // 卡片高度
  iconSize: number;       // 图标尺寸
  valueFontSize: number;  // 数值字体大小
  titleFontSize: number;  // 标题字体大小
  subtitleFontSize: number; // 副标题字体大小
  ringSize: number;       // 环形进度条尺寸
  strokeWidth: number;    // 进度条宽度
}

// 布局因子接口
interface LayoutFactors {
  xsmall: number;
  small: number;
  medium: number;
  large: number;
  xlarge: number;
}

@ComponentV2
export struct DeviceCard {
  // 必需参数
  @Param @Require config!: CardConfig;
  
  // 响应式布局实例
  private responsiveLayout: ResponsiveLayout = ResponsiveLayout.getInstance();
  
  // 本地状态
  @Local layoutMode: LayoutMode = LayoutMode.LARGE;
  
  // 响应式尺寸配置
  private sizes!: ResponsiveSizes;
  
  // 进度百分比
  private percent!: number;
  
  // 状态颜色
  private statusColor!: ResourceColor;
  
  // 响应式间距
  private spacing!: number;
  
  aboutToAppear() {
    // 初始化响应式布局
    const screenInfo = this.responsiveLayout.getCurrentScreenInfo();
    this.layoutMode = screenInfo.layoutMode;
    
    // 初始化变量
    this.sizes = this.getResponsiveSizes();
    this.percent = this.calculateProgressPercent();
    this.statusColor = this.getStatusColor();
    this.spacing = this.getResponsiveSpacing();
    
    // 注册布局变化监听器
    this.responsiveLayout.addChangeListener(this.layoutChangeCallback);
  }
  
  aboutToDisappear() {
    // 移除布局变化监听器
    this.responsiveLayout.removeChangeListener(this.layoutChangeCallback);
  }
  
  // 布局变化回调
  private layoutChangeCallback(width: number, height: number, breakpoint: string, layoutMode: LayoutMode): void {
    this.layoutMode = layoutMode;
    
    // 布局变化时重新计算响应式变量
    this.sizes = this.getResponsiveSizes();
    this.percent = this.calculateProgressPercent();
    this.statusColor = this.getStatusColor();
    this.spacing = this.getResponsiveSpacing();
  }
  
  // 获取响应式尺寸配置
  private getResponsiveSizes(): ResponsiveSizes {
    const baseSizes: ResponsiveSizes = {
      cardHeight: 180,
      iconSize: 32,
      valueFontSize: 24,
      titleFontSize: 16,
      subtitleFontSize: 14,
      ringSize: 80,
      strokeWidth: 8
    } as ResponsiveSizes;
    
    const factors: LayoutFactors = {
      xsmall: 0.8,
      small: 0.9,
      medium: 1.0,
      large: 1.0,
      xlarge: 1.1
    } as LayoutFactors;
    
    let factor = 1.0;
    switch (this.layoutMode) {
      case LayoutMode.XSMALL: factor = factors.xsmall; break;
      case LayoutMode.SMALL: factor = factors.small; break;
      case LayoutMode.MEDIUM: factor = factors.medium; break;
      case LayoutMode.LARGE: factor = factors.large; break;
      case LayoutMode.XLARGE: factor = factors.xlarge; break;
    }
    
    return {
      cardHeight: Math.round(baseSizes.cardHeight * factor),
      iconSize: Math.round(baseSizes.iconSize * factor),
      valueFontSize: Math.round(baseSizes.valueFontSize * factor),
      titleFontSize: Math.round(baseSizes.titleFontSize * factor),
      subtitleFontSize: Math.round(baseSizes.subtitleFontSize * factor),
      ringSize: Math.round(baseSizes.ringSize * factor),
      strokeWidth: Math.round(baseSizes.strokeWidth * factor)
    };
  }
  
  // 获取响应式间距
  private getResponsiveSpacing(baseSize: number = 12): number {
    return this.responsiveLayout.getSpacing(baseSize);
  }
  
  // 计算进度百分比
  private calculateProgressPercent(): number {
    if (this.config.maxValue && this.config.maxValue > 0) {
      return Math.min(100, Math.max(0, (this.config.value / this.config.maxValue) * 100));
    }
    return this.config.value; // 如果没提供maxValue，直接使用value作为百分比
  }
  
  // 获取状态级别
  private getStatusLevel(): StatusLevel {
    const percent = this.calculateProgressPercent();
    
    if (this.config.statusThresholds) {
      if (percent >= this.config.statusThresholds.danger) {
        return StatusLevel.DANGER;
      } else if (percent >= this.config.statusThresholds.warning) {
        return StatusLevel.WARNING;
      }
      return StatusLevel.GOOD;
    }
    
    // 默认阈值
    if (percent >= 90) {
      return StatusLevel.DANGER;
    } else if (percent >= 70) {
      return StatusLevel.WARNING;
    }
    return StatusLevel.GOOD;
  }
  
  // 获取状态颜色
  private getStatusColor(): ResourceColor {
    const statusLevel = this.getStatusLevel();
    
    if (this.config.color) {
      return this.config.color;
    }
    
    switch (statusLevel) {
      case StatusLevel.DANGER:
        return $r('app.color.health_bad');
      case StatusLevel.WARNING:
        return $r('app.color.health_warning');
      case StatusLevel.GOOD:
        return $r('app.color.health_good');
      default:
        return $r('app.color.primary');
    }
  }
  
  // 构建环形进度条
  @Builder
  private buildRingProgress(percent: number, ringSize: number, strokeWidth: number, statusColor: ResourceColor) {
    Stack() {
      // 背景环形
      Progress({ value: 100, type: ProgressType.Ring })
        .width(ringSize)
        .height(ringSize)
        .style({ strokeWidth })
        .backgroundColor($r('app.color.background_tertiary'))
        .color($r('app.color.background_tertiary'))
      
      // 进度环形
      Progress({ value: percent, type: ProgressType.Ring })
        .width(ringSize)
        .height(ringSize)
        .style({ strokeWidth })
        .backgroundColor(Color.Transparent)
        .color(statusColor)
    }
  }
  
  // 构建线性进度条
  @Builder
  private buildLinearProgress(percent: number, strokeWidth: number, statusColor: ResourceColor, spacing: number) {
    Stack() {
      // 背景进度条
      Progress({ value: 100, type: ProgressType.Linear })
        .width('100%')
        .height(strokeWidth)
        .style({ strokeWidth })
        .backgroundColor($r('app.color.background_tertiary'))
        .color($r('app.color.background_tertiary'))
      
      // 实际进度条
      Progress({ value: percent, type: ProgressType.Linear })
        .width('100%')
        .height(strokeWidth)
        .style({ strokeWidth })
        .backgroundColor(Color.Transparent)
        .color(statusColor)
    }
    .borderRadius(spacing)
    .width('100%')
  }
  
  // 构建数值显示
  @Builder
  private buildValueDisplay(value: number, unit: string, valueFontSize: number, statusColor: ResourceColor, bottomMargin: number) {
    Text(`${value}${unit}`)
      .fontSize(valueFontSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(statusColor)
      .margin({ bottom: bottomMargin })
  }
  
  // 构建标题显示
  @Builder
  private buildTitleDisplay(title: string, titleFontSize: number, bottomMargin: number) {
    Text(title)
      .fontSize(titleFontSize)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .margin({ bottom: bottomMargin })
  }
  
  // 构建副标题显示
  @Builder
  private buildSubtitleDisplay(subtitle: string, subtitleFontSize: number, bottomMargin: number) {
    if (subtitle) {
      Text(subtitle)
        .fontSize(subtitleFontSize)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: bottomMargin })
    }
  }
  
  // 构建图标显示
  @Builder
  private buildIconDisplay(icon: Resource | undefined, iconSize: number, bottomMargin: number) {
    if (icon) {
      Image(icon)
        .width(iconSize)
        .height(iconSize)
        .margin({ bottom: bottomMargin })
    }
  }
  
  // 构建评分卡片布局
  @Builder
  private buildRatingCard(percent: number, sizes: ResponsiveSizes, statusColor: ResourceColor, spacing: number) {
    Stack({ alignContent: Alignment.Center }) {
      this.buildRingProgress(percent, sizes.ringSize, sizes.strokeWidth, statusColor)
      Column() {
        this.buildValueDisplay(this.config.value, this.config.unit || '', sizes.valueFontSize, statusColor, spacing * 6)
        this.buildTitleDisplay(this.config.title, sizes.titleFontSize, spacing * 4)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .padding(spacing * 16)
  }
  
  // 构建通用卡片布局（带线性进度条）
  @Builder
  private buildGeneralCard(percent: number, sizes: ResponsiveSizes, statusColor: ResourceColor, spacing: number) {
    Column() {
      this.buildIconDisplay(this.config.icon, sizes.iconSize, spacing * 12)
      this.buildValueDisplay(this.config.value, this.config.unit || '', sizes.valueFontSize, statusColor, spacing * 6)
      this.buildTitleDisplay(this.config.title, sizes.titleFontSize, spacing * 4)
      this.buildSubtitleDisplay(this.config.subtitle || '', sizes.subtitleFontSize, spacing * 12)
      this.buildLinearProgress(percent, sizes.strokeWidth, statusColor, spacing * 4)
    }
    .padding({
      top: spacing * 20,
      bottom: spacing * 20,
      left: spacing * 16,
      right: spacing * 16
    })
  }
  
  build() {
    // 使用Stack作为根容器来确保只有一个根节点
    Stack() {
      Column() {
        if (this.config.type === 'rating') {
          this.buildRatingCard(this.percent, this.sizes, this.statusColor, this.spacing)
        } else {
          this.buildGeneralCard(this.percent, this.sizes, this.statusColor, this.spacing)
        }
      }
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(this.spacing * 16)
      .shadow({
        radius: this.spacing * 6,
        color: Color.Black,
        offsetX: 0,
        offsetY: this.spacing * 3
      })
      .width('100%')
      .height(this.sizes.cardHeight)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(this.sizes.cardHeight)
  }
}