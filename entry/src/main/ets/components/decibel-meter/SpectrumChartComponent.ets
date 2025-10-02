import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { DialogHub } from '@hadss/dialoghub';
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

  @Monitor('spectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.as.isDisplayApp) {
      this.drawSpectrum(newSpectrum);
    }
  }

  // 计算Canvas尺寸（响应式版本）- 优化平板横屏支持
  private async calculateCanvasDimensions(): Promise<void> {
    try {
      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();
      const isLandscape = availableArea.width > availableArea.height;
      
      // 更新响应式布局状态
      const availableWidthVp = px2vp(availableArea.width);
      const availableHeightVp = px2vp(availableArea.height);

      if (isLandscape) {
        // 横屏模式：使用2:1宽高比，更适合平板横屏
        this.canvasWidth = availableWidthVp * 0.7; // 占用70%可用宽度
        this.canvasHeight = this.canvasWidth / 2; // 2:1宽高比
      } else {
        // 竖屏模式：保持原有1.5:1宽高比
        this.canvasWidth = availableWidthVp - (16 as number * 2);
        this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
      }

      // 确保Canvas尺寸不会过大
      const maxCanvasWidth = Math.min(this.canvasWidth, 600);
      const maxCanvasHeight = Math.min(this.canvasHeight, 400);
      
      this.canvasWidth = maxCanvasWidth;
      this.canvasHeight = maxCanvasHeight;

      console.info(`[FREQ_TRACE][Canvas] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横屏: ${isLandscape}`);
    } catch (error) {
      console.error('[FREQ_TRACE][显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  @Builder
  SpectrumView() {
    Column() {
      // Canvas频谱显示
      Stack({ alignContent: Alignment.Top }) {
        this.SpectrumChart()
      }
    }
  }

  @Builder
  SpectrumChart() {
    Canvas(this.canvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(12)
      .backgroundColor('#ff000000')
      .shadow({
        radius: 8,
        color: $r('sys.color.comp_divider'),
        offsetX: 2,
        offsetY: 2
      })
      .border({
        width: 1,
        color: $r('sys.color.comp_divider')
      })
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
      .id('ashkjlgfshgal')
      .onClick(() => {
        let dialog = DialogHub.getSheet()
          .setStyle({
            detents: [SheetSize.FIT_CONTENT],
            backgroundColor: $r('sys.color.background_secondary'),
            title: { title: '频谱图', subtitle: '横坐标: 频率(Hz), 纵坐标: 分贝值(dB)' }
          })
          .setComponentTargetId('ashkjlgfshgal')
          .setContent(wrapBuilder(peakExp), this.as)
          .build();
        dialog.show();
        setInterval(() => {
          dialog.updateContent(this.as);
        }, 100)
      })
  }


  private drawSpectrum(spectrum: Float32Array) {
    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();
    drawSpectrum(this.canvasContext, this.canvasWidth, this.canvasHeight, spectrum, dbSteps, frequencySteps,
      this.fftSize, this.sampleRate, this.sysResourceManager);
  }

  build() {
    this.SpectrumView()
  }
}

@Builder
function peakExp(ak: AppKeys) {
  Column({ space: 16 }) {
    Text('峰值频率').fontSize(24)

    Text(`${ak.peakFreq.toFixed(0)}Hz`).fontSize(36)

    Text('峰值频率反映了噪音中"最响"的那个音高。是的，它可以理解为当前噪音中能量最高的频率，帮助我们快速定位噪音的主要特征和可能来源，为降噪提供关键依据。')

  }.backgroundColor($r('sys.color.comp_background_primary'))
  .padding(16)
  .borderRadius(16)
  .alignItems(HorizontalAlign.Center)
}