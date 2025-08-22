/**
 * 性能测试工具 - 用于验证HealthStatusCard优化效果
 */

import { DeviceHealthInfo, BatteryInfo, PerformanceInfo, SystemMemInfo, StorageInfo, NetworkInfo, SensorInfo } from "../types/DeviceHealthInfo"
import { MemoryUtils } from "./MemoryUtils"

export class PerformanceTest {
  // 模拟测试数据
  private static testHealthInfo: DeviceHealthInfo = new DeviceHealthInfo(
    new BatteryInfo(85, 95, 30, 'discharging'),
    new PerformanceInfo(
      45,
      new SystemMemInfo(8589934592n, 4294967296n, 6442450944n), // 8GB total, 4GB free, 6GB available
      new StorageInfo(128 * 1024, 64 * 1024, 64 * 1024) // 128GB total, 64GB used, 64GB free
    ),
    new NetworkInfo(
      true,
      'wifi',
      3,
      50000,
      20000,
      50,
      2,
      false,
      false,
      false,
      '5g'
    ),
    new SensorInfo('normal'),
    85,
    new Date().toISOString()
  )

  /**
   * 运行内存计算性能测试
   */
  static runMemoryCalculationTest(iterations: number = 1000): { 
    totalTime: number, 
    avgTime: number,
    results: number[] 
  } {
    console.log(`开始内存计算性能测试 (${iterations}次迭代)`);
    
    const results: number[] = [];
    const startTime = Date.now();

    for (let i = 0; i < iterations; i++) {
      const memStart = Date.now();
      const usage = MemoryUtils.calculateMemoryUsage(
        this.testHealthInfo.performance.memory.totalMem,
        this.testHealthInfo.performance.memory.totalMem - this.testHealthInfo.performance.memory.availableMem
      );
      const memTime = Date.now() - memStart;
      results.push(memTime);
      
      if (i === 0) {
        console.log(`首次计算结果: ${usage}%, 耗时: ${memTime}ms`);
      }
    }

    const totalTime = Date.now() - startTime;
    const avgTime = totalTime / iterations;

    console.log(`内存计算测试完成:`);
    console.log(`- 总耗时: ${totalTime}ms`);
    console.log(`- 平均耗时: ${avgTime.toFixed(3)}ms`);
    console.log(`- 总迭代次数: ${iterations}`);

    return { totalTime, avgTime, results };
  }

  /**
   * 运行存储计算性能测试
   */
  static runStorageCalculationTest(iterations: number = 1000): { 
    totalTime: number, 
    avgTime: number,
    results: number[] 
  } {
    console.log(`开始存储计算性能测试 (${iterations}次迭代)`);
    
    const results: number[] = [];
    const startTime = Date.now();

    for (let i = 0; i < iterations; i++) {
      const storageStart = Date.now();
      const usage = MemoryUtils.calculateStorageUsage(
        this.testHealthInfo.performance.storage.total,
        this.testHealthInfo.performance.storage.used
      );
      const storageTime = Date.now() - storageStart;
      results.push(storageTime);
      
      if (i === 0) {
        console.log(`首次计算结果: ${usage}%, 耗时: ${storageTime}ms`);
      }
    }

    const totalTime = Date.now() - startTime;
    const avgTime = totalTime / iterations;

    console.log(`存储计算测试完成:`);
    console.log(`- 总耗时: ${totalTime}ms`);
    console.log(`- 平均耗时: ${avgTime.toFixed(3)}ms`);
    console.log(`- 总迭代次数: ${iterations}`);

    return { totalTime, avgTime, results };
  }

