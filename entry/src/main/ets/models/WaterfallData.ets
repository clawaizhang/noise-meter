/**
 * 频谱瀑布图数据模型
 * 基于响应式数据管理，存储历史频谱数据用于瀑布图显示
 */
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
    
    constructor() {
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
     * 添加新的频谱数据帧
     * @param spectrum 频谱数据
     */
    addSpectrumFrame(spectrum: Float32Array): void {
        if (!this.isValidSpectrum(spectrum)) {
            console.warn('[WaterfallData] 无效的频谱数据');
            return;
        }
        
        // 检查是否需要压缩
        if (this.enableCompression && this.currentTimeIndex % this.compressionRatio !== 0) {
            this.currentTimeIndex++;
            return;
        }
        
        // 使用响应式更新模式
        const newHistory = [...this.spectrumHistory];
        const newTimestamps = [...this.timestamps];
        
        // 如果达到最大历史大小，移除最旧的数据
        if (newHistory.length >= this.maxHistorySize) {
            newHistory.shift();
            newTimestamps.shift();
        }
        
        // 添加新数据
        newHistory.push(new Float32Array(spectrum)); // 深拷贝数据
        newTimestamps.push(Date.now());
        
        // 更新响应式数据
        this.spectrumHistory = newHistory;
        this.timestamps = newTimestamps;
        this.currentTimeIndex++;
        
        console.debug(`[WaterfallData] 添加频谱帧，当前历史大小: ${this.spectrumHistory.length}`);
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