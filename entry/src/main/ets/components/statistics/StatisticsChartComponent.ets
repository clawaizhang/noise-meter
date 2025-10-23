/**
 * 实时统计图组件
 * 用于显示分贝值的实时统计分布直方图和关键统计指标
 * 遵循双管线数据架构，使用Monitor监测数据变化
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';

// 边距配置接口
interface MarginConfig {
  top: number;
  right: number;
  bottom: number;
  left: number;
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

  // 计算Canvas尺寸（响应式布局）
  private calculateCanvasDimensions(): void {
    const widthBp = this.ak.windowWidthBreakpoint;

    if (widthBp <= 1) { // XS/SM断点
      // 小屏幕：占满宽度
      this.canvasWidth = this.ak.windowWidth - 32;
      this.canvasHeight = 200;
    } else {
      // 中等及以上屏幕：固定宽度
      this.canvasWidth = 280;
      this.canvasHeight = 200;
    }

    // 重新绘制图表
    this.drawStatisticsChart();
  }

  // 绘制统计图表
  private drawStatisticsChart(): void {
    if (!this.canvasContext) {
      return;
    }

    console.debug(`[统计图表] 开始绘制: 画布尺寸=${this.canvasWidth}x${this.canvasHeight}, 分布数据长度=${this.ak.uiDisplayState.displayStatisticsDistribution.length}, 统计数据=${JSON.stringify({
      avg: this.ak.uiDisplayState.displayStatistics.avgDb,
      max: this.ak.uiDisplayState.displayStatistics.maxDb,
      min: this.ak.uiDisplayState.displayStatistics.minDb,
      duration: this.ak.uiDisplayState.displayStatistics.duration
    })}`);

    // 清除画布
    this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制背景
    this.drawBackground();

    // 绘制直方图
    this.drawHistogram();

    // 绘制统计指标
    this.drawStatisticsInfo();

    // 绘制标题和坐标轴
    this.drawTitleAndAxes();

    console.debug(`[统计图表] 绘制完成`);
  }

  // 绘制背景
  private drawBackground(): void {
    const ctx = this.canvasContext;

    // 绘制背景矩形 - 使用与其他图表一致的深色背景
    ctx.fillStyle = '#ff191a1c'; // 使用与频谱图相同的背景色
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制边框 - 使用与其他图表一致的边框颜色
    ctx.strokeStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.lineWidth = 1;
    ctx.strokeRect(0, 0, this.canvasWidth, this.canvasHeight);
  }

  // 绘制直方图
  private drawHistogram(): void {
    const ctx = this.canvasContext;
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;

    if (distribution.length === 0) {
      return;
    }

    const margin: MarginConfig = {
      top: 40,
      right: 20,
      bottom: 60,
      left: 50
    };
    const chartWidth = this.canvasWidth - margin.left - margin.right;
    const chartHeight = this.canvasHeight - margin.top - margin.bottom;
    const barCount = distribution.length;
    const barWidth = chartWidth / barCount;
    const maxCount = Math.max(...distribution, 1); // 避免除零

    // 绘制网格
    this.drawGrid(ctx, margin, chartWidth, chartHeight);

    // 绘制直方图柱子
    for (let i = 0; i < barCount; i++) {
      const barHeight = (distribution[i] / maxCount) * chartHeight * 0.8;
      const x = margin.left + i * barWidth;
      const y = margin.top + chartHeight - barHeight;

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
      ctx.strokeStyle =
        this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
      ctx.lineWidth = 1;
      ctx.strokeRect(x + 2, y, barWidth - 4, barHeight);

      // 绘制计数标签（如果计数大于0）
      if (distribution[i] > 0) {
        ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
        ctx.font = '10px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(distribution[i].toString(), x + barWidth / 2, y - 5);
      }

      // 绘制分贝区间标签
      ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'center';
      const dbRange: string = i === 10 ? '100+' : `${i * 10}-${(i + 1) * 10}`;
      ctx.fillText(dbRange, x + barWidth / 2, this.canvasHeight - margin.bottom + 15);
    }
  }

  // 绘制网格
  private drawGrid(ctx: CanvasRenderingContext2D, margin: MarginConfig, chartWidth: number, chartHeight: number): void {
    ctx.strokeStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.lineWidth = 0.5;

    // 水平网格线
    for (let i = 0; i <= 5; i++) {
      const y = margin.top + (chartHeight / 5) * i;
      ctx.beginPath();
      ctx.moveTo(margin.left, y);
      ctx.lineTo(margin.left + chartWidth, y);
      ctx.stroke();
    }

    // 垂直网格线
    for (let i = 0; i <= 10; i++) {
      const x = margin.left + (chartWidth / 10) * i;
      ctx.beginPath();
      ctx.moveTo(x, margin.top);
      ctx.lineTo(x, margin.top + chartHeight);
      ctx.stroke();
    }
  }

  // 绘制统计指标
  private drawStatisticsInfo(): void {
    const ctx = this.canvasContext;
    const stats = this.ak.uiDisplayState.displayStatistics;

    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'left';

    // 绘制统计信息标题
    ctx.font = 'bold 14px sans-serif';
    ctx.fillText('统计指标', 10, 20);

    // 绘制具体统计值
    ctx.font = '12px sans-serif';
    ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB`, 10, 40);
    ctx.fillText(`最大值: ${stats.maxDb.toFixed(1)} dB`, 10, 60);
    ctx.fillText(`最小值: ${stats.minDb.toFixed(1)} dB`, 10, 80);

    // 计算标准差（简化版本）
    const stdDev = this.calculateStandardDeviation();
    ctx.fillText(`标准差: ${stdDev.toFixed(1)} dB`, 10, 100);

    // 绘制持续时间
    ctx.fillText(`时长: ${stats.duration.toFixed(1)}s`, 10, 120);
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

  // 绘制标题和坐标轴
  private drawTitleAndAxes(): void {
    const ctx = this.canvasContext;
    const margin: MarginConfig = {
      top: 40,
      right: 20,
      bottom: 60,
      left: 50
    };

    // 绘制标题
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = 'bold 16px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('分贝值分布统计', this.canvasWidth / 2, 25);

    // 绘制Y轴标签
    ctx.save();
    ctx.translate(15, this.canvasHeight / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('出现次数', 0, 0);
    ctx.restore();

    // 绘制X轴标签
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('分贝区间 (dB)', this.canvasWidth / 2, this.canvasHeight - 10);
  }

  @Builder
  StatisticsChart() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 图表容器 - 使用与其他图表一致的背景色
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#ff191a1c') // 使用与频谱图相同的背景色
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
}