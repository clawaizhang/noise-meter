import { Subject } from 'rxjs';

/**
 * AudioController服务
 * 用于管理AudioController实例和事件通信
 */
export class AudioControllerService {
  private static instance: AudioControllerService | null = null;
  
  // 重置事件Subject
  private resetSubject = new Subject<void>();
  // 保存事件Subject
  private saveSubject = new Subject<string>();

  /**
   * 获取单例实例
   */
  public static getInstance(): AudioControllerService {
    if (!AudioControllerService.instance) {
      AudioControllerService.instance = new AudioControllerService();
    }
    return AudioControllerService.instance;
  }

  /**
   * 触发重置事件
   */
  public resetData(): void {
    this.resetSubject.next();
  }

  /**
   * 触发保存事件
   */
  public saveData(comments: string): void {
    this.saveSubject.next(comments);
  }

  /**
   * 订阅重置事件
   */
  public subscribeReset(callback: () => void): void {
    this.resetSubject.subscribe(callback);
  }

  /**
   * 订阅保存事件
   */
  public subscribeSave(callback: (comments: string) => void): void {
    this.saveSubject.subscribe(callback);
  }

  /**
   * 清理资源
   */
  public dispose(): void {
    this.resetSubject.complete();
    this.saveSubject.complete();
    AudioControllerService.instance = null;
  }
}