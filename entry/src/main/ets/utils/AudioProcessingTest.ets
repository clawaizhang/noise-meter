import { WindowFunctionCache } from './WindowFunctionCache';
import { FFTBufferManager, BufferStatus } from './FFTBufferManager';
import { AudioStreamProcessor } from './AudioStreamProcessor';
import { AudioAnalysisConfig } from '../common/AudioConfig';
import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';

/**
 * 音频处理测试类
 * 用于验证修正后的实现是否正常工作
 */
export class AudioProcessingTest {
  
  /**
   * 测试窗函数计算
   */
  static testWindowFunctions(): boolean {
    console.info('[测试] 开始测试窗函数计算');
    
    const fftSize = 1024;
    const windowTypes = [
      WindowType.HANNING,
      WindowType.BLACKMAN,
      WindowType.HAMMING,
      WindowType.BARTLETT,
      WindowType.TRIANGULAR,
      WindowType.WELCH,
      WindowType.SINE
    ];
    
    let allTestsPassed = true;
    
    for (const windowType of windowTypes) {
      try {
        const windowData = WindowFunctionCache.getWindowData(fftSize, windowType);
        const window = windowData.window;
        const correction = windowData.correction;
        
        // 验证窗函数基本属性
        if (window.length !== fftSize) {
          console.error(`[测试] ${windowType}窗函数长度错误: ${window.length} != ${fftSize}`);
          allTestsPassed = false;
        }
        
        // 验证能量校正因子
        if (correction <= 0) {
          console.error(`[测试] ${windowType}窗函数能量校正因子无效: ${correction}`);
          allTestsPassed = false;
        }
        
        // 验证窗函数对称性（对于对称窗）
        if (windowType !== WindowType.TUKEY && windowType !== WindowType.KAISER) {
          let isSymmetric = true;
          for (let i = 0; i < fftSize / 2; i++) {
            if (Math.abs(window[i] - window[fftSize - 1 - i]) > 1e-6) {
              isSymmetric = false;
              break;
            }
          }
          
          if (!isSymmetric) {
            console.error(`[测试] ${windowType}窗函数不对称`);
            allTestsPassed = false;
          }
        }
        
        console.info(`[测试] ${windowType}窗函数测试通过，能量校正因子: ${correction.toFixed(4)}`);
        
      } catch (error) {
        console.error(`[测试] ${windowType}窗函数测试失败: ${error}`);
        allTestsPassed = false;
      }
    }
    
    return allTestsPassed;
  }
  
  /**
   * 测试FFT缓冲区管理器
   */
  static testFFTBufferManager(): boolean {
    console.info('[测试] 开始测试FFT缓冲区管理器');
    
    const fftSize = 1024;
    const overlapRatio = 0.5;
    const bufferManager = new FFTBufferManager(fftSize, overlapRatio);
    
    let allTestsPassed = true;
    
    try {
      // 测试初始状态
      if (bufferManager.getFFTSize() !== fftSize) {
        console.error(`[测试] FFT大小不匹配: ${bufferManager.getFFTSize()} != ${fftSize}`);
        allTestsPassed = false;
      }
      
      if (bufferManager.getOverlapRatio() !== overlapRatio) {
        console.error(`[测试] 重叠比例不匹配: ${bufferManager.getOverlapRatio()} != ${overlapRatio}`);
        allTestsPassed = false;
      }
      
      // 测试数据添加和处理
      const testData1 = new ArrayBuffer(fftSize * 2); // 第一个完整窗口
      const testData2 = new ArrayBuffer(bufferManager.getStepSize() * 2); // 步进大小
      
      // 添加第一个窗口
      const canProcess1 = bufferManager.addData(testData1);
      if (!canProcess1) {
        console.error('[测试] 第一个窗口应该可以处理');
        allTestsPassed = false;
      }
      
      // 获取窗口数据
      const window1 = bufferManager.getWindow();
      if (window1.byteLength !== fftSize * 2) {
        console.error(`[测试] 窗口数据大小错误: ${window1.byteLength} != ${fftSize * 2}`);
        allTestsPassed = false;
      }
      
      // 前进窗口
      bufferManager.advanceWindow();
      
      // 添加步进数据
      const canProcess2 = bufferManager.addData(testData2);
      if (!canProcess2) {
        console.error('[测试] 第二个窗口应该可以处理');
        allTestsPassed = false;
      }
      
      // 获取第二个窗口数据
      const window2 = bufferManager.getWindow();
      if (window2.byteLength !== fftSize * 2) {
        console.error(`[测试] 第二个窗口数据大小错误: ${window2.byteLength} != ${fftSize * 2}`);
        allTestsPassed = false;
      }
      
      // 验证重叠部分
      const window1Data = new Int16Array(window1);
      const window2Data = new Int16Array(window2);
      const overlapSize = bufferManager.getOverlapSize();
      
      let overlapMatches = true;
      for (let i = 0; i < overlapSize; i++) {
        if (window1Data[fftSize - overlapSize + i] !== window2Data[i]) {
          overlapMatches = false;
          break;
        }
      }
      
      if (!overlapMatches) {
        console.error('[测试] 重叠部分数据不匹配');
        allTestsPassed = false;
      }
      
      console.info('[测试] FFT缓冲区管理器测试通过');
      
    } catch (error) {
      console.error(`[测试] FFT缓冲区管理器测试失败: ${error}`);
      allTestsPassed = false;
    }
    
    return allTestsPassed;
  }
  
