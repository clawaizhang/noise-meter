/**
 * 频谱瀑布图绘制工具
 * 实现瀑布图的绘制算法和颜色映射
 */

import { resourceManager } from '@kit.LocalizationKit';
import { taskpool } from '@kit.ArkTS';
import { WaterfallData, ColorMapConfig } from '../../models/WaterfallData';
import { concurrentGenerateColorMap } from '../../concurrent/ConcurrentColorMapGenerator';
import { concurrentProcessAllWaterfallFrames, ProcessedFrame } from '../../concurrent/ConcurrentWaterfallProcessor';

/**
 * 边距配置接口
 */
export interface MarginConfig {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

/**
 * 透视效果参数接口
 */
export interface PerspectiveConfig {
  rowSpacing: number; // 行间距
  depthScale: number; // 深度缩放
  opacityDecay: number; // 透明度衰减
}

/**
 * 绘制选项接口
 */
export interface DrawOptions {
  showGrid: boolean;
  showTimeAxis: boolean;
  showFrequencyAxis: boolean;
  enableSmoothing: boolean;
}

/**
 * 瀑布图绘制配置
 */
export interface WaterfallDrawConfig {
  // 边距配置
  margin: MarginConfig;

  // 颜色映射配置
  colorMap: ColorMapConfig;

  // 透视效果参数
  perspective: PerspectiveConfig;

  // 绘制选项
  options: DrawOptions;
}

/**
 * 颜色映射参数类
 */
class ColorMapParams {
  type: string = '';
  minDb: number = 0;
  maxDb: number = 0;
  opacity: number = 0;
}

/**
 * 缓存的状态类
 */
class WaterfallCacheState {
  colorMap: string[] = [];
  lastColorMapParams: ColorMapParams = new ColorMapParams();
  processedFrames: ProcessedFrame[] | null = null;
  lastProcessTime: number = 0;
}

/**
 * 默认边距配置
 */
export const DefaultMarginConfig: MarginConfig = {
  top: 20,
  right: 15,
  bottom: 40,
  left: 35
};

/**
 * 默认透视效果配置
 */
export const DefaultPerspectiveConfig: PerspectiveConfig = {
  rowSpacing: 2,
  depthScale: 0.8,
  opacityDecay: 0.05
};

/**
 * 默认绘制选项
 */
export const DefaultDrawOptions: DrawOptions = {
  showGrid: true,
  showTimeAxis: true,
  showFrequencyAxis: true,
  enableSmoothing: true
};

/**
 * 默认绘制配置
 */
export const DefaultWaterfallDrawConfig: WaterfallDrawConfig = {
  margin: DefaultMarginConfig,
  colorMap: new ColorMapConfig(),
  perspective: DefaultPerspectiveConfig,
  options: DefaultDrawOptions
};

// 缓存状态
let cacheState: WaterfallCacheState = new WaterfallCacheState();

/**
 * 绘制频谱瀑布图
 * @param canvasContext Canvas上下文
 * @param canvasWidth 画布宽度
 * @param canvasHeight 画布高度
 * @param waterfallData 瀑布图数据
 * @param sysResourceManager 资源管理器
 * @param drawConfig 绘制配置
 */
export async function drawWaterfall(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  waterfallData: WaterfallData,
  sysResourceManager: resourceManager.ResourceManager,
  drawConfig: WaterfallDrawConfig = DefaultWaterfallDrawConfig
): Promise<void> {
  console.info(`[瀑布图绘制] 开始绘制，数据帧数: ${waterfallData.spectrumHistory.length}`);

  if (!canvasContext || waterfallData.spectrumHistory.length === 0) {
    console.warn('[瀑布图绘制] Canvas上下文无效或数据为空');
    return;
  }

  // 清除画布
  canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);

  // 计算绘制区域
  const chartWidth = canvasWidth - drawConfig.margin.left - drawConfig.margin.right;
  const chartHeight = canvasHeight - drawConfig.margin.top - drawConfig.margin.bottom;

  if (chartWidth <= 0 || chartHeight <= 0) {
    console.warn('[瀑布图绘制] 绘制区域无效');
    return;
  }

  // 绘制背景和网格
  if (drawConfig.options.showGrid) {
    drawGrid(canvasContext, chartWidth, chartHeight, drawConfig, sysResourceManager);
  }

