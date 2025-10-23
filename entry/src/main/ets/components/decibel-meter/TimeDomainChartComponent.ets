import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawTimeDomain } from './DrawTimeDomain';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';

@ComponentV2
export struct TimeDomainChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!

  // 时域数据
  @Local private currentTimeDomainData: number[] = [];

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
      chartType: ChartType.TIME_DOMAIN,
      responsive: DefaultChartConfig.responsive
    };
  }

  @Monitor('ak.uiDisplayState.displayDb')
  onTimeDomainDataChange(monitor: IMonitor) {
    const newTimeDomainData = monitor.value<number[]>()?.now;
    if (newTimeDomainData && this.ak.isDisplayApp) {
      this.currentTimeDomainData = this.ak.uiDisplayState.displayTimeDomainData;
    }
  }

  // 时域绘制函数
  private drawTimeDomainChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    if (this.currentTimeDomainData.length === 0) {
      return;
    }

    drawTimeDomain(
      ctx,
      canvasWidth,
      canvasHeight,
      this.currentTimeDomainData,
      this.sysResourceManager
    );
  }

  build() {
    // 使用基础图表组件，传入时域特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawTimeDomainChart(ctx, width, height);
      }
    })
  }
}