import { resourceManager } from '@kit.LocalizationKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { PathPoint, SpectrumProcessResult } from './SpectrumTypes';

export function getDbSteps(): number[] {
  return [-20, 0, 20, 40, 60, 80, 100, 120, 140];
}

export function getFrequencySteps(): number[] {
  // 标准频率步进
  return [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
}

/**
 * 绘制静态元素（坐标标签、网格线）
 * 只在Canvas尺寸变化时调用
 */
export function drawStaticElements(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  dbSteps: number[],
  frequencySteps: number[],
  sysResourceManager: resourceManager.ResourceManager,
  fontSize: number = 12
): void {
  console.info(`[静态绘制] 开始绘制静态元素，尺寸=${canvasWidth}x${canvasHeight}`);

  if (!canvasContext) {
    console.warn('[静态绘制] Canvas上下文为空');
    return;
  }

  // 清除画布
  canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);

  const lineColor: Color = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
  
  // 设置基本样式
  canvasContext.strokeStyle = lineColor;
  canvasContext.lineWidth = 1;
  canvasContext.textAlign = 'right';
  canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
  canvasContext.fillStyle = lineColor;

  // 绘制分贝刻度
  drawDbLabels(canvasContext, canvasWidth, canvasHeight, dbSteps, lineColor, fontSize);
  
  // 绘制分贝网格线
  drawDbGridLines(canvasContext, canvasWidth, canvasHeight, dbSteps, lineColor);
  
  // 绘制频率刻度和网格线
  drawFrequencyElements(canvasContext, canvasWidth, canvasHeight, frequencySteps, sysResourceManager, fontSize);

  console.info('[静态绘制] 静态元素绘制完成');
}

/**
 * 绘制分贝标签
 */
function drawDbLabels(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  dbSteps: number[],
  lineColor: Color,
  fontSize: number
): void {
  const minDb: number = dbSteps[0];
  const maxDb: number = dbSteps[dbSteps.length - 1];

  for (const db of dbSteps) {
    const normalizedValue: number = (db - minDb) / (maxDb - minDb);
    const y: number = canvasHeight * (1 - normalizedValue);

    // 跳过最顶部和最底部的水平网格线，但绘制标签
    if (db === minDb || db === maxDb) {
      if (db === maxDb) {
        canvasContext.fillStyle = lineColor;
        canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
        canvasContext.textAlign = 'right';
        canvasContext.fillText(`${db}`, 30, y + 10);
      }
      continue;
    }

    // 只为特定分贝值显示标签
    if (dbSteps.includes(db)) {
      canvasContext.fillStyle = lineColor;
      canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
      canvasContext.textAlign = 'right';
      canvasContext.fillText(`${db}`, 30, y + 10);
    }
  }
}

/**
 * 绘制分贝网格线
 */
function drawDbGridLines(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  dbSteps: number[],
  lineColor: Color
): void {
  const minDb: number = dbSteps[0];
  const maxDb: number = dbSteps[dbSteps.length - 1];

  for (const db of dbSteps) {
    const normalizedValue: number = (db - minDb) / (maxDb - minDb);
    const y: number = canvasHeight * (1 - normalizedValue);

    // 跳过最顶部和最底部的水平网格线
    if (db === minDb || db === maxDb) {
      continue;
    }

    // 绘制水平网格线
    canvasContext.lineWidth = 0.5;
    canvasContext.beginPath();
    canvasContext.moveTo(0, y);
    canvasContext.lineTo(canvasWidth, y);
    canvasContext.stroke();
  }
}

/**
 * 绘制频率相关元素
 */
