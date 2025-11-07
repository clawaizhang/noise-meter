/**
 * 性能监控工具类
 * 用于监控瀑布图和其他组件的性能指标
 */

export interface PerformanceMetrics {
  frameRate: number;           // 当前帧率
  averageFrameTime: number;    // 平均帧时间
  renderCount: number;         // 渲染次数
  droppedFrames: number;       // 丢帧数
  lastRenderTime: number;      // 上次渲染时间
  memoryUsage: number;         // 内存使用量
}

export interface PerformanceAlert {
  type: 'FPS_DROP' | 'MEMORY_HIGH' | 'RENDER_SLOW';
  message: string;
  timestamp: number;
  value: number;
}

export interface AlertThresholds {
  minFPS: number;
  maxMemoryMB: number;
  maxFrameTime: number;
}

export class PerformanceMonitor {
  private static instance: PerformanceMonitor | null = null;
  
  private metrics: PerformanceMetrics = {
    frameRate: 0,
    averageFrameTime: 0,
    renderCount: 0,
    droppedFrames: 0,
    lastRenderTime: 0,
    memoryUsage: 0
  };
  
  private frameTimestamps: number[] = [];
  private frameTimes: number[] = [];
  private maxFrameHistory: number = 60; // 保存最近60帧的数据
  private alertThresholds: AlertThresholds = {
    minFPS: 10,
    maxMemoryMB: 200,
    maxFrameTime: 100 // 毫秒
  };
  
  private alerts: PerformanceAlert[] = [];
  private maxAlerts: number = 10;
  
  private constructor() {}
  
