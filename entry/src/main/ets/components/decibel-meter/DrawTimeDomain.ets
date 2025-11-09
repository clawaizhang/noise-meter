import { resourceManager } from '@kit.LocalizationKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

/**
 * 绘制时域波形图
 * @param canvasContext Canvas上下文
 * @param canvasWidth 画布宽度
 * @param canvasHeight 画布高度
 * @param timeDomainData 时域数据数组（归一化到[-1, 1]）
 * @param sysResourceManager 资源管理器
 * @param fontSize 字体大小
 */
export function drawTimeDomain(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  timeDomainData: number[],
  sysResourceManager: resourceManager.ResourceManager,
  fontSize: number = 16
): void {
  console.info(`[时域绘制] 开始绘制时域波形，数据长度=${timeDomainData.length}`);
  
  if (!canvasContext || timeDomainData.length === 0) {
    console.warn('[时域绘制] Canvas上下文无效或数据为空');
    return;
  }

  // 清除画布
  canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);

  // 设置样式
  const gridColor: number = sysResourceManager.getColorSync($r('app.color.font_on_tertiary').id);
  const waveformColor: number = sysResourceManager.getColorSync($r('app.color.font_on_secondary').id);
  const textColor: number = sysResourceManager.getColorSync($r('app.color.font_on_tertiary').id);

  // 绘制网格和坐标轴
  drawGridAndAxes(canvasContext, canvasWidth, canvasHeight, gridColor, textColor, fontSize);

  // 绘制时域波形
  drawWaveform(canvasContext, canvasWidth, canvasHeight, timeDomainData, waveformColor);

  console.info('[时域绘制] 时域波形绘制完成');
}

/**
 * 绘制网格和坐标轴
 */
function drawGridAndAxes(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  gridColor: number,
  textColor: number,
  fontSize: number
): void {
  canvasContext.strokeStyle = gridColor;
  canvasContext.lineWidth = 0.5;
  canvasContext.fillStyle = textColor;
  canvasContext.font = `${vp2px(fontSize + 2)}px sans-serif`;

  // 绘制中心线（零线）
  const centerY = canvasHeight / 2;
  canvasContext.beginPath();
  canvasContext.moveTo(0, centerY);
  canvasContext.lineTo(canvasWidth, centerY);
  canvasContext.stroke();

  // 绘制垂直网格线（时间轴）
  const timeSteps = 8; // 8个时间刻度
  for (let i = 1; i < timeSteps; i++) {
    const x = (canvasWidth / timeSteps) * i;
    
    canvasContext.beginPath();
    canvasContext.moveTo(x, 0);
    canvasContext.lineTo(x, canvasHeight);
    canvasContext.stroke();

    // 时间标签
    canvasContext.textAlign = 'center';
    canvasContext.fillText(`${i}`, x, centerY + 20);
  }

  // 绘制幅度刻度
  const amplitudeSteps = [-1, -0.5, 0, 0.5, 1];
  for (const amplitude of amplitudeSteps) {
    const y = centerY - (amplitude * centerY);
    
    // 水平网格线
    if (amplitude !== 0) {
      canvasContext.beginPath();
      canvasContext.moveTo(0, y);
      canvasContext.lineTo(canvasWidth, y);
      canvasContext.stroke();
    }

    // 幅度标签
    canvasContext.textAlign = 'left';
    canvasContext.fillText(`${amplitude}`, 5, y + 5);
  }

}

/**
 * 绘制时域波形
 */
function drawWaveform(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  timeDomainData: number[],
  waveformColor: number
): void {
  if (timeDomainData.length < 2) {
    console.warn('[时域绘制] 数据点不足，无法绘制波形');
    return;
  }

  const centerY = canvasHeight / 2;
  const amplitudeScale = centerY * 0.8; // 80%的画布高度用于波形显示

  canvasContext.strokeStyle = waveformColor;
  canvasContext.lineWidth = 1.5;
  canvasContext.beginPath();

  // 计算每个数据点的X坐标
  const pointSpacing = canvasWidth / (timeDomainData.length - 1);

  // 移动到第一个点
  const firstY = centerY - (timeDomainData[0] * amplitudeScale);
  canvasContext.moveTo(0, firstY);

  // 绘制波形
  for (let i = 1; i < timeDomainData.length; i++) {
    const x = i * pointSpacing;
    const y = centerY - (timeDomainData[i] * amplitudeScale);
    canvasContext.lineTo(x, y);
  }

  canvasContext.stroke();

  // 绘制峰值点标记
  drawPeakMarkers(canvasContext, timeDomainData, canvasWidth, centerY, amplitudeScale, waveformColor);
}

/**
 * 绘制峰值点标记
 */
function drawPeakMarkers(
  canvasContext: CanvasRenderingContext2D,
  timeDomainData: number[],
  canvasWidth: number,
  centerY: number,
  amplitudeScale: number,
  waveformColor: number
): void {
  if (timeDomainData.length === 0) return;

  // 找到正峰值和负峰值
  let maxPositive = -Infinity;
  let maxNegative = Infinity;
  let positiveIndex = -1;
  let negativeIndex = -1;

  for (let i = 0; i < timeDomainData.length; i++) {
    const value = timeDomainData[i];
    if (value > maxPositive) {
      maxPositive = value;
      positiveIndex = i;
    }
    if (value < maxNegative) {
      maxNegative = value;
      negativeIndex = i;
    }
  }

  // 绘制峰值点
  const pointSpacing = canvasWidth / (timeDomainData.length - 1);
  
  canvasContext.fillStyle = waveformColor;
  
  // 正峰值
  if (positiveIndex >= 0 && maxPositive > 0.1) {
    const x = positiveIndex * pointSpacing;
    const y = centerY - (maxPositive * amplitudeScale);
    
    canvasContext.beginPath();
    canvasContext.arc(x, y, 3, 0, 2 * Math.PI);
    canvasContext.fill();
  }

  // 负峰值
  if (negativeIndex >= 0 && maxNegative < -0.1) {
    const x = negativeIndex * pointSpacing;
    const y = centerY - (maxNegative * amplitudeScale);
    
    canvasContext.beginPath();
    canvasContext.arc(x, y, 3, 0, 2 * Math.PI);
    canvasContext.fill();
  }
}

/**
 * 虚拟像素转物理像素（兼容函数）
 */
function vp2px(vp: number): number {
  // 这是一个简化的转换，实际项目中应该使用系统提供的转换函数
  return Math.round(vp * 2); // 假设2倍缩放
}