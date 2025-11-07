import { resourceManager } from '@kit.LocalizationKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { ChartUtils } from '../common/charts/ChartUtils';
import { PerformanceMonitor } from '../../utils/PerformanceMonitor';

// 瀑布图数据点接口
export interface WaterfallDataPoint {
  frequency: number;
  amplitude: number;
  timestamp: number;
}

// 瀑布图配置接口
export interface WaterfallConfig {
  maxHistoryLines: number;      // 最大历史行数
  colorMap: string[];           // 颜色映射表
  minDb: number;                 // 最小分贝值
  maxDb: number;                 // 最大分贝值
  fadeEffect: boolean;           // 是否启用渐变效果
  updateTime: number;            // 更新间隔(毫秒)
  targetFPS: number;             // 目标帧率
  enableOptimization: boolean;  // 是否启用优化
}

// 边距接口
export interface Margin {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

// 历史数据接口
export interface HistoryData {
  data: Float32Array[];
  timestamps: number[];
}

// 默认瀑布图配置
export const DefaultWaterfallConfig: WaterfallConfig = {
  maxHistoryLines: 100,
  colorMap: [
    '#000033', // 深蓝 (最低)
    '#000055',
    '#0000ff', // 蓝
    '#0055ff',
    '#00ffff', // 青
    '#55ff00', // 绿
    '#ffff00', // 黄
    '#ff5500', // 橙
    '#ff0000', // 红
    '#ffffff'  // 白 (最高)
  ],
  minDb: -20,
  maxDb: 120,
  fadeEffect: true,
  updateTime: 100,
  targetFPS: 15,  // 降低目标帧率，减少CPU负载
  enableOptimization: true  // 启用优化
};

// 瀑布图历史数据管理类
export class WaterfallHistoryManager {
  private historyData: Float32Array[] = [];
  private timestamps: number[] = [];
  private config: WaterfallConfig;
  private circularBufferIndex: number = 0;
  private isBufferFull: boolean = false;

  constructor(config: WaterfallConfig = DefaultWaterfallConfig) {
    this.config = config;
    // 预分配缓冲区
    this.historyData = new Array(this.config.maxHistoryLines);
    this.timestamps = new Array(this.config.maxHistoryLines);
  }

  /**
   * 添加新的频谱数据（优化版本）
   */
  addData(spectrumData: Float32Array): void {
    // 使用循环缓冲区，避免频繁的数组操作
    this.historyData[this.circularBufferIndex] = spectrumData.slice(); // 创建副本
    this.timestamps[this.circularBufferIndex] = Date.now();
    
    this.circularBufferIndex = (this.circularBufferIndex + 1) % this.config.maxHistoryLines;
    
    if (this.circularBufferIndex === 0) {
      this.isBufferFull = true;
    }
  }

  /**
   * 获取历史数据（优化版本）
   */
  getHistoryData(): HistoryData {
    const result: HistoryData = {
      data: [],
      timestamps: []
    };
    
    if (this.isBufferFull) {
      // 缓冲区已满，从当前索引开始获取数据
      for (let i = this.circularBufferIndex; i < this.config.maxHistoryLines; i++) {
        if (this.historyData[i]) {
          result.data.push(this.historyData[i]);
          result.timestamps.push(this.timestamps[i]);
        }
      }
    }
    
    // 添加从开始到当前索引的数据
    for (let i = 0; i < this.circularBufferIndex; i++) {
      if (this.historyData[i]) {
        result.data.push(this.historyData[i]);
        result.timestamps.push(this.timestamps[i]);
      }
    }
    
    return result;
  }

  /**
   * 清空历史数据
   */
  clear(): void {
    this.circularBufferIndex = 0;
    this.isBufferFull = false;
    // 重置数组元素但保留数组结构
    for (let i = 0; i < this.config.maxHistoryLines; i++) {
      this.historyData[i] = new Float32Array();
      this.timestamps[i] = 0;
    }
  }

  /**
   * 获取数据行数
   */
  getLineCount(): number {
    return this.isBufferFull ? this.config.maxHistoryLines : this.circularBufferIndex;
  }
}

// 瀑布图渲染器类
export class WaterfallRenderer {
  private lastRenderTime: number = 0;
  private frameInterval: number = 1000 / 15; // 默认15FPS
  private imageDataCache: ImageData | null = null;
  private colorCache: Map<string, string> = new Map();
  private performanceMonitor: PerformanceMonitor;
  
  constructor(config: WaterfallConfig) {
    this.frameInterval = 1000 / config.targetFPS;
    this.performanceMonitor = PerformanceMonitor.getInstance();
  }
  
