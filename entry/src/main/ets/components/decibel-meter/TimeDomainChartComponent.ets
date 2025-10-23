import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawTimeDomain } from './DrawTimeDomain';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';

@ComponentV2
export struct TimeDomainChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local canvasWidth: number = 0
  @Local canvasHeight: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Monitor('canvasWidthInput','canvasHeightInput')
  onCanvasSizeChange(monitor: IMonitor) {
    this.canvasWidth = monitor.value<number>()?.now!;
    this.canvasHeight = monitor.value<number>()?.now!;
  }

  // 本地状态
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!

  aboutToAppear() {
    // 如果外部没有传入尺寸，则使用默认计算
    if (this.canvasWidthInput === 0 || this.canvasHeightInput === 0) {
      this.calculateCanvasDimensions();
    } else {
      this.canvasWidth = this.canvasWidthInput;
      this.canvasHeight = this.canvasHeightInput;
    }
  }

  aboutToDisappear() {
  }

  @Monitor('ak.windowWidth','ak.windowHeight')
  onWindowChange(monitor: IMonitor) {
    // 如果外部没有传入尺寸，则响应窗口变化
    if (this.canvasWidthInput === 0 || this.canvasHeightInput === 0) {
      this.calculateCanvasDimensions();
    }
  }

  @Monitor('ak.uiDisplayState.displayTimeDomainData')
  onTimeDomainDataChange(monitor: IMonitor) {
    const newTimeDomainData = monitor.value<number[]>()?.now;
    if (newTimeDomainData && this.ak.isDisplayApp) {
      this.drawTimeDomain(newTimeDomainData);
    }
  }

  // 计算Canvas尺寸（基于横向断点的简化版本）
  private calculateCanvasDimensions(): void {
    const widthBp = this.ak.windowWidthBreakpoint;
    const ASPECT_RATIO: number = 1.5;

    // 基于横向断点判断布局模式
    if (widthBp <= WidthBreakpoint.WIDTH_SM) {
      // 横向XS/SM：单列布局，时域图占满屏幕宽度
      this.canvasWidth = this.ak.windowWidth - 32; // 减去边距
      this.canvasHeight = this.canvasWidth / ASPECT_RATIO;
    } else {
      // 横向MD及以上：双列布局，时域图基于Grid分配的宽度计算
      this.canvasWidth = (this.ak.windowWidth / 2) - 32; // Grid分配半宽减去边距
      this.canvasHeight = this.canvasWidth / ASPECT_RATIO;
    }

    console.info(`[时域图][Canvas] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横向断点: ${widthBp}`);
  }

  @Builder
  TimeDomainChart() {
    Canvas(this.canvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(16)
      .backgroundColor('#ff191a1c')
      .onAreaChange((oldArea: Area, newArea: Area) => {
        console.info(`[时域图][Canvas] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
        this.canvasWidth = newArea.width as number;
        this.canvasHeight = newArea.height as number;
        console.info(`[时域图][Canvas] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth /
        this.canvasHeight).toFixed(2)}`);
      })
      .animation({ curve: Curve.EaseOut })
      .onReady(() => {
        // 初始化完成后开始绘制
        const emptyTimeDomainData: number[] = [];
        if (this.ak.isDisplayApp) {
          this.drawTimeDomain(emptyTimeDomainData);
        }
      })
  }

  private drawTimeDomain(timeDomainData: number[]) {
    drawTimeDomain(this.canvasContext, this.canvasWidth, this.canvasHeight, timeDomainData, this.sysResourceManager);
  }

  build() {
    this.TimeDomainChart()
  }
}