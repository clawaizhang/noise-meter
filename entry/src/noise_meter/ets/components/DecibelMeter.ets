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
  private readonly SIDE_MARGIN: number = 16 // 左右边距各16像素
  private readonly SAMPLE_RATE: number = 44100 // 采样率
  private MIN_DB: number = -20
  private MAX_DB: number = 120
  @Local private currentMode: AudioAnalysisMode = AudioAnalysisMode.BALANCED // 当前FFT大小
  @Local private currentFftSize: number = 2048 // 当前FFT大小
  private readonly PADDING_TOP: number = 20 // 顶部内边距减小到20px
  private readonly PADDING_BOTTOM: number = 20 // 底部内边距减小到20px
  private readonly PADDING_LEFT: number = 32 // 左侧内边距32px，给分贝值留出空间
  private readonly PADDING_RIGHT: number = 16 // 右侧内边距16px
  private readonly FONT_SIZE: number = 32 // 字体大小32px
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

      // 输出详细的显示设备信息
      console.info(`[FREQ_TRACE][显示设备信息]
        物理分辨率: ${displayInfo.width}x${displayInfo.height}
        密度DPI: ${displayInfo.densityDPI}
        密度像素比: ${displayInfo.densityPixels}
        缩放密度: ${displayInfo.scaledDensity}
        X方向DPI: ${displayInfo.xDPI}
        Y方向DPI: ${displayInfo.yDPI}
        可用区域: left=${availableArea.left}, top=${availableArea.top}, width=${availableArea.width}, height=${availableArea.height}
      `);

      // 计算实际可用显示区域（逻辑像素）
      const realWidth = Math.round(availableArea.width / displayInfo.densityPixels);
      const realHeight = Math.round(availableArea.height / displayInfo.densityPixels);
      console.info(`[FREQ_TRACE][显示设备信息] 实际可用显示区域(逻辑像素): ${realWidth}x${realHeight}`);

      // 计算Canvas宽度（实际宽度减去左右边距）
      this.canvasWidth = realWidth - (this.SIDE_MARGIN * 2);
      console.info(`[FREQ_TRACE][显示设备信息] Canvas宽度(减去边距): ${this.canvasWidth}`);

      // 根据宽高比计算高度
      this.canvasHeight = Math.round(this.canvasWidth / this.ASPECT_RATIO);
      console.info(`[FREQ_TRACE][显示设备信息] Canvas高度(宽高比${this.ASPECT_RATIO}): ${this.canvasHeight}`);

      console.info(`[FREQ_TRACE][显示设备信息] 最终Canvas尺寸(逻辑像素): ${this.canvasWidth}x${this.canvasHeight}`);

    } catch (error) {
      console.error('[FREQ_TRACE][显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  // 绘制频谱的方法
  private drawSpectrum(buffer: ArrayBuffer): void {
    if (this.canvasContext) {
      // 清除画布
      let isLowFreqMode = this.currentMode === AudioAnalysisMode.LOW_FREQUENCY;
      this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

      // 计算实际可用的绘制区域
      const effectiveHeight: number = this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM;

      // 分贝网格点生成
      const dbSteps: number[] =
        isLowFreqMode ? [-80, -60, -40, -20, 0, 20, 40, 60, 80] : [-20, 0, 20, 40, 60, 80, 100, 120];
      this.MIN_DB = isLowFreqMode ? -80 : -20;
      this.MAX_DB = isLowFreqMode ? 80 : 120;


      // 频率步进点生成
      const frequencySteps: number[] = isLowFreqMode ? 
        [16, 31.5, 63, 125, 250] : // 低频模式的频率步进
        [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      const frequencyHigh: number = isLowFreqMode ? 250 : 16000;

      // 仅在第一次绘制时记录频率步进点
      if (this.isFirstFrequencyRun) {
        // console.info(`[FREQ_TRACE][Frequency] 频率步进点: ${frequencySteps.join(', ')}`);
        this.isFirstFrequencyRun = false;
      }

      // 绘制分贝刻度
      this.canvasContext.strokeStyle = '#333333'; // 调整网格线颜色为更细的灰色
      this.canvasContext.lineWidth = 0.5; // 减细网格线
      this.canvasContext.textAlign = 'right'; // 右对齐
      this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
      this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色

      for (const db of dbSteps) {
        // 重新计算Y坐标，确保-20到120分贝均匀分布并填满画布高度
        const normalizedValue: number = (db - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const y: number = this.canvasHeight * (1 - normalizedValue);

        // 跳过最顶部和最底部的水平网格线
        if (db === this.MIN_DB || db === this.MAX_DB) {
          // 但是仍然绘制最顶部的标签
          if (db === this.MAX_DB) {
            this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色
            this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
            this.canvasContext.textAlign = 'right';
            this.canvasContext.fillText(
              `${db}`, 
              this.PADDING_LEFT - 5, 
              y + this.FONT_SIZE/3
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
          this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色
          this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
          this.canvasContext.textAlign = 'right';
          this.canvasContext.fillText(
            `${db}`, 
            this.PADDING_LEFT - 5, 
            y + this.FONT_SIZE/3
          );
        }

      }

      // 绘制频率刻度
      this.canvasContext.textAlign = 'left';  // 改为左对齐
      this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
      this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色

      // 计算对数坐标映射的常量
      const logMin: number = Math.log10(16);
      const logMax: number = Math.log10(frequencyHigh);

      // 计算100分贝对应的Y坐标
      const hundredDbNormalizedValue: number = (100 - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
      const hundredDbY: number = this.canvasHeight * (1 - hundredDbNormalizedValue);

      for (let i = 0; i < frequencySteps.length; i++) {
        const freq: number = frequencySteps[i];
        // 对数坐标映射
        const logFreq: number = Math.log10(freq);
        
        // 计算X坐标，确保从画布左侧到右侧
        const x: number = ((logFreq - logMin) / (logMax - logMin)) * this.canvasWidth;

        // 跳过最左侧和最右侧的垂直网格线
        if (i === 0 || i === frequencySteps.length - 1) {
          // 绘制第一个频率标签
          if (i === 0) {
            this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色
            this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
            this.canvasContext.textAlign = 'left';
            this.canvasContext.fillText(
              `${freq}`, 
              x, 
              hundredDbY - 5
            );
          }
          continue;
        }

        // 绘制垂直网格线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#333333'; // 细灰色网格线
        this.canvasContext.lineWidth = 0.5;
        this.canvasContext.moveTo(x, 0);
        this.canvasContext.lineTo(x, this.canvasHeight);
        this.canvasContext.stroke();

        // 绘制频率文本（在100分贝线的上方，左对齐）
        const label: string = freq >= 1000 ? 
          (freq === 1000 ? '1k' : `${freq/1000}k`) : 
          freq.toString();
        this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色
        this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
        this.canvasContext.textAlign = 'left';
        this.canvasContext.fillText(
          label, 
          x,  // 使用x坐标作为左对齐起点
          hundredDbY - 5  // 略微高于横线
        );
      }

      // 获取频谱数据并记录范围
      const rawSpectrum: Float32Array = FrequencyWeighting.getSpectrumData(buffer);
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
        const upperBin: number = Math.min(Math.floor(upperFreq * this.currentFftSize / this.SAMPLE_RATE), rawSpectrum.length - 1);

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
          const normalizedValue: number = (avgDb - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
          newDisplayPoints[i] = effectiveHeight * Math.max(0, Math.min(1, normalizedValue));
        } else {
          newDisplayPoints[i] = 0;
        }

        if (newDisplayPoints[i] > 0) {
          pointsAboveZero++;
        }
        totalPoints++;

      }

      // 绘制主频谱折线
      this.canvasContext.beginPath();
      this.canvasContext.strokeStyle = '#2196F3'; // 主曲线用蓝色
      this.canvasContext.lineWidth = 0.5;

      // 标记是否找到第一个有效点
      let isFirstValidPoint = true;
      // 记录上一个绘制点的坐标
      let lastX: number | null = null;
      let lastY: number | null = null;

      for (let i = 0; i < this.currentFftSize; i++) {
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, this.currentFftSize);
        if (centerFreq < 16 || centerFreq > frequencyHigh) {
          continue;
        } // 只显示16Hz-16kHz的范围

        // 安全检查：确保rawSpectrum存在且有效
        if (!rawSpectrum || i >= rawSpectrum.length) {
          continue;
        }

        const logFreq: number = Math.log10(centerFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(frequencyHigh);

        const x: number = this.PADDING_LEFT +
          ((logFreq - logMin) / (logMax - logMin)) * (this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT);

        const value: number = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
        const normalizedValue: number = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const height: number = (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM) * normalizedValue;
        const y: number = this.canvasHeight - this.PADDING_BOTTOM - height;

        // 转换为整数坐标
        const intX = Math.round(x);
        const intY = Math.round(y);

        // 检查是否为重复点
        const isDuplicatePoint = lastX !== null && lastY !== null &&
          intX === lastX && intY === lastY;

        // 只在找到第一个有效点或非重复点时绘制
        if (isFirstValidPoint || !isDuplicatePoint) {
          if (isFirstValidPoint) {
            this.canvasContext.moveTo(x, y);
            isFirstValidPoint = false;
          } else {
            this.canvasContext.lineTo(x, y);
          }

          // 更新最后一个绘制点的坐标
          lastX = intX;
          lastY = intY;
        }
      }

      // 显示峰值频率
      if (this.peakFreq > 0) {
        const logPeakFreq: number = Math.log10(this.peakFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(frequencyHigh);
        const effectiveWidth: number = this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT;
        const peakX: number = this.PADDING_LEFT + ((logPeakFreq - logMin) / (logMax - logMin)) * effectiveWidth;

        // 计算Y坐标的替代方案
        const peakFreqY: number = this.canvasHeight - this.PADDING_BOTTOM -
          (maxValue / (this.MAX_DB - this.MIN_DB)) * (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM);

        this.canvasContext.fillStyle = '#fffdfdfd'; // 峰值标签使用白色
        this.canvasContext.textAlign = 'center';
        this.canvasContext.font = `bold ${this.FONT_SIZE}px sans-serif`; // 使用统一的字体大小
        this.canvasContext.fillText(
          `${Math.round(this.peakFreq)}Hz`,
          peakX,
          peakFreqY - 30 // 稍微抬高标签位置
        );
      }

      this.canvasContext.stroke();

      // 更新调试信息
      const debugInfo: string = `[FREQ_TRACE][Debug] 当前分贝: ${this.currentDecibel}dB\n` +
        `频谱范围: ${this.MIN_DB}dB ~ ${this.MAX_DB}dB\n` +
        `高度范围: ${this.PADDING_TOP}px ~ ${this.canvasHeight - this.PADDING_BOTTOM}px`;

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
          // 创建一个空的 ArrayBuffer 用于初始化显示
          const emptyBuffer: ArrayBuffer = new ArrayBuffer(this.currentFftSize * 2); // 每个点用2字节表示
          this.drawSpectrum(emptyBuffer)
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
        const db: number = this.decibelService.calculateDecibel(buffer, buffer.byteLength);

        this.currentDecibel = Math.round(db);
        this.values.push(this.currentDecibel);
        this.updateStatistics(this.currentDecibel);

        this.drawSpectrum(buffer);

      });
    } catch (error) {
      // 如果启动失败，重置状态
      this.isRecording = false;
      this.currentDecibel = 0;
      this.minDecibel = 0;
      this.maxDecibel = 0;
      this.avgDecibel = 0;
      this.dbCount = 0;
      this.dbSum = 0;
      this.values = [];
      this.startTime = 0;
      this.recordingTime = 0;
    }
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
        this.currentDecibel = 0;
        this.minDecibel = 0;
        this.maxDecibel = 0;
        this.avgDecibel = 0;
        this.dbCount = 0;
        this.dbSum = 0;
        this.values = [];
        this.startTime = 0;
        this.recordingTime = 0;
        this.showStats = false;

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
      .margin({ left: 8, right: 8 })
      .backgroundColor(Color.White)
      .borderRadius(24)
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
    Button({
      type: ButtonType.Capsule,
      stateEffect: true
    }) {
      Row() {
        Image($r('app.media.ic_save'))
          .width(24)
          .height(24)
          .margin({ right: 8 })
          .fillColor(Color.White)
        Text('保存记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(56)
    .margin({ top: 0, left: 16, right: 16 })
    .backgroundColor('#2196F3')
    .onClick(() => {
      this.stopRecording();
    })
  }
}