  /**
   * 检查是否应该渲染新帧
   */
  private shouldRender(): boolean {
    const now = Date.now();
    if (now - this.lastRenderTime >= this.frameInterval) {
      this.lastRenderTime = now;
      return true;
    }
    return false;
  }
  
  /**
   * 获取缓存的颜色
   */
  getCachedColor(amplitude: number, alpha: number, config: WaterfallConfig): string {
    const key = `${amplitude.toFixed(2)}_${alpha.toFixed(2)}`;
    if (this.colorCache.has(key)) {
      return this.colorCache.get(key)!;
    }
    
    // 计算新颜色
    const normalizedValue = ChartUtils.normalizeValue(amplitude, config.minDb, config.maxDb, 0, 1);
    const colorIndex = Math.floor(normalizedValue * (config.colorMap.length - 1));
    const clampedIndex = Math.max(0, Math.min(colorIndex, config.colorMap.length - 1));
    const baseColor = config.colorMap[clampedIndex];
    const color = applyAlphaToColor(baseColor, alpha);
    
    // 缓存颜色（限制缓存大小）
    if (this.colorCache.size > 1000) {
      this.colorCache.clear();
    }
    this.colorCache.set(key, color);
    
    return color;
  }
  
  /**
   * 渲染瀑布图
   */
  render(
    canvasContext: CanvasRenderingContext2D,
    canvasWidth: number,
    canvasHeight: number,
    spectrumData: Float32Array,
    historyManager: WaterfallHistoryManager,
    frequencySteps: number[],
    fftSize: number,
    sampleRate: number,
    sysResourceManager: resourceManager.ResourceManager,
    config: WaterfallConfig = DefaultWaterfallConfig
  ): void {
    // 帧率控制
    if (config.enableOptimization && !this.shouldRender()) {
      return;
    }
    
    console.info(`[瀑布图渲染] 开始渲染，数据长度=${spectrumData.length}`);
    
    if (!canvasContext) {
      return;
    }

    // 添加当前数据到历史记录
    historyManager.addData(spectrumData);
    
    // 获取历史数据
    const historyDataResult = historyManager.getHistoryData();
    const historyData = historyDataResult.data;
    const timestamps = historyDataResult.timestamps;
    
    if (historyData.length === 0) {
      return;
    }

    // 清除画布
    canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);

    // 绘制背景
    ChartUtils.drawBackground(
      canvasContext,
      canvasWidth,
      canvasHeight,
      '#ff000000', // 黑色背景
      ChartUtils.getSystemColor(sysResourceManager, $r('sys.color.font_on_tertiary'))
    );

    // 计算绘制区域
    const margin: Margin = { top: 20, right: 40, bottom: 30, left: 35 };
    const chartWidth = canvasWidth - margin.left - margin.right;
    const chartHeight = canvasHeight - margin.top - margin.bottom;

    // 绘制频率轴标签
    drawFrequencyLabels(
      canvasContext,
      canvasWidth,
      canvasHeight,
      margin,
      frequencySteps,
      sampleRate,
      sysResourceManager
    );

    // 绘制时间轴标签
    drawTimeLabels(
      canvasContext,
      canvasWidth,
      canvasHeight,
      margin,
      timestamps,
      sysResourceManager
    );

    // 绘制瀑布图主体
    if (config.enableOptimization) {
      drawWaterfallBodyOptimized(
        canvasContext,
        chartWidth,
        chartHeight,
        margin,
        historyData,
        frequencySteps,
        fftSize,
        sampleRate,
        config,
        this
      );
    } else {
      drawWaterfallBody(
        canvasContext,
        chartWidth,
        chartHeight,
        margin,
        historyData,
        frequencySteps,
        fftSize,
        sampleRate,
        config
      );
    }

    // 绘制颜色标尺
    drawColorScale(
      canvasContext,
      canvasWidth,
      canvasHeight,
      margin,
      config,
      sysResourceManager
    );
  }
}

// 全局渲染器实例
let globalWaterfallRenderer: WaterfallRenderer | null = null;

/**
 * 绘制瀑布图（保持向后兼容）
 */
export function drawWaterfall(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  spectrumData: Float32Array,
  historyManager: WaterfallHistoryManager,
  frequencySteps: number[],
  fftSize: number,
  sampleRate: number,
  sysResourceManager: resourceManager.ResourceManager,
  config: WaterfallConfig = DefaultWaterfallConfig
): void {
  // 创建或获取渲染器实例
  if (!globalWaterfallRenderer) {
    globalWaterfallRenderer = new WaterfallRenderer(config);
  }
  
  globalWaterfallRenderer.render(
    canvasContext,
    canvasWidth,
    canvasHeight,
    spectrumData,
    historyManager,
    frequencySteps,
    fftSize,
    sampleRate,
    sysResourceManager,
    config
  );
}

