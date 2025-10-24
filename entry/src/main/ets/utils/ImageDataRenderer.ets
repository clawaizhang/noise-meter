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
    this.canvasContext = canvasContext;
    
    // 创建ImageData对象
    const width = Math.floor(this.config.width * this.config.pixelRatio);
    const height = Math.floor(this.config.height * this.config.pixelRatio);
    
    this.imageData = canvasContext.createImageData(width, height);
    this.data = this.imageData.data;
    this.isInitialized = true;
    
    console.info(`[ImageDataRenderer] 初始化完成，尺寸: ${width}x${height}`);
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
   */
  private setPixels(pixels: PixelData[]): void {
    if (!this.data) return;

    const width = this.imageData!.width;
    
    for (const pixel of pixels) {
      const x = Math.floor(pixel.x * this.config.pixelRatio);
      const y = Math.floor(pixel.y * this.config.pixelRatio);
      
      if (x >= 0 && x < width && y >= 0 && y < this.imageData!.height) {
        const index = (y * width + x) * 4;
        
        this.data[index] = pixel.r;     // R
        this.data[index + 1] = pixel.g; // G
        this.data[index + 2] = pixel.b; // B
        this.data[index + 3] = pixel.a; // A
      }
    }
  }

  /**
   * 清空缓冲区并渲染
   */
  flush(): void {
    if (!this.isInitialized || !this.canvasContext || !this.imageData || this.pixelBuffer.length === 0) {
      return;
    }

    const startTime = Date.now();

    // 批量设置像素
    this.setPixels(this.pixelBuffer);

    // 使用putImageData一次性绘制
    this.canvasContext.putImageData(this.imageData, 0, 0);

    // 清空缓冲区
    this.pixelBuffer = [];
    this.renderCount++;
    this.lastRenderTime = Date.now() - startTime;
    this.totalRenderTime += this.lastRenderTime;

    if (this.renderCount % 10 === 0) {
      console.debug(`[ImageDataRenderer] 渲染完成，耗时: ${this.lastRenderTime}ms, 总渲染次数: ${this.renderCount}`);
    }
  }

  /**
   * 智能渲染 - 根据时间间隔决定是否渲染
   */
  smartRender(): void {
    const currentTime = Date.now();
    const timeSinceLastRender = currentTime - this.lastRenderTime;

    // 如果距离上次渲染超过16ms（约60fps）或者缓冲区较大，则渲染
    if (timeSinceLastRender > 16 || this.pixelBuffer.length > 500) {
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
   * 创建矩形区域像素数据（优化版本）
   */
  createRectPixels(
    x: number, y: number, 
    width: number, height: number, 
    r: number, g: number, b: number, a: number
  ): PixelData[] {
    const pixels: PixelData[] = [];
    const endX = x + width;
    const endY = y + height;

    // 预计算缩放后的坐标
    const scaledX = Math.floor(x * this.config.pixelRatio);
    const scaledY = Math.floor(y * this.config.pixelRatio);
    const scaledWidth = Math.floor(width * this.config.pixelRatio);
    const scaledHeight = Math.floor(height * this.config.pixelRatio);

    // 批量生成像素数据
    for (let py = scaledY; py < scaledY + scaledHeight; py++) {
      for (let px = scaledX; px < scaledX + scaledWidth; px++) {
        pixels.push({
          x: px / this.config.pixelRatio,
          y: py / this.config.pixelRatio,
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