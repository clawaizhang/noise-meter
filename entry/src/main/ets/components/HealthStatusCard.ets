import { DeviceHealthInfo, ScoreHealth } from "../types/DeviceHealthInfo"
import { LengthUnit } from "@kit.ArkUI"
import { DeviceHealthService } from "../services/DeviceHealthService"
import { MetricItem } from "./common/MetricItem"
import { DesignConstants } from "../constants/DesignConstants"
import { MemoryUtils, calculateMemoryUsage, calculateStorageUsage } from "../utils/MemoryUtils"
import { navigationStack } from "../constants/ProviderConstant"
import display from '@ohos.display';

// 健康卡片状态枚举
enum HealthCardState {
  LOADING,    // 加载中
  SUCCESS,    // 加载成功
  ERROR,      // 错误状态
  EMPTY       // 空状态
}

// 定义导航参数接口
interface HealthDetailDialogParams {
  metricType: string;
  healthInfo: DeviceHealthInfo;
}

@ComponentV2
export struct HealthStatusCard {
  @Param @Require memoryUsagePercentage: number
  @Local healthInfo: DeviceHealthInfo = DeviceHealthService.getInstance().getHealthInfo();
  @Local screenWidth: number = 0;
  @Local layoutMode: string = 'large'; // large, medium, small, xsmall
  @Local selectedMetricType: string = ''
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local currentState: HealthCardState = HealthCardState.LOADING
  @Local errorMessage: string = ''
  @Local isLoading: boolean = true
  @Local lastLayoutUpdateTime: number = 0
  @Local lastHealthDataUpdateTime: number = 0
  @Local healthDataUpdateInterval: number = 10000 // 10秒更新间隔
  @Local dataUpdateTimer: number = 0
  
  // 缓存计算结果
  @Local cachedMemoryUsage: number = -1
  @Local cachedStorageUsage: number = -1
  @Local cachedAvailableMemory: string = ''
  @Local cachedFreeStorage: string = ''
  @Local cachedCpuUsage: string = ''
  @Local lastHealthInfoHash: string = ''
  @Local cachedLayoutMode: string = ''
  @Local cachedScreenWidth: number = 0
  
  // 性能监控
  @Local calculationTimes: Record<string, number> = {}

  aboutToAppear() {
    this.updateScreenWidth();
    // 监听屏幕旋转和尺寸变化
    display.on('change', () => {
      this.updateScreenWidth();
    });
    
    // 检查是否已经有有效数据，避免不必要的初始加载
    const currentHealthInfo = DeviceHealthService.getInstance().getHealthInfo();
    if (this.isDataValid(currentHealthInfo) && currentHealthInfo.score > 0) {
      // 已经有有效数据，直接使用
      this.healthInfo = currentHealthInfo;
      this.currentState = HealthCardState.SUCCESS;
      this.clearCache(); // 确保缓存正确初始化
    } else {
      // 立即加载数据（不等待定时器）
      this.loadHealthData();
    }
    
    // 设置定时数据更新检查
    this.setupDataUpdateTimer();
  }

