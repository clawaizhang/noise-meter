import { WindowType } from '../common/AudioConfig';
import { FFTAnalyzer } from './FFTAnalyzer';


/**
 * FFT Analyzer会话池 - 管理动态创建的FFTAnalyzer实例
 * 通过会话ID在整个计算流程中传递，在计算完成后释放
 */
export interface FFTAnalyzerSession {
  analyzer: FFTAnalyzer;
  sessionId: string;
}

export class FFTAnalyzerSessionPool {
  private static instance: FFTAnalyzerSessionPool = new FFTAnalyzerSessionPool();;
  private sessions: Map<string, FFTAnalyzer> = new Map();

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): FFTAnalyzerSessionPool {
    return FFTAnalyzerSessionPool.instance;
  }

  /**
   * 创建新的计算会话
   * @param fftSize FFT大小
   * @param windowType 窗函数类型
   * @param smoothingFactor 平滑因子
   * @param overlap 重叠率
   * @returns 包含FFTAnalyzer实例和会话ID的对象
   */
  public createSession(fftSize: number, windowType: WindowType, smoothingFactor: number,
    overlap: number): FFTAnalyzerSession {
    // 使用时间戳+随机数生成唯一会话ID
    const sessionId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    const analyzer = new FFTAnalyzer(fftSize, windowType, smoothingFactor, overlap);

    this.sessions.set(sessionId, analyzer);

    console.info(`[FFT_POOL] 创建新会话: ${sessionId}, FFT大小: ${fftSize}, 窗函数: ${windowType}`);

    return { analyzer, sessionId };
  }

  /**
   * 通过会话ID获取FFTAnalyzer实例
   * @param sessionId 会话ID
   * @returns FFT分析器实例，如果不存在则返回undefined
   */
  public getAnalyzerBySessionId(sessionId: string): FFTAnalyzer | undefined {
    const analyzer = this.sessions.get(sessionId);
    if (!analyzer) {
      console.warn(`[FFT_POOL] 找不到会话ID对应的FFTAnalyzer: ${sessionId}`);
    }
    return analyzer;
  }

  /**
   * 释放计算会话
   * @param sessionId 会话ID
   */
  public releaseSession(sessionId: string): void {
    const analyzer = this.sessions.get(sessionId);
    if (analyzer) {
      // 清理FFTAnalyzer内部资源
      analyzer.cleanup();
      this.sessions.delete(sessionId);
      console.info(`[FFT_POOL] 释放会话: ${sessionId}, 剩余会话数: ${this.sessions.size}`);
    } else {
      console.warn(`[FFT_POOL] 尝试释放不存在的会话: ${sessionId}`);
    }
  }

}