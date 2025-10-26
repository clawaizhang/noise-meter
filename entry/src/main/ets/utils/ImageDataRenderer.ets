/**
 * ImageData批量渲染器
 * 使用ImageData进行批量像素绘制，减少Canvas API调用
 */

/**
 * 渲染配置接口
 */
export interface ImageDataRenderConfig {
  width: number;
  height: number;
  pixelRatio: number;
  enableAntialiasing: boolean;
  maxFramesPerRender: number;
}

/**
 * 默认渲染配置
 */
export const DefaultImageDataRenderConfig: ImageDataRenderConfig = {
  width: 800,
  height: 400,
  pixelRatio: 1,
  enableAntialiasing: false,
  maxFramesPerRender: 50
};

/**
 * 像素数据接口
 */
export interface PixelData {
  x: number;
  y: number;
  r: number;
  g: number;
  b: number;
  a: number;
}

/**
 * 批量像素数据接口
 */
export interface BatchPixelData {
  pixels: PixelData[];
  frameIndex: number;
  timestamp: number;
}

/**
 * 渲染统计信息接口
 */
export interface RenderStats {
  renderCount: number;
  lastRenderTime: number;
  bufferSize: number;
  isInitialized: boolean;
  averageRenderTime: number;
  memoryUsage: number;
}

/**
 * ImageData渲染器
 */
export class ImageDataRenderer {
  private config: ImageDataRenderConfig;
  private imageData: ImageData | null = null;
  private data: Uint8ClampedArray | null = null;
  private canvasContext: CanvasRenderingContext2D | null = null;
  private isInitialized: boolean = false;
  private pixelBuffer: PixelData[] = [];
  private lastRenderTime: number = 0;
  private renderCount: number = 0;
  private totalRenderTime: number = 0;

  constructor(config: ImageDataRenderConfig = DefaultImageDataRenderConfig) {
    this.config = config;
  }

  /**
   * 初始化渲染器
   */
  initialize(canvasContext: CanvasRenderingContext2D): void {
    console.info(`[ImageData渲染器调试] 开始初始化渲染器`);
    this.canvasContext = canvasContext;
    
    // 创建ImageData对象
    const width = Math.floor(this.config.width * this.config.pixelRatio);
    const height = Math.floor(this.config.height * this.config.pixelRatio);
    
    console.info(`[ImageData渲染器调试] 创建ImageData，尺寸: ${width}x${height}`);
    this.imageData = canvasContext.createImageData(width, height);
    this.data = this.imageData.data;
    this.isInitialized = true;
    
    console.info(`[ImageData渲染器调试] 初始化完成，ImageData状态: ${this.imageData ? '成功' : '失败'}`);
    console.info(`[ImageData渲染器调试] 数据缓冲区状态: ${this.data ? '成功' : '失败'}`);
    console.info(`[ImageData渲染器调试] 渲染器状态: ${this.isInitialized ? '已初始化' : '未初始化'}`);
  }

  /**
   * 重置渲染器
   */
  reset(): void {
    if (this.data) {
      this.data.fill(0); // 清空数据
    }
    this.pixelBuffer = [];
    this.renderCount = 0;
  }

  /**
   * 批量添加像素数据
   */
  addPixels(pixels: PixelData[]): void {
    if (!this.isInitialized || !this.data) {
      console.warn('[ImageDataRenderer] 渲染器未初始化');
      return;
    }

    // 添加到缓冲区
    this.pixelBuffer.push(...pixels);

    // 如果缓冲区过大，立即渲染
    if (this.pixelBuffer.length > this.config.maxFramesPerRender * 1000) {
      this.flush();
    }
  }