  // 使用并行计算绘制瀑布图数据
  await drawWaterfallDataWithParallel(
    canvasContext,
    chartWidth,
    chartHeight,
    waterfallData,
    drawConfig,
    sysResourceManager
  );

  // 绘制坐标轴
  if (drawConfig.options.showTimeAxis || drawConfig.options.showFrequencyAxis) {
    drawAxes(canvasContext, chartWidth, chartHeight, drawConfig, sysResourceManager);
  }

  console.info('[瀑布图绘制] 绘制完成');
}

/**
 * 绘制网格
 */
function drawGrid(
  canvasContext: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  drawConfig: WaterfallDrawConfig,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const gridColor = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
  canvasContext.strokeStyle = gridColor;
  canvasContext.lineWidth = 0.5;

  // 水平网格线
  for (let i = 0; i <= 5; i++) {
    const y = drawConfig.margin.top + (chartHeight / 5) * i;
    canvasContext.beginPath();
    canvasContext.moveTo(drawConfig.margin.left, y);
    canvasContext.lineTo(drawConfig.margin.left + chartWidth, y);
    canvasContext.stroke();
  }

  // 垂直网格线
  for (let i = 0; i <= 8; i++) {
    const x = drawConfig.margin.left + (chartWidth / 8) * i;
    canvasContext.beginPath();
    canvasContext.moveTo(x, drawConfig.margin.top);
    canvasContext.lineTo(x, drawConfig.margin.top + chartHeight);
    canvasContext.stroke();
  }
}

/**
 * 使用并行计算绘制瀑布图数据
 */
async function drawWaterfallDataWithParallel(
  canvasContext: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  waterfallData: WaterfallData,
  drawConfig: WaterfallDrawConfig,
  sysResourceManager: resourceManager.ResourceManager
): Promise<void> {
  const spectrumHistory = waterfallData.spectrumHistory;
  const colorMapConfig = waterfallData.colorMap;

  if (spectrumHistory.length === 0) {
    return;
  }

  try {
    // 检查颜色映射是否需要更新
    const currentColorMapParams: ColorMapParams = new ColorMapParams();
    currentColorMapParams.type = colorMapConfig.colorMapType;
    currentColorMapParams.minDb = colorMapConfig.minDb;
    currentColorMapParams.maxDb = colorMapConfig.maxDb;
    currentColorMapParams.opacity = colorMapConfig.opacity;

    const shouldUpdateColorMap =
      currentColorMapParams.type !== cacheState.lastColorMapParams.type ||
        currentColorMapParams.minDb !== cacheState.lastColorMapParams.minDb ||
        currentColorMapParams.maxDb !== cacheState.lastColorMapParams.maxDb ||
        currentColorMapParams.opacity !== cacheState.lastColorMapParams.opacity;

    // 并行生成颜色映射表（如果需要更新）
    if (shouldUpdateColorMap || cacheState.colorMap.length === 0) {
      console.info('[瀑布图] 更新颜色映射表');
      cacheState.colorMap = await taskpool.execute<[string, number, number,number], string[]>(
        concurrentGenerateColorMap,
        colorMapConfig.colorMapType,
        colorMapConfig.minDb,
        colorMapConfig.maxDb,
        colorMapConfig.opacity
      );
      cacheState.lastColorMapParams.type = currentColorMapParams.type;
      cacheState.lastColorMapParams.minDb = currentColorMapParams.minDb;
      cacheState.lastColorMapParams.maxDb = currentColorMapParams.maxDb;
      cacheState.lastColorMapParams.opacity = currentColorMapParams.opacity;
    }

    // 并行处理所有帧数据
    console.info(`[瀑布图] 并行处理 ${spectrumHistory.length} 帧数据`);
    const processedFrames: ProcessedFrame[] = await taskpool.execute(
      concurrentProcessAllWaterfallFrames,
      spectrumHistory,
      chartWidth,
      chartHeight,
      cacheState.colorMap,
      drawConfig.perspective.rowSpacing,
      drawConfig.margin.left,
      colorMapConfig.minDb,
      colorMapConfig.maxDb,
      colorMapConfig.colorMapType,
      colorMapConfig.opacity
    ) as ProcessedFrame[];

    // 使用处理后的数据进行绘制
    drawProcessedFrames(canvasContext, processedFrames, drawConfig);

    // 更新缓存
    cacheState.processedFrames = processedFrames;
    cacheState.lastProcessTime = Date.now();

  } catch (error) {
    console.error('[瀑布图] 并行计算失败，回退到直接绘制:', error);
    // 回退到直接绘制
    drawWaterfallDataDirect(
      canvasContext,
      chartWidth,
      chartHeight,
      waterfallData,
      drawConfig,
      sysResourceManager
    );
  }
}

