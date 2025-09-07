import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import media from '@ohos.multimedia.media';
import audio from '@ohos.multimedia.audio';
import hilog from '@ohos.hilog';
import fs from '@ohos.file.fs';
import { promptAction } from '@kit.ArkUI';
import { PreferenceService } from './PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import resourceManager from '@ohos.resourceManager';

const TAG = 'AudioPlayerService';
const DOMAIN = 0x0000;

/**
 * 播放器状态枚举
 */
export enum PlayerState {
  STATE_NOT_INIT = 'STATE_NOT_INIT',
  STATE_IDLE = 'STATE_IDLE',
  STATE_INITIALIZED = 'STATE_INITIALIZED',
  STATE_PREPARING = 'STATE_PREPARING',
  STATE_PREPARED = 'STATE_PREPARED',
  STATE_PLAYING = 'STATE_PLAYING',
  STATE_PAUSED = 'STATE_PAUSED',
  STATE_STOPPED = 'STATE_STOPPED',
  STATE_COMPLETED = 'STATE_COMPLETED',
  STATE_RELEASED = 'STATE_RELEASED',
  STATE_ERROR = 'STATE_ERROR'
}

/**
 * 音频播放服务
 */
export class AudioPlayerService {
  private player: media.AVPlayer | null = null;
  private currentState: PlayerState = PlayerState.STATE_NOT_INIT;
  private onProgressListener?: (duration: number) => void;
  private onStateChangeListener: Array<(state: PlayerState) => void> = [];
  private progressTimer: number | null = null;
  private currentFile: fs.File | null = null;
  private currentFd: number | null = null;

  constructor() {
    try {
      this.initPlayer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 初始化播放器
   */
  private async initPlayer(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '开始初始化播放器');
      // 创建播放器实例
      this.player = await media.createAVPlayer();
      hilog.info(DOMAIN, TAG, '播放器实例创建成功');

      if (!this.player) {
        throw new Error('播放器创建失败');
      }

      // 设置播放器事件监听
      this.setupPlayerListeners();

      this.updateState(PlayerState.STATE_IDLE);
      hilog.info(DOMAIN, TAG, '播放器初始化完成');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
      throw new Error(error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 设置播放器事件监听
   */
  private setupPlayerListeners(): void {
    if (!this.player) {
      return;
    }

    // seek操作结果回调函数
    this.player.on('seekDone', (seekDoneTime: number) => {
      hilog.info(DOMAIN, TAG, 'seek完成, 时间: %{public}d', seekDoneTime);
    });

    // 错误监听
    this.player.on('error', (error: BusinessError) => {
      hilog.error(DOMAIN, TAG, '播放错误: [%{public}d] %{public}s', error.code, error.message);
      this.updateState(PlayerState.STATE_ERROR);
      this.stopProgressTimer();
      // 调用reset重置资源，触发idle状态
      if (this.player) {
        this.player.reset();
      }
    });

    // 状态变化监听
    this.player.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      hilog.info(DOMAIN, TAG, '播放状态变化: %{public}s, 原因: %{public}s', state, reason);
      switch (state) {
        case 'idle': // 成功调用reset接口后触发该状态机上报
          this.updateState(PlayerState.STATE_IDLE);
          break;

        case 'initialized': // avplayer 设置播放源后触发该状态上报
          this.updateState(PlayerState.STATE_INITIALIZED);
          if (this.player) {
            this.player.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
              rendererFlags: 0
            };
            await this.player.prepare(); // 准备播放
          }
          break;

        case 'prepared': // prepare调用成功后上报该状态机
          this.updateState(PlayerState.STATE_PREPARED);
          if (this.player) {
            // await audio.getAudioManager().getVolumeManager().setAppVolumePercentage(100);
            await this.player.play(); // 自动开始播放
          }
          break;

        case 'playing': // play成功调用后触发该状态机上报
          this.updateState(PlayerState.STATE_PLAYING);
          this.startProgressTimer();
          break;

        case 'paused': // pause成功调用后触发该状态机上报
          this.updateState(PlayerState.STATE_PAUSED);
          // await audio.getAudioManager()
          //   .getVolumeManager()
          //   .setAppVolumePercentage(PreferenceService.getInstance().getNumber(PreferenceKeyConstants.VOLUME));
          this.stopProgressTimer();
          break;

        case 'completed': // 播放结束后触发该状态机上报
          this.updateState(PlayerState.STATE_COMPLETED);
          this.stopProgressTimer();
          // await audio.getAudioManager()
          //   .getVolumeManager()
          //   .setAppVolumePercentage(PreferenceService.getInstance().getNumber(PreferenceKeyConstants.VOLUME));
          if (this.player) {
            await this.player.stop(); // 调用播放结束接口
          }
          break;

        case 'stopped': // stop接口成功调用后触发该状态机上报
          // await audio.getAudioManager()
          //   .getVolumeManager()
          //   .setAppVolumePercentage(PreferenceService.getInstance().getNumber(PreferenceKeyConstants.VOLUME));
          this.updateState(PlayerState.STATE_STOPPED);
          if (this.player) {
            await this.player.reset(); // 调用reset接口初始化avplayer状态
          }
          break;

        case 'released': // release接口成功调用后触发该状态机上报
          // await audio.getAudioManager()
          //   .getVolumeManager()
          //   .setAppVolumePercentage(PreferenceService.getInstance().getNumber(PreferenceKeyConstants.VOLUME));
          this.updateState(PlayerState.STATE_RELEASED);
          break;

        default:
          hilog.warn(DOMAIN, TAG, '未知的播放器状态: %{public}s', state);
          break;
      }
    });
  }

