import { DeviceHealthInfo, ScoreHealth } from "../types/DeviceHealthInfo"
import { LengthUnit } from "@kit.ArkUI"
import { DeviceHealthService } from "../services/DeviceHealthService"
import { MetricItem } from "./common/MetricItem"
import { DetailModal } from "./common/DetailModal"
import { DesignConstants } from "../constants/DesignConstants"
import { MemoryUtils, calculateMemoryUsage, calculateStorageUsage } from "../utils/MemoryUtils"
import window from '@ohos.window';
import display from '@ohos.display';

// 健康卡片状态枚举
enum HealthCardState {
  LOADING,    // 加载中
  SUCCESS,    // 加载成功
  ERROR,      // 错误状态
  EMPTY       // 空状态
}

@ComponentV2
export struct HealthStatusCard {
  @Param @Require memoryUsagePercentage: number
  @Local healthInfo: DeviceHealthInfo = DeviceHealthService.getInstance().getHealthInfo();
  @Local screenWidth: number = 0;
  @Local layoutMode: string = 'large'; // large, medium, small, xsmall
  @Local showDetailModal: boolean = false
  @Local selectedMetricType: string = ''
  @Local currentState: HealthCardState = HealthCardState.LOADING
  @Local errorMessage: string = ''
  @Local isLoading: boolean = true
  
  // 缓存计算结果
  @Local cachedMemoryUsage: number = -1
  @Local cachedStorageUsage: number = -1
  @Local cachedAvailableMemory: string = ''
  @Local cachedFreeStorage: string = ''
  @Local lastHealthInfoHash: string = ''
  
  // 性能监控
  @Local calculationTimes: Record<string, number> = {}

  aboutToAppear() {
    this.updateScreenWidth();
    // 监听屏幕旋转和尺寸变化
    display.on('change', () => {
      this.updateScreenWidth();
    });
    
    // 初始化加载数据
    this.loadHealthData();
  }


  @Builder
  buildResponsiveLayout() {
    if (this.layoutMode === 'xsmall') {
      this.buildXSmallLayout();
    } else if (this.layoutMode === 'small') {
      this.buildSmallLayout();
    } else if (this.layoutMode === 'medium') {
      this.buildMediumLayout();
    } else {
      this.buildLargeLayout();
    }
  }

  @Builder
  buildLargeLayout() {
    // 大屏布局：单行显示所有6个指标
    Flex({
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center,
      wrap: FlexWrap.NoWrap
    }) {
      this.buildAllMetrics()
    }
    .width('100%')
    .margin(DesignConstants.HEALTH_CARD.MARGIN_LARGE)
    .padding(DesignConstants.HEALTH_CARD.PADDING)
  }

