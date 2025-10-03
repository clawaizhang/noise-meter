import { WindowFunctionCache } from './WindowFunctionCache';

/**
 * FFT优化初始化函数
 * 在应用启动时调用，预缓存窗函数
 */
export function initializeFFTOptimizations(): void {
  WindowFunctionCache.initialize();
}

/**
 * 获取FFT优化状态信息
 * @returns 优化状态信息
 */
export function getFFTOptimizationStatus(): string {
  return '[FFT优化] 窗函数预缓存已启用';
}