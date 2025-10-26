/**
 * 瀑布图并行计算处理器
 * 将DrawWaterfall中的双重循环计算迁移到taskpool中执行
 */

import { ColorMapConfig } from '../models/WaterfallData';

/**
 * 处理后的单帧数据接口
 */
export interface ProcessedFrame {
  rowIndex: number;
  y: number;
  opacity: number;
  bins: ProcessedBin[];
}

/**
 * 处理后的频率bin数据接口
 */
export interface ProcessedBin {
  x: number;
  db: number;
  color: string;
  binIndex: number;
}



/**
 * 批量并行处理所有瀑布图帧数据
 * @param spectrumHistory 历史频谱数据（普通二维数组，用于taskpool序列化）
 * @param chartWidth 图表宽度
 * @param chartHeight 图表高度
 * @param colorMap 颜色映射表
 * @param rowSpacing 行间距
 * @param pixelSize 像素大小
 * @param marginLeft 左边距
 * @param minDb 最小分贝值
 * @param maxDb 最大分贝值
 * @param colorMapType 颜色映射类型
 * @param colorMapOpacity 颜色映射透明度
 */
@Concurrent
export function concurrentProcessAllWaterfallFrames(
  spectrumHistory: number[][],
  chartWidth: number,
  chartHeight: number,
  colorMap: string[],
  rowSpacing: number,
  pixelSize: number,
  marginLeft: number,
  minDb: number,
  maxDb: number,
  colorMapType: string,
  colorMapOpacity: number
): ProcessedFrame[] {
  // 计算最大可显示行数 - 使用Canvas高度和像素大小
  const maxDisplayRows = Math.floor(chartHeight / pixelSize);
  // 使用所有可用数据，但不超过Canvas能显示的最大行数
  const rowsToProcess = Math.min(spectrumHistory.length, maxDisplayRows);
  const processedFrames: ProcessedFrame[] = new Array(rowsToProcess);
  
  // 预计算对数坐标映射参数
  const logMin = Math.log10(16);
  const logMax = Math.log10(16000);
  
  console.debug(`[并行处理器] 处理参数: rowsToProcess=${rowsToProcess}, maxDisplayRows=${maxDisplayRows}, rowSpacing=${rowSpacing}, pixelSize=${pixelSize}, chartHeight=${chartHeight}`);
  
  // 并行处理所有帧
  for (let rowIndex = 0; rowIndex < rowsToProcess; rowIndex++) {
    const dataIndex = spectrumHistory.length - 1 - rowIndex;
    const spectrum = spectrumHistory[dataIndex];
    
    if (!spectrum || spectrum.length === 0) {
      continue;
    }
    
    const binCount = spectrum.length;
    const processedBins: ProcessedBin[] = new Array(binCount);
    
    // 计算透视效果参数
    const depthFactor = 1 - (rowIndex / rowsToProcess) * 0.8; // depthScale
    const opacity = Math.max(0.1, depthFactor * colorMapOpacity);
    
    // 处理每个频率bin
    for (let binIndex = 0; binIndex < binCount; binIndex++) {
      // 计算频率对应的X坐标（对数坐标）
      const frequency = (binIndex * 16000) / binCount;
      const logFreq = Math.log10(Math.max(16, frequency));
      const x = marginLeft + ((logFreq - logMin) / (logMax - logMin)) * chartWidth;
      
      // 获取分贝值
      const db = spectrum[binIndex];
      
      // 计算颜色
      // 归一化分贝值
      const normalized = Math.max(0, Math.min(1, (db - minDb) / (maxDb - minDb)));
      
      // 使用预计算的颜色映射表
      const colorIndex = Math.floor(normalized * 255);
      const baseColor = colorMap[colorIndex];
      
      // 应用当前透明度
      let color = baseColor;
      // 假设颜色格式为 rgba(r, g, b, a)
      const rgbaMatch = baseColor.match(/rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)/);
      if (rgbaMatch) {
        const r = rgbaMatch[1];
        const g = rgbaMatch[2];
        const b = rgbaMatch[3];
        color = `rgba(${r}, ${g}, ${b}, ${opacity})`;
      }
      
      processedBins[binIndex] = {
        x,
        db,
        color,
        binIndex
      };
    }
    
    // 计算Y坐标（从底部开始）- 使用像素大小，确保填满Canvas高度
    const y = chartHeight - (rowIndex * pixelSize);

    console.debug(`[并行处理器] 处理帧: rowIndex=${rowIndex}, y=${y}, opacity=${opacity} ,pixelSize = ${pixelSize}`);
    processedFrames[rowIndex] = {
      rowIndex,
      y,
      opacity,
      bins: processedBins
    };
  }
  
  console.debug(`[并行处理器] 处理完成，返回 ${processedFrames.length} 帧数据`);
  return processedFrames;
}