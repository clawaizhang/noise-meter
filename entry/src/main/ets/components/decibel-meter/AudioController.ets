import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { AudioPresets, WindowType } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { LocationInfo } from '../../services/LocationService';
import { WeightingType } from '../../constants/WeightingConstants';
import { Subject } from 'rxjs';
import { AppKeys } from '../../models/AppKeys';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { AudioControllerService } from '../../services/AudioControllerService';

/**
 * 带时间戳的分贝值接口
 */
interface TimedDecibelValue {
  timestamp: number;
  value: number;
}

/**
 * 带时间戳的加权类型接口
 */
interface TimedWeightingType {
  timestamp: number;
  type: WeightingType;
}

/**
 * 带时间戳的音频缓冲区接口
 */
interface TimedAudioBuffer {
  timestamp: number;
  buffer: ArrayBuffer;
}

@ComponentV2
export struct AudioController {
  // 音频状态
  @Local private isRecording: boolean = false
  @Local private recordingTime: number = 0
  @Local private startTime: number = 0
  // 错误状态（支持多个错误同时显示）
  @Local private errorMessages: string[] = []
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  // 配置参数
  @Param @Require pk: PreferenceKeys
  @Param @Require currentLocation: LocationInfo | null = null
  // 事件发射器
  @Event onSpectrumData: (spectrum: Float32Array) => void
  @Event onError: (errors: string[]) => void
  @Event onRecordingStateChange: (isRecording: boolean) => void
  @Event onRecordingTimeUpdate: (time: number) => void
  @Event onMinMaxAvgCurrent: (min: number, max: number, avg: number, current: number) => void
  @Event onAutoSaveTimeUpdate: (lastSaveTime: number) => void
  // 服务实例
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  // RxJS相关
  private audioBufferSubject = new Subject<void>();
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance();
  // 自动保存相关属性
  private autoSaveTimer?: number;
  private lastAutoSaveTime: number = 0;
  // 20分钟数据保留相关属性
  private dataCleanupTimer?: number;
  private readonly DATA_RETENTION_MINUTES = 20;
  private readonly CLEANUP_CHECK_INTERVAL = 60000; // 1分钟检查一次
  // 记录相关
  private timedValues: TimedDecibelValue[] = []
  private timedWeightingTypes: TimedWeightingType[] = []
  private timedAudioBuffers: TimedAudioBuffer[] = []
  private currentRecord?: DecibelRecord
  private minDecibel: number = 0;
  private maxDecibel: number = 0;
  private avgDecibel: number = 0;
  private currentDecibel: number = 0;
  private isNoiseAlarm: boolean = false;

  @Computed
  get fft_size() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Monitor('ak.microphonePermissionGranted')
  onRecordingPermissionChange(monitor: IMonitor) {
    let permissionGranted = monitor.value<boolean>()?.now!;
    if (permissionGranted) {
      this.startRecording();
    }
  }

  aboutToAppear() {
    if (this.ak.microphonePermissionGranted) {
      this.startRecording();
    }

    // 订阅重置事件
    this.audioControllerService.subscribeReset(() => {
      this.performReset();
    });

    // 订阅保存事件
    this.audioControllerService.subscribeSave((comments: string) => {
      this.performSave(comments);
    });

  }

  aboutToDisappear() {
    // 清理RxJS资源
    this.audioBufferSubject.complete();
    this.stopAutoSaveMonitoring();
    this.stopDataCleanupMonitoring();
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
  }

