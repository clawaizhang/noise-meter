/**
 * 峰值计算改进测试验证
 * 用于验证抛物线插值和重心法的精度改进
 */

import { SpectrumDataProcessor, PeakInterpolationMethod } from '../src/main/ets/components/decibel-meter/SpectrumDataProcessor';

/**
 * 创建测试频谱数据
 * @param peakFreq 峰值频率
 * @param fftSize FFT大小
 * @param sampleRate 采样率
 * @returns 模拟的频谱数据
 */
function createTestSpectrum(peakFreq: number, fftSize: number, sampleRate: number): Float32Array {
  const spectrum = new Float32Array(fftSize / 2);
  const peakIndex = Math.round(peakFreq * fftSize / sampleRate);
  
  // 填充噪声背景
  for (let i = 0; i < spectrum.length; i++) {
    spectrum[i] = Math.random() * 0.1 - 60; // 低噪声背景
  }
  
  // 添加峰值
  if (peakIndex > 0 && peakIndex < spectrum.length) {
    spectrum[peakIndex] = -20; // 强峰值
    // 添加邻近点模拟真实频谱
    if (peakIndex > 0) {
      spectrum[peakIndex - 1] = -25;
    }
    if (peakIndex < spectrum.length - 1) {
      spectrum[peakIndex + 1] = -25;
    }
  }
  
  return spectrum;
}

/**
 * 测试峰值检测精度
 */
export function testPeakDetectionAccuracy(): void {
  console.info('=== 开始峰值检测精度测试 ===');
  
  const fftSize = 2048;
  const sampleRate = 44100;
  const testFreqs = [440, 1000, 5000, 8000]; // 测试频率
  
  testFreqs.forEach(targetFreq => {
    console.info(`\n测试目标频率: ${targetFreq}Hz`);
    
    // 创建测试频谱
    const spectrum = createTestSpectrum(targetFreq, fftSize, sampleRate);
    
    // 测试无插值方法
    const peakNoInterpolation = SpectrumDataProcessor.findPeakFrequency(
      spectrum, fftSize, sampleRate, 16, 20000, false
    );
    
    // 测试抛物线插值
    const peakParabolic = SpectrumDataProcessor.findPeakFrequency(
      spectrum, fftSize, sampleRate, 16, 20000, true, PeakInterpolationMethod.PARABOLIC
    );
    
    // 测试重心法
    const peakCentroid = SpectrumDataProcessor.findPeakFrequency(
      spectrum, fftSize, sampleRate, 16, 20000, true, PeakInterpolationMethod.CENTROID
    );
    
    // 计算误差
    const errorNoInterpolation = Math.abs(targetFreq - (peakNoInterpolation?.frequency || 0));
    const errorParabolic = Math.abs(targetFreq - (peakParabolic?.frequency || 0));
    const errorCentroid = Math.abs(targetFreq - (peakCentroid?.frequency || 0));
    
    console.info(`  无插值: ${peakNoInterpolation?.frequency.toFixed(2)}Hz (误差: ${errorNoInterpolation.toFixed(2)}Hz)`);
    console.info(`  抛物线插值: ${peakParabolic?.frequency.toFixed(2)}Hz (误差: ${errorParabolic.toFixed(2)}Hz)`);
    console.info(`  重心法: ${peakCentroid?.frequency.toFixed(2)}Hz (误差: ${errorCentroid.toFixed(2)}Hz)`);
    
    // 计算精度改进
    const improvementParabolic = ((errorNoInterpolation - errorParabolic) / errorNoInterpolation * 100).toFixed(1);
    const improvementCentroid = ((errorNoInterpolation - errorCentroid) / errorNoInterpolation * 100).toFixed(1);
    
    console.info(`  抛物线插值精度改进: ${improvementParabolic}%`);
    console.info(`  重心法精度改进: ${improvementCentroid}%`);
  });
  
  console.info('\n=== 峰值检测精度测试完成 ===');
}

/**
 * 测试多峰值检测
 */
