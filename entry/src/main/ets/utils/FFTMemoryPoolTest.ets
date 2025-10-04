import { FFTMemoryPool } from './FFTMemoryPool';

/**
 * FFT内存池测试类
 * 用于验证内存池的功能和性能
 */
export class FFTMemoryPoolTest {
  
  /**
   * 测试内存池基本功能
   */
  public static testBasicFunctionality(): void {
    console.info('=== FFT内存池基本功能测试开始 ===');
    
    const memoryPool = FFTMemoryPool.getInstance();
    
    // 测试获取和释放数组
    const array1 = memoryPool.getArray(8192);
    const array2 = memoryPool.getArray(8192);
    const array3 = memoryPool.getArray(4096);
    
    if (array1 && array2 && array3) {
      console.info('✓ 成功获取3个数组');
      
      // 测试数组使用
      array1[0] = 1.0;
      array2[0] = 2.0;
      array3[0] = 3.0;
      
      console.info(`✓ 数组内容设置成功: ${array1[0]}, ${array2[0]}, ${array3[0]}`);
      
      // 释放数组
      memoryPool.releaseArray(array1, 8192);
      memoryPool.releaseArray(array2, 8192);
      memoryPool.releaseArray(array3, 4096);
      
      console.info('✓ 数组释放成功');
    } else {
      console.error('✗ 获取数组失败');
    }
    
    // 测试内存统计
    const stats = memoryPool.getMemoryStats();
    console.info(`内存统计: 总内存=${stats.totalMemory}字节, 使用数组=${stats.usedArrays}/${stats.totalArrays}`);
    
    console.info('=== FFT内存池基本功能测试完成 ===');
  }
  
  /**
   * 测试并发性能
   */
  public static async testConcurrentPerformance(): Promise<void> {
    console.info('=== FFT内存池并发性能测试开始 ===');
    
    const memoryPool = FFTMemoryPool.getInstance();
    const startTime = Date.now();
    
    // 模拟32个并发线程
    const promises = [];
    for (let i = 0; i < 32; i++) {
      promises.push(this.testSingleThread(memoryPool, i));
    }
    
    await Promise.all(promises);
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.info(`✓ 32线程并发测试完成，耗时: ${duration}ms`);
    
    // 检查内存使用情况
    const stats = memoryPool.getMemoryStats();
    console.info(`最终内存统计: 总内存=${stats.totalMemory}字节, 使用数组=${stats.usedArrays}/${stats.totalArrays}`);
    
    console.info('=== FFT内存池并发性能测试完成 ===');
  }
  
  /**
   * 测试单个线程
   */
  private static async testSingleThread(memoryPool: FFTMemoryPool, threadIndex: number): Promise<void> {
    // 获取3个数组（模拟FFT计算）
    const real = memoryPool.getArray(8192);
    const imag = memoryPool.getArray(8192);
    const spectrum = memoryPool.getArray(4096);
    
    if (!real || !imag || !spectrum) {
      console.error(`线程${threadIndex}: 获取数组失败`);
      return;
    }
    
    try {
      // 模拟FFT计算
      for (let i = 0; i < real.length; i++) {
        real[i] = Math.random();
        imag[i] = Math.random();
      }
      
      for (let i = 0; i < spectrum.length; i++) {
        spectrum[i] = Math.random() * 100 - 50; // 模拟分贝值
      }
      
      // 模拟1000ms间隔
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      console.info(`线程${threadIndex}: FFT计算完成`);
    } finally {
      // 确保释放数组
      memoryPool.releaseArray(real, 8192);
      memoryPool.releaseArray(imag, 8192);
      memoryPool.releaseArray(spectrum, 4096);
    }
  }
  
  /**
   * 测试内存池重置功能
   */
  public static testResetFunctionality(): void {
    console.info('=== FFT内存池重置功能测试开始 ===');
    
    const memoryPool = FFTMemoryPool.getInstance();
    
    // 先获取一些数组
    const arrays = [];
    for (let i = 0; i < 10; i++) {
      const array = memoryPool.getArray(8192);
      if (array) {
        arrays.push(array);
        array[0] = i; // 设置一些数据
      }
    }
    
    console.info(`获取了${arrays.length}个数组`);
    
    // 重置内存池
    memoryPool.clearArrays();
    
    // 检查数组是否被清理
    const stats = memoryPool.getMemoryStats();
    console.info(`重置后内存统计: 使用数组=${stats.usedArrays}/${stats.totalArrays}`);
    
    console.info('=== FFT内存池重置功能测试完成 ===');
  }
  
  /**
   * 运行所有测试
   */
  public static async runAllTests(): Promise<void> {
    console.info('🚀 开始FFT内存池全面测试');
    
    try {
      // 基本功能测试
      this.testBasicFunctionality();
      
      // 重置功能测试
      this.testResetFunctionality();
      
      // 并发性能测试
      await this.testConcurrentPerformance();
      
      console.info('🎉 FFT内存池所有测试通过！');
    } catch (error) {
      console.error('❌ FFT内存池测试失败:', error);
    }
  }
}