/**
 * 绘制频率轴标签
 */
function drawFrequencyLabels(
  ctx: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  margin: Margin,
  frequencySteps: number[],
  sampleRate: number,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const textColor = ChartUtils.getSystemColor(sysResourceManager, $r('sys.color.font_on_tertiary'));
  const fontSize = 10;
  
  ctx.save();
  ctx.fillStyle = textColor;
  ctx.font = `${ChartUtils.vp2px(fontSize)}px sans-serif`;
  ctx.textAlign = 'center';

  const chartWidth = canvasWidth - margin.left - margin.right;
  const frequencyHigh = frequencySteps[frequencySteps.length - 1];
  const logMinFreq = Math.log10(16);
  const logMax = Math.log10(frequencyHigh);

  for (let i = 0; i < frequencySteps.length; i++) {
    const freq = frequencySteps[i];
    const logFreq = Math.log10(freq);
    const x = margin.left + ((logFreq - logMinFreq) / (logMax - logMinFreq)) * chartWidth;
    
    const label = freq >= 1000 ? (freq === 1000 ? '1k' : `${freq / 1000}k`) : freq.toString();
    ctx.fillText(label, x, canvasHeight - 10);
  }

  ctx.restore();
}

/**
 * 绘制时间轴标签
 */
function drawTimeLabels(
  ctx: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  margin: Margin,
  timestamps: number[],
  sysResourceManager: resourceManager.ResourceManager
): void {
  const textColor = ChartUtils.getSystemColor(sysResourceManager, $r('sys.color.font_on_tertiary'));
  const fontSize = 10;
  
  ctx.save();
  ctx.fillStyle = textColor;
  ctx.font = `${ChartUtils.vp2px(fontSize)}px sans-serif`;
  ctx.textAlign = 'right';

  if (timestamps.length > 0) {
    const currentTime = Date.now();
    const timeSpan = currentTime - timestamps[0]; // 时间跨度(毫秒)
    
    // 显示时间范围
    const timeSpanSeconds = Math.floor(timeSpan / 1000);
    ctx.fillText(`-${timeSpanSeconds}s`, margin.left - 5, margin.top);
    ctx.fillText('0s', margin.left - 5, canvasHeight - margin.bottom);
  }

  ctx.restore();
}

/**
 * 绘制瀑布图主体（优化版本）
 */
function drawWaterfallBodyOptimized(
  ctx: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  margin: Margin,
  historyData: Float32Array[],
  frequencySteps: number[],
  fftSize: number,
  sampleRate: number,
  config: WaterfallConfig,
  renderer: WaterfallRenderer
): void {
  const lineCount = historyData.length;
  const lineHeight = chartHeight / Math.max(lineCount, 1);
  
  // 频率映射参数
  const frequencyHigh = frequencySteps[frequencySteps.length - 1];
  const logMinFreq = Math.log10(16);
  const logMax = Math.log10(frequencyHigh);
  
  // 预计算频率映射
  const freqMap: number[] = new Array(fftSize);
  const validFreqIndices: number[] = [];
  for (let i = 0; i < fftSize; i++) {
    const centerFreq = (i * sampleRate) / (2 * fftSize);
    if (centerFreq >= 16 && centerFreq <= frequencyHigh) {
      const logFreq = Math.log10(centerFreq);
      const x = margin.left + ((logFreq - logMinFreq) / (logMax - logMinFreq)) * chartWidth;
      freqMap[i] = x;
      validFreqIndices.push(i);
    }
  }
  
  const pixelWidth = Math.max(1, chartWidth / fftSize);

  // 批量绘制相同颜色的像素
  class ColorRect {
    x: number = 0;
    y: number = 0;
    width: number = 0;
    height: number = 0;
    
    constructor(x: number, y: number, width: number, height: number) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
  }
  
  const colorBatches: Map<string, ColorRect[]> = new Map();
  
  // 绘制每一行历史数据
  for (let lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    const spectrumData = historyData[lineIndex];
    const y = margin.top + lineIndex * lineHeight;
    
    // 应用渐变效果
    let alpha = 1.0;
    if (config.fadeEffect) {
      // 越老的数据越透明
      alpha = 0.3 + (0.7 * lineIndex / lineCount);
    }

    // 绘制该行的频谱数据
    for (const i of validFreqIndices) {
      const x = freqMap[i];
      const amplitude = spectrumData[i] || 0;
      const color = renderer.getCachedColor(amplitude, alpha, config);
      
      // 将相同颜色的像素分组
      if (!colorBatches.has(color)) {
        colorBatches.set(color, []);
      }
      const rect = new ColorRect(x, y, pixelWidth, lineHeight);
      colorBatches.get(color)!.push(rect);
    }
  }
  
  // 批量绘制每种颜色
  const colorKeys = colorBatches.keys();
  for (let i = 0; i < colorBatches.size; i++) {
    const color: string = colorKeys.next().value as string;
    const rects = colorBatches.get(color)!;
    ctx.fillStyle = color;
    for (let j = 0; j < rects.length; j++) {
      const rect = rects[j];
      ctx.fillRect(rect.x, rect.y, rect.width, rect.height);
    }
  }
}

