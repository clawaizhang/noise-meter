/**
 * 频谱瀑布图数据模型
 * 基于响应式数据管理，存储历史频谱数据用于瀑布图显示
 * 使用内存对象池优化内存分配和GC性能
 * 集成动态分辨率管理和滑动窗口功能
 */
import { GlobalMemoryPoolManager, Float32ArrayPool } from '../utils/MemoryPool';
import { DynamicResolutionManager, SlidingWindowManager, PerformanceLevel } from '../utils/DynamicResolutionManager';
/**
 * 频谱统计信息接口
 */
interface SpectrumStatistics {
    minDb: number;
    maxDb: number;
    avgDb: number;
    frameCount: number;
}

/**
 * 内存使用统计接口
 */
interface MemoryUsageStats {
    frameCount: number;
    estimatedSize: number;
}

@ObservedV2
export class ColorMapConfig {
    // 最小分贝值
    @Trace minDb: number = -20;
    
    // 最大分贝值
    @Trace maxDb: number = 120;
    
    // 颜色映射类型
    @Trace colorMapType: 'heat' | 'rainbow' | 'grayscale' = 'heat';
    
    // 透明度设置
    @Trace opacity: number = 0.8;
    
    constructor() {
    }
}

@ObservedV2
export class WaterfallData {
    // 历史频谱数据队列（固定大小）
    @Trace spectrumHistory: Float32Array[] = [];
    
    // 当前时间索引
    @Trace currentTimeIndex: number = 0;
    
    // 最大历史帧数
    @Trace maxHistorySize: number = 100;
    
    // 颜色映射配置
    @Trace colorMap: ColorMapConfig = new ColorMapConfig();
    
    // 时间戳数组，记录每帧频谱的时间
    @Trace timestamps: number[] = [];
    
    // 是否启用数据压缩
    @Trace enableCompression: boolean = true;
    
    // 压缩比例（每n帧保留1帧）
    @Trace compressionRatio: number = 2;
    
    // 内存池管理器
    private memoryPoolManager: GlobalMemoryPoolManager;
    private spectrumPool: Float32ArrayPool; // 使用具体类型替代any
    
    // 动态分辨率管理器
    private resolutionManager: DynamicResolutionManager;
    
    // 滑动窗口管理器
    private slidingWindowManager: SlidingWindowManager;
    
    // 性能监控
    private lastFrameTime: number = 0;
    private frameCount: number = 0;
    private droppedFrames: number = 0;
    
    constructor() {
        this.memoryPoolManager = GlobalMemoryPoolManager.getInstance();
        this.spectrumPool = this.memoryPoolManager.getSpectrumPool();
        this.resolutionManager = new DynamicResolutionManager();
        this.slidingWindowManager = new SlidingWindowManager(this.maxHistorySize);
        this.initialize();
    }
    
    /**
     * 初始化瀑布图数据
     */
    private initialize(): void {
        this.spectrumHistory = [];
        this.timestamps = [];
        this.currentTimeIndex = 0;
    }
    
    /**
     * 添加新的频谱数据帧（集成动态分辨率优化）
     * @param spectrum 频谱数据
     */
    addSpectrumFrame(spectrum: Float32Array): void {
      console.info(`[数据流调试] 添加频谱帧，原始长度: ${spectrum.length}`);
      
      if (!this.isValidSpectrum(spectrum)) {
        console.warn('[数据流调试] 无效的频谱数据');
        return;
      }
      
      console.info(`[数据流调试] 数据有效性: 有效`);
      
      // 应用动态分辨率调整
      const processedSpectrum = this.applyDynamicResolution(spectrum);
      console.info(`[数据流调试] 处理后长度: ${processedSpectrum.length}`);
      
      // 检查是否需要压缩（使用动态压缩比例）
      const currentCompressionRatio = this.resolutionManager.getCompressionRatio();
      console.info(`[数据流调试] 压缩比例: ${currentCompressionRatio}`);
      
      if (this.enableCompression && this.currentTimeIndex % currentCompressionRatio !== 0) {
        console.info(`[数据流调试] 跳过此帧（压缩）`);
        this.currentTimeIndex++;
        return;
      }
      
      // 使用响应式更新模式
      const newHistory = [...this.spectrumHistory];
      const newTimestamps = [...this.timestamps];
      
      // 动态调整最大历史大小
      const currentMaxHistorySize = this.resolutionManager.getMaxHistorySize();
      if (currentMaxHistorySize !== this.maxHistorySize) {
        this.maxHistorySize = currentMaxHistorySize;
        console.info(`[数据流调试] 更新最大历史大小: ${this.maxHistorySize}`);
      }
      
      // 如果达到最大历史大小，移除最旧的数据并释放内存
      if (newHistory.length >= this.maxHistorySize) {
        const removedSpectrum = newHistory.shift();
        newTimestamps.shift();
        
        // 释放被移除的频谱数据到内存池
        if (removedSpectrum) {
          this.spectrumPool.release(removedSpectrum);
          console.info(`[数据流调试] 移除最旧数据帧`);
        }
      }
      
      // 使用内存池获取新的Float32Array
      const newSpectrum = this.spectrumPool.acquire(processedSpectrum.length) as Float32Array;
      newSpectrum.set(processedSpectrum); // 复制处理后的数据
      
      // 添加新数据
      newHistory.push(newSpectrum);
      newTimestamps.push(Date.now());
      
      // 更新响应式数据
      this.spectrumHistory = newHistory;
      this.timestamps = newTimestamps;
      this.currentTimeIndex++;
      
      // 更新滑动窗口
      this.slidingWindowManager.addData(newSpectrum);
      
      // 更新性能指标
      this.updatePerformanceMetrics();
      
      console.info(`[数据流调试] 添加频谱帧完成，当前历史大小: ${this.spectrumHistory.length}, 压缩后大小: ${processedSpectrum.length}`);
    }
    