  /**
   * 获取性能监控实例
   */
  public static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }
  
  /**
   * 开始帧监控
   */
  public startFrame(): void {
    this.metrics.lastRenderTime = Date.now();
  }
  
  /**
   * 结束帧监控
   */
  public endFrame(): void {
    const now = Date.now();
    const frameTime = now - this.metrics.lastRenderTime;
    
    this.metrics.renderCount++;
    this.frameTimes.push(frameTime);
    this.frameTimestamps.push(now);
    
    // 限制历史数据长度
    if (this.frameTimes.length > this.maxFrameHistory) {
      this.frameTimes.shift();
      this.frameTimestamps.shift();
    }
    
    // 计算性能指标
    this.calculateMetrics();
    
    // 检查性能警报
    this.checkAlerts(frameTime);
  }
  
  /**
   * 计算性能指标
   */
  private calculateMetrics(): void {
    if (this.frameTimes.length === 0) {
      return;
    }
    
    // 计算平均帧时间
    const sumFrameTime = this.frameTimes.reduce((sum, time) => sum + time, 0);
    this.metrics.averageFrameTime = sumFrameTime / this.frameTimes.length;
    
    // 计算帧率
    if (this.frameTimestamps.length >= 2) {
      const timeSpan = this.frameTimestamps[this.frameTimestamps.length - 1] - this.frameTimestamps[0];
      this.metrics.frameRate = (this.frameTimestamps.length - 1) / (timeSpan / 1000);
    }
    
    // 获取内存使用情况
    this.updateMemoryUsage();
  }
  
  /**
   * 更新内存使用情况
   */
  private updateMemoryUsage(): void {
    try {
      // 在实际环境中，这里应该使用系统API获取内存使用情况
      // 这里使用模拟数据
      this.metrics.memoryUsage = Math.random() * 100 + 50; // 模拟50-150MB
    } catch (error) {
      console.warn('[性能监控] 获取内存使用情况失败:', error);
    }
  }
  
  /**
   * 检查性能警报
   */
  private checkAlerts(frameTime: number): void {
    const now = Date.now();
    
    // 检查帧率过低
    if (this.metrics.frameRate < this.alertThresholds.minFPS && this.metrics.frameRate > 0) {
      this.addAlert({
        type: 'FPS_DROP',
        message: `帧率过低: ${this.metrics.frameRate.toFixed(1)} FPS`,
        timestamp: now,
        value: this.metrics.frameRate
      });
    }
    
    // 检查帧时间过长
    if (frameTime > this.alertThresholds.maxFrameTime) {
      this.addAlert({
        type: 'RENDER_SLOW',
        message: `渲染过慢: ${frameTime.toFixed(1)}ms`,
        timestamp: now,
        value: frameTime
      });
    }
    
    // 检查内存使用过高
    if (this.metrics.memoryUsage > this.alertThresholds.maxMemoryMB) {
      this.addAlert({
        type: 'MEMORY_HIGH',
        message: `内存使用过高: ${this.metrics.memoryUsage.toFixed(1)}MB`,
        timestamp: now,
        value: this.metrics.memoryUsage
      });
    }
  }
  
  /**
   * 添加警报
   */
  private addAlert(alert: PerformanceAlert): void {
    this.alerts.push(alert);
    
    // 限制警报数量
    if (this.alerts.length > this.maxAlerts) {
      this.alerts.shift();
    }
    
    console.warn(`[性能警报] ${alert.message}`);
  }
  
  /**
   * 获取当前性能指标
   */
  public getMetrics(): PerformanceMetrics {
    const result: PerformanceMetrics = {
      frameRate: this.metrics.frameRate,
      averageFrameTime: this.metrics.averageFrameTime,
      renderCount: this.metrics.renderCount,
      droppedFrames: this.metrics.droppedFrames,
      lastRenderTime: this.metrics.lastRenderTime,
      memoryUsage: this.metrics.memoryUsage
    };
    return result;
  }
  
  /**
   * 获取最近的警报
   */
  public getAlerts(): PerformanceAlert[] {
    const result: PerformanceAlert[] = [];
    for (let i = 0; i < this.alerts.length; i++) {
      result.push(this.alerts[i]);
    }
    return result;
  }
  
  /**
   * 清除警报
   */
  public clearAlerts(): void {
    this.alerts = [];
  }
  
  /**
   * 重置所有指标
   */
  public reset(): void {
    this.metrics = {
      frameRate: 0,
      averageFrameTime: 0,
      renderCount: 0,
      droppedFrames: 0,
      lastRenderTime: 0,
      memoryUsage: 0
    };
    this.frameTimestamps = [];
    this.frameTimes = [];
    this.alerts = [];
  }
  
  /**
   * 设置警报阈值
   */
  public setAlertThresholds(thresholds: Partial<AlertThresholds>): void {
    if (thresholds.minFPS !== undefined) {
      this.alertThresholds.minFPS = thresholds.minFPS;
    }
    if (thresholds.maxMemoryMB !== undefined) {
      this.alertThresholds.maxMemoryMB = thresholds.maxMemoryMB;
    }
    if (thresholds.maxFrameTime !== undefined) {
      this.alertThresholds.maxFrameTime = thresholds.maxFrameTime;
    }
  }
  
  /**
   * 获取性能报告
   */
  public getPerformanceReport(): string {
    const metrics = this.metrics;
    const alerts = this.getAlerts();
    
    let report = `=== 性能监控报告 ===\n`;
    report += `帧率: ${metrics.frameRate.toFixed(1)} FPS\n`;
    report += `平均帧时间: ${metrics.averageFrameTime.toFixed(1)} ms\n`;
    report += `渲染次数: ${metrics.renderCount}\n`;
    report += `丢帧数: ${metrics.droppedFrames}\n`;
    report += `内存使用: ${metrics.memoryUsage.toFixed(1)} MB\n`;
    report += `警报数量: ${alerts.length}\n`;
    
    if (alerts.length > 0) {
      report += `\n=== 最近警报 ===\n`;
      alerts.slice(-3).forEach(alert => {
        report += `[${alert.type}] ${alert.message}\n`;
      });
    }
    
    return report;
  }
}