export function testMultiplePeakDetection(): void {
  console.info('=== 开始多峰值检测测试 ===');
  
  const fftSize = 2048;
  const sampleRate = 44100;
  const spectrum = new Float32Array(fftSize / 2);
  
  // 添加多个峰值
  const peakFreqs = [440, 1000, 5000];
  peakFreqs.forEach(freq => {
    const index = Math.round(freq * fftSize / sampleRate);
    if (index > 0 && index < spectrum.length) {
      spectrum[index] = -20 - peakFreqs.indexOf(freq) * 5; // 不同幅度的峰值
    }
  });
  
  // 添加噪声背景
  for (let i = 0; i < spectrum.length; i++) {
    if (spectrum[i] === 0) {
      spectrum[i] = Math.random() * 0.1 - 60;
    }
  }
  
  // 测试多峰值检测
  const multiplePeaks = SpectrumDataProcessor.findMultiplePeaks(
    spectrum, fftSize, sampleRate, 3, 10, -50, true, PeakInterpolationMethod.PARABOLIC
  );
  
  console.info(`检测到 ${multiplePeaks.length} 个峰值:`);
  multiplePeaks.forEach((peak, index) => {
    const expectedFreq = peakFreqs[index];
    const error = Math.abs(expectedFreq - peak.frequency);
    console.info(`  峰值${index + 1}: ${peak.frequency.toFixed(2)}Hz@${peak.dbValue.toFixed(1)}dB (期望: ${expectedFreq}Hz, 误差: ${error.toFixed(2)}Hz)`);
  });
  
  console.info('\n=== 多峰值检测测试完成 ===');
}

/**
 * 性能测试
 */
export function testPerformance(): void {
  console.info('=== 开始性能测试 ===');
  
  const fftSize = 2048;
  const sampleRate = 44100;
  const iterations = 1000;
  
  // 创建测试数据
  const spectrum = createTestSpectrum(1000, fftSize, sampleRate);
  
  // 测试无插值性能
  const startTimeNoInterpolation = Date.now();
  for (let i = 0; i < iterations; i++) {
    SpectrumDataProcessor.findPeakFrequency(spectrum, fftSize, sampleRate, 16, 20000, false);
  }
  const timeNoInterpolation = Date.now() - startTimeNoInterpolation;
  
  // 测试抛物线插值性能
  const startTimeParabolic = Date.now();
  for (let i = 0; i < iterations; i++) {
    SpectrumDataProcessor.findPeakFrequency(spectrum, fftSize, sampleRate, 16, 20000, true, PeakInterpolationMethod.PARABOLIC);
  }
  const timeParabolic = Date.now() - startTimeParabolic;
  
  // 测试重心法性能
  const startTimeCentroid = Date.now();
  for (let i = 0; i < iterations; i++) {
    SpectrumDataProcessor.findPeakFrequency(spectrum, fftSize, sampleRate, 16, 20000, true, PeakInterpolationMethod.CENTROID);
  }
  const timeCentroid = Date.now() - startTimeCentroid;
  
  console.info(`性能测试结果 (${iterations}次迭代):`);
  console.info(`  无插值: ${timeNoInterpolation}ms (平均: ${(timeNoInterpolation / iterations).toFixed(3)}ms)`);
  console.info(`  抛物线插值: ${timeParabolic}ms (平均: ${(timeParabolic / iterations).toFixed(3)}ms)`);
  console.info(`  重心法: ${timeCentroid}ms (平均: ${(timeCentroid / iterations).toFixed(3)}ms)`);
  
  const overheadParabolic = ((timeParabolic - timeNoInterpolation) / timeNoInterpolation * 100).toFixed(1);
  const overheadCentroid = ((timeCentroid - timeNoInterpolation) / timeNoInterpolation * 100).toFixed(1);
  
  console.info(`  抛物线插值性能开销: ${overheadParabolic}%`);
  console.info(`  重心法性能开销: ${overheadCentroid}%`);
  
  console.info('\n=== 性能测试完成 ===');
}