function drawFrequencyElements(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  frequencySteps: number[],
  sysResourceManager: resourceManager.ResourceManager,
  fontSize: number
): void {
  // 设置文本样式
  canvasContext.textAlign = 'left';
  canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
  canvasContext.fillStyle = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);

  // 计算对数坐标映射
  const frequencyHigh: number = frequencySteps[frequencySteps.length - 1];
  const logMin: number = Math.log10(16);
  const logMax: number = Math.log10(frequencyHigh);
  const logRange: number = logMax - logMin;

  // 计算0分贝对应的Y坐标
  const dbSteps: number[] = getDbSteps();
  const minDb: number = dbSteps[0];
  const maxDb: number = dbSteps[dbSteps.length - 1];
  const zeroDbNormalizedValue: number = (0 - minDb) / (maxDb - minDb);
  const zeroDbY: number = canvasHeight * (1 - zeroDbNormalizedValue);

  for (let i = 0; i < frequencySteps.length; i++) {
    const freq: number = frequencySteps[i];
    const logFreq: number = Math.log10(freq);
    const x: number = ((logFreq - logMin) / logRange) * canvasWidth;

    // 跳过最左侧和最右侧的垂直网格线
    if (i === 0 || i === frequencySteps.length - 1) {
      // 绘制第一个频率标签
      if (i === 0) {
        canvasContext.fillStyle = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
        canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
        canvasContext.textAlign = 'left';
        canvasContext.fillText(`${freq}`, x + 2, zeroDbY - 2);
      }
      continue;
    }

    // 绘制垂直网格线
    canvasContext.beginPath();
    canvasContext.strokeStyle = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    canvasContext.lineWidth = 0.5;
    canvasContext.moveTo(x, 0);
    canvasContext.lineTo(x, canvasHeight);
    canvasContext.stroke();

    // 绘制频率文本
    const label: string = freq >= 1000 ?
      (freq === 1000 ? '1k' : `${freq / 1000}k`) :
      freq.toString();
    
    canvasContext.fillStyle = sysResourceManager.getColorSync($r('sys.color.font_on_tertiary').id);
    canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
    canvasContext.textAlign = 'left';
    canvasContext.fillText(label, x + 2, zeroDbY - 2);
  }
}

/**
 * 绘制动态元素（频谱线、峰值频率）
 * 每次频谱数据更新时调用
 */
export function drawDynamicElements(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  processResult: SpectrumProcessResult,
  sysResourceManager: resourceManager.ResourceManager,
  fontSize: number = 12
): void {
  console.info(`[动态绘制] 开始绘制动态元素，路径点=${processResult.pathPoints.length}`);

  if (!canvasContext) {
    console.warn('[动态绘制] Canvas上下文为空');
    return;
  }

  // 清除动态区域（保留静态内容）
  // 注意：这里假设静态内容在底层，动态内容在顶层
  // 实际实现中可能需要更精细的清除策略
  canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);

  // 绘制频谱线
  drawSpectrumLine(canvasContext, processResult.pathPoints, sysResourceManager);

  // 绘制峰值频率标注
  if (processResult.peakFrequency > 0) {
    drawPeakFrequency(canvasContext, processResult, sysResourceManager, fontSize);
  }

  console.info('[动态绘制] 动态元素绘制完成');
}

/**
 * 绘制频谱线
 */
function drawSpectrumLine(
  canvasContext: CanvasRenderingContext2D,
  pathPoints: PathPoint[],
  sysResourceManager: resourceManager.ResourceManager
): void {
  if (pathPoints.length === 0) {
    return;
  }

  const spectrumPath: Path2D = new Path2D();
  let isFirstPoint: boolean = true;

  for (const point of pathPoints) {
    if (isFirstPoint) {
      spectrumPath.moveTo(point.x, point.y);
      isFirstPoint = false;
    } else {
      spectrumPath.lineTo(point.x, point.y);
    }
  }

  canvasContext.strokeStyle = sysResourceManager.getColorSync($r('sys.color.font_on_secondary').id);
  canvasContext.lineWidth = 0.5;
  canvasContext.stroke(spectrumPath);
}

/**
 * 绘制峰值频率标注
 */
function drawPeakFrequency(
  canvasContext: CanvasRenderingContext2D,
  processResult: SpectrumProcessResult,
  sysResourceManager: resourceManager.ResourceManager,
  fontSize: number
): void {
  canvasContext.fillStyle = sysResourceManager.getColorSync($r('sys.color.font_on_secondary').id);
  canvasContext.textAlign = 'center';
  canvasContext.font = `bold ${vp2px(fontSize)}px sans-serif`;
  canvasContext.fillText(
    `${Math.round(processResult.peakFrequency)}Hz`,
    processResult.peakX,
    processResult.peakY - 30
  );
}
