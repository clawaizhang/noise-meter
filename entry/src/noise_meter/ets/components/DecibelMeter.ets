import { AudioService } from '../../../library/ets/services/AudioService';
import { DecibelService } from '../services/DecibelService';
import { LocationService } from '../../../library/ets/services/LocationService';
import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import { DecibelRecordService } from '../services/DecibelRecordService';
import { LocationDisplay } from '../../../library/ets/components/business/LocationDisplay'
import common from '@ohos.app.ability.common';
import { BannerCard } from '../../../library/ets/components/business/BannerCard';
import { FileService } from '../../../library/ets/services/FileService';
import { noiseMeterNavStack } from '../constant/ProviderConstant';
import { promptAction } from '@kit.ArkUI';
import {
  PreferenceService,
  PreferenceChangeListener,
  PreferenceValue
} from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';
import type { BusinessError } from '@ohos.base';
import systemIcon from '@ohos.multimedia.image';
import display from '@ohos.display';
import { AudioAnalysisMode, AudioPresets, PREF_ANALYSIS_MODE } from '../../../library/ets/common/AudioConfig';
import { FFTAnalyzer } from '../../../library/ets/utils/FFTAnalyzer'; // 导入 FFTAnalyzer
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { taskpool } from '@kit.ArkTS';

@Concurrent
function concurrentCalculateSpectrum(savedMode: string, buffer: ArrayBuffer, weightingType: WeightingType,
  SAMPLE_RATE: number,
  highFreq: number): Float32Array {
  console.info(`[频谱分析] 开始处理音频数据: 数据大小=${buffer.byteLength}字节`);
  // 初始化权分析器
  const config = AudioPresets.getConfig(savedMode as AudioAnalysisMode);
  let fftAnalyzer = new FFTAnalyzer(
    config.fftSize,
    config.windowType,
    config.smoothingFactor
  );

  // 执行FFT变换并获取频谱数据
  const spectrum = fftAnalyzer.transform(buffer, weightingType);
  console.info(`[频谱分析] FFT变换完成: 频谱长度=${spectrum.length}`);
  console.info(`[频谱分析] 原始频谱样本: ${spectrum[0]}, ${spectrum[1]}, ${spectrum[2]}, ${spectrum[3]}, ${spectrum[4]}`);

  // 应用计权
  const weightedSpectrum = fftAnalyzer.applyWeighting(spectrum, weightingType);
  console.info(`[频谱分析] 计权后频谱样本: ${weightedSpectrum[0]}, ${weightedSpectrum[1]}, ${weightedSpectrum[2]}, ${weightedSpectrum[3]}, ${weightedSpectrum[4]}`);

  const filteredSpectrum = new Float32Array(weightedSpectrum.length);
  for (let i = 0; i < weightedSpectrum.length; i++) {
    filteredSpectrum[i] = weightedSpectrum[i];
  }
  return filteredSpectrum;
}

