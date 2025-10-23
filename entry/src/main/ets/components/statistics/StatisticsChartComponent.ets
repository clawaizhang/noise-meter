/**
 * 实时统计图组件 - 基于BaseChartComponent重构版本
 * 采用垂直分离布局，避免内容重叠，优化响应式设计
 * 遵循双管线数据架构，使用Monitor监测数据变化
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';

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
  
  // 依赖注入
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: DefaultChartConfig.margin,
      aspectRatio: 1.2, // 统计图表需要更高的宽高比来容纳统计信息
      backgroundColor: DefaultChartConfig.backgroundColor,
      gridColor: DefaultChartConfig.gridColor,
      textColor: DefaultChartConfig.textColor,
      fontSize: DefaultChartConfig.fontSize,
      chartType: ChartType.STATISTICS,
      responsive: DefaultChartConfig.responsive
    };
  }

  // 获取布局配置 - 适配BaseChartComponent版本
  private getLayoutConfig(canvasWidth: number, canvasHeight: number): LayoutConfig {
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    const isFullScreen = this.ak.windowWidthBreakpoint >= 3;
    
    if (isSmallScreen) {
      // 小屏幕：紧凑布局
      const margin: MarginConfig = {
        top: 25,
        right: 10,
        bottom: 50,
        left: 35
      };
      const fontSize: FontSizeConfig = {
        title: 14,
        axis: 11,
        stats: 12,
        small: 9
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 100,
        statsHeight: 45,
        fontSize: fontSize
      };
      return layout;
    } else if (isFullScreen) {
      // 全屏/大屏幕：充分利用空间
      const margin: MarginConfig = {
        top: 35,
        right: 25,
        bottom: 65,
        left: 45
      };
      const fontSize: FontSizeConfig = {
        title: 18,
        axis: 14,
        stats: 15,
        small: 11
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 150,
        statsHeight: 60,
        fontSize: fontSize
      };
      return layout;
    } else {
      // 中等屏幕：平衡布局
      const margin: MarginConfig = {
        top: 30,
        right: 15,
        bottom: 55,
        left: 40
      };
      const fontSize: FontSizeConfig = {
        title: 16,
        axis: 13,
        stats: 14,
        small: 10
      };
      const layout: LayoutConfig = {
        margin: margin,
        chartHeight: 120,
        statsHeight: 55,
        fontSize: fontSize
      };
      return layout;
    }
  }

  // 统计分布图绘制函数 - 适配BaseChartComponent
  private drawStatisticsChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    console.debug(`[统计图表] 开始绘制: 画布尺寸=${canvasWidth}x${canvasHeight}`);

    // 绘制直方图
    this.drawHistogram(ctx, canvasWidth, canvasHeight);

    // 绘制统计指标（在直方图下方）
    this.drawStatisticsInfo(ctx, canvasWidth, canvasHeight);

    console.debug(`[统计图表] 绘制完成`);
  }


  // 绘制直方图
  private drawHistogram(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;
    const layout = this.getLayoutConfig(canvasWidth, canvasHeight);

    if (distribution.length === 0) {
      return;
    }

    const chartWidth = canvasWidth - layout.margin.left - layout.margin.right;
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
    ctx.fillText('分贝区间 (dB)', this.canvasWidthInput / 2, layout.margin.top + layout.chartHeight + this.vp2px(25));
  }

  // 绘制统计指标 - 适配BaseChartComponent版本
  private drawStatisticsInfo(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    const stats = this.ak.uiDisplayState.displayStatistics;
    const layout = this.getLayoutConfig(canvasWidth, canvasHeight);

    // 减少统计指标起始位置的距离
    const statsStartY = layout.margin.top/2 + layout.chartHeight + this.vp2px(25); // 减少25vp
    
    ctx.fillStyle = this.sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    ctx.textAlign = 'center';

    // 绘制统计信息标题
    ctx.font = `bold ${this.vp2px(layout.fontSize.stats)}px sans-serif`;
    ctx.fillText('统计指标', canvasWidth / 2, statsStartY);

    // 绘制具体统计值 - 紧凑排列
    ctx.font = `${this.vp2px(layout.fontSize.stats)}px sans-serif`;
    
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    const isFullScreen = this.ak.windowWidthBreakpoint >= 3;
    
    if (isSmallScreen) {
      // 小屏幕：紧凑两行显示，减少行间距
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB`, canvasWidth / 4, statsStartY + this.vp2px(12));
      ctx.fillText(`最大值: ${stats.maxDb.toFixed(1)} dB`, canvasWidth * 3 / 4, statsStartY + this.vp2px(12));
      ctx.fillText(`最小值: ${stats.minDb.toFixed(1)} dB`, canvasWidth / 4, statsStartY + this.vp2px(24));
      ctx.fillText(`标准差: ${stdDev.toFixed(1)} dB`, canvasWidth * 3 / 4, statsStartY + this.vp2px(24));
    } else if (isFullScreen) {
      // 全屏模式：两行紧凑显示，充分利用空间
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB | 最大值: ${stats.maxDb.toFixed(1)} dB`,
                   canvasWidth / 2, statsStartY + this.vp2px(15));
      ctx.fillText(`最小值: ${stats.minDb.toFixed(1)} dB | 标准差: ${stdDev.toFixed(1)} dB`,
                   canvasWidth / 2, statsStartY + this.vp2px(30));
    } else {
      // 中等屏幕：单行紧凑显示
      const stdDev = this.calculateStandardDeviation();
      ctx.fillText(`平均值: ${stats.avgDb.toFixed(1)} dB | 最大值: ${stats.maxDb.toFixed(1)} dB | 最小值: ${stats.minDb.toFixed(1)} dB | 标准差: ${stdDev.toFixed(1)} dB`,
                   canvasWidth / 2, statsStartY + this.vp2px(15));
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

  build() {
    // 使用基础图表组件，传入统计分布图特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawStatisticsChart(ctx, width, height);
      }
    })
  }

  /**
   * 虚拟像素转物理像素
   */
  private vp2px(vp: number): number {
    return vp2px(vp);
  }
}