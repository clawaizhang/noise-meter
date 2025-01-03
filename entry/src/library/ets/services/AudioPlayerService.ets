import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { FileService } from './FileService';
import { CcPlayer, MediaSourceFactory, PlayerState } from '@seagazer/ccplayer';

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
    this.initPlayer();
  }

  /**
   * 初始化播放器
   */
  private initPlayer(): void {
    // 创建播放器实例
    this.player = new CcPlayer(this.context);
    // 设置循环播放为false
    this.player.setLooper(false);
    // 设置音量为1.0
    this.player.setVolume(1.0);
    // 设置播放完成监听
    this.player.addOnCompletionListener(() => {
      if (this.onStateChangeListener) {
        this.onStateChangeListener(PlayerState.STATE_COMPLETED);
      }
    });
    // 设置错误监听
    this.player.addOnErrorListener((code: number, message: string) => {
      console.error(`播放错误: [${code}] ${message}`);
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

      // 创建媒体源
      const mediaSource = await MediaSourceFactory.createFile('audio', audioFilePath);
      // 设置媒体源并在准备就绪后开始播放
      this.player.setMediaSource(mediaSource, () => {
        this.player?.start();
      });
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`播放音频失败: ${businessError.message}`);
      throw new Error(`播放音频失败: ${businessError.message}`);
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (this.player && this.isPlaying()) {
      try {
        await this.player.pause();
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`暂停播放失败: ${businessError.message}`);
        throw new Error(`暂停播放失败: ${businessError.message}`);
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
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`恢复播放失败: ${businessError.message}`);
        throw new Error(`恢复播放失败: ${businessError.message}`);
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
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`停止播放失败: ${businessError.message}`);
        throw new Error(`停止播放失败: ${businessError.message}`);
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
        await this.stop();
        await this.player.release();
        this.player = null;
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`释放播放器失败: ${businessError.message}`);
        throw new Error(`释放播放器失败: ${businessError.message}`);
      }
    }
  }
} 