@ComponentV2
export struct DecibelMeter {
  @Local private currentDecibel: number = 0
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private isRecording: boolean = false
  @Local private showStats: boolean = false
  @Local private recordingTime: number = 0
  @Local private isRecordEnabled: boolean = false
  @Local private displayPoints: Array<number> = [] // 动态数组，大小将根据FFT size调整
  @Local private peakPoints: Array<number> = [] // 动态数组，大小将根据FFT size调整
  @Local private peakHoldTime: Array<number> = [] // 动态数组，大小将根据FFT size调整
  @Local private debugText: string = ''
  @Local private peakFreq: number = 0 // 添加峰值频率变量
  @Local private savedMode: string = AudioAnalysisMode.BALANCED;
  private spectrumData: Float32Array = new Float32Array(1024)
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private fileService: FileService = new FileService(getContext() as common.Context)
  private preferenceService: PreferenceService = PreferenceService.getInstance()
  private dbCount: number = 0
  private dbSum: number = 0
  private context?: common.UIAbilityContext
  private values: number[] = []
  private startTime: number = 0
  private releaseTimer: number = -1
  private currentRecord?: DecibelRecord
  private recordListener?: PreferenceChangeListener
  // Canvas相关属性
  @Local private canvasWidth: number = 0 // Canvas宽度
  @Local private canvasHeight: number = 0 // Canvas高度
  private readonly ASPECT_RATIO: number = 1.5 // 宽高比改为3:2
  private readonly SIDE_MARGIN: number = 16 // 左右边距各16vp
  private readonly SAMPLE_RATE: number = 44100 // 采样率
  private MIN_DB: number = -20
  private MAX_DB: number = 120
  @Local private weightingType: WeightingType = WeightingType.A // 当前FFT大小
  @Local private currentMode: AudioAnalysisMode = AudioAnalysisMode.BALANCED // 当前FFT大小
  @Local private currentFftSize: number = 2048 // 当前FFT大小
  private readonly FONT_SIZE: number = 10 // 字体大小10vp
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  // 屏幕宽度
  @Local private isFirstFrequencyRun: boolean = true // 是否是第一次绘制频率