  /**
   * 运行内存格式化性能测试
   */
  static runMemoryFormatTest(iterations: number = 1000): { 
    totalTime: number, 
    avgTime: number,
    results: number[] 
  } {
    console.log(`开始内存格式化性能测试 (${iterations}次迭代)`);
    
    const results: number[] = [];
    const startTime = Date.now();

    for (let i = 0; i < iterations; i++) {
      const formatStart = Date.now();
      const formatted = MemoryUtils.formatMemory(this.testHealthInfo.performance.memory.availableMem);
      const formatTime = Date.now() - formatStart;
      results.push(formatTime);
      
      if (i === 0) {
        console.log(`首次格式化结果: ${formatted}, 耗时: ${formatTime}ms`);
      }
    }

    const totalTime = Date.now() - startTime;
    const avgTime = totalTime / iterations;

    console.log(`内存格式化测试完成:`);
    console.log(`- 总耗时: ${totalTime}ms`);
    console.log(`- 平均耗时: ${avgTime.toFixed(3)}ms`);
    console.log(`- 总迭代次数: ${iterations}`);
    console.log(`- 缓存命中率: ${MemoryUtils.getCacheStats().hitRate}%`);

    return { totalTime, avgTime, results };
  }

  /**
   * 运行综合性能测试
   */
  static runComprehensiveTest(): void {
    console.log('=== 开始综合性能测试 ===');
    
    // 清除缓存以确保公平测试
    MemoryUtils.clearCache();

    const memoryTest = this.runMemoryCalculationTest(10000);
    const storageTest = this.runStorageCalculationTest(10000);
    const formatTest = this.runMemoryFormatTest(1000);

    console.log('=== 综合测试结果 ===');
    console.log(`内存计算: ${memoryTest.avgTime.toFixed(3)}ms/次`);
    console.log(`存储计算: ${storageTest.avgTime.toFixed(3)}ms/次`);
    console.log(`内存格式化: ${formatTest.avgTime.toFixed(3)}ms/次`);
    console.log(`格式化缓存命中率: ${MemoryUtils.getCacheStats().hitRate}%`);

    // 性能基准判断
    const isOptimal = memoryTest.avgTime < 0.1 && storageTest.avgTime < 0.1 && formatTest.avgTime < 0.5;
    console.log(`性能优化结果: ${isOptimal ? '✅ 优秀' : '⚠️ 需要进一步优化'}`);
  }

  /**
   * 模拟HealthStatusCard组件渲染测试
   */
  static simulateComponentRendering(renderCount: number = 100): void {
    console.log(`模拟组件渲染测试 (${renderCount}次渲染)`);
    
    let totalMemoryTime = 0;
    let totalStorageTime = 0;
    let totalFormatTime = 0;

    for (let i = 0; i < renderCount; i++) {
      // 模拟getMemoryUsage调用
      const memStart = Date.now();
      const memUsage = MemoryUtils.calculateMemoryUsage(
        this.testHealthInfo.performance.memory.totalMem,
        this.testHealthInfo.performance.memory.totalMem - this.testHealthInfo.performance.memory.availableMem
      );
      totalMemoryTime += Date.now() - memStart;

      // 模拟getStorageUsage调用
      const storageStart = Date.now();
      const storageUsage = MemoryUtils.calculateStorageUsage(
        this.testHealthInfo.performance.storage.total,
        this.testHealthInfo.performance.storage.used
      );
      totalStorageTime += Date.now() - storageStart;

      // 模拟格式化调用
      const formatStart = Date.now();
      const formattedMem = MemoryUtils.formatMemory(this.testHealthInfo.performance.memory.availableMem);
      totalFormatTime += Date.now() - formatStart;

      if (i === 0) {
        console.log(`首次渲染结果 - 内存: ${memUsage}%, 存储: ${storageUsage}%, 格式化: ${formattedMem}`);
      }
    }

    console.log('组件渲染模拟完成:');
    console.log(`- 内存计算总耗时: ${totalMemoryTime}ms (平均: ${(totalMemoryTime / renderCount).toFixed(3)}ms)`);
    console.log(`- 存储计算总耗时: ${totalStorageTime}ms (平均: ${(totalStorageTime / renderCount).toFixed(3)}ms)`);
    console.log(`- 格式化总耗时: ${totalFormatTime}ms (平均: ${(totalFormatTime / renderCount).toFixed(3)}ms)`);
    console.log(`- 总耗时: ${totalMemoryTime + totalStorageTime + totalFormatTime}ms`);
  }
}

// 导出测试函数
export function runPerformanceTests(): void {
  if (process.env.NODE_ENV === 'development') {
    PerformanceTest.runComprehensiveTest();
    PerformanceTest.simulateComponentRendering(100);
  }
}