  /**
   * 批量设置像素
   * 修复坐标转换问题，确保像素位置准确
   */
  private setPixels(pixels: PixelData[]): void {
    if (!this.data || !this.imageData) return;

    const width = this.imageData.width;
    const height = this.imageData.height;
    
    for (const pixel of pixels) {
      // 应用像素比例缩放
      const x = Math.floor(pixel.x * this.config.pixelRatio);
      const y = Math.floor(pixel.y * this.config.pixelRatio);
      
      // 确保坐标在有效范围内
      if (x >= 0 && x < width && y >= 0 && y < height) {
        const index = (y * width + x) * 4;
        
        // 设置像素颜色值
        this.data[index] = pixel.r;     // R
        this.data[index + 1] = pixel.g; // G
        this.data[index + 2] = pixel.b; // B
        this.data[index + 3] = pixel.a; // A
      }
    }
  }

  /**
   * 清空缓冲区并渲染 - 修复闪烁问题
   */
  flush(): void {
    console.info(`[ImageData渲染器调试] 开始flush操作`);
    
    if (!this.isInitialized) {
      console.warn(`[ImageData渲染器调试] 渲染器未初始化`);
      return;
    }
    if (!this.canvasContext) {
      console.warn(`[ImageData渲染器调试] Canvas上下文无效`);
      return;
    }
    if (!this.imageData) {
      console.warn(`[ImageData渲染器调试] ImageData无效`);
      return;
    }
    if (this.pixelBuffer.length === 0) {
      console.info(`[ImageData渲染器调试] 像素缓冲区为空，跳过渲染`);
      return;
    }

    console.info(`[ImageData渲染器调试] 准备渲染 ${this.pixelBuffer.length} 个像素`);
    const startTime = Date.now();

    // 清空ImageData，避免残留像素导致闪烁
    if (this.data) {
      this.data.fill(0);
    }

    // 批量设置像素
    console.info(`[ImageData渲染器调试] 开始批量设置像素`);
    this.setPixels(this.pixelBuffer);
    console.info(`[ImageData渲染器调试] 像素设置完成`);

    // 使用putImageData一次性绘制
    console.info(`[ImageData渲染器调试] 开始putImageData操作`);
    this.canvasContext.putImageData(this.imageData, 0, 0);
    console.info(`[ImageData渲染器调试] putImageData完成`);

    // 清空缓冲区
    this.pixelBuffer = [];
    this.renderCount++;
    this.lastRenderTime = Date.now() - startTime;
    this.totalRenderTime += this.lastRenderTime;

    console.info(`[ImageData渲染器调试] 渲染完成，耗时: ${this.lastRenderTime}ms, 总渲染次数: ${this.renderCount}`);
  }

  /**
   * 智能渲染 - 修复闪烁问题，强制立即渲染
   */
  smartRender(): void {
    // 强制立即渲染，避免闪烁问题
    if (this.pixelBuffer.length > 0) {
      this.flush();
    }
  }

  /**
   * 直接渲染像素数据（不经过缓冲区）
   */
  renderDirect(pixels: PixelData[]): void {
    if (!this.isInitialized) return;

    this.setPixels(pixels);
    this.flush();
  }

  /**
   * 创建矩形区域像素数据（修复版本）
   * 修复像素坐标转换问题，确保位置准确
   */
  createRectPixels(
    x: number, y: number,
    width: number, height: number,
    r: number, g: number, b: number, a: number
  ): PixelData[] {
    const pixels: PixelData[] = [];
    
    // 直接使用原始坐标，避免双重转换
    // 在setPixels方法中会进行正确的缩放
    const endX = Math.ceil(x + width);
    const endY = Math.ceil(y + height);

    // 批量生成像素数据 - 使用原始坐标
    for (let py = Math.floor(y); py < endY; py++) {
      for (let px = Math.floor(x); px < endX; px++) {
        pixels.push({
          x: px,
          y: py,
          r, g, b, a
        });
      }
    }

    return pixels;
  }

