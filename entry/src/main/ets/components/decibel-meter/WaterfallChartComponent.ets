import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawWaterfall, WaterfallHistoryManager, DefaultWaterfallConfig, WaterfallConfig } from './DrawWaterfall';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';
import { getFrequencySteps } from './DrawSpectrum';
import { PerformanceMonitor, AlertThresholds } from '../../utils/PerformanceMonitor';

@ComponentV2
export struct WaterfallChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  
  // 瀑布图历史数据管理器
  @Local private historyManager: WaterfallHistoryManager = new WaterfallHistoryManager();
  
  // 瀑布图配置
  @Local private waterfallConfig: WaterfallConfig = DefaultWaterfallConfig;
  
  // 性能监控器
  @Local private performanceMonitor: PerformanceMonitor = PerformanceMonitor.getInstance();

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: DefaultChartConfig.margin,
      aspectRatio: 1.5,
      backgroundColor: DefaultChartConfig.backgroundColor,
      gridColor: DefaultChartConfig.gridColor,
      textColor: DefaultChartConfig.textColor,
      fontSize: DefaultChartConfig.fontSize,
      chartType: ChartType.WATERFALL,
      responsive: DefaultChartConfig.responsive
    };
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
    }
  }

  // 瀑布图绘制函数
  private drawWaterfallChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    if (this.currentSpectrumData.length === 0) {
      return;
    }

    const frequencySteps: number[] = getFrequencySteps();
    
    drawWaterfall(
      ctx,
      canvasWidth,
      canvasHeight,
      this.currentSpectrumData,
      this.historyManager,
      frequencySteps,
      this.fftSize,
      this.sampleRate,
      this.sysResourceManager,
      this.waterfallConfig
    );
  }

  aboutToAppear() {
    // 初始化瀑布图配置
    this.initializeWaterfallConfig();
    
    // 设置性能监控阈值
    const thresholds: AlertThresholds = {
      minFPS: 8,        // 低于8FPS视为性能问题
      maxMemoryMB: 150, // 内存使用超过150MB视为警告
      maxFrameTime: 120 // 单帧渲染时间超过120ms视为过慢
    };
    this.performanceMonitor.setAlertThresholds(thresholds);
  }

  /**
   * 初始化瀑布图配置
   */
  private initializeWaterfallConfig(): void {
    // 根据屏幕大小调整配置
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    
    if (isSmallScreen) {
      this.waterfallConfig.maxHistoryLines = 50; // 小屏幕减少历史行数
      this.waterfallConfig.updateTime = 150;       // 降低更新频率
      this.waterfallConfig.targetFPS = 10;        // 小屏幕降低帧率
    } else {
      this.waterfallConfig.maxHistoryLines = 100;
      this.waterfallConfig.updateTime = 100;
      this.waterfallConfig.targetFPS = 15;        // 正常屏幕帧率
    }
    
    // 启用优化
    this.waterfallConfig.enableOptimization = true;

    console.info(`[瀑布图组件] 初始化配置，历史行数: ${this.waterfallConfig.maxHistoryLines}, 目标帧率: ${this.waterfallConfig.targetFPS}FPS`);
  }

  /**
   * 清空瀑布图历史数据
   */
  public clearHistory(): void {
    this.historyManager.clear();
    console.info('[瀑布图组件] 已清空历史数据');
  }

  /**
   * 更新瀑布图配置
   */
  public updateConfig(config: Partial<WaterfallConfig>): void {
    if (config.maxHistoryLines !== undefined) {
      this.waterfallConfig.maxHistoryLines = config.maxHistoryLines;
      // 重新初始化历史管理器以适应新的缓冲区大小
      this.historyManager = new WaterfallHistoryManager(this.waterfallConfig);
    }
    if (config.colorMap !== undefined) {
      this.waterfallConfig.colorMap = config.colorMap;
    }
    if (config.minDb !== undefined) {
      this.waterfallConfig.minDb = config.minDb;
    }
    if (config.maxDb !== undefined) {
      this.waterfallConfig.maxDb = config.maxDb;
    }
    if (config.fadeEffect !== undefined) {
      this.waterfallConfig.fadeEffect = config.fadeEffect;
    }
    if (config.updateTime !== undefined) {
      this.waterfallConfig.updateTime = config.updateTime;
    }
    if (config.targetFPS !== undefined) {
      this.waterfallConfig.targetFPS = config.targetFPS;
    }
    if (config.enableOptimization !== undefined) {
      this.waterfallConfig.enableOptimization = config.enableOptimization;
    }
    console.info('[瀑布图组件] 配置已更新');
  }
  
  /**
   * 获取性能指标
   */
  public getPerformanceMetrics() {
    return this.performanceMonitor.getMetrics();
  }
  
  /**
   * 获取性能警报
   */
  public getPerformanceAlerts() {
    return this.performanceMonitor.getAlerts();
  }
  
  /**
   * 获取性能报告
   */
  public getPerformanceReport(): string {
    return this.performanceMonitor.getPerformanceReport();
  }
  
  /**
   * 重置性能监控
   */
  public resetPerformanceMonitoring(): void {
    this.performanceMonitor.reset();
  }

  build() {
    // 使用基础图表组件，传入瀑布图特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawWaterfallChart(ctx, width, height);
      }
    })
  }
}