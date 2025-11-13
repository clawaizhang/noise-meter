import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { AppStorageV2, PersistenceV2, promptAction } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { LocationInfo } from '../../services/LocationService';
import { WeightingType } from '../../constants/WeightingConstants';
import { AppKeys } from '../../models/AppKeys';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { AudioControllerService } from '../../services/AudioControllerService';
import { WindowType } from '../../common/WindowType';
import { Subscription } from 'rxjs';
import { AudioControllerLifecycleState, StateTransitionEvent } from '../../models/AudioControllerLifecycleState';
import {
  AudioControllerEvent,
  AudioControllerEventType,
  ResumeRecordingEvent
} from '../../models/AudioControllerEvents';
import { AutoSaveService } from '../../services/AutoSaveService';
import { PeakInterpolationMethod, SpectrumDataProcessor } from './SpectrumDataProcessor';

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
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  // 配置参数
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // RxJS订阅管理
  private locationSubscription?: Subscription;
  private errorSubscription?: Subscription;
  // 错误状态（支持多个错误同时显示）
  private errorMessages: string[] = []
  // 当前位置信息
  private currentLocation: LocationInfo | null = null;
  // 服务实例
  private audioService: AudioService = AudioService.getInstance(this.pk)
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
  // 自动保存服务
  private autoSaveService: AutoSaveService = AutoSaveService.getInstance(this.ak, this.pk);
  // 20分钟数据保留相关属性
  private dataCleanupTimer?: number;
  private readonly CLEANUP_CHECK_INTERVAL = 60000; // 1分钟检查一次
  private readonly CLEAN_INTERVAL_MINUTES = 60;
  // 记录相关
  private timedValues: TimedDecibelValue[] = []
  private timedWeightingTypes: TimedWeightingType[] = []
  private timedAudioBuffers: TimedAudioBuffer[] = []
  private originAudioBuffers: TimedAudioBuffer[] = []
  private currentRecord?: DecibelRecord
  private isNoiseAlarm: boolean = false;
  // 状态机相关属性
  private stateMachineSubscription?: Subscription;
  private eventSubscription?: Subscription;

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
    // 初始化AudioService配置
    this.audioService.initializeConfig();
    
    // 启动时间显示更新
    this.audioControllerService.startTimeDisplayUpdates();

    // 初始化状态机
    this.initializeStateMachine();

    if (this.ak.microphonePermissionGranted) {
      this.startRecording();
    }

    // 订阅重置事件
    this.audioControllerService.subscribeReset(() => {
      this.resetData();
    });

    // 订阅保存事件
    this.audioControllerService.subscribeSave((comments: string) => {
      this.performSave(comments);
    });

    // 订阅位置数据流
    this.locationSubscription = this.audioControllerService.getLocation$().subscribe(
      (location: LocationInfo | null) => {
        this.currentLocation = location;
        console.info('[RxJS] 位置信息已更新:', location);
      }
    );

    // 订阅错误数据流
    this.errorSubscription = this.audioControllerService.getError$().subscribe(
      (errors: string[]) => {
        this.errorMessages = errors;
        console.info('[RxJS] 错误信息已更新:', errors);
      }
    );

  }

  aboutToDisappear() {
    // 停止时间显示更新
    this.audioControllerService.stopTimeDisplayUpdates();

    // 清理RxJS订阅
    if (this.locationSubscription) {
      this.locationSubscription.unsubscribe();
    }
    if (this.errorSubscription) {
      this.errorSubscription.unsubscribe();
    }
    if (this.stateMachineSubscription) {
      this.stateMachineSubscription.unsubscribe();
    }
    if (this.eventSubscription) {
      this.eventSubscription.unsubscribe();
    }

    // 清理自动保存监控
    this.autoSaveService.stopAutoSaveMonitoring();

    // 清理其他资源
    this.stopDataCleanupMonitoring();
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
  }

  async startRecording(): Promise<void> {
    try {
      // 使用状态机控制录制
      const stateMachine = this.audioControllerService.getStateMachine();
      if (stateMachine) {
        await stateMachine.startRecording();
      }
    } catch (error) {
      console.error('[AudioController] 启动录制失败:', error);
      throw new Error('启动录制失败');
    }
  }

  private async tryStartCapture() {
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
        }
      }
    }
  }

  async stopRecording(comments: string): Promise<void> {
    try {
      // 使用状态机控制停止
      const stateMachine = this.audioControllerService.getStateMachine();
      if (stateMachine) {
        await stateMachine.stopRecording(comments);
      }
    } catch (error) {
      console.error('[AudioController] 停止录制失败:', error);
      throw new Error('停止录制失败');
    }
  }

  addDecibelValue(decibel: number, weightingType: WeightingType): void {
    const currentTime = new Date().getTime();
    this.timedValues.push({ timestamp: currentTime, value: decibel });
    this.timedWeightingTypes.push({ timestamp: currentTime, type: weightingType });
  }

  resetData() {
    // 重置状态
    this.timedValues = [];
    this.timedAudioBuffers = [];
    this.originAudioBuffers = [];
    this.ak.dataProcessingState.statisticsData.startTime = new Date().getTime();

    // 重置 weightingTypes 数组
    this.timedWeightingTypes = [];

    this.ak.dataProcessingState.statisticsData.reset();
    this.ak.uiDisplayState.reset();

  }

  private addErrorMessage(message: string): void {
    if (!this.errorMessages.includes(message)) {
      this.errorMessages.push(message);
      // 通过RxJS发布错误信息
      this.audioControllerService.publishError([...this.errorMessages]);
    }
  }

  private clearErrorMessage(): void {
    this.errorMessages = [];
    // 通过RxJS清除错误信息
    this.audioControllerService.publishError([]);
  }

  // 更新统计信息
  private updateStatistics(currentDb: number, spectrumData: Float32Array): void {
    const values = this.timedValues.map(item => item.value);

    // 双管线架构：更新数据处理状态
    this.ak.dataProcessingState.processingDb = currentDb;
    this.ak.dataProcessingState.processingSpectrumData = spectrumData;
    this.ak.dataProcessingState.statisticsData.updateStatistics(currentDb, values);

    // 同步到UI显示状态（仅在UI更新启用时）
    this.ak.uiDisplayState.syncFromProcessingState(this.ak.dataProcessingState);

    console.debug(`[统计更新] 分贝值: ${currentDb}dB, 历史数据点: ${values.length}, 统计分布: [${this.ak.uiDisplayState.displayStatisticsDistribution.join(', ')}]`);
  }

  /**
   * 处理时域波形数据
   * @param buffer 音频数据缓冲区
   */
  private processTimeDomainData(buffer: ArrayBuffer): void {
    try {
      // 将ArrayBuffer转换为Int16Array
      const samples = new Int16Array(buffer);

      // 限制数据点数量以提高性能（每4个样本取1个）
      const downsampledData: number[] = [];
      const step = Math.max(1, Math.floor(samples.length / 512)); // 目标512个数据点

      for (let i = 0; i < samples.length; i += step) {
        if (downsampledData.length >= 512) {
          break;
        } // 限制最大数据点数量

        // 归一化到[-1, 1]范围
        const normalizedValue = samples[i] / 32768.0;
        downsampledData.push(normalizedValue);
      }

      // 更新UI显示状态
      if (this.ak.uiDisplayState.isUIUpdatesEnabled) {
        this.ak.uiDisplayState.displayTimeDomainData = downsampledData;
      }

      console.debug(`[时域处理] 处理了${downsampledData.length}个数据点`);
    } catch (error) {
      console.error(`[时域处理] 处理时域数据时出错: ${error instanceof Error ? error.message : String(error)}`);
    }
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

  // 执行保存操作
  private performSave(comments: string) {
    console.info('[FREQ_TRACE][Save] 开始保存数据');

    // 更新UI显示状态中的保存时间（手动保存时）
    const currentTime = Date.now();
    this.audioControllerService.updateRecordingStartTime(currentTime);

    this.stopRecording(comments);
  }

  /**
   * 启动数据清理监控
   */
  private startDataCleanupMonitoring(): void {
    this.stopDataCleanupMonitoring();
    console.info('[数据清理] 启动数据清理监控');
    this.dataCleanupTimer = setInterval(() => {
      this.cleanupOldData();
    }, this.CLEANUP_CHECK_INTERVAL);
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
   * 清理过期数据
   */
  private cleanupOldData(): void {
    let cleanInterval = this.pk.auto_save_enabled ? this.pk.auto_save_interval : this.CLEAN_INTERVAL_MINUTES;
    const currentTime = new Date().getTime();
    const cutoffTime = currentTime - (cleanInterval * 60 * 1000);

    // 清理过期的分贝值
    const originalValuesLength = this.timedValues.length;
    this.timedValues = this.timedValues.filter(item => item.timestamp >= cutoffTime);

    // 清理过期的加权类型
    this.timedWeightingTypes = this.timedWeightingTypes.filter(item => item.timestamp >= cutoffTime);

    // 清理过期的音频缓冲区
    const originalAudioBuffersLength = this.timedAudioBuffers.length;
    this.timedAudioBuffers = this.timedAudioBuffers.filter(item => item.timestamp >= cutoffTime);

    this.originAudioBuffers = this.originAudioBuffers.filter(item => item.timestamp >= cutoffTime);

    // 如果数据被清理，重置增量统计并重新计算基于剩余数据的统计
    if (originalValuesLength !== this.timedValues.length) {
      this.ak.dataProcessingState.statisticsData.resetIncremental();
      // 重新计算基于剩余数据的统计
      const remainingValues = this.timedValues.map(item => item.value);
      if (remainingValues.length > 0) {
        const lastValue = remainingValues[remainingValues.length - 1];
        this.ak.dataProcessingState.statisticsData.updateStatistics(lastValue, remainingValues);
      }
    }
  }

  // ========== 状态机相关方法 ==========

  /**
   * 初始化状态机
   */
  private initializeStateMachine(): void {
    // 通过AudioControllerService初始化状态机（不再传入this实例）
    this.audioControllerService.initializeStateMachine();

    // 监听状态机事件
    this.audioControllerService.onEvent((event) => {
      this.handleStateMachineEvent(event);
    });

    console.info('[AudioController] 状态机事件监听已设置');
  }

  /**
   * 处理状态机事件
   */
  private handleStateMachineEvent(event: AudioControllerEvent): void {
    switch (event.type) {
      case AudioControllerEventType.START_RECORDING:
        this.handleStartRecordingEvent();
        break;
      case AudioControllerEventType.STOP_RECORDING:
        const stopEvent = event as StopRecordingEventWithPayload;
        this.handleStopRecordingEvent((stopEvent.payload as StopRecordingPayload).comments);
        break;
      case AudioControllerEventType.PAUSE_RECORDING:
        this.handlePauseRecordingEvent();
        break;
      case AudioControllerEventType.RESUME_RECORDING:
        this.handleResumeRecordingEvent();
        break;
      case AudioControllerEventType.RESET_DATA:
        this.handleResetDataEvent();
        break;
      case AudioControllerEventType.STATE_CHANGE:
        const stateEvent = event as StateChangeEventWithPayload;
        this.handleStateChange(stateEvent.payload as StateTransitionEvent);
        break;
    }
  }

  /**
   * 处理启动录制事件
   */
  private async handleStartRecordingEvent(): Promise<void> {
    try {
      await this.originalStartRecording();
      console.info('[AudioController] 通过事件启动录制成功');
    } catch (error) {
      console.error('[AudioController] 通过事件启动录制失败:', error);
      this.audioControllerService.publishError([`启动录制失败: ${error.message}`]);
    }
  }

  /**
   * 处理停止录制事件
   */
  private async handleStopRecordingEvent(comments: string): Promise<void> {
    try {
      console.info('[AudioController] 开始处理停止录制事件');
      await this.originalStopRecording(comments);
      console.info('[AudioController] 通过事件停止录制成功');
    } catch (error) {
      console.error('[AudioController] 通过事件停止录制失败:', error);
      this.audioControllerService.publishError([`停止录制失败: ${error.message}`]);
      // 即使失败也要确保状态正确
      try {
        // 强制停止音频服务
        await this.audioService.stopCapture();
      } catch (stopError) {
        console.warn('[AudioController] 强制停止音频服务时出错:', stopError);
      }
    }
  }

  /**
   * 处理暂停录制事件
   */
  private async handlePauseRecordingEvent(): Promise<void> {
    try {
      console.info('[AudioController] 开始处理暂停录制事件');
      await this.originalPauseRecording();
      console.info('[AudioController] 通过事件暂停录制成功');
    } catch (error) {
      console.error('[AudioController] 通过事件暂停录制失败:', error);
      this.audioControllerService.publishError([`暂停录制失败: ${error.message}`]);
      // 即使失败也要确保状态正确
      try {
        // 强制停止音频服务
        await this.audioService.stopCapture();
      } catch (stopError) {
        console.warn('[AudioController] 强制停止音频服务时出错:', stopError);
      }
    }
  }

  /**
   * 处理恢复录制事件
   */
  private async handleResumeRecordingEvent(): Promise<void> {
    try {
      console.info('[AudioController] 开始处理恢复录制事件');
      await this.originalResumeRecording();
      console.info('[AudioController] 通过事件恢复录制成功');
    } catch (error) {
      console.error('[AudioController] 通过事件恢复录制失败:', error);
      this.audioControllerService.publishError([`恢复录制失败: ${error.message}`]);
    }
  }

  /**
   * 处理重置数据事件
   */
  private handleResetDataEvent(): void {
    this.resetData();
    console.info('[AudioController] 通过事件重置数据成功');
  }

  /**
   * 处理状态变更
   */
  private handleStateChange(event: StateTransitionEvent): void {
    console.info(`[状态机] 状态变更: ${event.fromState} -> ${event.toState}`);

    // 根据状态变更执行相应操作
    switch (event.toState) {
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
        console.info('[状态机] 启动录制中...');
        this.autoSaveService.startAutoSaveMonitoring();
        break;
      case AudioControllerLifecycleState.CONTROLLER_RESUMING:
        console.info('[状态机] 恢复录制中...');
        // 恢复录制时不重置自动保存监控，继续使用现有配置
        this.autoSaveService.resumeAutoSaveMonitoring();
        break;
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        console.info('[状态机] 录制状态已设置为true');
        break;

      case AudioControllerLifecycleState.CONTROLLER_IDLE:
        console.info('[状态机] 录制状态已设置为false');
        break;

      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        // 错误状态，可能需要显示错误信息
        console.error('[状态机] 进入错误状态:', event.error);
        // 停止自动保存监控
        this.autoSaveService.stopAutoSaveMonitoring();
        if (event.error) {
          this.addErrorMessage(event.error);
        }
        break;

      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
        // 停止过程中，确保自动保存监控被停止
        this.autoSaveService.stopAutoSaveMonitoring();
        break;
    }
  }

  /**
   * 准备开始录制 - 重置数据和状态
   */
  private prepareForRecording(): void {
    // 重置数据状态
    this.ak.dataProcessingState.statisticsData.startTime = new Date().getTime();
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

    // 启动数据清理监控
    this.startDataCleanupMonitoring();

    // 启动自动保存监控
    if (this.pk.auto_save_enabled) {
      this.autoSaveService.startAutoSaveMonitoring();
    }
  }

  /**
   * 设置音频处理回调
   */
  private setupAudioProcessing(): void {
    // 注册音频数据回调
    this.audioService.registerOriginAudioDataCallBack((buffer: ArrayBuffer) => {
      this.originAudioBuffers.push({ timestamp: Date.now(), buffer: buffer.slice(0) });
    });

    // 开始处理音频数据
    this.audioService.startProcessing((buffer: ArrayBuffer) => {
      const currentTime = Date.now();
      this.timedAudioBuffers.push({ timestamp: currentTime, buffer: buffer.slice(0) });

      // 处理时域波形数据
      this.processTimeDomainData(buffer);

      let config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
      // 计算频谱数据（用于频谱图显示）
      taskpool.execute<[ArrayBuffer, WeightingType, number, number, WindowType, number, number, number, boolean, number, number, number, number, number, number], Float32Array>(
        concurrentCalculateSpectrum,
        buffer.slice(0),
        this.pk.weighting_type,
        this.pk.calibration_value,
        config.fftSize,
        config.windowType,
        config.smoothingFactor,
        config.overlap,
        config.sampleRate,
        config.decimationEnabled,
        config.decimationFactor,
        config.kaiserBeta,
        config.gaussianSigma,
        config.tukeyAlpha,
        config.chebyshevAttenuation,
        config.exponentialSmoothingFactor
      ).then((spectrum) => {
        // 双管线架构：频谱数据通过状态管理，不再通过事件传递

        // 计算分贝值
        const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
        const fftAnalyzer = new FFTAnalyzer(
          config.fftSize,
          config.windowType,
          config.smoothingFactor,
          config.overlap,
          config.sampleRate,
          config.decimationEnabled,
          config.decimationFactor,
          config.kaiserBeta,
          config.gaussianSigma,
          config.tukeyAlpha,
          config.chebyshevAttenuation,
          config.exponentialSmoothingFactor
        );
        
        const db: number = fftAnalyzer.calculateAverageDb(spectrum);
        let currentDecibel = Number(Math.round(db).toFixed(1));

        // 收集分贝值和加权类型（带时间戳）
        const currentTime = new Date().getTime();
        this.timedValues.push({ timestamp: currentTime, value: currentDecibel });
        this.timedWeightingTypes.push({ timestamp: currentTime, type: this.pk.weighting_type });

        // 计算峰值频率
        try {
          const peakInfo = SpectrumDataProcessor.findPeakFrequency(
            spectrum,
            config.fftSize,
            config.sampleRate, // 采样率
            16, // 最小频率
            20000, // 最大频率
            true, // 默认启用插值
            PeakInterpolationMethod.ADAPTIVE
          );
          
          if (peakInfo) {
            this.ak.dataProcessingState.processingPeakFreq = peakInfo.frequency;
            console.info(`[峰值检测] 峰值频率: ${peakInfo.frequency.toFixed(1)}Hz (使用已计算的频谱数据)`);
          }
        } catch (error) {
          console.warn(`[峰值检测] 错误: ${error}`);
        }

        // 更新统计信息
        this.updateStatistics(currentDecibel, spectrum);

        // 检查报警状态
        this.checkAlarmStatus(currentDecibel);
      });
    });
  }

  /**
   * 原有的启动录制逻辑（作为回退方案）
   */
  private async originalStartRecording(): Promise<void> {
    try {
      // 启动音频采集
      await this.tryStartCapture();

      // 准备录制环境 - 重置数据和状态
      this.prepareForRecording();

      // 设置音频处理回调
      this.setupAudioProcessing();

    } catch (error) {
      this.addErrorMessage(`音频采集启动失败: ${error.message}`);
      this.resetData();
      throw new Error(`音频采集停止失败: ${error.message}`);
    }
  }

  /**
   * 准备恢复录制 - 不重置数据，继续使用现有数据
   */
  private prepareForResumeRecording(): void {
    this.clearErrorMessage();

    // 注意：恢复录制时不重置数据，继续使用现有数据

    // 启动数据清理监控
    this.startDataCleanupMonitoring();

    // 恢复自动保存监控（不重置上次保存时间）
    if (this.pk.auto_save_enabled) {
      this.autoSaveService.resumeAutoSaveMonitoring();
    }
  }

  /**
   * 原有的恢复录制逻辑（继续采集，不重置数据）
   */
  private async originalResumeRecording(): Promise<void> {
    try {
      // 启动音频采集
      await this.tryStartCapture();

      // 准备恢复录制环境 - 不重置数据
      this.prepareForResumeRecording();

    } catch (error) {
      this.addErrorMessage(`音频采集恢复失败: ${error.message}`);
      throw new Error(`音频采集恢复失败: ${error.message}`);
    }
  }

  /**
   * 原有的暂停录制逻辑（停止采集但保留数据）
   */
  private async originalPauseRecording(): Promise<void> {
    console.info("[FREQ_TRACE][Recording] 暂停检测 - 开始");

    try {
      try {
        console.info('[AudioController] 开始暂停音频采集');
        await this.audioService.pauseCapture();
        console.info('[AudioController] 音频采集已暂停，数据保留');
      } catch (error) {
        console.error('[AudioController] 暂停音频采集失败:', error);
        this.addErrorMessage(`暂停音频采集失败: ${error.message}`);
        // 即使失败也要继续后续处理，避免阻塞
      }

      // 注意：这里不重置数据，保留所有历史数据
      // this.resetData();

      // 停止自动保存监控
      this.autoSaveService.stopAutoSaveMonitoring();

      // 停止数据清理监控
      this.stopDataCleanupMonitoring();

      console.info('[AudioController] 录制已暂停，数据保留');
    } catch (error) {
      console.error('[FREQ_TRACE][Record] 暂停录制失败:', error);
      this.addErrorMessage(`暂停录制失败: ${error.message}`);
      // 即使失败也要确保状态正确
      console.info('[AudioController] 录制暂停失败，保持当前状态');
    }
  }

  /**
   * 原有的停止录制逻辑（作为回退方案）
   */
  private async originalStopRecording(comments: string): Promise<void> {
    // 原有的停止录制逻辑...
    console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

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

      // 停止处理音频数据
      this.audioService.stopProcessing();

      // 停止音频采集，触发状态机状态转换
      try {
        console.info('[AudioController] 开始停止音频采集');
        await this.audioService.stopCapture();
        console.info('[AudioController] 音频采集已停止，状态机将转换到IDLE状态');
      } catch (error) {
        console.error('[AudioController] 停止音频采集失败:', error);
        this.addErrorMessage(`停止音频采集失败: ${error.message}`);
        // 即使失败也要继续后续处理，避免阻塞
      }

      // 如果启用了录音功能，获取并保存音频文件
      let currentAudioFilePath: string = '';

      if (this.pk.record_enabled) {
        try {
          // 获取音频数据
          const recentAudioBuffers = this.originAudioBuffers.map(item => item.buffer);
          console.info(`[音频保存] 使用最近${this.pk.auto_save_interval}分钟的音频数据，缓冲区数量: ${recentAudioBuffers.length}`);

          currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(recentAudioBuffers);
        } catch (error) {
          console.error('[FREQ_TRACE][Audio] 获取或保存WAV音频数据失败:', error);
          this.addErrorMessage(`音频文件保存失败: ${error.message}`);
        }
      }

      console.info('[FREQ_TRACE][Record] 准备创建记录');
      // 更新记录对象
      if (this.currentRecord) {
        this.currentRecord.minDecibel = this.ak.dataProcessingState.statisticsData.minDb;
        this.currentRecord.maxDecibel = this.ak.dataProcessingState.statisticsData.maxDb;
        this.currentRecord.avgDecibel = this.ak.dataProcessingState.statisticsData.avgDb;
        this.currentRecord.duration = this.ak.dataProcessingState.statisticsData.duration;
        console.info('[FREQ_TRACE][Record] 创建记录对象 持续时间 ' +
        this.ak.dataProcessingState.statisticsData.duration);
        this.currentRecord.decibelValues = this.timedValues.map(item => item.value);
        this.currentRecord.weightingTypes = this.timedWeightingTypes.map(item => item.type);
        this.currentRecord.audioFilePath = currentAudioFilePath;
        this.currentRecord.location = locationInfo?.address;
        this.currentRecord.comment = comments;

        // 保存记录
        await this.recordService.saveRecord(this.currentRecord);
        console.info('[FREQ_TRACE][Record] 记录保存成功');

        // 更新最后记录时间和记录总数
        this.ak.lastRecordTimestamp = Date.now();
        const totalCount = await this.recordService.getTotalCount();
        this.ak.totalRecordsCount = totalCount;

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

      // 真正的停止：不自动开始新的检测
      console.info('[AudioController] 录制已停止，保持停止状态');

    } catch (error) {
      console.error('[FREQ_TRACE][Record] 保存记录失败:', error);
      this.addErrorMessage(`记录保存失败: ${error.message}`);
      // 真正的停止：即使保存失败也不自动开始新的检测
      console.info('[AudioController] 录制已停止（保存失败），保持停止状态');
    }
  }


}

/**
 * 停止录制事件payload接口
 */
interface StopRecordingPayload {
  comments: string;
}

/**
 * 停止录制事件接口
 */
interface StopRecordingEventWithPayload extends AudioControllerEvent {
  payload: StopRecordingPayload;
}

/**
 * 状态变更事件接口
 */
interface StateChangeEventWithPayload extends AudioControllerEvent {
  payload: StateTransitionEvent;
}
