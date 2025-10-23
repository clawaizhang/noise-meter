import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';

@ComponentV2
export struct SpectrumChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();

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
      chartType: ChartType.SPECTRUM,
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

  // 频谱绘制函数
  private drawSpectrumChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    if (this.currentSpectrumData.length === 0) {
      return;
    }

    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();
    
    drawSpectrum(
      ctx,
      canvasWidth,
      canvasHeight,
      this.currentSpectrumData,
      dbSteps,
      frequencySteps,
      this.fftSize,
      this.sampleRate,
      this.sysResourceManager
    );
  }

  build() {
    // 使用基础图表组件，传入频谱特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawSpectrumChart(ctx, width, height);
      }
    })
  }
}
