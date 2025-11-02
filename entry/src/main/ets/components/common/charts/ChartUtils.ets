/**
 * 图表工具类
 * 提供通用的图表绘制工具方法
 */

import { resourceManager } from '@kit.LocalizationKit';
import { MarginConfig, FontSizeConfig } from './ChartConfig';

// 图表区域接口
export interface ChartArea {
  width: number;
  height: number;
}

/**
 * 图表绘制工具类
 */
export class ChartUtils {
  /**
   * 虚拟像素转物理像素
   */
  static vp2px(vp: number): number {
    // 这是一个简化的转换，实际项目中应该使用系统提供的转换函数
    return Math.round(vp * 2); // 假设2倍缩放
  }

  /**
   * 绘制文本
   */
  static drawText(
    ctx: CanvasRenderingContext2D,
    text: string,
    x: number,
    y: number,
    fontSize: number,
    color: string,
    align: CanvasTextAlign = 'left',
    baseline: CanvasTextBaseline = 'alphabetic'
  ): void {
    ctx.save();
    ctx.fillStyle = color;
    ctx.font = `${vp2px(fontSize)}px sans-serif`;
    ctx.textAlign = align;
    ctx.textBaseline = baseline;
    ctx.fillText(text, x, y);
    ctx.restore();
  }

  /**
   * 绘制水平网格线
   */
  static drawHorizontalGridLines(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    margin: MarginConfig,
    lineCount: number,
    color: string
  ): void {
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 0.5;

    const chartHeight = canvasHeight - margin.top - margin.bottom;
    const step = chartHeight / lineCount;

    for (let i = 1; i < lineCount; i++) {
      const y = margin.top + step * i;
      ctx.beginPath();
      ctx.moveTo(margin.left, y);
      ctx.lineTo(canvasWidth - margin.right, y);
      ctx.stroke();
    }

    ctx.restore();
  }

  /**
   * 绘制垂直网格线
   */
  static drawVerticalGridLines(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    margin: MarginConfig,
    lineCount: number,
    color: string
  ): void {
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 0.5;

    const chartWidth = canvasWidth - margin.left - margin.right;
    const step = chartWidth / lineCount;

    for (let i = 1; i < lineCount; i++) {
      const x = margin.left + step * i;
      ctx.beginPath();
      ctx.moveTo(x, margin.top);
      ctx.lineTo(x, canvasHeight - margin.bottom);
      ctx.stroke();
    }

    ctx.restore();
  }

  /**
   * 绘制背景
   */
  static drawBackground(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    backgroundColor: string,
    borderColor?: string
  ): void {
    ctx.save();
    
    // 绘制背景
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, canvasWidth, canvasHeight);

    // 绘制边框（如果提供了边框颜色）
    if (borderColor) {
      ctx.strokeStyle = borderColor;
      ctx.lineWidth = 1;
      ctx.strokeRect(0, 0, canvasWidth, canvasHeight);
    }

    ctx.restore();
  }

  /**
   * 数值归一化
   */
  static normalizeValue(
    value: number,
    min: number,
    max: number,
    outputMin: number = 0,
    outputMax: number = 1
  ): number {
    if (max === min) return outputMin;
    return ((value - min) / (max - min)) * (outputMax - outputMin) + outputMin;
  }

  /**
   * 对数坐标映射
   */
  static logScale(
    value: number,
    logMin: number,
    logMax: number,
    outputMin: number,
    outputMax: number
  ): number {
    const logValue = Math.log10(value);
    return ((logValue - logMin) / (logMax - logMin)) * (outputMax - outputMin) + outputMin;
  }

  /**
   * 获取系统颜色
   */
  static getSystemColor(
    sysResourceManager: resourceManager.ResourceManager,
    colorResource: Resource
  ): string {
    try {
      return sysResourceManager.getColorSync(colorResource.id).toString();
    } catch (error) {
      console.warn(`[ChartUtils] 获取系统颜色失败: ${error}, 使用默认颜色`);
      return '#ffffffff';
    }
  }

  /**
   * 格式化频率显示
   */
  static formatFrequency(freq: number): string {
    if (freq >= 1000) {
      return freq === 1000 ? '1k' : `${(freq / 1000).toFixed(1)}k`;
    }
    return freq.toString();
  }

  /**
   * 格式化分贝显示
   */
  static formatDecibel(db: number): string {
    return `${Math.round(db)} dB`;
  }

  /**
   * 计算图表绘制区域
   */
  static calculateChartArea(
    canvasWidth: number,
    canvasHeight: number,
    margin: MarginConfig
  ): ChartArea {
    return {
      width: canvasWidth - margin.left - margin.right,
      height: canvasHeight - margin.top - margin.bottom
    };
  }

  /**
   * 检查Canvas上下文有效性
   */
  static isValidCanvasContext(ctx: CanvasRenderingContext2D): boolean {
    return ctx !== null && ctx !== undefined;
  }

  /**
   * 清除画布
   */
  static clearCanvas(
    ctx: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number
  ): void {
    if (ChartUtils.isValidCanvasContext(ctx)) {
      ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    }
  }
}