  async startRecording(): Promise<void> {
    try {
      // 启动音频采集，带重试机制
      const maxRetries = 3;
      const retryInterval = 1000; // 1秒
      let retryCount = 0;

      while (true) {
        try {
          await this.audioService.startCapture();
          console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
          break; // 成功则退出循环
        } catch (error) {
          retryCount++;
          console.error(`[FREQ_TRACE][Audio] 音频采集启动失败，重试次数：${retryCount}/${maxRetries}`, error);
          await new Promise<void>(resolve => setTimeout(resolve, retryInterval));
          if (retryCount > maxRetries) {
            // 达到最大重试次数，提示用户
            this.addErrorMessage(`音频采集启动失败: ${error.message}`);
            return;
          }
        }
      }

      this.isRecording = true;
      this.startTime = new Date().getTime();
      this.recordingTime = 0;
      this.timedValues = [];
      this.timedAudioBuffers = [];
      this.clearErrorMessage();

      // 创建新的记录对象
      this.currentRecord = new DecibelRecord(
        0, // minDecibel
        0, // maxDecibel
        0, // avgDecibel
        0, // duration
        [], // decibelValues
        undefined, // location
        undefined// audioFilePath
      );

      // 初始化 weightingTypes 数组
      this.timedWeightingTypes = [];

      // 如果启用了录音功能，开始录音
      if (this.pk.record_enabled) {
        this.audioService.startRecording();
      }

      // 启动自动保存监控
      this.startAutoSaveMonitoring();

      // 启动数据清理监控
      this.startDataCleanupMonitoring();

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 发出事件通知有新的音频数据到达
        this.audioBufferSubject.next();

        // 存储带时间戳的音频缓冲区
        const currentTime = Date.now();
        this.timedAudioBuffers.push({timestamp: currentTime, buffer: buffer.slice(0)});

        // 计算频谱数据（用于频谱图显示）
        const overrideEnabled = this.pk.window_function_override_enabled;
        const overrideType = this.pk.window_function_override_type;

        taskpool.execute<[string, ArrayBuffer, WeightingType, number, WindowType], Float32Array>(
          concurrentCalculateSpectrum,
          this.pk.audio_analysis_mode,
          buffer.slice(0),
          this.pk.weighting_type,
          this.pk.calibration_value,
          overrideEnabled ? overrideType : AudioPresets.getConfig(this.pk.audio_analysis_mode).windowType
        ).then((spectrum) => {
          this.onSpectrumData(spectrum);

          // 计算分贝值
          const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
          const db: number = new FFTAnalyzer(
            config.fftSize,
            config.windowType,
            config.smoothingFactor,
            config.overlap
          ).calculateAverageDb(spectrum);
          this.currentDecibel = Math.round(db);

          // 收集分贝值和加权类型（带时间戳）
          const currentTime = new Date().getTime();
          this.timedValues.push({timestamp: currentTime, value: this.currentDecibel});
          this.timedWeightingTypes.push({timestamp: currentTime, type: this.pk.weighting_type});

          // 更新统计信息
          this.updateStatistics(this.currentDecibel);

          // 检查报警状态
          this.checkAlarmStatus(this.currentDecibel);

          // 更新计时器（毫秒级）
          this.recordingTime = new Date().getTime() - this.startTime;
          this.onRecordingTimeUpdate(this.recordingTime);
        })
      });

