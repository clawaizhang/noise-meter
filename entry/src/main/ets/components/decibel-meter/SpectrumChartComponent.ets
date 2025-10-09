import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawStaticElements, drawDynamicElements, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { spectrumCalculatorProcess } from './SpectrumCalculator';
import { SpectrumProcessResult } from './SpectrumTypes';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { taskpool } from '@kit.ArkTS';

@ComponentV2
export struct SpectrumChartComponent {
  // 输入参数
  sampleRate: number = 44100
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  // 本地状态
  @Local private canvasWidth: number = 0
  @Local private canvasHeight: number = 0
  // 双Canvas上下文
  private staticCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private staticCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.staticCanvasSettings)
  private dynamicCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private dynamicCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.dynamicCanvasSettings)
  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!
  // 常量
  private readonly ASPECT_RATIO: number = 1.5
  private readonly FONT_SIZE: number = 12
  // 缓存上次的Canvas尺寸，用于检测变化
  private lastCanvasWidth: number = 0
  private lastCanvasHeight: number = 0

  aboutToAppear() {
    this.calculateCanvasDimensions();
  }

  aboutToDisappear() {
  }

  @Monitor('as.windowWidth','as.windowHeight')
  onWindowChange(monitor: IMonitor) {
    this.calculateCanvasDimensions();
    this.redrawStaticLayerIfNeeded();
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.processAndDrawDynamicLayer(newSpectrum);
    }
  }

  // 计算Canvas尺寸（基于横向断点的简化版本）
  private calculateCanvasDimensions(): void {
    const widthBp = this.ak.windowWidthBreakpoint;

    // 基于横向断点判断布局模式
    if (widthBp <= WidthBreakpoint.WIDTH_SM) {
      // 横向XS/SM：单列布局，频谱图占满屏幕宽度
      this.canvasWidth = this.ak.windowWidth - 32; // 减去边距
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
    } else {
      // 横向MD及以上：双列布局，频谱图基于Grid分配的宽度计算
      this.canvasWidth = (this.ak.windowWidth / 2) - 32; // Grid分配半宽减去边距
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
    }

    console.info(`[FREQ_TRACE][Canvas] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横向断点: ${widthBp}`);
  }

  // 检查是否需要重绘静态层
  private redrawStaticLayerIfNeeded(): void {
    const hasSizeChanged = this.canvasWidth !== this.lastCanvasWidth ||
      this.canvasHeight !== this.lastCanvasHeight;

    if (hasSizeChanged) {
      console.info(`[静态层] Canvas尺寸变化，重绘静态层: ${this.lastCanvasWidth}x${this.lastCanvasHeight} -> ${this.canvasWidth}x${this.canvasHeight}`);
      this.redrawStaticLayer();

      // 更新缓存
      this.lastCanvasWidth = this.canvasWidth;
      this.lastCanvasHeight = this.canvasHeight;
    }
  }

  // 重绘静态层
  private redrawStaticLayer(): void {
    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();

    drawStaticElements(
      this.staticCanvasContext,
      this.canvasWidth,
      this.canvasHeight,
      dbSteps,
      frequencySteps,
      this.sysResourceManager,
      this.FONT_SIZE
    );
  }

  // 处理并绘制动态层（使用TaskPool）
  private processAndDrawDynamicLayer(spectrum: Float32Array): void {
    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();

    // 使用TaskPool在后台线程处理频谱数据
    try {
      taskpool.execute<[Float32Array, number, number, number[], number[], number, number], SpectrumProcessResult>(
        spectrumCalculatorProcess,
        spectrum,
        this.canvasWidth,
        this.canvasHeight,
        dbSteps,
        frequencySteps,
        this.fftSize,
        this.sampleRate
      ).then((result: SpectrumProcessResult) => {
        // 在主线程绘制动态内容
        this.drawDynamicLayer(result);
      }).catch((error: Error) => {
        console.error(`[TaskPool] 频谱计算失败: ${error.message}`);
        // 降级处理：在主线程计算
        this.fallbackProcessAndDraw(spectrum);
      });

    } catch (error) {
      console.error(`[TaskPool] 任务创建失败: ${error.message}`);
      // 降级处理：在主线程计算
      this.fallbackProcessAndDraw(spectrum);
    }
  }

  // 降级处理：在主线程计算和绘制
  private fallbackProcessAndDraw(spectrum: Float32Array): void {
    console.warn('[频谱绘制] 使用降级处理（主线程计算）');

    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();

    const result: SpectrumProcessResult = spectrumCalculatorProcess(
      spectrum,
      this.canvasWidth,
      this.canvasHeight,
      dbSteps,
      frequencySteps,
      this.fftSize,
      this.sampleRate
    );

    this.drawDynamicLayer(result);
  }

  // 绘制动态层
  private drawDynamicLayer(processResult: SpectrumProcessResult): void {
    drawDynamicElements(
      this.dynamicCanvasContext,
      this.canvasWidth,
      this.canvasHeight,
      processResult,
      this.sysResourceManager,
      this.FONT_SIZE
    );
  }

  @Builder
  StaticCanvas() {
    Canvas(this.staticCanvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(16)
      .backgroundColor('#ff191a1c')
      .onAreaChange((oldArea: Area, newArea: Area) => {
        console.info(`[静态Canvas] 区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
        this.canvasWidth = newArea.width as number;
        this.canvasHeight = newArea.height as number;
        this.redrawStaticLayerIfNeeded();
      })
      .onReady(() => {
        console.info('[静态Canvas] 初始化完成，绘制静态元素');
        this.redrawStaticLayer();
      })
  }

  @Builder
  DynamicCanvas() {
    Canvas(this.dynamicCanvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(16)
      .backgroundColor(Color.Transparent) // 透明背景，叠加在静态Canvas上
      .onAreaChange((oldArea: Area, newArea: Area) => {
        console.info(`[动态Canvas] 区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
        this.canvasWidth = newArea.width as number;
        this.canvasHeight = newArea.height as number;
      })
      .onReady(() => {
        console.info('[动态Canvas] 初始化完成');
        // 动态Canvas不需要初始化绘制，等待频谱数据
      })
  }

  @Builder
  SpectrumChart() {
    Stack() {
      // 静态Canvas（底层）
      this.StaticCanvas()

      // 动态Canvas（顶层）
      this.DynamicCanvas()
    }
    .width(this.canvasWidth)
    .height(this.canvasHeight)
  }

  build() {
    this.SpectrumChart()
  }
}
