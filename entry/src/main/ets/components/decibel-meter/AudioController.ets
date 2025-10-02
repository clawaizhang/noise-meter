import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { LocationInfo } from '../../services/LocationService';
import { WeightingType } from '../../constants/WeightingConstants';
import { BusinessError } from '@kit.BasicServicesKit';
import { catchError, delay, filter, from, map, of, Subject, Subscription, switchMap, take, tap } from 'rxjs';
import { AppKeys } from '../../models/AppKeys';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { AudioControllerService } from '../../services/AudioControllerService';

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
  @Event onAudioBuffer: (buffer: ArrayBuffer) => void
  @Event onSpectrumData: (spectrum: Float32Array) => void
  @Event onError: (errors: string[]) => void
  @Event onRecordingStateChange: (isRecording: boolean) => void
  @Event onRecordingTimeUpdate: (time: number) => void
  @Event onMinMaxAvgCurrent: (min: number, max: number, avg: number, current: number) => void
  // 服务实例
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  // RxJS相关
  private audioBufferSubject = new Subject<void>();
  private durationCheckSubscription?: Subscription;
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance();
  // 常量
  private readonly MAX_RECORDING_DURATION: number = 60 * 60_000;
  // 记录相关
  private values: number[] = []
  private weightingTypes: WeightingType[] = []
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
    this.stopDurationMonitoring();
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
      this.values = [];
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
      this.weightingTypes = [];

      // 如果启用了录音功能，开始录音
      if (this.pk.record_enabled) {
        this.audioService.startRecording();
      }

      // 启动时长监控
      this.startDurationMonitoring();

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 发出事件通知有新的音频数据到达
        this.audioBufferSubject.next();

        // 更新音频缓冲区数据，供显示组件使用
        this.onAudioBuffer(buffer.slice(0));

        // 计算频谱数据（用于频谱图显示）
        taskpool.execute<[string, ArrayBuffer, WeightingType, number], Float32Array>(
          concurrentCalculateSpectrum,
          this.pk.audio_analysis_mode,
          buffer.slice(0),
          this.pk.weighting_type,
          this.pk.calibration_value
        ).then(spectrum => {
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

          // 收集分贝值和加权类型
          this.values.push(this.currentDecibel);
          this.weightingTypes.push(this.pk.weighting_type);

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

      // 停止时长监控
      this.stopDurationMonitoring();

      // 如果是自动保存，不显示保存提示
      const isAutoSave = new Date().getTime() - this.startTime >= this.MAX_RECORDING_DURATION;

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
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData();
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
          this.currentRecord.decibelValues = [...this.values];
          this.currentRecord.weightingTypes = [...this.weightingTypes];
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
    this.values.push(decibel);
    this.weightingTypes.push(weightingType);
  }

  resetData() {
    // 重置状态
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;

    // 重置 weightingTypes 数组
    this.weightingTypes = [];

    // 重置统计信息
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.currentDecibel = 0;

    // 通知UI更新
    this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, this.currentDecibel);
    this.onRecordingTimeUpdate(this.recordingTime);
  }

  private startDurationMonitoring(): void {
    // 停止之前的监控（如果存在）
    this.stopDurationMonitoring();

    this.durationCheckSubscription = this.audioBufferSubject.pipe(
      // 每次音频数据到达时检查时长
      map(() => new Date().getTime() - this.startTime),
      filter(duration => duration > this.MAX_RECORDING_DURATION),
      take(1),
      tap(() => console.info('[自动保存] 达到60分钟录音限制，自动保存并开始新录音')),
      switchMap(() => from(this.stopRecording('自动保存')).pipe(
        catchError((error: BusinessError) => {
          console.error('[自动保存] 停止录音失败:', error);
          this.addErrorMessage(`自动保存失败: ${error.message}`);
          return of(null);
        })
      )),
      delay(100),
      tap(() => {
        try {
          this.startRecording();
        } catch (error) {
          console.error('[自动保存] 重新开始录音失败:', error);
          this.addErrorMessage(`重新开始录音失败: ${error.message}`);
        }
      })
    ).subscribe({
      error: (error: BusinessError) => {
        console.error('[自动保存] RxJS监控流错误:', error);
        this.addErrorMessage(`录音监控错误: ${error.message}`);
        setTimeout(() => {
          try {
            this.startRecording();
          } catch (e) {
            console.error('[自动保存] 错误恢复失败:', e);
            this.addErrorMessage(`错误恢复失败: ${e.message}`);
          }
        }, 100);
      }
    });
  }

  private stopDurationMonitoring(): void {
    if (this.durationCheckSubscription) {
      this.durationCheckSubscription.unsubscribe();
      this.durationCheckSubscription = undefined;
    }
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
    if (this.values.length === 0) {
      this.minDecibel = currentDb;
      this.maxDecibel = currentDb;
      this.avgDecibel = currentDb;
    } else {
      this.minDecibel = Math.min(this.minDecibel, currentDb);
      this.maxDecibel = Math.max(this.maxDecibel, currentDb);

      // 计算平均值
      let sum = 0;
      for (let value of this.values) {
        sum += value;
      }
      this.avgDecibel = Math.round(sum / this.values.length);
    }
    this.ak.db = currentDb;
    this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, currentDb);
  }

  // 检查报警状态
  private checkAlarmStatus(currentDb: number): void {
    const shouldAlarm = this.pk.noise_alarm_enabled && currentDb >= this.pk.noise_threshold;
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
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;
    this.weightingTypes = [];
    
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
}