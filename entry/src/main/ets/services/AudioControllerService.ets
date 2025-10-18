import { Subject } from 'rxjs';
import { UIDisplayState } from '../models/UIDisplayState';
import { DataProcessingState } from '../models/DataProcessingState';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { AppKeys } from '../models/AppKeys';

/**
 * AudioController服务
 * 用于管理AudioController实例和事件通信
 */
export class AudioControllerService {
  private static instance: AudioControllerService | null = null;
  private dataProcessingState: DataProcessingState;
  private uiDisplayState: UIDisplayState;
  // 重置事件Subject
  private resetSubject = new Subject<void>();
  // 保存事件Subject
  private saveSubject = new Subject<string>();
  // 时间显示定时器
  private timeDisplayTimer?: number;
  private pk: PreferenceKeys;

  constructor(ak: AppKeys, pk: PreferenceKeys) {
    this.dataProcessingState = ak.dataProcessingState;
    this.uiDisplayState = ak.uiDisplayState;
    this.pk = pk;
  }


  /**
   * 获取单例实例
   */
  public static getInstance(ak: AppKeys, pk: PreferenceKeys): AudioControllerService {
    if (!AudioControllerService.instance) {
      AudioControllerService.instance = new AudioControllerService(ak, pk);
    }
    return AudioControllerService.instance;
  }

  /**
   * 获取单例实例
   */
  public static getInstancePlain(): AudioControllerService | null {
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
    // 立即更新一次时间显示
    this.uiDisplayState.updateTimeDisplay(this.pk);
    console.info('[双管线架构] UI更新已恢复');
  }

  /**
   * 检查是否在后台运行
   */
  public isInBackground(): boolean {
    return this.dataProcessingState.isBackground;
  }

  /**
   * 启动时间显示更新
   */
  public startTimeDisplayUpdates(): void {
    this.stopTimeDisplayUpdates(); // 先停止之前的定时器

    // 每秒更新一次时间显示
    this.timeDisplayTimer = setInterval(() => {
      const currentTime = Date.now();
      this.uiDisplayState.updateCurrentTime(currentTime);
      this.uiDisplayState.updateTimeDisplay(this.pk);
    }, 1000);

    console.info('[双管线架构] 时间显示更新已启动');
  }

  /**
   * 停止时间显示更新
   */
  public stopTimeDisplayUpdates(): void {
    if (this.timeDisplayTimer) {
      clearInterval(this.timeDisplayTimer);
      this.timeDisplayTimer = undefined;
      console.info('[双管线架构] 时间显示更新已停止');
    }
  }

  /**
   * 更新最后保存时间
   * @param saveTime 保存时间戳
   */
  public updateLastSaveTime(saveTime: number): void {
    this.uiDisplayState.updateLastSaveTime(saveTime);
    // 立即更新一次时间显示
    this.uiDisplayState.updateTimeDisplay(this.pk);
  }

  /**
   * 清理资源
   */
  public dispose(): void {
    this.stopTimeDisplayUpdates();
    this.resetSubject.complete();
    this.saveSubject.complete();
    AudioControllerService.instance = null;
  }
}