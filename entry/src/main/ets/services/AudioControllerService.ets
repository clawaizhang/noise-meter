import { Subject } from 'rxjs';
import { UIDisplayState } from '../models/UIDisplayState';
import { AppStorageV2 } from '@kit.ArkUI';
import { DataProcessingState } from '../models/DataProcessingState';

/**
 * AudioController服务
 * 用于管理AudioController实例和事件通信
 */
export class AudioControllerService {
  private static instance: AudioControllerService | null = null;
  private dataProcessingState: DataProcessingState = AppStorageV2.connect(DataProcessingState,() => new DataProcessingState())!;
  private uiDisplayState: UIDisplayState = AppStorageV2.connect(UIDisplayState,() => new UIDisplayState())!;
  
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
   * 暂停UI更新（后台运行时调用）
   */
  public pauseUIUpdates(): void {
    this.uiDisplayState.pauseUIUpdates();
    this.dataProcessingState.isBackground = true;
    console.info('[双管线架构] UI更新已暂停');
  }

  /**
   * 恢复UI更新（前台运行时调用）
   */
  public resumeUIUpdates(): void {
    this.uiDisplayState.resumeUIUpdates();
    this.dataProcessingState.isBackground = false;
    // 同步最新数据到UI
    this.uiDisplayState.syncFromProcessingState(this.dataProcessingState);
    console.info('[双管线架构] UI更新已恢复');
  }

  /**
   * 检查是否在后台运行
   */
  public isInBackground(): boolean {
    return this.dataProcessingState.isBackground;
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