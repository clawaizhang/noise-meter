/**
 * 频率响应曲线组件
 * 用于显示A/C/Z计权的频率响应曲线
 */

import { WeightingType } from '../../constants/WeightingConstants';
import { FrequencyWeightingConstants } from '../../constants/FrequencyWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct FrequencyResponseChartComponent {
  @Param @Require selectedWeighting: WeightingType; // 选中的计权类型

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  // 绘制频率响应曲线
  private drawFrequencyResponse() {
    const canvasWidth = 300;
    const canvasHeight = 160;
    const ctx = this.canvasContext;
    
    // 清除画布
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    
    // 设置背景
    ctx.fillStyle = '#1E1E1E';
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
    
    // 绘制网格
    this.drawGrid(ctx, canvasWidth, canvasHeight);
    
    // 绘制坐标轴
    this.drawAxes(ctx, canvasWidth, canvasHeight);
    
    // 绘制频率响应曲线
    this.drawResponseCurve(ctx, canvasWidth, canvasHeight);
    
    // 绘制图例
    this.drawLegend(ctx, canvasWidth, canvasHeight);
  }

  // 绘制网格
  private drawGrid(ctx: CanvasRenderingContext2D, width: number, height: number) {
    ctx.strokeStyle = '#333333';
    ctx.lineWidth = 0.5;
    
    // 水平网格线 (dB刻度)
    for (let i = -60; i <= 10; i += 10) {
      const y = this.dbToY(i, height);
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
      
      // 绘制dB刻度标签
      ctx.fillStyle = '#888888';
      ctx.font = '10px sans-serif';
      ctx.fillText(`${i}dB`, 5, y - 2);
    }
    
    // 垂直网格线 (频率刻度)
    const freqLabels = [20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000];
    for (const freq of freqLabels) {
      const x = this.freqToX(freq, width);
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
      
      // 绘制频率刻度标签
      ctx.fillStyle = '#888888';
      ctx.font = '10px sans-serif';
      let label = freq >= 1000 ? `${freq/1000}k` : `${freq}`;
      ctx.fillText(label, x - 10, height - 5);
    }
  }

  // 绘制坐标轴
  private drawAxes(ctx: CanvasRenderingContext2D, width: number, height: number) {
    ctx.strokeStyle = '#666666';
    ctx.lineWidth = 1;
    
    // X轴 (频率轴)
    ctx.beginPath();
    ctx.moveTo(0, height - 20);
    ctx.lineTo(width, height - 20);
    ctx.stroke();
    
    // Y轴 (dB轴)
    ctx.beginPath();
    ctx.moveTo(40, 0);
    ctx.lineTo(40, height);
    ctx.stroke();
    
    // 坐标轴标签
    ctx.fillStyle = '#CCCCCC';
    ctx.font = '12px sans-serif';
    ctx.fillText('频率 (Hz)', width / 2 - 30, height - 5);
    ctx.save();
    ctx.translate(15, height / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText('增益 (dB)', 0, 0);
    ctx.restore();
  }

  // 绘制响应曲线
  private drawResponseCurve(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const data = FrequencyWeightingConstants.FREQUENCY_RESPONSE_DATA[this.selectedWeighting];
    if (!data || data.length === 0) return;
    
    // 设置曲线颜色
    let curveColor = '#FF6B6B'; // A计权 - 红色
    if (this.selectedWeighting === WeightingType.C) {
      curveColor = '#4ECDC4'; // C计权 - 青色
    } else if (this.selectedWeighting === WeightingType.Z) {
      curveColor = '#45B7D1'; // Z计权 - 蓝色
    }
    
    ctx.strokeStyle = curveColor;
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    // 绘制曲线
    for (let i = 0; i < data.length; i++) {
      const point = data[i];
      const x = this.freqToX(point.freq, width);
      const y = this.dbToY(point.gain, height);
      
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    
    ctx.stroke();
    
    // 绘制数据点
    ctx.fillStyle = curveColor;
    for (let i = 0; i < data.length; i += 3) { // 每隔3个点绘制一个标记
      const point = data[i];
      const x = this.freqToX(point.freq, width);
      const y = this.dbToY(point.gain, height);
      ctx.beginPath();
      ctx.arc(x, y, 2, 0, 2 * Math.PI);
      ctx.fill();
    }
  }

  // 绘制图例
  private drawLegend(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const weightingName = FrequencyWeightingConstants.getWeightingDisplayName(this.selectedWeighting);
    
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 14px sans-serif';
    ctx.fillText(weightingName, width - 80, 20);
    
    // 绘制图例线
    let legendColor = '#FF6B6B';
    if (this.selectedWeighting === WeightingType.C) {
      legendColor = '#4ECDC4';
    } else if (this.selectedWeighting === WeightingType.Z) {
      legendColor = '#45B7D1';
    }
    
    ctx.strokeStyle = legendColor;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(width - 100, 18);
    ctx.lineTo(width - 85, 18);
    ctx.stroke();
  }

  // 频率转换为X坐标 (对数坐标)
  private freqToX(freq: number, width: number): number {
    const logMin = Math.log10(20);  // 20Hz
    const logMax = Math.log10(20000); // 20kHz
    const logFreq = Math.log10(freq);
    return 40 + (logFreq - logMin) / (logMax - logMin) * (width - 60);
  }

  // dB值转换为Y坐标
  private dbToY(db: number, height: number): number {
    const minDb = -60;
    const maxDb = 10;
    return 10 + (maxDb - db) / (maxDb - minDb) * (height - 30);
  }

  build() {
    Column() {
      Canvas(this.canvasContext)
        .width(300)
        .height(160)
        .backgroundColor('#1E1E1E')
        .borderRadius(8)
        .onReady(() => {
          this.drawFrequencyResponse();
        })
        .onAreaChange(() => {
          this.drawFrequencyResponse();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}