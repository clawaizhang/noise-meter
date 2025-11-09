/**
 * 时间响应曲线组件
 * 用于显示音频分析模式的动态响应特性，包含实时动画和脉冲模拟
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { DesignConstants } from '../../constants/DesignConstants';
import { resourceManager } from '@kit.LocalizationKit';

@ComponentV2
export struct TimeResponseChartComponent {
  @Param @Require selectedMode: AudioAnalysisMode; // 当前选中的音频分析模式
  @Local private canvasWidth: number = 0; // Canvas宽度
  @Local private canvasHeight: number = 0; // Canvas高度
  @Local private responseData: number[] = []; // 响应数据数组
  @Local private animationTime: number = 0; // 动画时间
  @Local private isAnimating: boolean = false; // 动画状态
  @Local private pulseTriggered: boolean = false; // 脉冲触发状态
  @Local private cycleCount: number = 0; // 循环计数器
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private animationTimer: number = 0; // 动画定时器
  
  // 常量定义
  private readonly TOTAL_TIME: number = 2000; // 总时间范围(ms)
  private readonly SAMPLE_COUNT: number = 200; // 增加采样点数提高时间分辨率
  private readonly ANIMATION_INTERVAL: number = 16; // 动画间隔(ms) ~60fps
  private readonly PULSE_INTERVAL: number = 1500; // 脉冲触发间隔(ms)

  aboutToAppear() {
    this.initializeCanvasDimensions();
    this.initializeResponseData();
  }

  aboutToDisappear() {
    this.cleanupResources();
  }

  @Monitor('selectedMode')
  selectedModeChange(monitor: IMonitor) {
    // 模式变化时重置动画和数据
    this.stopAnimation();
    this.initializeResponseData();
    this.startAnimation();
  }

  // 清理所有资源
  private cleanupResources(): void {
    this.stopAnimation();
    this.responseData = [];
    this.animationTime = 0;
    this.pulseTriggered = false;
    this.cycleCount = 0;
  }

  // 初始化Canvas尺寸
  private initializeCanvasDimensions() {
    // 使用响应式布局，适应容器尺寸
    this.canvasWidth = 280; // 默认宽度
    this.canvasHeight = 120; // 默认高度
  }

  // 初始化响应数据
  private initializeResponseData() {
    // 重用现有数组，避免频繁创建新数组
    if (this.responseData.length !== this.SAMPLE_COUNT) {
      this.responseData = new Array(this.SAMPLE_COUNT).fill(0);
    } else {
      // 重用现有数组，直接填充0
      for (let i = 0; i < this.SAMPLE_COUNT; i++) {
        this.responseData[i] = 0;
      }
    }
    this.animationTime = 0;
    this.pulseTriggered = false;
    this.cycleCount = 0;
  }

  // 启动动画
  private startAnimation() {
    if (this.isAnimating) {
      return;
    }
    
    this.isAnimating = true;
    this.animationTimer = setInterval(() => {
      this.updateAnimation();
    }, this.ANIMATION_INTERVAL);
  }

  // 停止动画
  private stopAnimation() {
    if (this.animationTimer) {
      clearInterval(this.animationTimer);
      this.animationTimer = 0;
    }
    this.isAnimating = false;
    // 强制垃圾回收提示
    this.responseData = [];
  }

  // 更新动画帧
  private updateAnimation() {
    this.animationTime += this.ANIMATION_INTERVAL;
    
    // 检查是否需要重置时间轴（循环播放）
    if (this.animationTime >= this.TOTAL_TIME) {
      this.animationTime = 0;
      this.cycleCount++;
    }
    
    // 每PULSE_INTERVAL触发一次脉冲
    if (this.animationTime % this.PULSE_INTERVAL < this.ANIMATION_INTERVAL) {
      this.triggerPulse();
    }
    
    // 更新响应数据
    this.updateResponseData();
    
    // 重绘Canvas
    this.drawResponseChart();
  }

  // 触发脉冲
  private triggerPulse() {
    this.pulseTriggered = true;
    // 重置响应数据，模拟脉冲输入 - 重用现有数组
    for (let i = 0; i < this.SAMPLE_COUNT; i++) {
      this.responseData[i] = 0;
    }
  }

  // 更新响应数据
  private updateResponseData() {
    const timeStep = this.TOTAL_TIME / this.SAMPLE_COUNT;
    
    for (let i = 0; i < this.SAMPLE_COUNT; i++) {
      const currentTime = i * timeStep;
      const elapsedTime = this.animationTime - currentTime;
      
      if (elapsedTime >= 0) {
        this.responseData[i] = this.calculateResponseValue(elapsedTime);
      } else {
        // 对于未来的时间点，保持为0
        this.responseData[i] = 0;
      }
    }
  }

  // 计算响应值（基于音频分析模式）
  private calculateResponseValue(elapsedTime: number): number {
    if (elapsedTime < 0) return 0;
    
    switch (this.selectedMode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        // 快速模式：125ms时间常数 - 快速响应和衰减
        // 使用指数上升和衰减的组合来模拟真实响应
        if (elapsedTime < 125) {
          // 上升阶段：在125ms内达到峰值
          return 1 - Math.exp(-elapsedTime / 40);
        } else {
          // 下降阶段：指数衰减
          return Math.exp(-(elapsedTime - 125) / 125);
        }
        
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        // 慢速模式：1s时间常数 - 缓慢响应和衰减
        if (elapsedTime < 1000) {
          // 上升阶段：在1s内缓慢达到峰值
          return 1 - Math.exp(-elapsedTime / 300);
        } else {
          // 下降阶段：缓慢衰减
          return Math.exp(-(elapsedTime - 1000) / 1000);
        }
        
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        // 脉冲模式：35ms上升，1.5s下降 - 快速上升，缓慢下降
        if (elapsedTime < 35) {
          // 上升阶段：在35ms内快速达到峰值
          return Math.min(1.0, elapsedTime / 35);
        } else {
          // 下降阶段：非常缓慢的衰减
          return Math.exp(-(elapsedTime - 35) / 1500);
        }
        
      default:
        return 0;
    }
  }

  // 构建响应曲线图表
  @Builder
  private buildResponseChart() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 图表标题
      Text('动态响应特性预览')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // Canvas绘制区域
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor($r('app.color.black'))
        .onAreaChange((oldArea: Area, newArea: Area) => {
          // 响应式尺寸调整
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          this.drawResponseChart();
        })
        .onReady(() => {
          this.startAnimation();
        })

      // 坐标轴标签
      Row() {
        Text('0ms')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('app.color.font_tertiary'))
        Text('时间')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('app.color.font_tertiary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('2000ms')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('app.color.font_tertiary'))
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_XS })

    }
    .width('100%')
  }

  // 绘制响应图表
  private drawResponseChart() {
    if (!this.canvasContext) return;

    // 清除画布
    this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制背景网格
    this.drawGrid();
    
    // 绘制响应曲线
    this.drawResponseCurve();
    
    // 绘制时间常数标记
    this.drawTimeConstantMarkers();
  }

  // 绘制网格
  private drawGrid() {
    const ctx = this.canvasContext;
    const gridColor = this.sysResourceManager.getColorSync($r('app.color.font_on_secondary').id);
    
    // 水平网格线
    for (let i = 0; i <= 4; i++) {
      const y = (this.canvasHeight / 4) * i;
      ctx.beginPath();
      ctx.strokeStyle = gridColor;
      ctx.lineWidth = 0.5;
      ctx.moveTo(0, y);
      ctx.lineTo(this.canvasWidth, y);
      ctx.stroke();
    }
    
    // 垂直网格线
    for (let i = 0; i <= 4; i++) {
      const x = (this.canvasWidth / 4) * i;
      ctx.beginPath();
      ctx.strokeStyle = gridColor;
      ctx.lineWidth = 0.5;
      ctx.moveTo(x, 0);
      ctx.lineTo(x, this.canvasHeight);
      ctx.stroke();
    }
    
    // Y轴标签
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('app.color.font_on_tertiary').id);
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText('1.0', 25, 15);
    ctx.fillText('0.5', 25, this.canvasHeight / 2 + 5);
    ctx.fillText('0.0', 25, this.canvasHeight - 5);
  }

  // 绘制响应曲线
  private drawResponseCurve() {
    if (this.responseData.length === 0) return;

    const ctx = this.canvasContext;
    const step = this.canvasWidth / (this.SAMPLE_COUNT - 1);
    
    ctx.beginPath();
    ctx.strokeStyle = this.sysResourceManager.getColorSync($r('app.color.font_on_primary').id);
    ctx.lineWidth = 2;
    
    // 移动到起点
    const startY = this.canvasHeight - (this.responseData[0] * this.canvasHeight);
    ctx.moveTo(0, startY);
    
    // 绘制曲线
    for (let i = 1; i < this.SAMPLE_COUNT; i++) {
      const x = i * step;
      const y = this.canvasHeight - (this.responseData[i] * this.canvasHeight);
      ctx.lineTo(x, y);
    }
    
    ctx.stroke();
  }

  // 绘制时间常数标记
  private drawTimeConstantMarkers() {
    const ctx = this.canvasContext;
    const markerColor = this.sysResourceManager.getColorSync($r('app.color.confirm').id);
    
    ctx.strokeStyle = markerColor;
    ctx.lineWidth = 1;
    ctx.setLineDash([5, 3]);
    
    switch (this.selectedMode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        // 快速模式：125ms标记
        this.drawTimeMarker(125, '125ms');
        break;
        
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        // 慢速模式：1s标记
        this.drawTimeMarker(1000, '1s');
        break;
        
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        // 脉冲模式：35ms和1.5s标记
        this.drawTimeMarker(35, '35ms');
        this.drawTimeMarker(1500, '1.5s');
        break;
    }
    
    ctx.setLineDash([]);
  }

  // 绘制时间标记
  private drawTimeMarker(timeMs: number, label: string) {
    const ctx = this.canvasContext;
    const x = (timeMs / this.TOTAL_TIME) * this.canvasWidth;
    
    // 绘制垂直线
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, this.canvasHeight);
    ctx.stroke();
    
    // 绘制标签
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('app.color.font_on_secondary').id);
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(label, x, this.canvasHeight - 10);
  }

  build() {
    this.buildResponseChart()
  }
}