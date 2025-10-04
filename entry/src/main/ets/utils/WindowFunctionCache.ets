import { WindowType } from '../common/AudioConfig';

/**
 * 窗函数预缓存管理器
 * 预缓存常用的FFT大小和窗函数类型组合，避免重复计算
 */
export interface WindowCorrection {
  window: Float32Array;
  correction: number;
}

export class WindowFunctionCache {
  private static cache: Map<string, WindowCorrection> = new Map();
  
  /**
   * 预缓存所有需要的窗函数和能量校正因子
   */
  public static initialize(): void {
    const fftSizes = [1024, 2048, 4096, 8192];
    const windowTypes = [WindowType.HANNING, WindowType.BLACKMAN];
    
    for (const size of fftSizes) {
      for (const windowType of windowTypes) {
        const key = WindowFunctionCache.getKey(size, windowType);
        const windowData = WindowFunctionCache.createWindowData(size, windowType);
        WindowFunctionCache.cache.set(key, windowData);
      }
    }
    
    console.info(`[窗函数缓存] 预缓存完成: ${fftSizes.length * windowTypes.length} 个窗函数`);
  }
  
  /**
   * 获取窗函数数据（包含窗函数和能量校正因子）
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @returns 窗函数数据和能量校正因子
   */
  public static getWindowData(size: number, windowType: WindowType): WindowCorrection {
    const key = WindowFunctionCache.getKey(size, windowType);
    const windowData = WindowFunctionCache.cache.get(key);
    
    if (!windowData) {
      console.warn(`[窗函数缓存] 未找到预缓存的窗函数: ${key}, 动态创建`);
      return WindowFunctionCache.createWindowData(size, windowType);
    }
    
    return windowData;
  }
  
  /**
   * 单独获取窗函数（向后兼容）
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @returns 窗函数数组
   */
  public static getWindow(size: number, windowType: WindowType): Float32Array {
    return WindowFunctionCache.getWindowData(size, windowType).window;
  }
  
  /**
   * 获取能量校正因子
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @returns 能量校正因子
   */
  public static getCorrectionFactor(size: number, windowType: WindowType): number {
    return WindowFunctionCache.getWindowData(size, windowType).correction;
  }
  
  private static getKey(size: number, windowType: WindowType): string {
    return `${size}-${windowType}`;
  }
  
  private static createWindowData(size: number, windowType: WindowType): WindowCorrection {
    const window = new Float32Array(size);
    const N = size - 1;
    let correction: number;
    
    switch (windowType) {
      case WindowType.HANNING:
        for (let i = 0; i < size; i++) {
          window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / N));
        }
        correction = 2.67; // Hanning窗的能量校正因子 (8/3)
        break;
      case WindowType.BLACKMAN:
        for (let i = 0; i < size; i++) {
          window[i] = 0.42 - 0.5 * Math.cos(2 * Math.PI * i / N) + 
                     0.08 * Math.cos(4 * Math.PI * i / N);
        }
        correction = 2.38; // Blackman窗的能量校正因子
        break;
      default:
        // 默认使用Hanning窗
        for (let i = 0; i < size; i++) {
          window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / N));
        }
        correction = 2.67;
    }
    
    return { window, correction };
  }
}