  aboutToDisappear() {
    // 移除屏幕变化监听器
    display.off('change');
    
    // 清除数据更新定时器
    if (this.dataUpdateTimer) {
      clearInterval(this.dataUpdateTimer);
      this.dataUpdateTimer = 0;
    }
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
      justifyContent: FlexAlign.SpaceAround,
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

      // 第二行：1个指标（网络）
      Flex({
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(4) // 网络
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

      // 第二行：1个指标（网络）
      Flex({
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap
      }) {
        this.buildMetricItem(4) // 网络
      }
      .width('100%')
      .margin({ bottom: 10 })
    }
    .width('100%')
    .margin(DesignConstants.HEALTH_CARD.MARGIN_SMALL)
    .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
  }

  @Builder
  buildXSmallLayout() {
    // 超小屏布局：六行显示，每行1个指标
    Column() {
      ForEach([0, 1, 2, 4], (index: number) => {
        Flex({
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center,
          wrap: FlexWrap.NoWrap
        }) {
          this.buildMetricItem(index === 3 ? 4 : index) // 将索引3映射到网络指标
        }
        .width('100%')
        .margin({ bottom: index < 3 ? 6 : 0 })
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

  // 获取CPU使用率格式化字符串（带缓存）
  private getCpuUsageFormatted(): string {
    const currentHash = this.getHealthInfoHash();
    if (this.cachedCpuUsage && currentHash === this.lastHealthInfoHash) {
      return this.cachedCpuUsage;
    }

    const startTime = Date.now();
    this.cachedCpuUsage = this.formatValue(this.healthInfo.performance.cpu, '%');

    this.recordCalculationTime('cpuFormat', Date.now() - startTime);

    return this.cachedCpuUsage;
  }

  // 生成健康信息哈希用于缓存验证（优化版）
  private getHealthInfoHash(): string {
    return this.generateHealthInfoHash(this.healthInfo);
  }
  
  // 为指定健康信息生成哈希（优化算法，减少字符串拼接）
  private generateHealthInfoHash(healthInfo: DeviceHealthInfo): string {
    const mem = healthInfo.performance.memory;
    const storage = healthInfo.performance.storage;
    const battery = healthInfo.battery;
    const network = healthInfo.network;
    const sensors = healthInfo.sensors;
    
    // 使用更高效的哈希算法，只包含关键变化数据
    // 避免不必要的字符串拼接，使用数字计算
    const hashParts = [
      Math.round(battery.level / 5) * 5, // 电池电量按5%分组
      battery.health,
      Math.round(battery.temperature),
      battery.status,
      Math.round(Number(mem.availableMem) / 1000000), // 内存按MB计算
      Math.round(storage.used / 1024), // 存储按GB计算
      Math.round(healthInfo.performance.cpu / 5) * 5, // CPU使用率按5%分组
      network.signalStrength,
      network.type,
      network.isConnected ? 1 : 0,
      sensors.status === 'normal' ? 1 : sensors.status === 'warning' ? 2 : 3,
      Math.round(healthInfo.score / 5) * 5 // 评分按5分分组
    ];
    
    return hashParts.join('_');
  }

  // 记录计算耗时
  private recordCalculationTime(operation: string, time: number) {
    this.calculationTimes[operation] = time;
    // 开发环境下输出性能数据（注释掉，因为ArkTS不支持process.env）
    // if (process.env.NODE_ENV === 'development') {
    //   console.debug(`[Performance] ${operation}: ${time}ms`);
    // }
  }

  // 数值格式化函数优化版（减少重复调用）
  private formatValue(value: number, unit: string = ''): string {
    // 快速检查无效值
    if (!isFinite(value) || isNaN(value)) {
      return `0${unit}`;
    }
    
    const startTime = Date.now();
    let result: string;
    
    // 使用更高效的条件判断
    if (unit === '%') {
      // 百分比直接取整
      result = `${Math.round(value)}${unit}`;
    } else if (unit === 'GB' || unit === 'MB') {
      // 存储容量使用更精确的格式化
      result = `${Math.round(value)}${unit}`;
    } else {
      // 其他情况：如果是整数直接显示，否则保留一位小数
      result = Number.isInteger(value) ? `${value}${unit}` : `${value.toFixed(1)}${unit}`;
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
        this.showHealthDetailDialog()
      }
    })

    // 可用内存（使用缓存优化）
    MetricItem({
      icon: $r('app.media.ic_storage'),
      value: this.getAvailableMemoryFormatted(),
      label: $r('app.string.memory_label'),
      onClickItem: () => {
        this.selectedMetricType = 'memory'
        this.showHealthDetailDialog()
      }
    })

    // 可用存储（使用缓存优化）
    MetricItem({
      icon: $r('app.media.ic_storage'),
      value: this.getFreeStorageFormatted(),
      label: $r('app.string.storage_label'),
      onClickItem: () => {
        this.selectedMetricType = 'storage'
        this.showHealthDetailDialog()
      }
    })

    // 网络质量
    MetricItem({
      icon: $r('app.media.ic_security'),
      value: `${this.healthInfo.network.signalStrength}/4`,
      label: $r('app.string.network_label'),
      onClickItem: () => {
        this.selectedMetricType = 'network'
        this.showHealthDetailDialog()
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
          this.showHealthDetailDialog()
        }
      })
    } else if (index === 1) { // 内存（使用缓存优化）
      MetricItem({
        icon: $r('app.media.ic_storage'),
        value: this.getAvailableMemoryFormatted(),
        label: $r('app.string.memory_label'),
        onClickItem: () => {
          this.selectedMetricType = 'memory'
          this.showHealthDetailDialog()
        }
      })
    } else if (index === 2) { // 存储（使用缓存优化）
      MetricItem({
        icon: $r('app.media.ic_storage'),
        value: this.getFreeStorageFormatted(),
        label: $r('app.string.storage_label'),
        onClickItem: () => {
          this.selectedMetricType = 'storage'
          this.showHealthDetailDialog()
        }
      })
    } else if (index === 4) { // 网络
      MetricItem({
        icon: $r('app.media.ic_security'),
        value: `${this.healthInfo.network.signalStrength}/4`,
        label: $r('app.string.network_label'),
        onClickItem: () => {
          this.selectedMetricType = 'network'
          this.showHealthDetailDialog()
        }
      })
    }
  }

  // 更新屏幕宽度（带缓存优化）
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      const newScreenWidth = displayClass.width;
      
      // 只有当屏幕宽度有显著变化时才更新布局模式
      if (Math.abs(newScreenWidth - this.cachedScreenWidth) > 20) { // 20px变化阈值
        this.screenWidth = newScreenWidth;
        this.cachedScreenWidth = newScreenWidth;
        this.updateLayoutMode(this.screenWidth);
      }
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 显示健康详情对话框
  private showHealthDetailDialog() {
    if (this.selectedMetricType && this.healthInfo) {
      const navPathInfo = new NavPathInfo(
        'HealthDetailDialog',
        { metricType: this.selectedMetricType} as HealthDetailDialogParams
      )
      this.navStack.pushPath(navPathInfo)
    }
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
          // 添加防抖机制，避免频繁触发布局更新
          const currentTime = Date.now();
          if (currentTime - this.lastLayoutUpdateTime > 300) { // 300ms防抖
            this.updateLayoutMode(Number(newValue.width));
            this.lastLayoutUpdateTime = currentTime;
          }
        })
      }

    }
  }
  

  // 加载健康数据（带频率控制和状态管理优化）
  private loadHealthData() {
    const currentTime = Date.now();
    
    // 控制数据更新频率，避免过于频繁的更新
    if (this.lastHealthDataUpdateTime > 0 && currentTime - this.lastHealthDataUpdateTime < this.healthDataUpdateInterval) {
      return;
    }
    
    const newHealthInfo = DeviceHealthService.getInstance().getHealthInfo();
    
    // 检查数据是否有显著变化，如果没有变化则不触发加载状态
    if (!this.hasSignificantChange(newHealthInfo) && this.currentState === HealthCardState.SUCCESS) {
      // 数据没有显著变化且当前已经是成功状态，直接更新缓存哈希并返回
      this.lastHealthInfoHash = this.getHealthInfoHash();
      this.lastHealthDataUpdateTime = currentTime;
      return;
    }
    
    // 只有在当前不是加载状态时才显示加载UI
    if (this.currentState !== HealthCardState.LOADING) {
      this.currentState = HealthCardState.LOADING;
    }
    this.isLoading = true;
    this.lastHealthDataUpdateTime = currentTime;
    
    try {
      // 保存this引用
      const self = this;
      
      // 模拟异步数据加载
      setTimeout(() => {
        const healthInfo = DeviceHealthService.getInstance().getHealthInfo();
        
        // 检查数据是否有效
        if (self.isDataValid(healthInfo)) {
          // 检查数据是否有显著变化，如果没有变化则保持当前状态
          if (self.hasSignificantChange(healthInfo)) {
            self.healthInfo = healthInfo;
            // 数据更新时清除缓存
            self.clearCache();
          }
          // 更新为成功状态
          self.currentState = HealthCardState.SUCCESS;
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
    // 检查基本数据是否有效（允许score为0，因为可能是初始状态）
    return healthInfo != undefined &&
           healthInfo.battery != undefined &&
           healthInfo.performance != undefined &&
           healthInfo.network != undefined &&
           healthInfo.sensors != undefined;
  }
  
  // 重试加载数据
  private retryLoadData() {
    this.loadHealthData();
  }
  
  // 设置数据更新定时器
  private setupDataUpdateTimer() {
    // 每10秒检查一次数据更新（与healthDataUpdateInterval保持一致）
    this.dataUpdateTimer = setInterval(() => {
      // 只有在当前不是加载状态且组件可见时才触发数据加载
      if (this.currentState !== HealthCardState.LOADING) {
        this.loadHealthData();
      }
    }, this.healthDataUpdateInterval);
  }
  
  // 检查数据是否有显著变化（避免微小变化触发布局重绘）
  private hasSignificantChange(newHealthInfo: DeviceHealthInfo): boolean {
    const oldInfo = this.healthInfo;
    
    // 如果这是第一次加载数据，总是返回true
    if (!oldInfo || oldInfo.score === 0) {
      return true;
    }
    
    // 使用哈希比较作为第一层快速检查
    const newHash = this.generateHealthInfoHash(newHealthInfo);
    const oldHash = this.lastHealthInfoHash;
    
    if (newHash === oldHash && oldHash !== '') {
      return false; // 哈希相同，数据没有变化
    }
    
    // 检查各项指标是否有显著变化（阈值可以根据需要调整）
    const batteryChange = Math.abs(newHealthInfo.battery.level - oldInfo.battery.level) > 2;
    const cpuChange = Math.abs(newHealthInfo.performance.cpu - oldInfo.performance.cpu) > 5;
    const memoryChange = Math.abs(
      Number(newHealthInfo.performance.memory.availableMem) -
      Number(oldInfo.performance.memory.availableMem)
    ) > 1000000; // 1MB变化
    const networkChange = newHealthInfo.network.signalStrength !== oldInfo.network.signalStrength;
    const sensorChange = newHealthInfo.sensors.status !== oldInfo.sensors.status;
    
    // 如果有任何显著变化，返回true
    return batteryChange || cpuChange || memoryChange || networkChange || sensorChange;
  }
  
  // 更新布局模式（带滞后阈值防止频繁切换和缓存优化）
  private updateLayoutMode(width: number) {
    // 计算各布局模式的最小宽度要求
    const minWidthForLargeLayout = DesignConstants.METRIC_ITEM.WIDTH * 6 + DesignConstants.SPACING_MD * 5;
    const minWidthForMediumLayout = DesignConstants.METRIC_ITEM.WIDTH * 3 + DesignConstants.SPACING_MD * 2;
    const minWidthForSmallLayout = DesignConstants.METRIC_ITEM.WIDTH * 2 + DesignConstants.SPACING_MD;
    
    // 添加滞后阈值（15px），防止在边界值附近频繁切换
    const hysteresis = 15;
    
    let newLayoutMode: string;
    
    if (width >= minWidthForLargeLayout + hysteresis) {
      newLayoutMode = 'large';
    } else if (width >= minWidthForMediumLayout + hysteresis) {
      // 如果当前是大屏模式，需要更宽的阈值才能切换到中屏
      newLayoutMode = (this.cachedLayoutMode === 'large' && width >= minWidthForLargeLayout - hysteresis) ?
        'large' : 'medium';
    } else if (width >= minWidthForSmallLayout + hysteresis) {
      // 如果当前是中屏模式，需要更宽的阈值才能切换到小屏
      newLayoutMode = (this.cachedLayoutMode === 'medium' && width >= minWidthForMediumLayout - hysteresis) ?
        'medium' : 'small';
    } else {
      // 如果当前是小屏模式，需要更窄的阈值才能切换到超小屏
      newLayoutMode = (this.cachedLayoutMode === 'small' && width >= minWidthForSmallLayout - hysteresis) ?
        'small' : 'xsmall';
    }
    
    // 只有当布局模式真正改变时才更新
    if (newLayoutMode !== this.cachedLayoutMode) {
      this.layoutMode = newLayoutMode;
      this.cachedLayoutMode = newLayoutMode;
      console.debug(`[LayoutMode] Screen width: ${width}px, Mode: ${this.layoutMode}`);
    }
  }

  // 清除缓存
  private clearCache() {
    this.cachedMemoryUsage = -1;
    this.cachedStorageUsage = -1;
    this.cachedAvailableMemory = '';
    this.cachedFreeStorage = '';
    this.cachedCpuUsage = '';
    this.lastHealthInfoHash = this.getHealthInfoHash();
    this.calculationTimes = {};
  }

  // 构建骨架屏加载状态
  @Builder
  buildSkeletonLoading() {
    Column() {
      Flex({
        justifyContent: FlexAlign.SpaceAround,
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
                .width(35)  // 调整为更小的宽度
                .height(12)
                .backgroundColor($r('app.color.skeleton_background'))
                .borderRadius(DesignConstants.BORDER_RADIUS_XS)
                .margin({ bottom: 4 })
              
              // 数值占位
              Column()
                .width(50)  // 调整为更小的宽度
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