  @Builder
  buildMediumLayout() {
    // 中屏布局：两行显示，每行3个指标
    Column() {
      // 第一行：3个指标
      Flex({
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(0) // 电量
        this.buildMetricItem(1) // 内存
        this.buildMetricItem(2) // 存储
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 第二行：3个指标
      Flex({
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(3) // CPU
        this.buildMetricItem(4) // 网络
        this.buildMetricItem(5) // 传感器
      }
      .width('100%')
    }
    .width('100%')
    .margin(DesignConstants.HEALTH_CARD.MARGIN_MEDIUM)
    .padding(DesignConstants.HEALTH_CARD.PADDING)
  }

  @Builder
  buildSmallLayout() {
    // 小屏布局：三行显示，每行2个指标
    Column() {
      // 第一行：2个指标
      Flex({
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(0) // 电量
        this.buildMetricItem(1) // 内存
      }
      .width('100%')
      .margin({ bottom: 10 })

      // 第二行：2个指标
      Flex({
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(2) // 存储
        this.buildMetricItem(3) // CPU
      }
      .width('100%')
      .margin({ bottom: 10 })

      // 第三行：2个指标
      Flex({
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(4) // 网络
        this.buildMetricItem(5) // 传感器
      }
      .width('100%')
    }
    .width('100%')
    .margin(DesignConstants.HEALTH_CARD.MARGIN_SMALL)
    .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
  }

  @Builder
  buildXSmallLayout() {
    // 超小屏布局：六行显示，每行1个指标
    Column() {
      ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
        Flex({
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center,
          wrap: FlexWrap.NoWrap
        }) {
          this.buildMetricItem(index)
        }
        .width('100%')
        .margin({ bottom: index < 5 ? 6 : 0 })
        .padding({ top: 4, bottom: 4 })
      })
    }
    .width('100%')
    .margin(DesignConstants.HEALTH_CARD.MARGIN_XSMALL)
    .padding({ top: DesignConstants.SPACING_XS, bottom: DesignConstants.SPACING_XS })
  }

  @Builder
  HealthMetricItem($$: ScoreHealth) {
    Column() {
      Image($$.icon)
        .width(DesignConstants.ICON_SIZE_MD)
        .height(DesignConstants.ICON_SIZE_MD)
        .margin({ right: DesignConstants.SPACING_SM })
      Column() {
        Text($$.label)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.text_secondary'))
        Text($$.value)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getMetricColor($$.score))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding(DesignConstants.METRIC_ITEM.PADDING)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.METRIC_ITEM.BORDER_RADIUS)
    .width(DesignConstants.METRIC_ITEM.WIDTH)
    .height(DesignConstants.METRIC_ITEM.HEIGHT)
  }

  private getScoreColor(): ResourceColor {
    if (this.healthInfo.score >= 80) {
      return $r('app.color.health_good');
    }
    if (this.healthInfo.score >= 60) {
      return $r('app.color.health_warning');
    }
    return $r('app.color.health_bad');
  }

  private getMetricColor(score: number): ResourceColor {
    if (score >= 80) {
      return $r('app.color.health_good');
    }
    if (score >= 60) {
      return $r('app.color.health_warning');
    }
    return $r('app.color.health_bad');
  }

  private getMemoryUsage(): number {
    // 检查缓存是否有效
    const currentHash = this.getHealthInfoHash();
    if (this.cachedMemoryUsage >= 0 && currentHash === this.lastHealthInfoHash) {
      return this.cachedMemoryUsage;
    }
    
    const startTime = Date.now();
    
    const total = this.healthInfo.performance.memory.totalMem;
    const available = this.healthInfo.performance.memory.availableMem;
    
    // 使用优化的工具函数计算内存使用率
    this.cachedMemoryUsage = calculateMemoryUsage(total, total - available);
    
    // 记录计算耗时
    this.recordCalculationTime('memoryUsage', Date.now() - startTime);
    
    return this.cachedMemoryUsage;
  }

  private getStorageUsage(): number {
    // 检查缓存是否有效
    const currentHash = this.getHealthInfoHash();
    if (this.cachedStorageUsage >= 0 && currentHash === this.lastHealthInfoHash) {
      return this.cachedStorageUsage;
    }
    
    const startTime = Date.now();
    
    const total = this.healthInfo.performance.storage.total;
    const used = this.healthInfo.performance.storage.used;
    
    // 使用优化的工具函数计算存储使用率
    this.cachedStorageUsage = calculateStorageUsage(total, used);
    
    // 记录计算耗时
    this.recordCalculationTime('storageUsage', Date.now() - startTime);
    
    return this.cachedStorageUsage;
  }

  // 获取可用内存格式化字符串（带缓存）
  private getAvailableMemoryFormatted(): string {
    const currentHash = this.getHealthInfoHash();
    if (this.cachedAvailableMemory && currentHash === this.lastHealthInfoHash) {
      return this.cachedAvailableMemory;
    }
    
    const startTime = Date.now();
    const availableMemKB = this.healthInfo.performance.memory.availableMem;
    this.cachedAvailableMemory = MemoryUtils.formatMemory(availableMemKB);
    
    this.recordCalculationTime('memoryFormat', Date.now() - startTime);
    
    return this.cachedAvailableMemory;
  }

  // 获取可用存储格式化字符串（带缓存）
  private getFreeStorageFormatted(): string {
    const currentHash = this.getHealthInfoHash();
    if (this.cachedFreeStorage && currentHash === this.lastHealthInfoHash) {
      return this.cachedFreeStorage;
    }
    
    const startTime = Date.now();
    const freeStorageKB = BigInt(Math.round(this.healthInfo.performance.storage.free * 1024)); // 转换为KB
    this.cachedFreeStorage = MemoryUtils.formatMemory(freeStorageKB);
    
    this.recordCalculationTime('storageFormat', Date.now() - startTime);
    
    return this.cachedFreeStorage;
  }

  // 生成健康信息哈希用于缓存验证
  private getHealthInfoHash(): string {
    const mem = this.healthInfo.performance.memory;
    const storage = this.healthInfo.performance.storage;
    
    // 使用关键数据生成简单哈希
    return `${mem.totalMem}_${mem.availableMem}_${storage.total}_${storage.used}_${storage.free}`;
  }

  // 记录计算耗时
  private recordCalculationTime(operation: string, time: number) {
    this.calculationTimes[operation] = time;
    // 开发环境下输出性能数据（注释掉，因为ArkTS不支持process.env）
    // if (process.env.NODE_ENV === 'development') {
    //   console.debug(`[Performance] ${operation}: ${time}ms`);
    // }
  }

  // 数值格式化函数优化版
  private formatValue(value: number, unit: string = ''): string {
    // 快速检查无效值
    if (!isFinite(value) || isNaN(value)) {
      return `0${unit}`;
    }
    
    const startTime = Date.now();
    let result: string;
    
    switch (unit) {
      case '%':
        // 百分比直接取整
        result = `${Math.round(value)}${unit}`;
        break;
      case 'GB':
      case 'MB':
        // 存储容量使用更精确的格式化
        result = `${Math.round(value)}${unit}`;
        break;
      default:
        // 其他情况保留一位小数，但优化性能
        result = value % 1 === 0 ? `${value}${unit}` : `${value.toFixed(1)}${unit}`;
    }
    
    this.recordCalculationTime('formatValue', Date.now() - startTime);
    return result;
  }

  // 构建所有指标项
  @Builder
  buildAllMetrics() {
    // 电量
    MetricItem({
      icon: $r('app.media.ic_battery'),
      value: `${this.healthInfo.battery.level}%`,
      label: $r('app.string.battery_label'),
      onClickItem: () => {
        this.selectedMetricType = 'battery'
        this.showDetailModal = true
      }
    })

    // 可用内存（使用缓存优化）
    MetricItem({
      icon: $r('app.media.ic_storage'),
      value: this.getAvailableMemoryFormatted(),
      label: $r('app.string.memory_label'),
      onClickItem: () => {
        this.selectedMetricType = 'memory'
        this.showDetailModal = true
      }
    })

    // 可用存储（使用缓存优化）
    MetricItem({
      icon: $r('app.media.ic_storage'),
      value: this.getFreeStorageFormatted(),
      label: $r('app.string.storage_label'),
      onClickItem: () => {
        this.selectedMetricType = 'storage'
        this.showDetailModal = true
      }
    })

    // CPU使用率
    MetricItem({
      icon: $r('app.media.ic_cpu'),
      value: this.formatValue(this.healthInfo.performance.cpu, '%'),
      label: $r('app.string.cpu_label'),
      onClickItem: () => {
        this.selectedMetricType = 'cpu'
        this.showDetailModal = true
      }
    })

    // 网络质量
    MetricItem({
      icon: $r('app.media.ic_security'),
      value: `${this.healthInfo.network.signalStrength}/4`,
      label: $r('app.string.network_label'),
      onClickItem: () => {
        this.selectedMetricType = 'network'
        this.showDetailModal = true
      }
    })

    // 传感器状态
    MetricItem({
      icon: $r('app.media.ic_sensor'),
      value: this.healthInfo.sensors.status === 'normal' ? '正常' :
        this.healthInfo.sensors.status === 'warning' ? '警告' : '错误',
      label: $r('app.string.sensors_label'),
      onClickItem: () => {
        this.selectedMetricType = 'sensors'
        this.showDetailModal = true
      }
    })
  }

  // 构建单个指标项
  @Builder
  buildMetricItem(index: number) {
    if (index === 0) { // 电量
      MetricItem({
        icon: $r('app.media.ic_battery'),
        value: `${this.healthInfo.battery.level}%`,
        label: $r('app.string.battery_label'),
        onClickItem: () => {
          this.selectedMetricType = 'battery'
          this.showDetailModal = true
        }
      })
    } else if (index === 1) { // 内存（使用缓存优化）
      MetricItem({
        icon: $r('app.media.ic_storage'),
        value: this.getAvailableMemoryFormatted(),
        label: $r('app.string.memory_label'),
        onClickItem: () => {
          this.selectedMetricType = 'memory'
          this.showDetailModal = true
        }
      })
    } else if (index === 2) { // 存储（使用缓存优化）
      MetricItem({
        icon: $r('app.media.ic_storage'),
        value: this.getFreeStorageFormatted(),
        label: $r('app.string.storage_label'),
        onClickItem: () => {
          this.selectedMetricType = 'storage'
          this.showDetailModal = true
        }
      })
    } else if (index === 3) { // CPU
      MetricItem({
        icon: $r('app.media.ic_cpu'),
        value: this.formatValue(this.healthInfo.performance.cpu, '%'),
        label: $r('app.string.cpu_label'),
        onClickItem: () => {
          this.selectedMetricType = 'cpu'
          this.showDetailModal = true
        }
      })
    } else if (index === 4) { // 网络
      MetricItem({
        icon: $r('app.media.ic_security'),
        value: `${this.healthInfo.network.signalStrength}/4`,
        label: $r('app.string.network_label'),
        onClickItem: () => {
          this.selectedMetricType = 'network'
          this.showDetailModal = true
        }
      })
    } else if (index === 5) { // 传感器
      MetricItem({
        icon: $r('app.media.ic_sensor'),
        value: this.healthInfo.sensors.status === 'normal' ? '正常' :
          this.healthInfo.sensors.status === 'warning' ? '警告' : '错误',
        label: $r('app.string.sensors_label'),
        onClickItem: () => {
          this.selectedMetricType = 'sensors'
          this.showDetailModal = true
        }
      })
    }
  }

  // 更新屏幕宽度
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      this.screenWidth = displayClass.width;
      this.updateLayoutMode(this.screenWidth);
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 关闭详情弹窗
  private closeDetailModal() {
    this.showDetailModal = false
    this.selectedMetricType = ''
  }

  build() {
    // 顶部状态栏
    Stack() {
      // 根据状态显示不同内容
      if (this.currentState === HealthCardState.LOADING) {
        this.buildSkeletonLoading()
      } else if (this.currentState === HealthCardState.ERROR) {
        this.buildErrorState()
      } else if (this.currentState === HealthCardState.EMPTY) {
        this.buildEmptyState()
      } else {
        Column() {
          // 响应式指标布局
          this.buildResponsiveLayout()
        }
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.updateLayoutMode(Number(newValue.width));
        })
      }

      // 详情弹窗
      DetailModal({
        isVisible: this.showDetailModal,
        metricType: this.selectedMetricType,
        healthInfo: this.healthInfo,
        onClose: () => {
          this.closeDetailModal()
        }
      })
    }
  }
  

  // 加载健康数据
  private loadHealthData() {
    this.currentState = HealthCardState.LOADING;
    this.isLoading = true;
    
    try {
      // 保存this引用
      const self = this;
      
      // 模拟异步数据加载
      setTimeout(() => {
        const healthInfo = DeviceHealthService.getInstance().getHealthInfo();
        
        // 检查数据是否有效
        if (self.isDataValid(healthInfo)) {
          self.healthInfo = healthInfo;
          self.currentState = HealthCardState.SUCCESS;
          // 数据更新时清除缓存
          self.clearCache();
        } else {
          self.currentState = HealthCardState.EMPTY;
          self.errorMessage = '健康数据为空';
        }
        self.isLoading = false;
      }, 1000); // 模拟1秒加载时间
    } catch (error) {
      this.currentState = HealthCardState.ERROR;
      this.errorMessage = '健康数据加载失败';
      this.isLoading = false;
      console.error('Failed to load health data:', error);
    }
  }
  
  // 检查数据有效性
  private isDataValid(healthInfo: DeviceHealthInfo): boolean {
    // 检查基本数据是否有效
    return healthInfo &&
           healthInfo.battery &&
           healthInfo.performance &&
           healthInfo.network &&
           healthInfo.sensors &&
           healthInfo.score > 0;
  }
  
  // 重试加载数据
  private retryLoadData() {
    this.loadHealthData();
  }
  
  // 更新布局模式
  private updateLayoutMode(width: number) {
    if (width > 1200) {
      this.layoutMode = 'large';
    } else if (width > 768) {
      this.layoutMode = 'medium';
    } else if (width > 480) {
      this.layoutMode = 'small';
    } else {
      this.layoutMode = 'xsmall';
    }
  }

  // 清除缓存
  private clearCache() {
    this.cachedMemoryUsage = -1;
    this.cachedStorageUsage = -1;
    this.cachedAvailableMemory = '';
    this.cachedFreeStorage = '';
    this.lastHealthInfoHash = this.getHealthInfoHash();
    this.calculationTimes = {};
  }

  // 构建骨架屏加载状态
  @Builder
  buildSkeletonLoading() {
    Column() {
      Flex({
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        ForEach([0, 1, 2, 3, 4, 5], (index: number) => {
          Column() {
            // 图标占位
            Column()
              .width(DesignConstants.ICON_SIZE_MD)
              .height(DesignConstants.ICON_SIZE_MD)
              .backgroundColor($r('app.color.skeleton_background'))
              .borderRadius(DesignConstants.BORDER_RADIUS_SM)
              .margin({ right: DesignConstants.SPACING_SM })

            Column() {
              // 标签占位
              Column()
                .width(40)
                .height(12)
                .backgroundColor($r('app.color.skeleton_background'))
                .borderRadius(DesignConstants.BORDER_RADIUS_XS)
                .margin({ bottom: 4 })
              
              // 数值占位
              Column()
                .width(60)
                .height(16)
                .backgroundColor($r('app.color.skeleton_background'))
                .borderRadius(DesignConstants.BORDER_RADIUS_SM)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .padding(DesignConstants.METRIC_ITEM.PADDING)
          .backgroundColor($r('app.color.background_secondary'))
          .borderRadius(DesignConstants.METRIC_ITEM.BORDER_RADIUS)
          .width(DesignConstants.METRIC_ITEM.WIDTH)
          .height(DesignConstants.METRIC_ITEM.HEIGHT)
        })
      }
      .width('100%')
      .margin(DesignConstants.HEALTH_CARD.MARGIN_LARGE)
      .padding(DesignConstants.HEALTH_CARD.PADDING)
    }
    .width('100%')
  }

  // 构建错误状态显示
  @Builder
  buildErrorState() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(80)
        .height(80)
        .margin({ bottom: DesignConstants.SPACING_MD })
      
      Text(this.errorMessage)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: DesignConstants.SPACING_LG })
        .textAlign(TextAlign.Center)
      
      Button($r('app.string.retry_button'), { type: ButtonType.Capsule })
        .onClick(() => {
          this.retryLoadData()
        })
        .backgroundColor($r('app.color.primary'))
        .fontColor(Color.White)
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 构建空状态显示
  @Builder
  buildEmptyState() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(80)
        .height(80)
        .margin({ bottom: DesignConstants.SPACING_MD })
      
      Text($r('app.string.no_health_data'))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      
      Button($r('app.string.refresh_button'), { type: ButtonType.Capsule })
        .onClick(() => {
          this.retryLoadData()
        })
        .backgroundColor($r('app.color.primary'))
        .fontColor(Color.White)
        .margin({ top: DesignConstants.SPACING_MD })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}