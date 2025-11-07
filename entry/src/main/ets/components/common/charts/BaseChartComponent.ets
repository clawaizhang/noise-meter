/**
 * 基础图表组件
 * 提供通用的Canvas管理、响应式布局、生命周期管理
 * 采用组合模式，其他图表组件通过使用此组件来复用公共功能
 */

import { AppStorageV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../../models/AppKeys';
import { ChartConfig, ChartType, DefaultChartConfig } from './ChartConfig';
import { ChartUtils } from './ChartUtils';

@ComponentV2
export struct BaseChartComponent {
  // 输入参数
  @Param canvasWidthInput: number = 0;
  @Param canvasHeightInput: number = 0;
  @Param chartConfig: ChartConfig = DefaultChartConfig;
  @Event onDrawChart?: (ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number) => void;

  // 本地状态
  @Local canvasWidth: number = 0;
  @Local canvasHeight: number = 0;

  // 依赖注入
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  // Canvas相关属性
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  aboutToAppear() {
    // 如果外部没有传入尺寸，则使用默认计算
    if (this.canvasWidthInput === 0 || this.canvasHeightInput === 0) {
      this.calculateCanvasDimensions();
    } else {
      this.canvasWidth = this.canvasWidthInput;
      this.canvasHeight = this.canvasHeightInput;
    }
  }

  @Monitor('ak.uiDisplayState.displayDb')
  onDisplayDbChange(monitor: IMonitor) {
    this.drawChart();
  }

  @Monitor('canvasWidthInput','canvasHeightInput')
  onCanvasSizeChange(monitor: IMonitor) {
    this.canvasWidth = monitor.value<number>()?.now!;
    this.canvasHeight = monitor.value<number>()?.now!;
    this.drawChart();
  }

  @Monitor('ak.windowWidth','ak.windowHeight')
  onWindowChange(monitor: IMonitor) {
    // 如果外部没有传入尺寸，则响应窗口变化
    if (this.canvasWidthInput === 0 || this.canvasHeightInput === 0) {
      this.calculateCanvasDimensions();
    }
  }

  /**
   * 计算Canvas尺寸（响应式布局）
   */
  private calculateCanvasDimensions(): void {
    const widthBp = this.ak.windowWidthBreakpoint;
    const heightBp = this.ak.windowHeightBreakpoint;
    const ASPECT_RATIO: number = this.chartConfig.aspectRatio;

    // 基于横向断点判断布局模式
    if (widthBp <= 1) { // XS/SM断点
      // 小屏幕：单列布局，图表占满屏幕宽度
      this.canvasWidth = this.ak.windowWidth - 32; // 减去边距
      this.canvasHeight = this.canvasWidth / ASPECT_RATIO;
    } else {
      // 中等及以上屏幕：双列布局，图表基于Grid分配的宽度计算
      this.canvasWidth = (this.ak.windowWidth / 2) - 32; // Grid分配半宽减去边距
      this.canvasHeight = this.canvasWidth / ASPECT_RATIO;
    }

    console.info(`[BaseChart] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横向断点: ${widthBp}`);
  }

  /**
   * 绘制图表
   */
  private drawChart(): void {
    if (!ChartUtils.isValidCanvasContext(this.canvasContext)) {
      return;
    }

    console.debug(`[BaseChart] 开始绘制图表，尺寸: ${this.canvasWidth}x${this.canvasHeight}`);

    // 清除画布
    ChartUtils.clearCanvas(this.canvasContext, this.canvasWidth, this.canvasHeight);

    // 绘制背景
    ChartUtils.drawBackground(
      this.canvasContext,
      this.canvasWidth,
      this.canvasHeight,
      this.chartConfig.backgroundColor,
      ChartUtils.getSystemColor(this.sysResourceManager, $r('sys.color.font_on_tertiary'))
    );

    // 调用具体的图表绘制回调
    if (this.onDrawChart) {
      this.onDrawChart(this.canvasContext, this.canvasWidth, this.canvasHeight);
    }
    
    console.debug(`[BaseChart] 图表绘制完成`);
  }

  /**
   * 构建图表Canvas
   */
  @Builder
  ChartCanvas() {
    Canvas(this.canvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(16)
      .backgroundColor(this.chartConfig.backgroundColor)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        console.info(`[BaseChart] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
        this.canvasWidth = newArea.width as number;
        this.canvasHeight = newArea.height as number;
        console.info(`[BaseChart] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth / this.canvasHeight).toFixed(2)}`);
        
        // 重新绘制图表
        this.drawChart();
      })
      .animation({ curve: Curve.EaseOut })
      .onReady(() => {
        // 初始化完成后开始绘制
        this.drawChart();
      })
  }

  build() {
    this.ChartCanvas()
  }
}