/**
 * 绘制处理后的帧数据
 */
function drawProcessedFrames(
  canvasContext: CanvasRenderingContext2D,
  processedFrames: ProcessedFrame[],
  drawConfig: WaterfallDrawConfig
): void {
  for (const frame of processedFrames) {
    if (!frame || !frame.bins) {
      continue;
    }

    for (const bin of frame.bins) {
      if (!bin || !isFinite(bin.db) || bin.db < drawConfig.colorMap.minDb) {
        continue;
      }

      // 直接使用预计算的颜色和坐标
      canvasContext.fillStyle = bin.color;
      canvasContext.fillRect(
        bin.x,
        frame.y,
        drawConfig.perspective.rowSpacing,
        drawConfig.perspective.rowSpacing
      );
    }
  }
}

/**
 * 直接绘制瀑布图数据（回退方案）
 */
function drawWaterfallDataDirect(
  canvasContext: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  waterfallData: WaterfallData,
  drawConfig: WaterfallDrawConfig,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const spectrumHistory = waterfallData.spectrumHistory;
  const colorMap = waterfallData.colorMap;

  if (spectrumHistory.length === 0) {
    return;
  }

  // 计算每行的高度（考虑透视效果）
  const maxRows = Math.floor(chartHeight / drawConfig.perspective.rowSpacing);
  const rowsToDraw = Math.min(spectrumHistory.length, maxRows);

  // 从最新数据开始绘制（从底部向上）
  for (let rowIndex = 0; rowIndex < rowsToDraw; rowIndex++) {
    const dataIndex = spectrumHistory.length - 1 - rowIndex;
    const spectrum = spectrumHistory[dataIndex];

    if (!spectrum || spectrum.length === 0) {
      continue;
    }

    // 计算当前行的Y坐标（从底部开始）
    const y = drawConfig.margin.top + chartHeight - (rowIndex * drawConfig.perspective.rowSpacing);

    // 计算透视效果：越远的行透明度越低
    const depthFactor = 1 - (rowIndex / rowsToDraw) * drawConfig.perspective.depthScale;
    const opacity = Math.max(0.1, depthFactor * drawConfig.colorMap.opacity);

    // 绘制单行频谱数据
    drawWaterfallRow(
      canvasContext,
      spectrum,
      y,
      chartWidth,
      drawConfig,
      colorMap,
      opacity,
      sysResourceManager
    );
  }
}

/**
 * 绘制单行频谱数据
 */
function drawWaterfallRow(
  canvasContext: CanvasRenderingContext2D,
  spectrum: Float32Array,
  y: number,
  chartWidth: number,
  drawConfig: WaterfallDrawConfig,
  colorMap: ColorMapConfig,
  opacity: number,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const binCount = spectrum.length;
  const binWidth = chartWidth / binCount;

  // 对数频率坐标映射（与频谱图保持一致）
  const logMin = Math.log10(16);
  const logMax = Math.log10(16000);

  for (let binIndex = 0; binIndex < binCount; binIndex++) {
    // 计算频率对应的X坐标（对数坐标）
    const frequency = (binIndex * 16000) / binCount; // 假设最大频率16kHz
    const logFreq = Math.log10(Math.max(16, frequency));
    const x = drawConfig.margin.left + ((logFreq - logMin) / (logMax - logMin)) * chartWidth;

    // 获取分贝值
    const db = spectrum[binIndex];

    // 跳过无效数据
    if (!isFinite(db) || db < colorMap.minDb) {
      continue;
    }

    // 计算颜色
    const color = getColorForDb(db, colorMap, opacity, sysResourceManager);

    // 绘制单个数据点（使用矩形或线段）
    canvasContext.fillStyle = color;
    canvasContext.fillRect(x, y, binWidth, drawConfig.perspective.rowSpacing);
  }
}