    /**
     * 应用动态分辨率处理
     */
    private applyDynamicResolution(spectrum: Float32Array): Float32Array {
        // 应用对数频率压缩
        return this.resolutionManager.applyLogCompression(spectrum);
    }
    
    /**
     * 更新性能指标
     */
    private updatePerformanceMetrics(): void {
        const currentTime = Date.now();
        
        // 计算帧时间
        if (this.lastFrameTime > 0) {
            const frameTime = currentTime - this.lastFrameTime;
            const fps = 1000 / frameTime;
            
            // 计算内存使用量
            const memoryStats = this.getMemoryUsage();
            const memoryUsageMB = memoryStats.estimatedSize / (1024 * 1024);
            
            // 更新性能指标
            this.resolutionManager.updateMetrics({
                frameTime,
                memoryUsage: memoryUsageMB,
                fps,
                droppedFrames: this.droppedFrames
            });
        }
        
        this.lastFrameTime = currentTime;
        this.frameCount++;
    }
    
    /**
     * 验证频谱数据有效性
     */
    private isValidSpectrum(spectrum: Float32Array): boolean {
        return spectrum && 
               spectrum.length > 0 && 
               spectrum.every(value => !isNaN(value) && isFinite(value));
    }
    
    /**
     * 获取指定时间范围的频谱数据
     */
    getSpectrumInTimeRange(startTime: number, endTime: number): Float32Array[] {
        const result: Float32Array[] = [];
        
        for (let i = 0; i < this.timestamps.length; i++) {
            if (this.timestamps[i] >= startTime && this.timestamps[i] <= endTime) {
                result.push(this.spectrumHistory[i]);
            }
        }
        
        return result;
    }
    
    /**
     * 获取最近N帧的频谱数据
     */
    getRecentSpectrumFrames(count: number): Float32Array[] {
        const startIndex = Math.max(0, this.spectrumHistory.length - count);
        return this.spectrumHistory.slice(startIndex);
    }
    

    /**
     * 获取频谱数据的统计信息
     */
    getStatistics(): SpectrumStatistics {
        if (this.spectrumHistory.length === 0) {
            const emptyStats: SpectrumStatistics = { minDb: 0, maxDb: 0, avgDb: 0, frameCount: 0 };
            return emptyStats;
        }
        
        let minDb = Infinity;
        let maxDb = -Infinity;
        let sumDb = 0;
        let totalValues = 0;
        
        for (const spectrum of this.spectrumHistory) {
            for (const value of spectrum) {
                if (isFinite(value)) {
                    minDb = Math.min(minDb, value);
                    maxDb = Math.max(maxDb, value);
                    sumDb += value;
                    totalValues++;
                }
            }
        }
        
        const avgDb = totalValues > 0 ? sumDb / totalValues : 0;
        
        const stats: SpectrumStatistics = {
            minDb: isFinite(minDb) ? minDb : 0,
            maxDb: isFinite(maxDb) ? maxDb : 0,
            avgDb: isFinite(avgDb) ? avgDb : 0,
            frameCount: this.spectrumHistory.length
        };
        return stats;
    }
    
    /**
     * 清空历史数据
     */
    clear(): void {
        // 释放所有频谱数据到内存池
        for (const spectrum of this.spectrumHistory) {
            this.spectrumPool.release(spectrum);
        }
        
        this.spectrumHistory = [];
        this.timestamps = [];
        this.currentTimeIndex = 0;
        console.info('[WaterfallData] 清空瀑布图数据');
    }
    
    /**
     * 设置最大历史大小
     */
    setMaxHistorySize(size: number): void {
        if (size > 0 && size <= 1000) { // 限制最大大小
            this.maxHistorySize = size;
            
            // 如果当前数据超过新的大小，截断数据
            if (this.spectrumHistory.length > size) {
                const newHistory = this.spectrumHistory.slice(-size);
                const newTimestamps = this.timestamps.slice(-size);
                this.spectrumHistory = newHistory;
                this.timestamps = newTimestamps;
            }
        }
    }
    


    /**
     * 获取数据使用情况
     */
    getMemoryUsage(): MemoryUsageStats {
        const frameCount = this.spectrumHistory.length;
        let estimatedSize = 0;
        
        for (const spectrum of this.spectrumHistory) {
            estimatedSize += spectrum.length * 4; // Float32Array每个元素4字节
        }
        
        const usage: MemoryUsageStats = {
            frameCount,
            estimatedSize: estimatedSize
        };
        return usage;
    }
}