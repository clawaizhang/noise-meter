import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';

@ComponentV2
export struct SpectrumChartComponent {
  // 输入参数
  @Param spectrumData: Float32Array = new Float32Array()
  sampleRate: number = 44100
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  // 本地状态
  @Local private canvasWidth: number = 0
  @Local private canvasHeight: number = 0
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  
  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private as: AppKeys = AppStorageV2.connect(AppKeys)!
  
  // 常量
  private readonly ASPECT_RATIO: number = 1.5

  aboutToAppear() {
    this.calculateCanvasDimensions();
  }
  
  aboutToDisappear() {
  }

  @Monitor('spectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.as.isDisplayApp) {
      this.drawSpectrum(newSpectrum);
    }
  }

  // 计算Canvas尺寸（基于横向断点的简化版本）
  private calculateCanvasDimensions(): void {
    const widthBp = this.as.windowWidthBreakpoint;
    
    // 基于横向断点判断布局模式
    if (widthBp === WidthBreakpoint.WIDTH_XS || widthBp === WidthBreakpoint.WIDTH_SM) {
      // 横向XS/SM：单列布局，频谱图占满屏幕宽度
      this.canvasWidth = this.as.windowWidth - 32; // 减去边距
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
    } else {
      // 横向MD及以上：双列布局，频谱图基于Grid分配的宽度计算
      this.canvasWidth = (this.as.windowWidth / 2) - 32; // Grid分配半宽减去边距
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
    }

    console.info(`[FREQ_TRACE][Canvas] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横向断点: ${widthBp}`);
  }

  @Builder
  SpectrumChart() {
    Canvas(this.canvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(12)
      .backgroundColor('#ff191a1c')
      .onAreaChange((oldArea: Area, newArea: Area) => {
        console.info(`[FREQ_TRACE][Canvas] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
        this.canvasWidth = newArea.width as number;
        this.canvasHeight = newArea.height as number;
        console.info(`[FREQ_TRACE][Canvas] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth /
        this.canvasHeight).toFixed(2)}`);
      })
      .animation({ curve: Curve.EaseOut })
      .onReady(() => {
        // 初始化完成后开始绘制
        const emptySpectrum: Float32Array = new Float32Array(this.fftSize * 2);
        if (this.as.isDisplayApp) {
          this.drawSpectrum(emptySpectrum);
        }
      })
  }


  private drawSpectrum(spectrum: Float32Array) {
    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();
    drawSpectrum(this.canvasContext, this.canvasWidth, this.canvasHeight, spectrum, dbSteps, frequencySteps,
      this.fftSize, this.sampleRate, this.sysResourceManager);
  }

  build() {
    this.SpectrumChart()
  }
}
