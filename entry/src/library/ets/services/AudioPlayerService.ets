import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { FileService } from './FileService';
import { CcPlayer, MediaSourceFactory, PlayerState } from '@seagazer/ccplayer';
import hilog from '@ohos.hilog';

const TAG = 'AudioPlayerService';
const DOMAIN = 0x0000;

/**
 * 音频播放服务
 */
export class AudioPlayerService {
  private player: CcPlayer | null = null;
  private fileService: FileService;
  private context: common.Context;
  private onProgressListener?: (duration: number) => void;
  private onStateChangeListener?: (state: PlayerState) => void;

  constructor(context: common.Context, fileService: FileService) {
    this.context = context;
    this.fileService = fileService;
    try {
      this.initPlayer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 初始化播放器
   */
  private initPlayer(): void {
    try {
      hilog.info(DOMAIN, TAG, '开始初始化播放器');
      // 创建播放器实例
      this.player = new CcPlayer(this.context);
      hilog.info(DOMAIN, TAG, '播放器实例创建成功');

      if (!this.player) {
        throw new Error('播放器创建失败');
      }

      // 设置循环播放为false
      this.player.setLooper(false);
      hilog.info(DOMAIN, TAG, '设置循环播放完成');

      // 设置音量为1.0
      this.player.setVolume(1.0);
      hilog.info(DOMAIN, TAG, '设置音量完成');

      // 设置播放完成监听
      this.player.addOnCompletionListener(() => {
        hilog.info(DOMAIN, TAG, '播放完成');
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_COMPLETED);
        }
      });

      // 设置错误监听
      this.player.addOnErrorListener((code: number, message: string) => {
        hilog.error(DOMAIN, TAG, '播放错误: [%{public}d] %{public}s', code, message);
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_ERROR);
        }
      });

      // 设置进度监听
      this.player.addOnProgressChangedListener((duration: number) => {
        if (this.onProgressListener) {
          this.onProgressListener(duration);
        }
      });

      hilog.info(DOMAIN, TAG, '播放器初始化完成');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
      throw new Error(error);
    }
  }

  /**
   * 播放音频文件
   * @param audioFilePath - 音频文件路径
   */
  async playAudioFile(audioFilePath: string): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('播放器未初始化');
      }

      // 如果正在播放，先停止
      if (this.isPlaying()) {
        await this.stop();
      }

      hilog.info(DOMAIN, TAG, '准备播放音频文件: %{public}s', audioFilePath);
      // 创建媒体源
      const mediaSource = await MediaSourceFactory.createFile('audio', audioFilePath);
      hilog.info(DOMAIN, TAG, '媒体源创建成功');

      // 设置媒体源并在准备就绪后开始播放
      this.player.setMediaSource(mediaSource, () => {
        hilog.info(DOMAIN, TAG, '媒体源设置成功，开始播放');
        this.player?.start();
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_STARTED);
        }
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error(`播放音频失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (this.player && this.isPlaying()) {
      try {
        await this.player.pause();
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_PAUSED);
        }
        hilog.info(DOMAIN, TAG, '暂停播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '暂停播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(`暂停播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 恢复播放
   */
  async resume(): Promise<void> {
    if (this.player && !this.isPlaying()) {
      try {
        await this.player.start();
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_STARTED);
        }
        hilog.info(DOMAIN, TAG, '恢复播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '恢复播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(`恢复播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    if (this.player) {
      try {
        await this.player.stop();
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_STOPPED);
        }
        hilog.info(DOMAIN, TAG, '停止播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(`停止播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 设置音量
   * @param volume - 音量值，范围 0.0-1.0
   */
  setVolume(volume: number): void {
    if (this.player) {
      this.player.setVolume(Math.max(0, Math.min(1, volume)));
    }
  }

  /**
   * 跳转到指定位置
   * @param position - 目标位置（毫秒）
   */
  async seekTo(position: number): Promise<void> {
    if (this.player) {
      try {
        await this.player.seekTo(position);
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`跳转失败: ${businessError.message}`);
        throw new Error(`跳转失败: ${businessError.message}`);
      }
    }
  }

  /**
   * 获取当前播放位置
   */
  getCurrentPosition(): number {
    return this.player?.getCurrentPosition() ?? 0;
  }

  /**
   * 获取音频总时长
   */
  getDuration(): number {
    return this.player?.getDuration() ?? 0;
  }

  /**
   * 检查是否正在播放
   */
  isPlaying(): boolean {
    return this.player?.isPlaying() ?? false;
  }

  /**
   * 获取当前播放状态
   */
  getPlayerState(): PlayerState {
    return this.player?.getPlayerState() ?? PlayerState.STATE_NOT_INIT;
  }

  /**
   * 设置进度监听器
   */
  setOnProgressListener(listener: (duration: number) => void): void {
    this.onProgressListener = listener;
  }

  /**
   * 设置状态变化监听器
   */
  setOnStateChangeListener(listener: (state: PlayerState) => void): void {
    this.onStateChangeListener = listener;
  }

  /**
   * 释放播放器资源
   */
  async release(): Promise<void> {
    if (this.player) {
      try {
        // 先停止播放
        if (this.player.isPlaying() || this.getPlayerState() === PlayerState.STATE_PAUSED) {
          await this.stop();
        }
        // 释放播放器资源
        await this.player.release();
        this.player = null;
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_NOT_INIT);
        }
        hilog.info(DOMAIN, TAG, '播放器资源释放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '释放播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(`释放播放器失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }
} 