import { DecibelService } from '../../services/DecibelService'
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioPlayer } from '../business/AudioPlayer';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType } from '../common/charts/ChartConfig';
import { DesignConstants } from '../../constants/DesignConstants';
import { resourceManager } from '@kit.LocalizationKit';

interface StandardLine {
  value: number;
  label: string;
  color: string;
}

/**
 * 噪音趋势图组件 V2
 * 使用 BaseChartComponent，浅色主题，标准参考线
 */
@ComponentV2
export struct NoiseChartV2 {
  @Param selectedRecord: DecibelRecord | null = null;
  private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  // 标准线配置
  private readonly STANDARD_LINES: StandardLine[] = [
    { value: 55, label: '居住区', color: '#4CAF50' },
    { value: 60, label: '商业区', color: '#FFC107' },
    { value: 70, label: '工业区', color: '#FF9800' },
    { value: 75, label: '交通干线', color: '#F44336' }
  ];

  @Computed
  get hasAudio(): boolean {
    return !!this.selectedRecord?.audioFilePath;
  }

  @Computed
  get hasData(): boolean {
    return (this.selectedRecord?.decibelValues?.length ?? 0) > 0;
  }

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: { top: 30, right: 60, bottom: 40, left: 40 },
      aspectRatio: 2.0,
      backgroundColor: '#00000000',
      gridColor: '#33000000',
      textColor: '#666666',
      fontSize: { title: 14, axis: 10, label: 9, small: 8 },
      chartType: ChartType.TIME_DOMAIN,
      responsive: true
    };
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题和音频播放器
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_meter'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('音量变化趋势')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()

        // 音频播放器（如果有）
        if (this.hasAudio) {
          AudioPlayer({
            audioFilePath: this.selectedRecord!.audioFilePath!,
            compact: true
          })
        }
      }
      .width('100%')

      // 图表区域
      if (!this.hasData) {
        Column({ space: DesignConstants.SPACING_MD }) {
          Image($r('app.media.ic_empty'))
            .width(48)
            .height(48)
            .fillColor($r('sys.color.font_tertiary'))
          Text('暂无数据')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      } else {
        Column({ space: DesignConstants.SPACING_SM }) {
          // 图表
          BaseChartComponent({
            chartConfig: this.chartConfig,
            onDrawChart: (ctx, width, height) => this.drawChart(ctx, width, height)
          })

          // 标准线图例
          this.StandardLegend()
        }
        .width('100%')
      }

      // 关键数据点
      if (this.hasData) {
        this.KeyDataPoints()
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  StandardLegend() {
    Scroll() {
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.STANDARD_LINES, (line: StandardLine, index) => {
          Row({ space: DesignConstants.SPACING_XS }) {
            Circle()
              .width(8)
              .height(8)
              .fill(line.color)
            Text(`${line.label} ${line.value}dB`)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_secondary'))
          }
        })
      }
    }
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
  }

  @Builder
  KeyDataPoints() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 最高音量点
      this.DataPointCard(
        '最高音量',
        `${this.selectedRecord!.maxDecibel}`,
        'dB',
        `检测后${Math.round(parseFloat(this.getPeakTime()))}秒`
      )

      // 平均音量点
      this.DataPointCard(
        '平均音量',
        `${this.selectedRecord!.avgDecibel.toFixed(1)}`,
        'dB',
        '全程平均'
      )
    }
    .width('100%')
  }

  @Builder
  DataPointCard(label: string, value: string, unit: string, time: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))
      
      Row({ space: 2 }) {
        Text(value)
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
        Text(unit)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 4 })
      }
      
      Text(time)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_tertiary'))
    }
    .layoutWeight(1)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .alignItems(HorizontalAlign.Center)
  }

  private drawChart(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    const values = this.selectedRecord!.decibelValues;
    const totalSeconds = this.selectedRecord!.duration;
    const maxValue = Math.max(...values, 80);
    const minValue = Math.min(...values, 30);

    const margin = this.chartConfig.margin;
    const chartWidth = width - margin.left - margin.right;
    const chartHeight = height - margin.top - margin.bottom;

    // 绘制标准虚线
    ctx.setLineDash([5, 5]);
    ctx.lineWidth = 1;
    
    this.STANDARD_LINES.forEach(line => {
      if (line.value >= minValue && line.value <= maxValue) {
        const y = margin.top + chartHeight - ((line.value - minValue) / (maxValue - minValue)) * chartHeight;
        
        ctx.beginPath();
        ctx.moveTo(margin.left, y);
        ctx.lineTo(margin.left + chartWidth, y);
        ctx.strokeStyle = line.color;
        ctx.stroke();

        // 标签
        ctx.fillStyle = line.color;
        ctx.textAlign = 'left';
        ctx.font = `${vp2px(9)}px sans-serif`;
        ctx.fillText(`${line.label} ${line.value}dB`, margin.left + chartWidth + 4, y);
      }
    });

    ctx.setLineDash([]);

    // 绘制网格线
    ctx.strokeStyle = this.chartConfig.gridColor;
    ctx.lineWidth = 0.5;

    // Y轴网格线和标签
    const ySteps = 5;
    ctx.textAlign = 'right';
    ctx.fillStyle = this.chartConfig.textColor;
    ctx.font = `${vp2px(10)}px sans-serif`;
    
    for (let i = 0; i <= ySteps; i++) {
      const y = margin.top + (chartHeight / ySteps) * i;
      const value = maxValue - ((maxValue - minValue) / ySteps) * i;
      
      ctx.beginPath();
      ctx.moveTo(margin.left, y);
      ctx.lineTo(margin.left + chartWidth, y);
      ctx.stroke();

      ctx.fillText(`${Math.round(value)}`, margin.left - 6, y);
    }

    // X轴标签
    const xSteps = Math.min(6, values.length);
    ctx.textAlign = 'center';
    
    for (let i = 0; i < xSteps; i++) {
      const x = margin.left + (chartWidth / (xSteps - 1)) * i;
      const seconds = Math.round((totalSeconds / (xSteps - 1)) * i);
      
      ctx.fillText(`${seconds}s`, x, margin.top + chartHeight + 15);
    }

    // 绘制数据曲线
    const xScale = chartWidth / (values.length - 1);
    const yScale = chartHeight / (maxValue - minValue);

    // 填充区域
    ctx.beginPath();
    ctx.moveTo(margin.left, margin.top + chartHeight);
    
    values.forEach((value, index) => {
      const x = margin.left + index * xScale;
      const y = margin.top + chartHeight - (value - minValue) * yScale;
      
      if (index === 0) {
        ctx.lineTo(x, y);
      } else {
        // 贝塞尔曲线平滑
        const prevX = margin.left + (index - 1) * xScale;
        const prevY = margin.top + chartHeight - (values[index - 1] - minValue) * yScale;
        const cpX = (prevX + x) / 2;
        ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y);
      }
    });

    ctx.lineTo(margin.left + chartWidth, margin.top + chartHeight);
    ctx.closePath();
    
    // 渐变填充
    const gradient = ctx.createLinearGradient(0, margin.top, 0, margin.top + chartHeight);
    gradient.addColorStop(0, 'rgba(24, 144, 255, 0.3)');
    gradient.addColorStop(1, 'rgba(24, 144, 255, 0.05)');
    ctx.fillStyle = gradient;
    ctx.fill();

    // 绘制数据线
    ctx.beginPath();
    ctx.strokeStyle = '#1890FF';
    ctx.lineWidth = 2;
    
    values.forEach((value, index) => {
      const x = margin.left + index * xScale;
      const y = margin.top + chartHeight - (value - minValue) * yScale;
      
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        const prevX = margin.left + (index - 1) * xScale;
        const prevY = margin.top + chartHeight - (values[index - 1] - minValue) * yScale;
        const cpX = (prevX + x) / 2;
        ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y);
      }
    });
    ctx.stroke();

    // 标记峰值点
    const maxIndex = values.indexOf(Math.max(...values));
    const maxX = margin.left + maxIndex * xScale;
    const maxY = margin.top + chartHeight - (values[maxIndex] - minValue) * yScale;
    
    ctx.beginPath();
    ctx.arc(maxX, maxY, 5, 0, Math.PI * 2);
    ctx.fillStyle = '#F44336';
    ctx.fill();
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 2;
    ctx.stroke();
  }

  private getPeakTime(): string {
    const values = this.selectedRecord?.decibelValues ?? [];
    const maxIndex = values.indexOf(Math.max(...values));
    const totalDuration = this.selectedRecord?.duration ?? 0;
    return ((maxIndex / (values.length - 1)) * totalDuration).toFixed(1);
  }
}