  // 计算Canvas尺寸
  private async calculateCanvasDimensions(): Promise<void> {
    try {
      // 获取屏幕信息
      const displayInfo = display.getDefaultDisplaySync();

      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();

      // 先把可用区域的像素转换为vp
      const availableWidthVp = px2vp(availableArea.width);
      const availableHeightVp = px2vp(availableArea.height);

      // 然后用vp单位进行计算
      this.canvasWidth = availableWidthVp - (this.SIDE_MARGIN * 2);
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;

      console.info(`[FREQ_TRACE][显示设备信息]
        物理分辨率: ${displayInfo.width}x${displayInfo.height}
        密度DPI: ${displayInfo.densityDPI}
        可用区域(px): ${availableArea.width}x${availableArea.height}
        可用区域(vp): ${availableWidthVp}x${availableHeightVp}
        Canvas尺寸(vp): ${this.canvasWidth}x${this.canvasHeight}
      `);

    } catch (error) {
      console.error('[FREQ_TRACE][显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  // 绘制频谱的方法
  private drawSpectrum(rawSpectrum: Float32Array): void {
    if (this.canvasContext) {
      // 清除画布
      let isLowFreqMode = this.currentMode === AudioAnalysisMode.LOW_FREQUENCY;
      this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

      // 分贝网格点生成
      const dbSteps: number[] =
        isLowFreqMode ? [-60, -40, -20, 0, 20, 40, 60, 80, 100] : [-20, 0, 20, 40, 60, 80, 100, 120, 140];
      this.MIN_DB = isLowFreqMode ? -60 : -20;
      this.MAX_DB = isLowFreqMode ? 100 : 140;


      // 频率步进点生成
      const frequencySteps: number[] = isLowFreqMode ?
        [16, 31.5, 63, 125, 250, 500] : // 低频模式的频率步进
        [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      const frequencyHigh: number = isLowFreqMode ? 500 : 16000;

      // 仅在第一次绘制时记录频率步进点
      if (this.isFirstFrequencyRun) {
        // console.info(`[FREQ_TRACE][Frequency] 频率步进点: ${frequencySteps.join(', ')}`);
        this.isFirstFrequencyRun = false;
      }

      // 绘制分贝刻度
      this.canvasContext.strokeStyle = '#333333';
      this.canvasContext.lineWidth = 0.5;
      this.canvasContext.textAlign = 'right';
      this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`; // 字体大小需要转换为px
      this.canvasContext.fillStyle = '#AAAAAA';

      for (const db of dbSteps) {
        // 重新计算Y坐标，确保分贝均匀分布并填满画布高度
        const normalizedValue: number = (db - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const y: number = this.canvasHeight * (1 - normalizedValue);

        // 跳过最顶部和最底部的水平网格线
        if (db === this.MIN_DB || db === this.MAX_DB) {
          // 但是仍然绘制最顶部的标签
          if (db === this.MAX_DB) {
            this.canvasContext.fillStyle = '#AAAAAA';
            this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`;
            this.canvasContext.textAlign = 'right';
            this.canvasContext.fillText(
              `${db}`,
              30,
              y + 10
            );
          }
          continue;
        }

        // 绘制水平网格线（从画布左侧到右侧）
        this.canvasContext.beginPath();
        this.canvasContext.moveTo(0, y);
        this.canvasContext.lineTo(this.canvasWidth, y);
        this.canvasContext.stroke();

        // 只为特定分贝值显示标签
        if (dbSteps.includes(db)) {
          this.canvasContext.fillStyle = '#AAAAAA';
          this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`;
          this.canvasContext.textAlign = 'right';
          this.canvasContext.fillText(
            `${db}`,
            30,
            y + 10
          );
        }

      }

      // 绘制频率刻度
      this.canvasContext.textAlign = 'left';
      this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`;
      this.canvasContext.fillStyle = '#AAAAAA';

      // 计算对数坐标映射的常量
      const logMin: number = Math.log10(16);
      const logMax: number = Math.log10(frequencyHigh);

      // 计算0分贝对应的Y坐标
      const zeroDbNormalizedValue: number = (0 - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
      const zeroDbY: number = this.canvasHeight * (1 - zeroDbNormalizedValue);

      for (let i = 0; i < frequencySteps.length; i++) {
        const freq: number = frequencySteps[i];
        // 对数坐标映射
        const logFreq: number = Math.log10(freq);

        // 计算X坐标，确保从画布左侧到右侧
        const x: number =
          ((logFreq - logMin) / (logMax - logMin)) * this.canvasWidth;

        // 跳过最左侧和最右侧的垂直网格线
        if (i === 0 || i === frequencySteps.length - 1) {
          // 绘制第一个频率标签
          if (i === 0) {
            this.canvasContext.fillStyle = '#AAAAAA';
            this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`;
            this.canvasContext.textAlign = 'left';
            this.canvasContext.fillText(
              `${freq}`,
              x + 2,
              zeroDbY - 2  // 使用0分贝线的位置
            );
          }
          continue;
        }

        // 绘制垂直网格线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#333333';
        this.canvasContext.lineWidth = 0.5;
        this.canvasContext.moveTo(x, 0);
        this.canvasContext.lineTo(x, this.canvasHeight);
        this.canvasContext.stroke();

        // 绘制频率文本（在0分贝线的上方，左对齐）
        const label: string = freq >= 1000 ?
          (freq === 1000 ? '1k' : `${freq / 1000}k`) :
        freq.toString();
        this.canvasContext.fillStyle = '#AAAAAA';
        this.canvasContext.font = `${vp2px(this.FONT_SIZE)}px sans-serif`;
        this.canvasContext.textAlign = 'left';
        this.canvasContext.fillText(
          label,
          x + 2, // 使用x坐标作为左对齐起点
          zeroDbY - 2  // 使用0分贝线的位置，略微上移5像素
        );
      }

      // 获取频谱数据并记录范围
      let minSpectrum: number = Infinity;
      let maxSpectrum: number = -Infinity;
      for (const value of rawSpectrum) {
        if (isFinite(value)) {
          // 使用绝对值来比较
          const absValue = Math.abs(value);
          minSpectrum = Math.min(minSpectrum, absValue);
          maxSpectrum = Math.max(maxSpectrum, absValue);
        }
      }

      // 预计算频率相关的常量
      const octaveRatio: number = Math.pow(2, 1 / 3); // 每1/3个八度的比例
      const newDisplayPoints: number[] = new Array<number>(this.currentFftSize / 2);
      let maxValue: number = -Infinity;
      let maxIndex: number = -1;
      this.peakFreq = 0;

      // 按照八度分频计算每个频点
      let pointsAboveZero: number = 0;
      let totalPoints: number = 0;
      for (let i = 0; i < this.currentFftSize / 2; i++) {
        // 使用标准频率计算方法
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, this.currentFftSize);

        // 过滤超过频率范围的值
        if (centerFreq > frequencyHigh) {
          continue;
        }

        // 计算频带边界
        const lowerFreq: number = centerFreq / Math.pow(octaveRatio, 0.5);
        const upperFreq: number = centerFreq * Math.pow(octaveRatio, 0.5);

        // 将频率转换为FFT bin索引
        const lowerBin: number = Math.max(1, Math.floor(lowerFreq * this.currentFftSize / this.SAMPLE_RATE));
        const upperBin: number =
          Math.min(Math.floor(upperFreq * this.currentFftSize / this.SAMPLE_RATE), rawSpectrum.length - 1);

        let binSpectrum = new Float32Array();
        // 计算频段内的平均能量
        for (let bin = lowerBin; bin <= upperBin; bin++) {
          const value: number = rawSpectrum[bin];
          if (isFinite(value)) {
            // 使用绝对值来比较和存储
            const absValue = Math.abs(value);
            binSpectrum.fill(absValue);
            if (absValue > maxValue) {
              maxValue = absValue;
              maxIndex = bin;
              this.peakFreq = (bin * this.SAMPLE_RATE / this.currentFftSize);
            }
          }
        }

        // 计算高度
        if (binSpectrum.length > 0) {
          const avgDb: number = FrequencyWeighting.calculateAverageDb(binSpectrum);
          // 直接将分贝值映射到画布高度，考虑负值情况
          const y = this.canvasHeight - ((avgDb - this.MIN_DB) / (this.MAX_DB - this.MIN_DB)) * this.canvasHeight;
          newDisplayPoints[i] = Math.max(0, Math.min(this.canvasHeight, y));
        } else {
          newDisplayPoints[i] = this.canvasHeight; // 无声时显示在底部
        }

        if (newDisplayPoints[i] > 0) {
          pointsAboveZero++;
        }
        totalPoints++;

      }

      // 绘制主频谱折线
      const spectrumPath = new Path2D(); // 创建新的Path2D对象
      this.canvasContext.strokeStyle = '#2196F3'; // 主曲线用蓝色
      this.canvasContext.lineWidth = 0.5;

      // 标记是否找到第一个有效点
      let isFirstValidPoint = true;
      // 记录上一个绘制点的坐标
      let lastX: number | null = null;
      let lastY: number | null = null;

      for (let i = 0; i < this.currentFftSize; i++) {
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, this.currentFftSize);
        if (centerFreq < 16) {
          continue;
        } // 只显示16Hz以上的范围

        // 安全检查：确保rawSpectrum存在且有效
        if (!rawSpectrum || i >= rawSpectrum.length) {
          continue;
        }

        const logFreq: number = Math.log10(centerFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(frequencyHigh);

        const x: number =
          ((logFreq - logMin) / (logMax - logMin)) * this.canvasWidth;

        const value: number = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
        const normalizedValue: number = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const height: number = this.canvasHeight * normalizedValue;
        const y: number = this.canvasHeight - height;

        // 转换为整数坐标
        const intX = Math.round(x);
        const intY = Math.round(y);

        // 检查是否为重复点
        const isDuplicatePoint = lastX !== null && lastY !== null &&
          intX === lastX && intY === lastY;

        // 只在找到第一个有效点或非重复点时绘制
        if (isFirstValidPoint || !isDuplicatePoint) {
          if (isFirstValidPoint) {
            spectrumPath.moveTo(x, y); // 使用Path2D的moveTo
            isFirstValidPoint = false;
          } else {
            spectrumPath.lineTo(x, y); // 使用Path2D的lineTo
          }

          // 更新最后一个绘制点的坐标
          lastX = intX;
          lastY = intY;
        }
      }

      // 一次性绘制整个路径
      this.canvasContext.stroke(spectrumPath);

      // 显示峰值频率
      if (this.peakFreq > 0) {
        const logPeakFreq: number = Math.log10(this.peakFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(frequencyHigh);
        const peakX: number = ((logPeakFreq - logMin) / (logMax - logMin)) * this.canvasWidth;

        // 计算Y坐标的替代方案
        const peakFreqY: number = this.canvasHeight -
          (maxValue / (this.MAX_DB - this.MIN_DB)) * this.canvasHeight;

        this.canvasContext.fillStyle = '#fffdfdfd'; // 峰值标签使用白色
        this.canvasContext.textAlign = 'center';
        this.canvasContext.font = `bold ${vp2px(this.FONT_SIZE)}px sans-serif`;
        this.canvasContext.fillText(
          `${Math.round(this.peakFreq)}Hz`,
          peakX,
          peakFreqY - 30 // 稍微抬高标签位置
        );
      }

      // 更新调试信息
      const debugInfo: string = `[FREQ_TRACE][Debug] 当前分贝: ${this.currentDecibel}dB\n` +
        `频谱范围: ${this.MIN_DB}dB ~ ${this.MAX_DB}dB\n` +
        `高度范围: 0vp ~ ${this.canvasHeight}vp`;

      this.debugText = debugInfo;

      // 更新计时器
      this.recordingTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
    }
  }

  @Builder
  private SpectrumView() {
    Column() {
      // Canvas频谱显示
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#000000')
        .borderRadius(12)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          console.info(`[FREQ_TRACE][Canvas] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          console.info(`[FREQ_TRACE][Canvas] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth /
          this.canvasHeight).toFixed(2)}`);
        })
        .onReady(() => {
          // 初始化完成后开始绘制
          // 创建一个空的 Float32Array 用于初始化显示
          const emptySpectrum: Float32Array = new Float32Array(this.currentFftSize * 2); // 每个点用2字节表示
          this.drawSpectrum(emptySpectrum)
        })
    }
  }

  aboutToDisappear() {
    // 原有的清理代码
    if (this.recordListener) {
      this.preferenceService.removeChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);
    }
    if (this.isRecording) {
      this.stopRecording();
    }
    if (this.releaseTimer !== -1) {
      clearTimeout(this.releaseTimer);
      this.releaseTimer = -1;
    }
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
  }

  async aboutToAppear() {
    try {
      // 从首选项加载分析模式
      this.savedMode = this.preferenceService.getString(PREF_ANALYSIS_MODE, AudioAnalysisMode.BALANCED);

      // 添加配置变更监听
      this.preferenceService.addChangeListener(PREF_ANALYSIS_MODE, (key: string, value: PreferenceValue) => {
        if (key === PREF_ANALYSIS_MODE && typeof value === 'string') {
          this.savedMode as AudioAnalysisMode
        }
      });
      // 获取当前的计权类型
      this.weightingType =
        this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
      console.debug('[DecibelService] 当前计权类型:', this.weightingType);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.WEIGHTING,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.WEIGHTING && typeof value === 'string') {
            this.weightingType = value as WeightingType;
          }
        })
      //获取fftSize
      // 获取当前分析模式和FFT大小
      this.currentMode = this.preferenceService.getString(PREF_ANALYSIS_MODE, 'default') as AudioAnalysisMode;
      this.currentFftSize = AudioPresets.getConfig(this.currentMode).fftSize;
      console.info(`[FREQ_TRACE][FFT] 当前模式: ${this.currentMode}, FFT大小: ${this.currentFftSize}`);
      this.preferenceService.addChangeListener(PREF_ANALYSIS_MODE, (key: string, value: PreferenceValue) => {
        if (key === PREF_ANALYSIS_MODE && typeof value === 'string') {
          this.currentMode = value as AudioAnalysisMode;
          this.currentFftSize = AudioPresets.getConfig(this.currentMode).fftSize;
        }
      })
      // 获取屏幕信息并初始化Canvas尺寸
      await this.calculateCanvasDimensions();
      console.info(`[FREQ_TRACE][Screen] aboutToAppear - 初始化后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}`);
    } catch (error) {
      console.error('[FREQ_TRACE][Screen] 初始化失败:', error);
    }

    // 原有的初始化代码
    // 获取录音开关状态
    this.isRecordEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.RECORD);

    // 监听录音开关状态变化
    this.recordListener = (key: string, value: PreferenceValue): void => {
      if (key === PreferenceKeyConstants.RECORD) {
        this.isRecordEnabled = value as boolean;
      }
    };
    this.preferenceService.addChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);