      this.onRecordingStateChange(true);

    } catch (error) {
      // 如果启动失败，重置状态
      this.isRecording = false;
      this.onRecordingStateChange(false);
      this.addErrorMessage(`音频采集启动失败: ${error.message}`);
      this.resetData();
    }
  }

  async stopRecording(comments: string): Promise<void> {
    if (this.isRecording) {
      this.isRecording = false;
      this.onRecordingStateChange(false);
      console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

      // 停止自动保存监控
      this.stopAutoSaveMonitoring();

      // 停止数据清理监控
      this.stopDataCleanupMonitoring();

      // 判断是否为自动保存
      const isAutoSave = comments === '自动保存';

      try {
        let locationInfo: LocationInfo | null = null;

        if (this.pk.location_enabled) {
          locationInfo = this.currentLocation;
          console.info('[FREQ_TRACE][Location] 位置信息:', locationInfo);
        } else {
          console.info('[FREQ_TRACE][Location] 位置服务已关闭，不保存位置信息');
        }

        // 计算检测时长
        const duration: number = new Date().getTime() - this.startTime;
        console.info('[FREQ_TRACE][Duration] 检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath: string = '';

        if (this.pk.record_enabled) {
          try {
            // 获取最近20分钟的音频数据
            const recentAudioBuffers = this.timedAudioBuffers.map(item => item.buffer);
            console.info(`[音频保存] 使用最近${this.DATA_RETENTION_MINUTES}分钟的音频数据，缓冲区数量: ${recentAudioBuffers.length}`);
            
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(recentAudioBuffers);
          } catch (error) {
            console.error('[FREQ_TRACE][Audio] 获取或保存WAV音频数据失败:', error);
            this.addErrorMessage(`音频文件保存失败: ${error.message}`);
          }
        }

        console.info('[FREQ_TRACE][Record] 准备创建记录');
        // 更新记录对象
        if (this.currentRecord) {
          this.currentRecord.minDecibel = this.minDecibel;
          this.currentRecord.maxDecibel = this.maxDecibel;
          this.currentRecord.avgDecibel = this.avgDecibel;
          this.currentRecord.duration = duration;
          this.currentRecord.decibelValues = this.timedValues.map(item => item.value);
          this.currentRecord.weightingTypes = this.timedWeightingTypes.map(item => item.type);
          this.currentRecord.audioFilePath = currentAudioFilePath;
          this.currentRecord.location = locationInfo?.address;
          this.currentRecord.comment = comments;

          // 保存记录
          await this.recordService.saveRecord(this.currentRecord);
          console.info('[FREQ_TRACE][Record] 记录保存成功');

          // 显示详情对话框
          if (isAutoSave) {
            promptAction.showToast({
              message: '自动保存记录成功',
              duration: 3000
            });
          }
        }

        // 重置状态
        this.resetData();

        // 自动开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500); // 延迟500ms后开始新的检测

      } catch (error) {
        console.error('[FREQ_TRACE][Record] 保存记录失败:', error);
        this.addErrorMessage(`记录保存失败: ${error.message}`);
        // 即使保存失败也开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500);
      }
    }
  }

  addDecibelValue(decibel: number, weightingType: WeightingType): void {
    const currentTime = new Date().getTime();
    this.timedValues.push({timestamp: currentTime, value: decibel});
    this.timedWeightingTypes.push({timestamp: currentTime, type: weightingType});
  }

  resetData() {
    // 重置状态
    this.timedValues = [];
    this.timedAudioBuffers = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;

    // 重置 weightingTypes 数组
    this.timedWeightingTypes = [];

    // 重置统计信息
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.currentDecibel = 0;

    // 通知UI更新
    this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, this.currentDecibel);
    this.onRecordingTimeUpdate(this.recordingTime);
  }


  private addErrorMessage(message: string): void {
    if (!this.errorMessages.includes(message)) {
      this.errorMessages.push(message);
      this.onError([...this.errorMessages]);
    }
  }

  private clearErrorMessage(): void {
    this.errorMessages = [];
    this.onError([]);
  }

  // 更新统计信息
  private updateStatistics(currentDb: number): void {
    const values = this.timedValues.map(item => item.value);
    
    if (values.length === 0) {
      this.minDecibel = currentDb;
      this.maxDecibel = currentDb;
      this.avgDecibel = currentDb;
    } else {
      this.minDecibel = Math.min(...values);
      this.maxDecibel = Math.max(...values);
      this.avgDecibel = Math.round(values.reduce((sum, val) => sum + val, 0) / values.length);
    }
    this.ak.db = currentDb;
    this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, currentDb);
  }

  // 检查报警状态
  private checkAlarmStatus(currentDb: number): void {
    const shouldAlarm = this.pk.system_notification_enabled && currentDb >= this.pk.noise_threshold;
    if (shouldAlarm !== this.isNoiseAlarm) {
      this.isNoiseAlarm = shouldAlarm;
      // 可以在这里触发报警通知
      if (this.isNoiseAlarm) {
        console.info(`[Alarm] 噪音超过阈值: ${currentDb}dB >= ${this.pk.noise_threshold}dB`);
      }
    }
  }

  build() {
    // AudioController 主要负责逻辑处理，不渲染UI
    // UI渲染由父组件DecibelMeter负责
    Column()
  }


  // 执行重置操作
  private performReset() {
    console.info('[FREQ_TRACE][Reset] 开始重置数据');
    
    // 重置数据
    this.timedValues = [];
    this.timedAudioBuffers = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;
    this.timedWeightingTypes = [];
    
    // 重置统计信息
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.currentDecibel = 0;

    // 通知UI更新
    this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, this.currentDecibel);
    this.onRecordingTimeUpdate(this.recordingTime);
    
    console.info('[FREQ_TRACE][Reset] 数据重置完成');
  }

  // 执行保存操作
  private performSave(comments: string) {
    console.info('[FREQ_TRACE][Save] 开始保存数据');
    this.stopRecording(comments);
  }

  // 自动保存监控方法
  private startAutoSaveMonitoring(): void {
    this.stopAutoSaveMonitoring();
    
    if (this.pk.auto_save_enabled && this.isRecording) {
      this.lastAutoSaveTime = new Date().getTime();
      
      // 每秒检查一次是否需要自动保存
      this.autoSaveTimer = setInterval(() => {
        this.checkAutoSave();
      }, 1000);
    }
  }

  private stopAutoSaveMonitoring(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = undefined;
    }
  }

  private checkAutoSave(): void {
    if (!this.pk.auto_save_enabled || !this.isRecording) {
      return;
    }
    
    const currentTime = new Date().getTime();
    const elapsed = currentTime - this.lastAutoSaveTime;
    const intervalMs = this.pk.auto_save_interval * 60 * 1000;
    
    // 检查是否达到自动保存间隔且有足够数据
    if (elapsed >= intervalMs && this.timedValues.length > 10) {
      this.performAutoSave();
    }
  }

  private performAutoSave(): void {
    console.info('[自动保存] 执行定时自动保存');
    
    // 更新最后保存时间
    this.lastAutoSaveTime = new Date().getTime();
    
    // 通知父组件更新时间
    this.onAutoSaveTimeUpdate(this.lastAutoSaveTime);
    
    // 显示保存提示
    promptAction.showToast({
      message: `自动保存记录（${this.pk.auto_save_interval}分钟）`,
      duration: 2000
    });
    
    // 调用保存逻辑
    this.performSave('自动保存');
  }

  // 20分钟数据清理相关方法

  /**
   * 启动数据清理监控
   */
  private startDataCleanupMonitoring(): void {
    this.stopDataCleanupMonitoring();
    
    if (!this.pk.auto_save_enabled && this.isRecording) {
      console.info('[数据清理] 启动20分钟数据清理监控');
      this.dataCleanupTimer = setInterval(() => {
        this.cleanupOldData();
      }, this.CLEANUP_CHECK_INTERVAL);
    }
  }

  /**
   * 停止数据清理监控
   */
  private stopDataCleanupMonitoring(): void {
    if (this.dataCleanupTimer) {
      clearInterval(this.dataCleanupTimer);
      this.dataCleanupTimer = undefined;
      console.info('[数据清理] 停止数据清理监控');
    }
  }

  /**
   * 清理过期数据（超过20分钟的数据）
   */
  private cleanupOldData(): void {
    if (this.pk.auto_save_enabled) {
      return; // 自动保存开启时不清理数据
    }
    
    const currentTime = new Date().getTime();
    const cutoffTime = currentTime - (this.DATA_RETENTION_MINUTES * 60 * 1000);
    
    // 清理过期的分贝值
    const originalValuesLength = this.timedValues.length;
    this.timedValues = this.timedValues.filter(item => item.timestamp >= cutoffTime);
    
    // 清理过期的加权类型
    this.timedWeightingTypes = this.timedWeightingTypes.filter(item => item.timestamp >= cutoffTime);
    
    // 清理过期的音频缓冲区
    const originalAudioBuffersLength = this.timedAudioBuffers.length;
    this.timedAudioBuffers = this.timedAudioBuffers.filter(item => item.timestamp >= cutoffTime);
    
    if (originalValuesLength !== this.timedValues.length || originalAudioBuffersLength !== this.timedAudioBuffers.length) {
      console.info(`[数据清理] 清理了${originalValuesLength - this.timedValues.length}条分贝数据，${originalAudioBuffersLength - this.timedAudioBuffers.length}条音频数据，保留${this.timedValues.length}条分贝数据，${this.timedAudioBuffers.length}条音频数据`);
    }
  }

}