/**
 * 根据分贝值获取颜色
 */
function getColorForDb(
  db: number,
  colorMap: ColorMapConfig,
  opacity: number,
  sysResourceManager: resourceManager.ResourceManager
): string {
  // 归一化分贝值
  const normalized = Math.max(0, Math.min(1, (db - colorMap.minDb) / (colorMap.maxDb - colorMap.minDb)));

  let r: number, g: number, b: number;

  switch (colorMap.colorMapType) {
    case 'heat':
      // 热力图：蓝色 -> 绿色 -> 黄色 -> 红色
      if (normalized < 0.25) {
        r = 0;
        g = Math.floor(normalized * 4 * 255);
        b = 255;
      } else if (normalized < 0.5) {
        r = 0;
        g = 255;
        b = Math.floor((1 - (normalized - 0.25) * 4) * 255);
      } else if (normalized < 0.75) {
        r = Math.floor((normalized - 0.5) * 4 * 255);
        g = 255;
        b = 0;
      } else {
        r = 255;
        g = Math.floor((1 - (normalized - 0.75) * 4) * 255);
        b = 0;
      }
      break;

    case 'rainbow':
      // 彩虹色：紫色 -> 蓝色 -> 绿色 -> 黄色 -> 红色
      const hue = (1 - normalized) * 240; // 240度色相范围
      return hslToRgb(hue / 360, 1, 0.5, opacity);

    case 'grayscale':
    default:
    // 灰度图
      const intensity = Math.floor(normalized * 255);
      r = g = b = intensity;
      break;
  }

  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

/**
 * HSL转RGB颜色
 */
function hslToRgb(h: number, s: number, l: number, a: number): string {
  let r: number, g: number, b: number;

  if (s === 0) {
    r = g = b = l; // 灰度
  } else {
    const hue2rgb = (p: number, q: number, t: number) => {
      if (t < 0) {
        t += 1;
      }
      if (t > 1) {
        t -= 1;
      }
      if (t < 1 / 6) {
        return p + (q - p) * 6 * t;
      }
      if (t < 1 / 2) {
        return q;
      }
      if (t < 2 / 3) {
        return p + (q - p) * (2 / 3 - t) * 6;
      }
      return p;
    };

    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }

  return `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${a})`;
}

/**
 * 绘制坐标轴
 */
function drawAxes(
  canvasContext: CanvasRenderingContext2D,
  chartWidth: number,
  chartHeight: number,
  drawConfig: WaterfallDrawConfig,
  sysResourceManager: resourceManager.ResourceManager
): void {
  const textColor = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
  canvasContext.fillStyle = textColor;
  canvasContext.font = '12px sans-serif';
  canvasContext.textAlign = 'center';

  // 频率轴标签（底部）
  if (drawConfig.options.showFrequencyAxis) {
    const frequencies = [16, 63, 250, 1000, 4000, 16000];
    const logMin = Math.log10(16);
    const logMax = Math.log10(16000);

    for (const freq of frequencies) {
      const logFreq = Math.log10(freq);
      const x = drawConfig.margin.left + ((logFreq - logMin) / (logMax - logMin)) * chartWidth;
      const label = freq >= 1000 ? `${freq / 1000}k` : freq.toString();
      canvasContext.fillText(label, x, drawConfig.margin.top + chartHeight + 15);
    }

    // 频率轴标题
    canvasContext.fillText('频率 (Hz)', drawConfig.margin.left + chartWidth / 2,
      drawConfig.margin.top + chartHeight + 30);
  }

  // 时间轴标签（左侧）
  if (drawConfig.options.showTimeAxis) {
    canvasContext.save();
    canvasContext.translate(10, drawConfig.margin.top + chartHeight / 2);
    canvasContext.rotate(-Math.PI / 2);
    canvasContext.fillText('时间', 0, 0);
    canvasContext.restore();
  }
}

/**
 * 虚拟像素转物理像素（兼容函数）
 */
function vp2px(vp: number): number {
  // 这是一个简化的转换，实际项目中应该使用系统提供的转换函数
  return Math.round(vp * 2); // 假设2倍缩放
}