    // 启动音频采集
    this.audioService.startCapture().then(() => {
      console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
      // 直接开始检测
      this.startRecording();
    }).catch((error: BusinessError) => {
      console.error('[FREQ_TRACE][Audio] 音频采集启动失败:', error);
    });
  }

  private async startRecording() {
    try {
      this.isRecording = true;
      this.startTime = new Date().getTime();
      this.recordingTime = 0;
      this.values = [];
      this.dbCount = 0;
      this.dbSum = 0;

      // 创建新的记录对象
      this.currentRecord = new DecibelRecord(
        0, // minDecibel
        0, // maxDecibel
        0, // avgDecibel
        0, // duration
        [], // decibelValues
        this.locationService.getCachedLocation()?.address, // location
        undefined// audioFilePath
      );

      // 如果启用了录音功能，开始录音
      if (this.isRecordEnabled) {
        this.audioService.startRecording();
      }

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 计算分贝值
        let highFreq: number = this.currentMode === AudioAnalysisMode.LOW_FREQUENCY ? 500 : 16000;

        taskpool.execute<[string, ArrayBuffer, WeightingType, number, number], Float32Array>(concurrentCalculateSpectrum,
          this.savedMode,
          buffer, this.weightingType, this.SAMPLE_RATE, highFreq).then((spectrum: Float32Array) => {
          const db: number = FrequencyWeighting.calculateAverageDb(spectrum);

          this.currentDecibel = Math.round(db);
          this.values.push(this.currentDecibel);
          this.updateStatistics(this.currentDecibel);

          this.drawSpectrum(spectrum);
        })


      });
    } catch (error) {
      // 如果启动失败，重置状态
      this.isRecording = false;
      this.resetData();
    }
  }

  private resetData() {
    // 重置状态
    this.currentDecibel = 0;
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.dbCount = 0;
    this.dbSum = 0;
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;
  }

  private async stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        console.info('[FREQ_TRACE][Location] 位置信息:', locationInfo);

        // 计算检测时长
        const duration: number = new Date().getTime() - this.startTime;
        console.info('[FREQ_TRACE][Duration] 检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath: string = '';
        if (this.isRecordEnabled) {
          try {
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(this.fileService);
          } catch (error) {
            console.error('[FREQ_TRACE][Audio] 获取或保存WAV音频数据失败:', error);
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
          this.currentRecord.audioFilePath = currentAudioFilePath;

          // 保存记录
          await this.recordService.saveRecord(this.currentRecord);
          console.info('[FREQ_TRACE][Record] 记录保存成功');

          // 显示详情对话框
          this.navStack.pushDestinationByName('DetailDialog', {
            selectedRecord: this.currentRecord,
            context: getContext(this),
            fileService: this.fileService
          });
        }

        // 重置状态
        this.resetData();

        // 自动开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500); // 延迟500ms后开始新的检测

      } catch (error) {
        console.error('[FREQ_TRACE][Record] 保存记录失败:', error);
        // 显示错误提示
        promptAction.showToast({
          message: '保存记录失败：' + (error instanceof Error ? error.message : String(error)),
          duration: 3000
        });
        // 即使保存失败也开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500);
      }
    }
  }

  private updateStatistics(value: number) {
    if (value > 0) {
      // 记录分贝值
      this.values.push(value);

      if (this.dbCount === 0) {
        // 第一次检测到的值作为初始值
        this.minDecibel = value;
        this.maxDecibel = value;
        this.avgDecibel = value;
        // 延迟显示统计区域，添加动画效果
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          this.showStats = true;
        })
      } else {
        // 更新最小值
        if (value < this.minDecibel) {
          this.minDecibel = value;
        }
        // 更新最大值
        if (value > this.maxDecibel) {
          this.maxDecibel = value;
        }
      }
      // 更新平均值
      this.dbSum += value;
      this.dbCount++;
      this.avgDecibel = Math.round(this.dbSum / this.dbCount);
    }
  }

  private formatDuration(seconds: number): string {
    const hours: number = Math.floor(seconds / 3600);
    const minutes: number = Math.floor((seconds % 3600) / 60);
    const remainingSeconds: number = seconds % 60;

    let result: string = '';
    if (hours > 0) {
      result += `${hours}时`;
    }
    if (minutes > 0 || hours > 0) {
      result += `${minutes}分`;
    }
    result += `${remainingSeconds}秒`;

    return result;
  }

  build() {
    Column() {
      // 频谱显示
      this.SpectrumView()

      // 分贝显示卡片
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          // 分贝值显示
          Row() {
            Column() {
              Text('最小')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              Text(this.minDecibel === 0 ? '-' : this.minDecibel.toString())
                .fontSize(32)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.decibelService.getDecibelColor(this.minDecibel))
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 32 })

            Column() {
              Text(this.currentDecibel === 0 ? '-' : this.currentDecibel.toString())
                .fontSize(80)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
              Row() {
                if (this.isRecording) {
                  Text(new Date(this.startTime).toLocaleTimeString('zh-CN', {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false
                  }))
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(' | ')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(this.formatDuration(this.recordingTime))
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(' | ')
                    .fontSize(14)
                    .fontColor('#666666')
                }
                Text(this.decibelService.getDecibelLevel(this.currentDecibel))
                  .fontSize(14)
                  .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
              }
              .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('最大')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
                .fontSize(32)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.decibelService.getDecibelColor(this.maxDecibel))
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 32 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .padding({
          top: 20,
          bottom: 20,
          left: 16,
          right: 16
        })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .onClick(() => {
          if (this.currentRecord) {
            this.navStack.pushDestinationByName('DetailDialog', {
              selectedRecord: this.currentRecord,
              context: getContext(this),
              fileService: this.fileService
            });
          }
        })
      }
      .width('100%')
      .margin({ left: 8, right: 8, top: 24 })
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 2, color: '#1A000000', offsetY: 2 })

      // 位置显示
      Row() {
        LocationDisplay()
      }
      .width('92%')
      .margin({ top: 16, bottom: 16 })

      this.StartStopButton()
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StartStopButton() {
    Row() {
      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Row() {
          Image($r('app.media.ic_reset'))
            .width(16)
            .height(16)
            .margin({ right: 4 })
            .fillColor(Color.White)
          Text('重置')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('30%') // 进一步减小宽度
      .height(42) // 略微降低高度
      .margin({ top: 0, left: 16, right: 8 })
      .backgroundColor('#4A90E2') // 柔和的灰蓝色
      .shadow({
        radius: 4,
        color: '#1A4A90E2', // 轻微阴影
        offsetY: 2
      })
      .onClick(() => {
        // 重置音频数据和统计信息
        this.audioService.resetData();
        this.resetData();
      })

      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Row() {
          Image($r('app.media.ic_save'))
            .width(16)
            .height(16)
            .margin({ right: 4 })
            .fillColor(Color.White)
          Text('保存')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('30%') // 进一步减小宽度
      .height(42) // 略微降低高度
      .margin({ top: 0, left: 8, right: 16 })
      .backgroundColor('#1A5A9E') // 深蓝色
      .shadow({
        radius: 4,
        color: '#1A1A5A9E', // 轻微阴影
        offsetY: 2
      })
      .onClick(() => {
        this.stopRecording();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}