  /**
   * 创建线条像素数据（优化版本）
   */
  createLinePixels(
    x1: number, y1: number, 
    x2: number, y2: number, 
    thickness: number, 
    r: number, g: number, b: number, a: number
  ): PixelData[] {
    const pixels: PixelData[] = [];
    const dx = Math.abs(x2 - x1);
    const dy = Math.abs(y2 - y1);
    const sx = (x1 < x2) ? 1 : -1;
    const sy = (y1 < y2) ? 1 : -1;
    let err = dx - dy;

    // Bresenham算法绘制线条
    while (true) {
      // 添加线条厚度
      for (let t = -thickness; t <= thickness; t++) {
        for (let s = -thickness; s <= thickness; s++) {
          if (Math.sqrt(t * t + s * s) <= thickness) {
            pixels.push({
              x: x1 + s,
              y: y1 + t,
              r, g, b, a
            });
          }
        }
      }

      if (x1 === x2 && y1 === y2) break;
      const e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }

    return pixels;
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<ImageDataRenderConfig>): void {
    this.config = {
      width: newConfig.width ?? this.config.width,
      height: newConfig.height ?? this.config.height,
      pixelRatio: newConfig.pixelRatio ?? this.config.pixelRatio,
      enableAntialiasing: newConfig.enableAntialiasing ?? this.config.enableAntialiasing,
      maxFramesPerRender: newConfig.maxFramesPerRender ?? this.config.maxFramesPerRender
    };
    this.reset();
    
    // 重新初始化
    if (this.canvasContext) {
      this.initialize(this.canvasContext);
    }
  }

  /**
   * 获取渲染统计信息
   */
  getStats(): RenderStats {
    const averageRenderTime = this.renderCount > 0 ? this.totalRenderTime / this.renderCount : 0;
    const memoryUsage = this.pixelBuffer.length * 4; // 每个像素4字节
    
    return {
      renderCount: this.renderCount,
      lastRenderTime: this.lastRenderTime,
      bufferSize: this.pixelBuffer.length,
      isInitialized: this.isInitialized,
      averageRenderTime: averageRenderTime,
      memoryUsage: memoryUsage
    };
  }

  /**
   * 销毁渲染器
   */
  destroy(): void {
    this.imageData = null;
    this.data = null;
    this.canvasContext = null;
    this.isInitialized = false;
    this.pixelBuffer = [];
  }
}

/**
 * 高性能ImageData渲染器（支持多通道渲染）
 */
export class HighPerformanceImageDataRenderer extends ImageDataRenderer {
  private channelBuffers: Map<string, PixelData[]> = new Map();
  private mergeThreshold: number = 1000;

  constructor(config: ImageDataRenderConfig = DefaultImageDataRenderConfig) {
    super(config);
  }

  /**
   * 按通道添加像素数据
   */
  addPixelsByChannel(channel: string, pixels: PixelData[]): void {
    if (!this.channelBuffers.has(channel)) {
      this.channelBuffers.set(channel, []);
    }
    
    const channelBuffer = this.channelBuffers.get(channel)!;
    channelBuffer.push(...pixels);

    // 检查是否需要合并渲染
    let totalPixels = 0;
    for (const buffer of this.channelBuffers.values()) {
      totalPixels += buffer.length;
    }

    if (totalPixels >= this.mergeThreshold) {
      this.mergeAndRender();
    }
  }

  /**
   * 合并所有通道并渲染
   */
  private mergeAndRender(): void {
    const allPixels: PixelData[] = [];
    
    for (const entry of this.channelBuffers) {
      const channel = entry[0];
      const pixels = entry[1];
      allPixels.push(...pixels);
      this.channelBuffers.set(channel, []); // 清空通道缓冲区
    }

    if (allPixels.length > 0) {
      this.renderDirect(allPixels);
    }
  }

  /**
   * 渲染指定通道
   */
  renderChannel(channel: string): void {
    const pixels = this.channelBuffers.get(channel);
    if (pixels && pixels.length > 0) {
      this.renderDirect(pixels);
      this.channelBuffers.set(channel, []);
    }
  }

  /**
   * 渲染所有通道
   */
  renderAllChannels(): void {
    this.mergeAndRender();
  }

  /**
   * 获取通道统计信息
   */
  getChannelStats(): Map<string, number> {
    const stats = new Map<string, number>();
    for (const entry of this.channelBuffers) {
      const channel = entry[0];
      const pixels = entry[1];
      stats.set(channel, pixels.length);
    }
    return stats;
  }
}