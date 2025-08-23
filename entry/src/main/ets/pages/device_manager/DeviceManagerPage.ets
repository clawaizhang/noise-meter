import router from '@ohos.router';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { SystemMemInfo } from '../../types/DeviceInfo';
import { formatMemory } from '../../utils/MemoryUtils';
import { DeviceHealthInfo } from '../../types/DeviceHealthInfo';
import { DeviceHealthService } from '../../services/DeviceHealthService';
import { HealthStatusCard } from '../../components/HealthStatusCard';
import { FunctionLinksPanel } from '../../components/FunctionLinksPanel';
import { netQuality } from '@kit.NetworkBoostKit';
import { ResponsiveLayout, Breakpoint, LayoutMode, responsiveSpacing } from '../../utils/ResponsiveLayout';
import { DeviceCard, StatusThresholds } from '../../components/device_manager/DeviceCard';

@Extend(Text)
function titleTextStyle() {
  .fontSize(20)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function cardTitleStyle() {
  .fontSize(16)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function cardValueStyle() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function gridItemTextStyle() {
  .fontSize(14)
  .fontColor($r('app.color.text_secondary'))
  .margin({ top: 8 })
}

// 评分等级枚举
enum RatingLevel {
  EXCELLENT,  // 优秀: 90-100
  GOOD,       // 良好: 70-89
  FAIR,       // 一般: 60-69
  POOR        // 差: 0-59
}

// 评分等级信息接口
interface RatingLevelInfo {
  level: RatingLevel;
  label: string;
  color: ResourceColor;
  minScore: number;
  maxScore: number;
}

// 存储信息类型
interface StorageInfo {
  usedGB: number;
  totalGB: number;
  usagePercent: number;
  availableGB: number;
}

// 温度信息类型
interface TemperatureInfo {
  temperature: number;
  tempPercent: number;
}

// 高度因子类型
interface HeightFactors {
  xsmall: number;
  small: number;
  medium: number;
  large: number;
  xlarge: number;
}

@ComponentV2
export struct DeviceManagerPage {
  @Local memoryInfo: SystemMemInfo | null = null;
  @Local rotateAngle: number = 0;
  @Local usagePercent: number = 0;
  @Local progressColor: Resource = $r('app.color.success');
  @Local layoutMode: LayoutMode = LayoutMode.LARGE;
  @Local screenWidth: number = 0;
  @Local storageInfo: StorageInfo = { usedGB: 0, totalGB: 0, usagePercent: 0, availableGB: 0 };
  @Local temperatureInfo: TemperatureInfo = { temperature: 0, tempPercent: 0 };
  
  // RatingPanel 相关的本地变量
  @Local cachedLayoutMode: LayoutMode = LayoutMode.LARGE;
  @Local cachedScreenWidth: number = 0;
  @Local lastLayoutUpdateTime: number = 0;
  @Local cachedRingSize: number | undefined = undefined;
  @Local cachedStrokeWidth: number | undefined = undefined;
  @Local cachedScoreFontSize: number | undefined = undefined;
  @Local cachedLabelFontSize: number | undefined = undefined;
  
  private deviceHealthService: DeviceHealthService = DeviceHealthService.getInstance();
  private responsiveLayout: ResponsiveLayout = ResponsiveLayout.getInstance();

  aboutToAppear() {
    this.getSystemMemoryInfo();
    setInterval(() => {
      this.getSystemMemoryInfo();
    }, 5000);

    // 动画效果
    animateTo({ duration: 1000 }, () => {
      this.rotateAngle = 360;
    });

    // 初始化响应式布局
    this.updateLayoutMode();
    // 注册布局变化监听器
    this.responsiveLayout.addChangeListener(this.layoutChangeCallback);
  }

  aboutToDisappear(): void {
    netQuality.off('netQosChange');
    // 移除布局变化监听器
    this.responsiveLayout.removeChangeListener(this.layoutChangeCallback);
  }

  // 获取系统内存信息
  private async getSystemMemoryInfo() {
    const rawData = hidebug.getSystemMemInfo();
    this.memoryInfo = {
      totalMem: rawData.totalMem,
      freeMem: rawData.freeMem,
      availableMem: rawData.availableMem
    };

    // 计算初始值
    if (this.memoryInfo) {
      const usedMem = Number(this.memoryInfo.totalMem - this.memoryInfo.freeMem);
      const totalMem = Number(this.memoryInfo.totalMem);
      this.deviceHealthService
        .getHealthInfo()
        .performance
        .memory
        .availableMem = this.memoryInfo.availableMem;
      this.deviceHealthService
        .getHealthInfo()
        .performance
        .memory
        .totalMem = this.memoryInfo.totalMem;
      // 简化百分比计算，直接取整避免不必要的小数处理
      this.usagePercent = Math.round(usedMem / totalMem * 100);
      this.progressColor = this.usagePercent > 80 ? $r('app.color.health_bad') :
        this.usagePercent > 60 ? $r('app.color.health_warning') : $r('app.color.success');
    }

    // 更新存储和温度信息
    this.storageInfo = this.getStorageInfo();
    this.temperatureInfo = this.getTemperatureInfo();
  }

  // 布局变化回调
  private layoutChangeCallback = (width: number, height: number, breakpoint: Breakpoint, layoutMode: LayoutMode) => {
    this.layoutMode = layoutMode;
    this.screenWidth = width;
  }

  // 更新布局模式
  private updateLayoutMode() {
    const screenInfo = this.responsiveLayout.getCurrentScreenInfo();
    this.layoutMode = screenInfo.layoutMode;
    this.screenWidth = screenInfo.width;
  }

  // 获取响应式间距
  private getResponsiveSpacing(baseSize: number = 12): number {
    return this.responsiveLayout.getSpacing(baseSize);
  }

  // 获取响应式字体大小
  private getResponsiveFontSize(baseSize: number = 16): number {
    return this.responsiveLayout.getFontSize(baseSize);
  }

  // 获取响应式图标尺寸
  private getResponsiveIconSize(baseSize: number = 32): number {
    return this.responsiveLayout.getIconSize(baseSize);
  }

  // 获取响应式卡片高度
  private getResponsiveCardHeight(baseHeight: number = 180): number {
    const heightFactors: HeightFactors = {
      xsmall: 0.9,
      small: 0.95,
      medium: 1.0,
      large: 1.05,
      xlarge: 1.1
    };

    let factor = 1.0;
    switch (this.layoutMode) {
      case LayoutMode.XSMALL:
        factor = heightFactors.xsmall;
        break;
      case LayoutMode.SMALL:
        factor = heightFactors.small;
        break;
      case LayoutMode.MEDIUM:
        factor = heightFactors.medium;
        break;
      case LayoutMode.LARGE:
        factor = heightFactors.large;
        break;
      case LayoutMode.XLARGE:
        factor = heightFactors.xlarge;
        break;
    }

    return Math.round(baseHeight * factor);
  }

  // 获取响应式进度条高度
  private getResponsiveProgressHeight(baseHeight: number = 8): number {
    const heightFactors: HeightFactors = {
      xsmall: 0.8,
      small: 0.9,
      medium: 1.0,
      large: 1.1,
      xlarge: 1.2
    };

    let factor = 1.0;
    switch (this.layoutMode) {
      case LayoutMode.XSMALL:
        factor = heightFactors.xsmall;
        break;
      case LayoutMode.SMALL:
        factor = heightFactors.small;
        break;
      case LayoutMode.MEDIUM:
        factor = heightFactors.medium;
        break;
      case LayoutMode.LARGE:
        factor = heightFactors.large;
        break;
      case LayoutMode.XLARGE:
        factor = heightFactors.xlarge;
        break;
    }

    return Math.max(4, Math.round(baseHeight * factor));
  }

  // 判断是否为小屏幕设备
  private get isSmallScreen(): boolean {
    return this.layoutMode === LayoutMode.XSMALL || this.layoutMode === LayoutMode.SMALL;
  }

  // 判断是否为中等屏幕设备
  private get isMediumScreen(): boolean {
    return this.layoutMode === LayoutMode.MEDIUM;
  }

  // 判断是否为大屏幕设备
  private get isLargeScreen(): boolean {
    return this.layoutMode === LayoutMode.LARGE || this.layoutMode === LayoutMode.XLARGE;
  }

  // 计算设备综合评分
  private calculateDeviceScore(): number {
    const healthInfo = this.deviceHealthService.getHealthInfo();

    // 如果健康信息无效，返回默认评分
    if (!healthInfo || healthInfo.score === 0) {
      return 85; // 默认良好评分
    }

    // 基于健康状态数据的评分计算逻辑
    let score = healthInfo.score;

    // 根据内存使用率调整评分
    if (this.usagePercent > 90) {
      score -= 15; // 内存使用率过高，扣分
    } else if (this.usagePercent > 80) {
      score -= 10; // 内存使用率较高，扣分
    } else if (this.usagePercent > 70) {
      score -= 5; // 内存使用率中等，轻微扣分
    }

    // 确保评分在0-100范围内
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  // 获取存储信息
  private getStorageInfo(): StorageInfo {
    const storageInfo = this.deviceHealthService.getHealthInfo().performance.storage;
    const usedGB = Math.round(storageInfo.used / 1024 / 1024); // KB to GB
    const totalGB = Math.round(storageInfo.total / 1024 / 1024); // KB to GB
    const usagePercent = Math.round((usedGB / totalGB) * 100);
    const availableGB = totalGB - usedGB;

    return {
      usedGB,
      totalGB,
      usagePercent,
      availableGB
    };
  }

  // 获取评分等级信息
  private getRatingLevelInfo(score: number): RatingLevelInfo {
    if (score >= 90) {
      return {
        level: RatingLevel.EXCELLENT,
        label: '优秀',
        color: $r('app.color.health_good'),
        minScore: 90,
        maxScore: 100
      };
    } else if (score >= 70) {
      return {
        level: RatingLevel.GOOD,
        label: '良好',
        color: $r('app.color.primary'),
        minScore: 70,
        maxScore: 89
      };
    } else if (score >= 60) {
      return {
        level: RatingLevel.FAIR,
        label: '一般',
        color: $r('app.color.health_warning'),
        minScore: 60,
        maxScore: 69
      };
    } else {
      return {
        level: RatingLevel.POOR,
        label: '差',
        color: $r('app.color.health_bad'),
        minScore: 0,
        maxScore: 59
      };
    }
  }

  // 根据布局模式获取环形大小（使用缓存机制）
  private getRingSize(): number {
    // 缓存计算结果，避免重复switch判断
    if (!this.cachedRingSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedRingSize = 80; break;
        case LayoutMode.MEDIUM: this.cachedRingSize = 70; break;
        case LayoutMode.SMALL: this.cachedRingSize = 60; break;
        case LayoutMode.XSMALL: this.cachedRingSize = 50; break;
        default: this.cachedRingSize = 80;
      }
    }
    return this.cachedRingSize;
  }

  // 根据布局模式获取环形宽度（使用缓存机制）
  private getStrokeWidth(): number {
    if (!this.cachedStrokeWidth) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedStrokeWidth = 8; break;
        case LayoutMode.MEDIUM: this.cachedStrokeWidth = 7; break;
        case LayoutMode.SMALL: this.cachedStrokeWidth = 6; break;
        case LayoutMode.XSMALL: this.cachedStrokeWidth = 5; break;
        default: this.cachedStrokeWidth = 8;
      }
    }
    return this.cachedStrokeWidth;
  }

  // 根据布局模式获取分数字体大小（使用缓存机制）
  private getScoreFontSize(): number {
    if (!this.cachedScoreFontSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedScoreFontSize = 32; break;
        case LayoutMode.MEDIUM: this.cachedScoreFontSize = 28; break;
        case LayoutMode.SMALL: this.cachedScoreFontSize = 24; break;
        case LayoutMode.XSMALL: this.cachedScoreFontSize = 20; break;
        default: this.cachedScoreFontSize = 32;
      }
    }
    return this.cachedScoreFontSize;
  }

  // 根据布局模式获取标签字体大小（使用缓存机制）
  private getLabelFontSize(): number {
    if (!this.cachedLabelFontSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedLabelFontSize = 16; break;
        case LayoutMode.MEDIUM: this.cachedLabelFontSize = 14; break;
        case LayoutMode.SMALL: this.cachedLabelFontSize = 14; break;
        case LayoutMode.XSMALL: this.cachedLabelFontSize = 12; break;
        default: this.cachedLabelFontSize = 16;
      }
    }
    return this.cachedLabelFontSize;
  }

  // 当布局模式改变时清除缓存
  private clearCache() {
    this.cachedRingSize = undefined;
    this.cachedStrokeWidth = undefined;
    this.cachedScoreFontSize = undefined;
    this.cachedLabelFontSize = undefined;
  }

  // 构建存储卡片（使用通用组件）
  @Builder
  buildStorageCard() {
    DeviceCard({
      config: {
        type: 'storage',
        title: '可用存储',
        value: this.storageInfo.availableGB,
        maxValue: this.storageInfo.totalGB,
        unit: 'GB',
        icon: $r('app.media.ic_storage'),
        progressType: 'Linear',
        statusThresholds: {
          warning: 70,
          danger: 90
        } as StatusThresholds
      }
    })
  }

  // 获取温度信息
  private getTemperatureInfo(): TemperatureInfo {
    const temperature = this.deviceHealthService.getHealthInfo().battery.temperature;
    const tempPercent = Math.min(100, Math.max(0, (temperature / 50) * 100));

    return { temperature, tempPercent };
  }

  // 构建温度卡片（使用通用组件）
  @Builder
  buildTemperatureCard() {
    DeviceCard({
      config: {
        type: 'temperature',
        title: '手机温度',
        value: this.temperatureInfo.temperature,
        maxValue: 50, // 温度范围0-50°C
        unit: '°C',
        icon: $r('app.media.ic_sensor'),
        progressType: 'Linear',
        statusThresholds: {
          warning: 35,
          danger: 45
        } as StatusThresholds
      }
    })
  }

  // 获取存储使用率颜色
  private getStorageColor(usagePercent: number): ResourceColor {
    if (usagePercent > 90) {
      return $r('app.color.health_bad');
    } else if (usagePercent > 70) {
      return $r('app.color.health_warning');
    } else {
      return $r('app.color.health_good');
    }
  }

  // 获取温度颜色
  private getTemperatureColor(temperature: number): ResourceColor {
    if (temperature > 45) {
      return $r('app.color.health_bad'); // 过高温度：红色
    } else if (temperature > 35) {
      return $r('app.color.health_warning'); // 警告温度：橙色
    } else {
      return $r('app.color.health_good'); // 正常温度：绿色
    }
  }

  @Builder
  GridItemBuilder(icon: Resource, label: string, targetPage: string) {
    Column() {
      Image(icon)
        .width(32)
        .height(32)
      Text(label)
        .gridItemTextStyle()
    }
    .onClick(() => {
      router.pushUrl({
        url: targetPage
      }, router.RouterMode.Standard, (err) => {
        if (err) {
          console.error(`Failed to navigate to ${targetPage}: ${JSON.stringify(err)}`);
        }
      });
    })
  }


  // 构建评分卡片（使用通用组件）
  @Builder
  buildRatingCard(score: number) {
    DeviceCard({
      config: {
        type: 'rating',
        title: this.getRatingLevelInfo(score).label,
        value: score,
        maxValue: 100,
        progressType: 'Ring'
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('设备健康状态')
          .titleTextStyle()
          .margin({
            top: this.getResponsiveSpacing(16),
            bottom: this.getResponsiveSpacing(24)
          })
          .width('100%')
          .textAlign(TextAlign.Center)

        // 根据屏幕尺寸选择布局方式
        if (this.isSmallScreen) {
          // 小屏幕设备：垂直排列
          this.buildVerticalLayout()
        } else if (this.isMediumScreen) {
          // 中等屏幕设备：2x2网格布局
          this.buildGridLayout()
        } else {
          // 大屏幕设备：水平三栏布局
          this.buildHorizontalLayout()
        }

        // 功能链接面板
        Column() {
          FunctionLinksPanel()
            .width('100%')
        }
        .margin({ bottom: this.getResponsiveSpacing(24) })

      }
      .width('100%')
      .padding({
        top: this.getResponsiveSpacing(8),
        bottom: this.getResponsiveSpacing(16),
        left: this.getResponsiveSpacing(16),
        right: this.getResponsiveSpacing(16)
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.On)
    .scrollBarWidth(4)
  }

  // 构建水平三栏布局（大屏幕）
  @Builder
  buildHorizontalLayout() {
    Flex({
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Stretch,
      wrap: FlexWrap.NoWrap
    }) {
      // 左侧：设备评分面板
      Column() {
        this.buildRatingCard(this.calculateDeviceScore())
      }
      .layoutWeight(1)
      .margin({ right: this.getResponsiveSpacing(16) })

      // 中间：可用存储面板
      Column() {
        this.buildStorageCard()
      }
      .layoutWeight(1)
      .margin({ right: this.getResponsiveSpacing(16), left: this.getResponsiveSpacing(16) })

      // 右侧：手机温度面板
      Column() {
        this.buildTemperatureCard()
      }
      .layoutWeight(1)
      .margin({ left: this.getResponsiveSpacing(16) })
    }
    .width('100%')
    .margin({ bottom: this.getResponsiveSpacing(24) })
  }

  // 构建网格布局（中等屏幕）
  @Builder
  buildGridLayout() {
    Grid() {
      // 第一行：设备评分和可用存储
      GridItem() {
        Column() {
          this.buildRatingCard(this.calculateDeviceScore())
        }
        .width('100%')
        .height('100%')
      }
      .columnStart(0)
      .columnEnd(1)
      .rowStart(0)
      .rowEnd(0)

      GridItem() {
        Column() {
          this.buildStorageCard()
        }
        .width('100%')
        .height('100%')
      }
      .columnStart(1)
      .columnEnd(2)
      .rowStart(0)
      .rowEnd(0)

      // 第二行：手机温度（跨两列）
      GridItem() {
        Column() {
          this.buildTemperatureCard()
        }
        .width('100%')
        .height('100%')
      }
      .columnStart(0)
      .columnEnd(2)
      .rowStart(1)
      .rowEnd(1)
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(this.getResponsiveSpacing(16))
    .rowsGap(this.getResponsiveSpacing(16))
    .width('100%')
    .margin({ bottom: this.getResponsiveSpacing(24) })
  }

  // 构建垂直布局（小屏幕）
  @Builder
  buildVerticalLayout() {
    Column() {
      // 设备评分面板
      Column() {
        this.buildRatingCard(this.calculateDeviceScore())
      }
      .width('100%')
      .margin({ bottom: this.getResponsiveSpacing(16) })

      // 可用存储面板
      Column() {
        this.buildStorageCard()
      }
      .width('100%')
      .margin({ bottom: this.getResponsiveSpacing(16) })

      // 手机温度面板
      Column() {
        this.buildTemperatureCard()
      }
      .width('100%')
      .margin({ bottom: this.getResponsiveSpacing(24) })
    }
    .width('100%')
  }
}