  /**
   * 测试音频流处理器
   */
  static testAudioStreamProcessor(): boolean {
    console.info('[测试] 开始测试音频流处理器');
    
    const config: AudioAnalysisConfig = {
      fftSize: 1024,
      updateInterval: 100,
      smoothingFactor: 0.2,
      windowType: WindowType.HANNING,
      overlap: 0.5,
      bufferSize: 2048,
      sampleRate: 44100,
      decimationEnabled: false,
      decimationFactor: 1,
      kaiserBeta: 6.0,
      gaussianSigma: 0.5,
      tukeyAlpha: 0.5,
      chebyshevAttenuation: 60.0
    };
    
    const processor = new AudioStreamProcessor(config);
    let allTestsPassed = true;
    let processCount = 0;
    
    try {
      // 设置处理回调
      processor.startProcessing((buffer: ArrayBuffer) => {
        processCount++;
        if (buffer.byteLength !== config.fftSize * 2) {
          console.error(`[测试] 处理回调数据大小错误: ${buffer.byteLength} != ${config.fftSize * 2}`);
          allTestsPassed = false;
        }
      });
      
      // 添加数据触发处理
      const testData1 = new ArrayBuffer(config.fftSize * 2); // 第一个完整窗口
      processor.processAudioData(testData1);
      
      // 等待处理完成
      setTimeout(() => {
        if (processCount === 0) {
          console.error('[测试] 处理回调未被调用');
          allTestsPassed = false;
        }
        
        // 添加更多数据测试连续处理
        const testData2 = new ArrayBuffer(processor.getFFTBufferManager().getStepSize() * 2);
        processor.processAudioData(testData2);
        
        setTimeout(() => {
          if (processCount < 2) {
            console.error(`[测试] 连续处理失败，预期2次，实际${processCount}次`);
            allTestsPassed = false;
          }
          
          // 停止处理
          processor.stopProcessing();
          
          console.info('[测试] 音频流处理器测试通过');
        }, 200);
      }, 200);
      
    } catch (error) {
      console.error(`[测试] 音频流处理器测试失败: ${error}`);
      allTestsPassed = false;
    }
    
    return allTestsPassed;
  }
  
  /**
   * 运行所有测试
   */
  static runAllTests(): boolean {
    console.info('[测试] 开始运行所有音频处理测试');
    
    const windowTest = this.testWindowFunctions();
    const bufferTest = this.testFFTBufferManager();
    const processorTest = this.testAudioStreamProcessor();
    
    const allTestsPassed = windowTest && bufferTest && processorTest;
    
    if (allTestsPassed) {
      console.info('[测试] 所有测试通过！音频处理修正成功。');
    } else {
      console.error('[测试] 部分测试失败，需要进一步检查。');
    }
    
    return allTestsPassed;
  }
}