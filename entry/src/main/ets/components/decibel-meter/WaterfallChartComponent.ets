/**
 * 频谱瀑布图组件
 * 基于BaseChartComponent框架，实现频谱瀑布图的响应式显示
 */

import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawWaterfall, DefaultWaterfallDrawConfig, WaterfallDrawConfig } from './DrawWaterfall';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';
import { ColorMapConfig } from '../../models/WaterfallData';

@ComponentV2
export struct WaterfallChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!

  // 异步绘制状态
  @Local private isDrawing: boolean = false;
  @Local private lastDrawTime: number = 0;
  @Local private drawError: string = '';

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: DefaultChartConfig.margin,
      aspectRatio: 1.8, // 瀑布图需要更高的宽高比来显示时间维度
      backgroundColor: DefaultChartConfig.backgroundColor,
      gridColor: DefaultChartConfig.gridColor,
      textColor: DefaultChartConfig.textColor,
      fontSize: DefaultChartConfig.fontSize,
      chartType: ChartType.WATERFALL,
      responsive: DefaultChartConfig.responsive
    };
  }

  @Monitor('ak.uiDisplayState.displayWaterfallData.spectrumHistory')
  onWaterfallDataChange(monitor: IMonitor) {
    const newHistory = monitor.value<Float32Array[]>()?.now;
    if (newHistory && this.ak.isDisplayApp) {
      console.debug(`[瀑布图] 数据更新，当前帧数: ${newHistory.length}`);
      // 数据变化会自动触发BaseChartComponent的重绘
    }
  }

  @Monitor('ak.uiDisplayState.displayWaterfallData.colorMap')
  onColorMapChange(monitor: IMonitor) {
    const newColorMap = monitor.value<ColorMapConfig>()?.now;
    if (newColorMap && this.ak.isDisplayApp) {
      console.debug('[瀑布图] 颜色映射配置更新');
      // 颜色映射变化触发重绘
    }
  }

  // 瀑布图绘制函数
  private async drawWaterfallChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): Promise<void> {
    const waterfallData = this.ak.uiDisplayState.displayWaterfallData;
    
    if (waterfallData.spectrumHistory.length === 0) {
      this.drawEmptyState(ctx, canvasWidth, canvasHeight);
      return;
    }

    // 防止过于频繁的绘制
    const now = Date.now();
    if (now - this.lastDrawTime < 50) { // 最小绘制间隔50ms
      return;
    }

    // 设置绘制状态
    this.isDrawing = true;
    this.drawError = '';

    // 使用自定义的瀑布图绘制配置
    const drawConfig: WaterfallDrawConfig = {
      margin: DefaultWaterfallDrawConfig.margin,
      colorMap: waterfallData.colorMap,
      perspective: DefaultWaterfallDrawConfig.perspective,
      options: DefaultWaterfallDrawConfig.options
    };

    try {
      await drawWaterfall(
        ctx,
        canvasWidth,
        canvasHeight,
        waterfallData,
        this.sysResourceManager,
        drawConfig
      );
      this.lastDrawTime = now;
    } catch (error) {
      console.error('[瀑布图] 绘制失败:', error);
      this.drawError = (error as Error).message;
      this.drawErrorState(ctx, canvasWidth, canvasHeight, (error as Error).message);
    } finally {
      this.isDrawing = false;
    }
  }

  // 同步包装函数，用于BaseChartComponent的回调
  private drawWaterfallChartSync(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    // 异步绘制，但不等待完成
    this.drawWaterfallChart(ctx, canvasWidth, canvasHeight).catch((error: Error) => {
      console.error('[瀑布图] 异步绘制失败:', error);
    });
  }

  // 绘制空状态
  private drawEmptyState(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    // 清除画布
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    
    // 绘制背景
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.background_primary').id);
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    // 绘制提示文本
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = '16px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    const centerX = canvasWidth / 2;
    const centerY = canvasHeight / 2;
    
    ctx.fillText('等待频谱数据...', centerX, centerY - 20);
    ctx.font = '12px sans-serif';
    ctx.fillText('频谱瀑布图将显示频率随时间的变化', centerX, centerY + 10);
  }

  // 绘制错误状态
  private drawErrorState(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number, errorMessage: string): void {
    // 清除画布
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    
    // 绘制背景
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.background_primary').id);
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    // 绘制错误信息
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = '14px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    
    const centerX = canvasWidth / 2;
    const centerY = canvasHeight / 2;
    
    ctx.fillText('瀑布图绘制错误', centerX, centerY - 20);
    ctx.font = '10px sans-serif';
    ctx.fillText(errorMessage.substring(0, 50) + '...', centerX, centerY + 10);
  }

  build() {
    // 使用基础图表组件，传入瀑布图特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawWaterfallChartSync(ctx, width, height);
      }
    })
  }
}