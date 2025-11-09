import { WindowType } from '../common/WindowType';

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
    const fftSizes = [64, 128, 256, 512, 1024, 2048, 4096, 8192];
    const windowTypes = [
      WindowType.HANNING, 
      WindowType.BLACKMAN,
      WindowType.HAMMING,
      WindowType.BARTLETT,
      WindowType.KAISER,
      WindowType.FLATTOP,
      WindowType.TRIANGULAR,
      WindowType.WELCH,
      WindowType.SINE,
      WindowType.GAUSSIAN,
      WindowType.TUKEY,
      WindowType.CHEBYSHEV
    ];
    
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
   * 获取带参数的窗函数数据（包含窗函数和能量校正因子）
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @param kaiserBeta Kaiser窗Beta参数
   * @param gaussianSigma Gaussian窗Sigma参数
   * @param tukeyAlpha Tukey窗Alpha参数
   * @param chebyshevAttenuation Chebyshev窗衰减参数
   * @returns 窗函数数据和能量校正因子
   */
  public static getWindowDataWithParams(size: number, windowType: WindowType, 
    kaiserBeta?: number, gaussianSigma?: number, tukeyAlpha?: number, chebyshevAttenuation?: number): WindowCorrection {
    const key = WindowFunctionCache.getKeyWithParams(size, windowType, kaiserBeta, gaussianSigma, tukeyAlpha, chebyshevAttenuation);
    const windowData = WindowFunctionCache.cache.get(key);
    
    if (!windowData) {
      console.warn(`[窗函数缓存] 未找到预缓存的窗函数: ${key}, 动态创建`);
      return WindowFunctionCache.createWindowData(size, windowType, kaiserBeta, gaussianSigma, tukeyAlpha, chebyshevAttenuation);
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
   * 获取带参数的窗函数（向后兼容）
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @param kaiserBeta Kaiser窗Beta参数
   * @param gaussianSigma Gaussian窗Sigma参数
   * @param tukeyAlpha Tukey窗Alpha参数
   * @param chebyshevAttenuation Chebyshev窗衰减参数
   * @returns 窗函数数组
   */
  public static getWindowWithParams(size: number, windowType: WindowType, 
    kaiserBeta?: number, gaussianSigma?: number, tukeyAlpha?: number, chebyshevAttenuation?: number): Float32Array {
    return WindowFunctionCache.getWindowDataWithParams(size, windowType, kaiserBeta, gaussianSigma, tukeyAlpha, chebyshevAttenuation).window;
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
  
  /**
   * 获取带参数的能量校正因子
   * @param size FFT大小
   * @param windowType 窗函数类型
   * @param kaiserBeta Kaiser窗Beta参数
   * @param gaussianSigma Gaussian窗Sigma参数
   * @param tukeyAlpha Tukey窗Alpha参数
   * @param chebyshevAttenuation Chebyshev窗衰减参数
   * @returns 能量校正因子
   */
  public static getCorrectionFactorWithParams(size: number, windowType: WindowType, 
    kaiserBeta?: number, gaussianSigma?: number, tukeyAlpha?: number, chebyshevAttenuation?: number): number {
    return WindowFunctionCache.getWindowDataWithParams(size, windowType, kaiserBeta, gaussianSigma, tukeyAlpha, chebyshevAttenuation).correction;
  }
  
  private static getKey(size: number, windowType: WindowType): string {
    return `${size}-${windowType}`;
  }
  
  private static getKeyWithParams(size: number, windowType: WindowType, 
    kaiserBeta?: number, gaussianSigma?: number, tukeyAlpha?: number, chebyshevAttenuation?: number): string {
    let key = `${size}-${windowType}`;
    
    if (windowType === WindowType.KAISER && kaiserBeta !== undefined) {
      key += `-beta${kaiserBeta.toFixed(1)}`;
    }
    if (windowType === WindowType.GAUSSIAN && gaussianSigma !== undefined) {
      key += `-sigma${gaussianSigma.toFixed(2)}`;
    }
    if (windowType === WindowType.TUKEY && tukeyAlpha !== undefined) {
      key += `-alpha${tukeyAlpha.toFixed(2)}`;
    }
    if (windowType === WindowType.CHEBYSHEV && chebyshevAttenuation !== undefined) {
      key += `-att${chebyshevAttenuation.toFixed(0)}`;
    }
    
    return key;
  }
  
  private static createWindowData(size: number, windowType: WindowType, 
    kaiserBeta?: number, gaussianSigma?: number, tukeyAlpha?: number, chebyshevAttenuation?: number): WindowCorrection {
    const window = new Float32Array(size);
    const N = size - 1;
    let correction: number;
    
    switch (windowType) {
      case WindowType.HANNING:
        for (let i = 0; i < size; i++) {
          window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / N));
        }
        // 精确计算能量校正因子
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.BLACKMAN:
        for (let i = 0; i < size; i++) {
          window[i] = 0.42 - 0.5 * Math.cos(2 * Math.PI * i / N) + 
                     0.08 * Math.cos(4 * Math.PI * i / N);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.HAMMING:
        for (let i = 0; i < size; i++) {
          window[i] = 0.54 - 0.46 * Math.cos(2 * Math.PI * i / N);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.BARTLETT:
        // 修正巴特利特窗公式，使用N-1而不是N
        for (let i = 0; i < size; i++) {
          window[i] = 2.0 / (N - 1) * (i <= N / 2 ? i : N - 1 - i);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.KAISER:
        // Kaiser窗，使用传入的beta参数
        const beta = kaiserBeta || 6.0;
        const i0Beta = WindowFunctionCache.besselI0(beta);
        for (let i = 0; i < size; i++) {
          const alpha = N / 2.0;
          const arg = beta * Math.sqrt(1 - Math.pow((i - alpha) / alpha, 2));
          window[i] = WindowFunctionCache.besselI0(arg) / i0Beta;
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.FLATTOP:
        for (let i = 0; i < size; i++) {
          const phase = 2 * Math.PI * i / N;
          window[i] = 0.21557895 - 0.41663158 * Math.cos(phase) + 
                     0.277263158 * Math.cos(2 * phase) - 
                     0.083578947 * Math.cos(3 * phase) + 
                     0.006947368 * Math.cos(4 * phase);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.TRIANGULAR:
        // 修正三角窗实现，使其与巴特利特窗区分开来
        // 三角窗是巴特利特窗的周期版本
        for (let i = 0; i < size; i++) {
          const n = i - N / 2;
          window[i] = 1.0 - Math.abs(2.0 * n / (N + 1));
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.WELCH:
        for (let i = 0; i < size; i++) {
          const x = (i - N / 2) / (N / 2);
          window[i] = 1 - x * x;
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.SINE:
        for (let i = 0; i < size; i++) {
          window[i] = Math.sin(Math.PI * i / N);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.GAUSSIAN:
        // Gaussian窗，使用传入的sigma参数
        const sigma = gaussianSigma || 0.4;
        for (let i = 0; i < size; i++) {
          const x = (i - N / 2) / (sigma * N / 2);
          window[i] = Math.exp(-0.5 * x * x);
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.TUKEY:
        // Tukey窗，使用传入的alpha参数
        const alpha = tukeyAlpha || 0.5;
        const edgeWidth = Math.floor(alpha * N / 2);
        for (let i = 0; i < size; i++) {
          if (i < edgeWidth) {
            window[i] = 0.5 * (1 + Math.cos(Math.PI * (i / edgeWidth - 1)));
          } else if (i > N - edgeWidth) {
            window[i] = 0.5 * (1 + Math.cos(Math.PI * ((i - N + edgeWidth) / edgeWidth)));
          } else {
            window[i] = 1.0;
          }
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      case WindowType.CHEBYSHEV:
        // Chebyshev窗，使用传入的attenuation参数
        const attenuation = chebyshevAttenuation || 60.0;
        const ripple = Math.pow(10, attenuation / 20.0);
        const x0 = Math.cosh(1.0 / (N - 1) * WindowFunctionCache.acosh(ripple));
        for (let i = 0; i < size; i++) {
          const x = x0 * Math.cos(Math.PI * i / N);
          window[i] = Math.cosh((N - 1) * WindowFunctionCache.acosh(x)) / ripple;
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
        break;
        
      default:
        // 默认使用Hanning窗
        for (let i = 0; i < size; i++) {
          window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / N));
        }
        correction = WindowFunctionCache.calculateCorrectionFactor(window);
    }
    
    return { window, correction };
  }
  
  /**
   * 精确计算窗函数的能量校正因子
   * @param window 窗函数数组
   * @returns 能量校正因子
   */
  private static calculateCorrectionFactor(window: Float32Array): number {
    let sumSquares = 0;
    for (let i = 0; i < window.length; i++) {
      sumSquares += window[i] * window[i];
    }
    // 能量校正因子 = N / sum(w[n]^2)
    return window.length / sumSquares;
  }
  
  /**
   * 计算修正的零阶贝塞尔函数I0
   * @param x 输入值
   * @returns I0(x)
   */
  private static besselI0(x: number): number {
    let result = 1.0;
    let term = 1.0;
    let k = 1.0;
    
    // 使用级数展开计算I0(x)
    while (term > 1e-10) {
      term *= (x * x) / (4.0 * k * k);
      result += term;
      k += 1.0;
    }
    
    return result;
  }
  
  /**
   * 计算反双曲余弦函数
   * @param x 输入值，x >= 1
   * @returns acosh(x)
   */
  private static acosh(x: number): number {
    return Math.log(x + Math.sqrt(x * x - 1.0));
  }
}