/**
 * 绘制瀑布图主体（原始版本）
 */
function drawWaterfallBody(
  ctx: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  margin: Margin,
  historyData: Float32Array[],
  frequencySteps: number[],
  fftSize: number,
  sampleRate: number,
  config: WaterfallConfig
): void {
  const lineCount = historyData.length;
  const lineHeight = chartHeight / Math.max(lineCount, 1);
  
  // 频率映射参数
  const frequencyHigh = frequencySteps[frequencySteps.length - 1];
  const logMinFreq = Math.log10(16);
  const logMax = Math.log10(frequencyHigh);

  // 绘制每一行历史数据
  for (let lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    const spectrumData = historyData[lineIndex];
    const y = margin.top + lineIndex * lineHeight;
    
    // 应用渐变效果
    let alpha = 1.0;
    if (config.fadeEffect) {
      // 越老的数据越透明
      alpha = 0.3 + (0.7 * lineIndex / lineCount);
    }

    // 绘制该行的频谱数据
    for (let i = 0; i < fftSize; i++) {
      const centerFreq = (i * sampleRate) / (2 * fftSize);
      if (centerFreq < 16 || centerFreq > frequencyHigh) {
        continue;
      }

      // 计算X坐标（对数坐标）
      const logFreq = Math.log10(centerFreq);
      const x = margin.left + ((logFreq - logMinFreq) / (logMax - logMinFreq)) * chartWidth;

      // 获取幅度值并映射到颜色
      const amplitude = spectrumData[i] || 0;
      const color = getAmplitudeColor(amplitude, config, alpha);

      // 绘制像素点
      ctx.fillStyle = color;
      ctx.fillRect(x, y, Math.max(1, chartWidth / fftSize), lineHeight);
    }
  }
}

/**
 * 根据幅度值获取颜色
 */
function getAmplitudeColor(amplitude: number, config: WaterfallConfig, alpha: number = 1.0): string {
  // 将幅度值映射到颜色索引
  const normalizedValue = ChartUtils.normalizeValue(amplitude, config.minDb, config.maxDb, 0, 1);
  const colorIndex = Math.floor(normalizedValue * (config.colorMap.length - 1));
  const clampedIndex = Math.max(0, Math.min(colorIndex, config.colorMap.length - 1));
  
  // 获取颜色并应用透明度
  const baseColor = config.colorMap[clampedIndex];
  return applyAlphaToColor(baseColor, alpha);
}

/**
 * 应用透明度到颜色
 */
function applyAlphaToColor(color: string, alpha: number): string {
  // 将十六进制颜色转换为RGBA
  const hex = color.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);
  
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/**
 * 绘制颜色标尺
 */
function drawColorScale(
  ctx: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  margin: Margin,
  config: WaterfallConfig,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const scaleWidth = 20;
  const scaleHeight = canvasHeight - margin.top - margin.bottom;
  const scaleX = canvasWidth - margin.right - scaleWidth - 5;
  const scaleLabelsX = scaleX + scaleWidth + 5;

  ctx.save();

  // 绘制颜色条
  for (let i = 0; i < config.colorMap.length; i++) {
    const y = margin.top + (i * scaleHeight / (config.colorMap.length - 1));
    const color = config.colorMap[config.colorMap.length - 1 - i]; // 反转颜色顺序
    
    ctx.fillStyle = color;
    ctx.fillRect(scaleX, y, scaleWidth, scaleHeight / config.colorMap.length + 1);
  }

  // 绘制分贝标签
  const textColor = ChartUtils.getSystemColor(sysResourceManager, $r('sys.color.font_on_tertiary'));
  ctx.fillStyle = textColor;
  ctx.font = `${ChartUtils.vp2px(9)}px sans-serif`;
  ctx.textAlign = 'left';

  // 显示几个关键分贝值
  const dbSteps = [config.maxDb, (config.maxDb + config.minDb) / 2, config.minDb];
  for (let i = 0; i < dbSteps.length; i++) {
    const db = dbSteps[i];
    const normalizedValue = ChartUtils.normalizeValue(db, config.minDb, config.maxDb, 0, 1);
    const y = margin.top + (1 - normalizedValue) * scaleHeight;
    
    ctx.fillText(`${Math.round(db)}dB`, scaleLabelsX, y + 3);
  }

  ctx.restore();
}