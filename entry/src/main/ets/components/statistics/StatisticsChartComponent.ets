/**
 * 实时统计图组件 - 优化版本
 * 采用垂直分离布局，避免内容重叠，优化响应式设计
 * 遵循双管线数据架构，使用Monitor监测数据变化
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';

// 布局配置接口
interface MarginConfig {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

interface FontSizeConfig {
  title: number;
  axis: number;
  stats: number;
  small: number;
}

interface LayoutConfig {
  margin: MarginConfig;
  chartHeight: number;
  statsHeight: number;
  fontSize: FontSizeConfig;
}

@ComponentV2
export struct StatisticsChartComponent {
  // 输入参数
  @Param canvasWidthInput: number = 0;
  @Param canvasHeightInput: number = 0;
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

  @Monitor('canvasWidthInput','canvasHeightInput')
  onCanvasSizeChange(monitor: IMonitor) {
    this.canvasWidth = monitor.value<number>()?.now!;
    this.canvasHeight = monitor.value<number>()?.now!;
  }

  @Monitor('ak.windowWidthBreakpoint')
  onWindowChange(monitor: IMonitor) {
    // 如果外部没有传入尺寸，则响应窗口变化
    if (this.canvasWidthInput === 0 || this.canvasHeightInput === 0) {
      this.calculateCanvasDimensions();
    }
  }

  @Monitor('ak.uiDisplayState.displayStatisticsDistribution')
  onStatisticsDistributionChange(monitor: IMonitor) {
    const distribution = monitor.value<number[]>()?.now;
    console.debug(`[统计图表] 分布数据变化: [${distribution?.join(', ') || '空'}]`);
    this.drawStatisticsChart();
  }

  @Monitor('ak.uiDisplayState.displayDb')
  onStatisticsChange(monitor: IMonitor) {
    const displayDb = monitor.value<number>()?.now;
    console.debug(`[统计图表] 统计数据变化: 当前=${displayDb}dB`);
    this.drawStatisticsChart();
  }

  // 计算Canvas尺寸（响应式布局）- 优化版本
  private calculateCanvasDimensions(): void {
    const widthBp = this.ak.windowWidthBreakpoint;
    const isFullScreen = widthBp >= 3;

    if (widthBp <= 1) { // XS/SM断点
      // 小屏幕：占满宽度，紧凑高度
      const availableWidth = this.ak.windowWidth - 32;
      this.canvasWidth = availableWidth;
      this.canvasHeight = 180; // 减少60px，更紧凑
    } else if (isFullScreen) {
      // 全屏/大屏幕：充分利用空间
      const availableWidth = Math.min(this.ak.windowWidth - 48, 400);
      this.canvasWidth = availableWidth;
      this.canvasHeight = 220; // 减少40px，但相对较大
    } else {
      // 中等屏幕：固定宽度，紧凑高度
      this.canvasWidth = 280; // 略微减小
      this.canvasHeight = 200; // 减少60px，更紧凑
    }

    // 重新绘制图表
    this.drawStatisticsChart();
  }

  // 获取布局配置 - 优化版本（减少垂直间距）
  private getLayoutConfig(): LayoutConfig {
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    const isFullScreen = this.ak.windowWidthBreakpoint >= 3; // 大屏幕或全屏模式
    
    if (isSmallScreen) {
      // 小屏幕：紧凑布局
      const margin: MarginConfig = {
        top: 25,    // 减少20px
        right: 10,
        bottom: 50, // 减少30px
        left: 35    // 减少10px
      };
      const fontSize: FontSizeConfig = {
        title: 14,  // 减小字体
        axis: 11,
        stats: 12,
        small: 9
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 100,  // 减少20px
        statsHeight: 45,   // 减少15px
        fontSize: fontSize
      };
      return layout;
    } else if (isFullScreen) {
      // 全屏/大屏幕：充分利用空间
      const margin: MarginConfig = {
        top: 35,    // 相对较小的固定边距
        right: 25,
        bottom: 65, // 减少25px
        left: 45
      };
      const fontSize: FontSizeConfig = {
        title: 18,
        axis: 14,
        stats: 15,  // 略微减小
        small: 11
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 150,  // 增加10px以利用空间
        statsHeight: 60,   // 减少10px
        fontSize: fontSize
      };
      return layout;
    } else {
      // 中等屏幕：平衡布局
      const margin: MarginConfig = {
        top: 30,    // 减少20px
        right: 15,
        bottom: 55, // 减少35px
        left: 40    // 减少10px
      };
      const fontSize: FontSizeConfig = {
        title: 16,  // 略微减小
        axis: 13,
        stats: 14,
        small: 10
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 120,  // 减少20px
        statsHeight: 55,   // 减少15px
        fontSize: fontSize
      };
      return layout;
    }
  }

  // 绘制统计图表
  private drawStatisticsChart(): void {
    if (!this.canvasContext) {
      return;
    }

    console.debug(`[统计图表] 开始绘制: 画布尺寸=${this.canvasWidth}x${this.canvasHeight}`);

    // 清除画布
    this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制背景
    this.drawBackground();

    // 绘制直方图
    this.drawHistogram();

    // 绘制统计指标（在直方图下方）
    this.drawStatisticsInfo();

    console.debug(`[统计图表] 绘制完成`);
  }

  // 绘制背景
  private drawBackground(): void {
    const ctx = this.canvasContext;

    // 绘制背景矩形
    ctx.fillStyle = '#ff191a1c';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制边框
    ctx.strokeStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.lineWidth = 1;
    ctx.strokeRect(0, 0, this.canvasWidth, this.canvasHeight);
  }

  // 绘制直方图
  private drawHistogram(): void {
    const ctx = this.canvasContext;
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;
    const layout = this.getLayoutConfig();

    if (distribution.length === 0) {
      return;
    }

    const chartWidth = this.canvasWidth - layout.margin.left - layout.margin.right;
    const barCount = distribution.length;
    const barWidth = chartWidth / barCount;
    const maxCount = Math.max(...distribution, 1); // 避免除零

    // 绘制网格
    this.drawGrid(ctx, layout, chartWidth);

    // 绘制直方图柱子
    for (let i = 0; i < barCount; i++) {
      const barHeight = (distribution[i] / maxCount) * layout.chartHeight * 0.8;
      const x = layout.margin.left + i * barWidth;
      const y = layout.margin.top + layout.chartHeight - barHeight;

      // 根据分贝区间设置不同颜色
      let barColor: string = '#4CAF50'; // 低分贝 - 绿色
      if (i >= 6) {
        barColor = '#FF9800';
      } // 中高分贝 - 橙色
      if (i >= 8) {
        barColor = '#F44336';
      } // 高分贝 - 红色

      // 绘制柱子
      ctx.fillStyle = barColor;
      ctx.fillRect(x + 2, y, barWidth - 4, barHeight);

      // 绘制柱子边框
      ctx.strokeStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
      ctx.lineWidth = 1;
      ctx.strokeRect(x + 2, y, barWidth - 4, barHeight);

      // 绘制计数标签（如果计数大于0）- 优化位置
      if (distribution[i] > 0) {
        ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
        ctx.font = `${this.vp2px(layout.fontSize.small)}px sans-serif`;
        ctx.textAlign = 'center';
        ctx.fillText(distribution[i].toString(), x + barWidth / 2, y - this.vp2px(4)); // 减少2vp
      }

      // 绘制分贝区间标签 - 优化位置（减少间距）
      ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
      ctx.font = `${this.vp2px(layout.fontSize.axis)}px sans-serif`;
      ctx.textAlign = 'center';
      const dbRange: string = i === 10 ? '100+' : `${i * 10}`;
      ctx.fillText(dbRange, x, layout.margin.top + layout.chartHeight + this.vp2px(10)); // 减少5vp
    }

    // 绘制坐标轴标签
    this.drawAxisLabels(ctx, layout, chartWidth);
  }

  // 绘制网格
  private drawGrid(ctx: CanvasRenderingContext2D, layout: LayoutConfig, chartWidth: number): void {
    ctx.strokeStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.lineWidth = 0.5;

    // 水平网格线
    for (let i = 0; i <= 5; i++) {
      const y = layout.margin.top + (layout.chartHeight / 5) * i;
      ctx.beginPath();
      ctx.moveTo(layout.margin.left, y);
      ctx.lineTo(layout.margin.left + chartWidth, y);
      ctx.stroke();
    }

    // 垂直网格线
    for (let i = 0; i <= 10; i++) {
      const x = layout.margin.left + (chartWidth / 10) * i;
      ctx.beginPath();
      ctx.moveTo(x, layout.margin.top);
      ctx.lineTo(x, layout.margin.top + layout.chartHeight);
      ctx.stroke();
    }
  }

  // 绘制坐标轴标签
  private drawAxisLabels(ctx: CanvasRenderingContext2D, layout: LayoutConfig, chartWidth: number): void {
    // 绘制Y轴标签
    ctx.save();
    ctx.translate(this.vp2px(15), layout.margin.top + layout.chartHeight / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = `${this.vp2px(layout.fontSize.axis)}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('出现次数', 0, 0);
    ctx.restore();

    // 绘制X轴标签 - 优化位置（减少间距）
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = `${this.vp2px(layout.fontSize.axis)}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('分贝区间 (dB)', this.canvasWidth / 2, layout.margin.top + layout.chartHeight + this.vp2px(25)); // 减少10vp
  }

  // 绘制统计指标 - 优化版本（紧凑布局）
  private drawStatisticsInfo(): void {
    const ctx = this.canvasContext;
    const stats = this.ak.uiDisplayState.displayStatistics;
    const layout = this.getLayoutConfig();

    // 减少统计指标起始位置的距离
    const statsStartY = layout.margin.top/2 + layout.chartHeight + this.vp2px(25); // 减少25vp
    
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.textAlign = 'center';

    // 绘制统计信息标题
    ctx.font = `bold ${this.vp2px(layout.fontSize.stats)}px sans-serif`;
    ctx.fillText('统计指标', this.canvasWidth / 2, statsStartY);

    // 绘制具体统计值 - 紧凑排列
    ctx.font = `${this.vp2px(layout.fontSize.stats)}px sans-serif`;
    
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    const isFullScreen = this.ak.windowWidthBreakpoint >= 3;
    
    if (isSmallScreen) {
      // 小屏幕：紧凑两行显示，减少行间距
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB`, this.canvasWidth / 4, statsStartY + this.vp2px(12)); // 减少8vp
      ctx.fillText(`最大值: ${stats.maxDb.toFixed(1)} dB`, this.canvasWidth * 3 / 4, statsStartY + this.vp2px(12));
      ctx.fillText(`最小值: ${stats.minDb.toFixed(1)} dB`, this.canvasWidth / 4, statsStartY + this.vp2px(24)); // 减少16vp
      ctx.fillText(`标准差: ${stdDev.toFixed(1)} dB`, this.canvasWidth * 3 / 4, statsStartY + this.vp2px(24));
    } else if (isFullScreen) {
      // 全屏模式：两行紧凑显示，充分利用空间
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB | 最大值: ${stats.maxDb.toFixed(1)} dB`,
                   this.canvasWidth / 2, statsStartY + this.vp2px(15));
      ctx.fillText(`最小值: ${stats.minDb.toFixed(1)} dB | 标准差: ${stdDev.toFixed(1)} dB`,
                   this.canvasWidth / 2, statsStartY + this.vp2px(30));
    } else {
      // 中等屏幕：单行紧凑显示
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB | 最大值: ${stats.maxDb.toFixed(1)} dB | 最小值: ${stats.minDb.toFixed(1)} dB | 标准差: ${stdDev.toFixed(1)} dB`,
                   this.canvasWidth / 2, statsStartY + this.vp2px(15)); // 减少5vp
    }
  }

  // 计算标准差（简化版本）
  private calculateStandardDeviation(): number {
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;
    if (distribution.length === 0 || distribution.reduce((a, b) => a + b, 0) === 0) {
      return 0;
    }

    // 计算加权平均值
    let weightedSum = 0;
    let totalCount = 0;
    for (let i = 0; i < distribution.length; i++) {
      const midValue = i * 10 + 5; // 使用区间中值
      weightedSum += midValue * distribution[i];
      totalCount += distribution[i];
    }

    const mean = weightedSum / totalCount;

    // 计算方差
    let variance = 0;
    for (let i = 0; i < distribution.length; i++) {
      const midValue = i * 10 + 5;
      variance += Math.pow(midValue - mean, 2) * distribution[i];
    }
    variance /= totalCount;

    return Math.sqrt(variance);
  }

  @Builder
  StatisticsChart() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 图表容器
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#ff191a1c')
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .shadow(DesignConstants.SHADOW_SM)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          // 响应式尺寸调整
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          this.drawStatisticsChart();
        })
        .onReady(() => {
          this.drawStatisticsChart();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_MD)
  }

  build() {
    this.StatisticsChart()
  }

  /**
   * 虚拟像素转物理像素
   */
  private vp2px(vp: number): number {
    return vp2px(vp);
  }
}