  /**
   * 播放音频文件
   * @param fd - 音频文件fd
   */
  async playAudioFileByFd(fd: resourceManager.RawFileDescriptor): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('播放器未初始化');
      }
      // 如果正在播放或已完成播放，先重置播放器
      if (this.isPlaying() || this.currentState === PlayerState.STATE_COMPLETED) {
        await this.player.reset();
        this.updateState(PlayerState.STATE_IDLE);
      }

      // 关闭之前的文件描述符
      if (this.currentFd) {
        try {
          fs.closeSync(this.currentFd);
          this.currentFd = null;
        } catch (e) {
          hilog.error(DOMAIN, TAG, '关闭文件描述符失败: %{public}s', e instanceof Error ? e.message : String(e));
        }
      }

      let avFileDescriptor: media.AVFileDescriptor =
        { fd: fd.fd, offset: fd.offset, length: fd.length };
      // 为fdSrc赋值触发initialized状态机上报。
      this.player.fdSrc = avFileDescriptor;

      this.updateState(PlayerState.STATE_PREPARING);

      hilog.info(DOMAIN, TAG, '开始播放音频');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
      // 尝试重置播放器
      if (this.player) {
        try {
          await this.player.reset();
          this.updateState(PlayerState.STATE_IDLE);
        } catch (e) {
          hilog.error(DOMAIN, TAG, '重置播放器失败: %{public}s', e instanceof Error ? e.message : String(e));
        }
      }
      throw new Error(error instanceof Error ? error.message : String(error));
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

      // 如果正在播放或已完成播放，先重置播放器
      if (this.isPlaying() || this.currentState === PlayerState.STATE_COMPLETED) {
        await this.player.reset();
        this.updateState(PlayerState.STATE_IDLE);
      }

      hilog.info(DOMAIN, TAG, '准备播放音频文件: %{public}s', audioFilePath);

      // 关闭之前的文件描述符
      if (this.currentFile) {
        try {
          fs.closeSync(this.currentFile.fd);
          this.currentFile = null;
        } catch (e) {
          hilog.error(DOMAIN, TAG, '关闭文件描述符失败: %{public}s', e instanceof Error ? e.message : String(e));
        }
      }

      // 打开文件获取文件描述符
      this.currentFile = await fs.open(audioFilePath);
      const fdPath = `fd://${this.currentFile.fd}`;

      // 设置音频源
      this.player.url = fdPath;
      this.updateState(PlayerState.STATE_PREPARING);

      hilog.info(DOMAIN, TAG, '开始播放音频');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
      // 尝试重置播放器
      if (this.player) {
        try {
          await this.player.reset();
          this.updateState(PlayerState.STATE_IDLE);
        } catch (e) {
          hilog.error(DOMAIN, TAG, '重置播放器失败: %{public}s', e instanceof Error ? e.message : String(e));
        }
      }
      throw new Error(error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 释放播放器资源
   */
  async release(): Promise<void> {
    if (this.player) {
      try {
        // 先停止播放
        if (this.isPlaying()) {
          await this.stop();
        }

        // 停止进度计时器
        this.stopProgressTimer();

        // 取消事件监听
        this.player.off('error');
        this.player.off('stateChange');

        // 关闭文件描述符
        if (this.currentFile) {
          try {
            fs.closeSync(this.currentFile.fd);
            this.currentFile = null;
          } catch (e) {
            hilog.error(DOMAIN, TAG, '关闭文件描述符失败: %{public}s', e instanceof Error ? e.message : String(e));
          }
        }

        // 释放播放器资源
        await this.player.release();
        this.player = null;
        this.updateState(PlayerState.STATE_NOT_INIT);
        hilog.info(DOMAIN, TAG, '播放器资源释放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '释放播放器资源失败: %{public}s',
          error instanceof Error ? error.message : String(error));
        throw new Error(error instanceof Error ? error.message : String(error));
      }
    }
  }

  /**
   * 更新播放器状态
   */
  private updateState(state: PlayerState): void {
    this.currentState = state;
    if (this.onStateChangeListener?.length > 0) {
      this.onStateChangeListener.forEach(listener => listener(state));
    }
  }

  /**
   * 开始进度计时器
   */
  private startProgressTimer(): void {
    this.stopProgressTimer();
    this.progressTimer = setInterval(async () => {
      if (this.onProgressListener && this.player) {
        const position = await this.getCurrentPosition();
        this.onProgressListener(position);
      }
    }, 1000);
  }

  /**
   * 停止进度计时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (this.player && this.isPlaying()) {
      try {
        await this.player.pause();
        hilog.info(DOMAIN, TAG, '暂停播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '暂停播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(error instanceof Error ? error.message : String(error));
      }
    }
  }

  /**
   * 恢复播放
   */
  async resume(): Promise<void> {
    if (this.player && this.currentState === PlayerState.STATE_PAUSED) {
      try {
        await this.player.play();
        hilog.info(DOMAIN, TAG, '恢复播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '恢复播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(error instanceof Error ? error.message : String(error));
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
        hilog.info(DOMAIN, TAG, '停止播放成功');
      } catch (error) {
        hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(error instanceof Error ? error.message : String(error));
      }
    }
  }

  /**
   * 设置音量
   * @param volume - 音量值，范围 0.0-1.0
   */
  async setVolume(volume: number): Promise<void> {
    if (this.player) {
      try {
        const normalizedVolume = Math.max(0, Math.min(1, volume));
        this.player.setVolume(normalizedVolume);
      } catch (error) {
        hilog.error(DOMAIN, TAG, '设置音量失败: %{public}s', error instanceof Error ? error.message : String(error));
      }
    }
  }

  /**
   * 跳转到指定位置
   * @param position - 目标位置（毫秒）
   */
  async seekTo(position: number): Promise<void> {
    if (this.player) {
      try {
        this.player.seek(position);
      } catch (error) {
        hilog.error(DOMAIN, TAG, '跳转失败: %{public}s', error instanceof Error ? error.message : String(error));
        throw new Error(error instanceof Error ? error.message : String(error));
      }
    }
  }

  /**
   * 获取当前播放位置
   */
  async getCurrentPosition(): Promise<number> {
    if (!this.player) {
      return 0;
    }
    try {
      return this.player.currentTime;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取当前播放位置失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      return 0;
    }
  }

  /**
   * 获取音频总时长
   */
  async getDuration(): Promise<number> {
    if (!this.player) {
      return 0;
    }
    try {
      return this.player.duration;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取音频总时长失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      return 0;
    }
  }

  /**
   * 检查是否正在播放
   */
  isPlaying(): boolean {
    return this.currentState === PlayerState.STATE_PLAYING;
  }

  /**
   * 获取当前播放状态
   */
  getPlayerState(): PlayerState {
    return this.currentState;
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
  addOnStateChangeListener(listener: (state: PlayerState) => void): void {
    this.onStateChangeListener?.push(listener);
  }
} 