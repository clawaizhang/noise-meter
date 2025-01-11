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
  private readonly MIN_FREQ: number = 0 // 最小频率改为0Hz
  private readonly MAX_FREQ: number = 22050 // 最大频率改为采样率的一半
  private readonly SAMPLE_RATE: number = 44100 // 采样率
  private readonly MIN_DB: number = -20 // 最小分贝值调整为-20
  private readonly MAX_DB: number = 120 // 最大分贝值保持120
  private readonly DB_STEP: number = 30 // 分贝刻度步进保持30
  @Local private currentFftSize: number = 2048 // 当前FFT大小
  private readonly PADDING_TOP: number = 20 // 顶部内边距减小到20px
  private readonly PADDING_BOTTOM: number = 20 // 底部内边距减小到20px
  private readonly PADDING_LEFT: number = 32 // 左侧内边距32px，给分贝值留出空间
  private readonly PADDING_RIGHT: number = 16 // 右侧内边距16px
  private readonly FONT_SIZE: number = 32 // 字体大小32px
  private readonly FREQ_LABEL_OFFSET: number = 5 // 频率标签距离网格底部的偏移量
  private readonly PEAK_HOLD_TIME: number = 30 // 峰值保持时间（帧数）
  private readonly PEAK_DROP_SPEED: number = 2 // 峰值下降速度（像素/帧）
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  // 屏幕宽度
  @Local private screenWidth: number = 0 // 屏幕宽度
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
      console.info(`[FREQ_TRACE][Spectrum] 开始绘制，Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}`);

      // 获取当前分析模式和FFT大小
      const currentMode = this.preferenceService.getString(PREF_ANALYSIS_MODE, 'default') as AudioAnalysisMode;
      const fftSize = AudioPresets.getConfig(currentMode).fftSize;
      console.info(`[FREQ_TRACE][FFT] 当前模式: ${currentMode}, FFT大小: ${fftSize}`);

      // 清除画布
      this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

      // 计算实际可用的绘制区域
      const effectiveWidth: number = this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT;
      const effectiveHeight: number = this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM;
      console.info(`[FREQ_TRACE][Canvas] 实际可绘制区域: ${effectiveWidth}x${effectiveHeight}, 内边距: 上${this.PADDING_TOP} 下${this.PADDING_BOTTOM} 左${this.PADDING_LEFT} 右${this.PADDING_RIGHT}`);
      console.info(`[FREQ_TRACE][Grid] 分贝范围: ${this.MIN_DB} ~ ${this.MAX_DB}`);
      console.info(`[FREQ_TRACE][Grid] 网格步进: ${this.DB_STEP}`);
      console.info(`[FREQ_TRACE][Grid] Canvas高度: ${this.canvasHeight}`);
      console.info(`[FREQ_TRACE][Grid] PADDING_TOP: ${this.PADDING_TOP}, PADDING_BOTTOM: ${this.PADDING_BOTTOM}`);
      console.info(`[FREQ_TRACE][Grid] 有效高度: ${effectiveHeight}`);

      // 分贝网格点生成
      const dbSteps: number[] = [-20, 0, 20, 40, 60, 80, 100, 120];
      console.info(`[FREQ_TRACE][Grid] 分贝网格点: ${dbSteps.join(', ')}`);

      // 频率步进点生成
      const frequencySteps: number[] = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      const MIN_FREQ: number = 16; // 最小频率
      const MAX_FREQ: number = 16000; // 最大频率

      // 仅在第一次绘制时记录频率步进点
      if (this.isFirstFrequencyRun) {
        console.info(`[FREQ_TRACE][Frequency] 频率步进点: ${frequencySteps.join(', ')}`);
        this.isFirstFrequencyRun = false;
      }

      // 更精确的对数映射计算
      for (let i = 0; i < frequencySteps.length; i++) {
        const freq: number = frequencySteps[i];
        
        // 使用对数映射公式：(log(freq) - log(MIN_FREQ)) / (log(MAX_FREQ) - log(MIN_FREQ))
        const logFreq: number = Math.log10(freq);
        const normalizedLogFreq: number = (logFreq - Math.log10(MIN_FREQ)) / (Math.log10(MAX_FREQ) - Math.log10(MIN_FREQ));
        
        console.info(`[FREQ_TRACE][Frequency] 频率: ${freq}Hz, 原始对数映射: ${logFreq}, 归一化对数映射: ${normalizedLogFreq.toFixed(4)}`);
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
          // 但是仍然绘制最顶部（120分贝）的标签
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
        if ([-20, 0, 20, 40, 60, 80, 100, 120].includes(db)) {
          this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色
          this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
          this.canvasContext.textAlign = 'right';
          this.canvasContext.fillText(
            `${db}`, 
            this.PADDING_LEFT - 5, 
            y + this.FONT_SIZE/3
          );
        }

        console.info(`[FREQ_TRACE][Grid] 分贝: ${db}, Y坐标: ${y}`);
      }

      // 频率网格点生成（1/3八度间隔）
      const frequencySteps1: number[] = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      console.info(`[FREQ_TRACE][Freq] 频率网格点: ${frequencySteps1.join(', ')}`);

      // 绘制频率刻度
      this.canvasContext.textAlign = 'left';  // 改为左对齐
      this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;
      this.canvasContext.fillStyle = '#AAAAAA'; // 频率标签颜色

      // 计算对数坐标映射的常量
      const logMin: number = Math.log10(16);
      const logMax: number = Math.log10(16000);

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

        console.info(`[FREQ_TRACE][Freq] 频率: ${freq}, X坐标: ${x}`);
      }

      // 使用 FFTAnalyzer 的频率映射工具方法
      FFTAnalyzer.printFrequencyBinMapping(this.SAMPLE_RATE, fftSize);

      for (let i = 0; i < fftSize / 2; i++) {
        // 使用标准频率计算方法
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, fftSize);
        
        // 计算x坐标
        const normalizedIndex: number = i / (fftSize / 2);
        const x: number = this.canvasWidth * normalizedIndex;
        
        console.info(`[FREQ_TRACE][FrequencyBin] 频率映射 - 索引: ${i}, 中心频率: ${centerFreq.toFixed(2)}Hz, X坐标: ${x.toFixed(2)}`);
      }

      // 获取频谱数据并记录范围
      const rawSpectrum: Float32Array = FrequencyWeighting.getSpectrumData(buffer);
      let minSpectrum: number = Infinity;
      let maxSpectrum: number = -Infinity;
      for (const value of rawSpectrum) {
        if (isFinite(value)) {
          minSpectrum = Math.min(minSpectrum, value);
          maxSpectrum = Math.max(maxSpectrum, value);
        }
      }
      console.info(`[FREQ_TRACE][Spectrum] 原始频谱数据范围: ${minSpectrum.toFixed(2)}dB ~ ${maxSpectrum.toFixed(2)}dB`);

      // 添加详细的频谱数据调试日志
      const MIN_DB_THRESHOLD: number = -120.0; // 定义一个明确的最小分贝阈值
      console.info(`频谱数据调试: 长度=${rawSpectrum.length}, 非零值数量=${rawSpectrum.filter(v => v > MIN_DB_THRESHOLD).length}`);
      console.info(`前10个频谱值: ${rawSpectrum.slice(0, 10).map(v => v).join(', ')}`);
      console.info(`最后10个频谱值: ${rawSpectrum.slice(-10).map(v => v).join(', ')}`);

      // 预计算频率相关的常量
      const octaveRatio: number = Math.pow(2, 1 / 3); // 每1/3个八度的比例
      const newDisplayPoints: number[] = new Array<number>(fftSize / 2);
      let maxValue: number = -Infinity;
      let maxIndex: number = -1;
      this.peakFreq = 0;

      // 记录一些关键频点的计算结果
      const debugFreqs: number[] = [16, 1000, 16000]; // 记录这些特定频率点的计算结果
      for (const freq of debugFreqs) {
        const logFreq: number = Math.log10(freq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(16000);
        const x: number = this.PADDING_LEFT + ((logFreq - logMin) / (logMax - logMin)) * effectiveWidth;
        console.info(`[FREQ_TRACE][Coordinates] 频率${freq}Hz -> x坐标: ${x.toFixed(2)}`);
      }

      // 按照八度分频计算每个频点
      let pointsAboveZero: number = 0;
      let totalPoints: number = 0;
      for (let i = 0; i < fftSize / 2; i++) {
        // 使用标准频率计算方法
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, fftSize);

        // 计算频带边界
        const lowerFreq: number = centerFreq / Math.pow(octaveRatio, 0.5);
        const upperFreq: number = centerFreq * Math.pow(octaveRatio, 0.5);

        // 将频率转换为FFT bin索引
        const lowerBin: number = Math.max(1, Math.floor(lowerFreq * fftSize / this.SAMPLE_RATE));
        const upperBin: number = Math.min(Math.floor(upperFreq * fftSize / this.SAMPLE_RATE), rawSpectrum.length - 1);

        let sum: number = 0;
        let count: number = 0;

        // 计算频段内的平均能量
        for (let bin = lowerBin; bin <= upperBin; bin++) {
          const value: number = rawSpectrum[bin];
          if (isFinite(value)) {
            sum += value;
            count++;
            if (value > maxValue) {
              maxValue = value;
              maxIndex = bin;
              this.peakFreq = (bin * this.SAMPLE_RATE / fftSize);
            }
          }
        }

        // 计算高度
        if (count > 0) {
          const avgDb: number = sum / count;
          const normalizedValue: number = (avgDb - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
          newDisplayPoints[i] = effectiveHeight * Math.max(0, Math.min(1, normalizedValue));
        } else {
          newDisplayPoints[i] = 0;
        }

        if (newDisplayPoints[i] > 0) {
          pointsAboveZero++;
        }
        totalPoints++;

        if (i % (fftSize / 8) === 0) { // 每1/8的点记录一次
          console.info(`[FREQ_TRACE][Points] 索引${i}: 高度=${newDisplayPoints[i].toFixed(2)}, ` +
            `对应频率=${(i * this.SAMPLE_RATE / fftSize).toFixed(2)}Hz`);
        }
      }
      console.info(`[FREQ_TRACE][Statistics] 总点数: ${totalPoints}, 高度大于0的点数: ${pointsAboveZero}`);

      // 打印详细的频谱数据调试信息
      console.info(`[FREQ_TRACE][SpectrumDebug] 
        频谱数据长度: ${newDisplayPoints.length}
        原始数据: ${newDisplayPoints.join(', ')}
        最大值索引: ${maxIndex}
        最大值: ${maxValue}
        最大值对应的频率: ${this.peakFreq}Hz`);

      // 显示峰值频率
      if (this.peakFreq > 0) {
        const logPeakFreq: number = Math.log10(this.peakFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(16000);
        const effectiveWidth: number = this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT;
        const peakX: number = this.PADDING_LEFT + ((logPeakFreq - logMin) / (logMax - logMin)) * effectiveWidth;

        // 计算Y坐标的替代方案
        const peakFreqY: number = this.canvasHeight - this.PADDING_BOTTOM - 
          (maxValue / (this.MAX_DB - this.MIN_DB)) * (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM);

        this.canvasContext.fillStyle = '#FF8C00'; // 峰值标签使用深橙色
        this.canvasContext.textAlign = 'center';
        this.canvasContext.font = `bold ${this.FONT_SIZE}px sans-serif`; // 使用统一的字体大小
        this.canvasContext.fillText(
          `${Math.round(this.peakFreq)}Hz`,
          peakX,
          peakFreqY - 10 // 稍微抬高标签位置
        );
      }

      // 绘制主频谱折线
      this.canvasContext.beginPath();
      this.canvasContext.strokeStyle = '#2196F3'; // 主曲线用蓝色
      this.canvasContext.lineWidth = 2;

      for (let i = 0; i < fftSize / 2; i++) {
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, fftSize);
        const logFreq: number = Math.log10(centerFreq);
        const logMin: number = Math.log10(16);
        const logMax: number = Math.log10(16000);
        const x: number = this.PADDING_LEFT +
          ((logFreq - logMin) / (logMax - logMin)) * (this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT);

        const value: number = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
        const normalizedValue: number = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const height: number = (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM) * normalizedValue;
        const y: number = this.canvasHeight - this.PADDING_BOTTOM - height;

        if (i === 0) {
          this.canvasContext.moveTo(x, y);
        } else {
          this.canvasContext.lineTo(x, y);
        }
      }
      this.canvasContext.stroke();

      // 频率点处理：使用对数映射计算中心频率
      const FREQ_MIN: number = 16; // 最小频率
      const FREQ_MAX: number = 22050; // 最大频率（采样率的一半）
      const LOG_FREQ_RANGE: number = Math.log2(FREQ_MAX / FREQ_MIN);
      
      console.info(`[FREQ_TRACE][FrequencyMapping] 频率范围: ${FREQ_MIN}Hz - ${FREQ_MAX}Hz`);
      console.info(`[FREQ_TRACE][FrequencyMapping] 对数频率范围: ${LOG_FREQ_RANGE.toFixed(2)}`);

      for (let i = 0; i < fftSize / 2; i++) {
        // 使用标准频率计算方法
        const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, fftSize);
        
        // 计算x坐标
        const x: number = this.canvasWidth * i / (fftSize / 2);
        
        console.info(`[FREQ_TRACE][FrequencyBin] 频率映射 - 索引: ${i}, 中心频率: ${centerFreq.toFixed(2)}Hz, X坐标: ${x.toFixed(2)}`);

        // 每隔一定间隔记录详细日志
        if (i % 50 === 0) {
          console.info(`[FREQ_TRACE][FrequencyBin] 详细频率处理 - 索引: ${i}, 对数映射频率: ${centerFreq.toFixed(2)}Hz`);
        }
      }

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

        // 获取频谱数据
        const rawSpectrum: Float32Array = FrequencyWeighting.getSpectrumData(buffer);

        this.drawSpectrum(buffer);
        // 绘制主频谱折线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#2196F3'; // 主曲线用蓝色
        this.canvasContext.lineWidth = 2;

        // 遍历所有FFT点
        for (let i = 0; i < this.currentFftSize; i++) {
          const centerFreq: number = FFTAnalyzer.calculateCenterFrequency(i, this.SAMPLE_RATE, this.currentFftSize);
          if (centerFreq < 16 || centerFreq > 16000) {
            continue;
          } // 只显示16Hz-16kHz的范围

          const logFreq: number = Math.log10(centerFreq);
          const logMin: number = Math.log10(16);
          const logMax: number = Math.log10(16000);
          const x: number = this.PADDING_LEFT +
            ((logFreq - logMin) / (logMax - logMin)) * (this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT);

          const value: number = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
          const normalizedValue: number = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
          const height: number = (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM) * normalizedValue;
          const y: number = this.canvasHeight - this.PADDING_BOTTOM - height;

          if (i === 0 || centerFreq === 16) {
            this.canvasContext.moveTo(x, y);
          } else {
            this.canvasContext.lineTo(x, y);
          }
        }
        this.canvasContext.stroke();

        // 更新调试信息
        const debugInfo: string = `[FREQ_TRACE][Debug] 当前分贝: ${this.currentDecibel}dB\n` +
          `频谱范围: ${this.MIN_DB}dB ~ ${this.MAX_DB}dB\n` +
          `高度范围: ${this.PADDING_TOP}px ~ ${this.canvasHeight - this.PADDING_BOTTOM}px`;

        this.debugText = debugInfo;

        // 更新计时器
        this.recordingTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
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
      console.info('[FREQ_TRACE][Recording] 停止检测 - 开始');

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