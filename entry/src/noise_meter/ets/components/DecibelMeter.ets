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
import { PreferenceService, PreferenceChangeListener, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';
import type { BusinessError } from '@ohos.base';
import systemIcon from '@ohos.multimedia.image';
import display from '@ohos.display'; // 新增屏幕相关的import

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
  @Local private displayBars: Array<number> = new Array(64).fill(2)
  @Local private debugText: string = ''
  @Local private peakFreq: number = 0  // 添加峰值频率变量
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
  @Local private canvasWidth: number = 0  // Canvas宽度
  @Local private canvasHeight: number = 0  // Canvas高度
  private readonly TOTAL_BARS: number = 64  // 总柱子数量固定为64
  private barWidth: number = 0  // 频谱条宽度
  private barGap: number = 0  // 频谱条间距
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)  // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)  // Canvas上下文

  // 屏幕宽度
  @Local private screenWidth: number = 0   // 屏幕宽度

  // 计算柱子宽度和间距的方法
  private calculateBarDimensions(): void {
    // 如果Canvas宽度为0，使用屏幕宽度计算
    if (this.canvasWidth === 0 && this.screenWidth > 0) {
      // 考虑系统边距(左右各12px)和组件内部padding(左右各16px)
      const systemMargin: number = 24;  // 左右各12px
      const componentPadding: number = 32;  // 左右各16px
      this.canvasWidth = this.screenWidth - systemMargin - componentPadding;
    }

    // Canvas内部padding
    const padding: number = 12;
    // 实际可用宽度
    const availableWidth: number = this.canvasWidth - (padding * 2);
    
    // 计算单个柱子的总宽度（包含间距）
    const totalBarWidth: number = availableWidth / this.TOTAL_BARS;
    
    // 柱子宽度占总宽度的80%，间距占20%
    this.barWidth = Math.max(1, Math.floor(totalBarWidth * 0.8));
    this.barGap = Math.max(1, Math.floor(totalBarWidth * 0.2));
    
    console.info(`[频谱图] 屏幕宽度: ${this.screenWidth}, Canvas宽度: ${this.canvasWidth}, 可用宽度: ${availableWidth}, 柱子宽度: ${this.barWidth}, 间距: ${this.barGap}`);
  }

  // 绘制频谱的方法
  private drawSpectrum(): void {
    // 清空画布
    this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    
    const padding: number = 12;
    const effectiveWidth: number = this.canvasWidth - (padding * 2);
    const effectiveHeight: number = this.canvasHeight - (padding * 2);
    
    // 计算实际可用的绘制区域
    console.info(`[频谱图] 绘制区域: 总宽度=${this.canvasWidth}, 有效宽度=${effectiveWidth}, 柱子数量=${this.TOTAL_BARS}`);
    
    // 绘制频谱条
    for (let i = 0; i < this.TOTAL_BARS; i++) {
      const height: number = (this.displayBars[i] / 100) * effectiveHeight;
      const x: number = padding + (i * effectiveWidth / this.TOTAL_BARS);
      const y: number = this.canvasHeight - padding - height;
      const actualBarWidth: number = Math.max(1, Math.floor(effectiveWidth / this.TOTAL_BARS * 0.8));
      const lineHeight: number = 2;  // 设置横线高度为4像素
      
      // 创建横条的渐变色
      const gradient = this.canvasContext.createLinearGradient(
        x,
        y,
        x + actualBarWidth,
        y
      );
      
      // 判断是否是峰值频率对应的点
      const isPeakFreq = this.displayBars[i] === Math.max(...this.displayBars);
      
      if (isPeakFreq) {
        // 峰值频率点使用橙色渐变
        gradient.addColorStop(0, '#FFA50000');
        gradient.addColorStop(0.2, '#FFA500');
        gradient.addColorStop(0.8, '#FFA500');
        gradient.addColorStop(1, '#FFA50000');
      } else {
        // 普通频率点使用蓝色渐变
        gradient.addColorStop(0, '#2196F300');
        gradient.addColorStop(0.2, '#2196F3');
        gradient.addColorStop(0.8, '#2196F3');
        gradient.addColorStop(1, '#2196F300');
      }
      
      // 设置渐变填充
      this.canvasContext.fillStyle = gradient;
      
      // 绘制横线（高度为4像素，居中显示）
      this.canvasContext.fillRect(x, y - lineHeight/2, actualBarWidth, lineHeight);
      
      // 如果是峰值频率点，显示频率值
      if (isPeakFreq) {
        this.canvasContext.fillStyle = '#FFA500';  // 改用橙色显示文字
        this.canvasContext.textAlign = 'center';
        this.canvasContext.font = 'bold 32px Arial';  // 添加bold使字体加粗
        this.canvasContext.fillText(
          `${Math.round(this.peakFreq)}Hz`,
          x + actualBarWidth/2,
          y - 10
        );
      }
    }
  }

  // 绘制圆角矩形的辅助方法
  private drawRoundedRect(
    x: number,
    y: number,
    width: number,
    height: number,
    radius: number
  ): void {
    // 确保所有参数都是有效的数字
    if (!isFinite(x) || !isFinite(y) || !isFinite(width) || !isFinite(height)) {
      console.error(`[频谱图] 无效的绘制参数: x=${x}, y=${y}, width=${width}, height=${height}`);
      return;
    }
    
    this.canvasContext.beginPath();
    this.canvasContext.moveTo(x + radius, y);
    this.canvasContext.lineTo(x + width - radius, y);
    this.canvasContext.quadraticCurveTo(x + width, y, x + width, y + radius);
    this.canvasContext.lineTo(x + width, y + height - radius);
    this.canvasContext.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    this.canvasContext.lineTo(x + radius, y + height);
    this.canvasContext.quadraticCurveTo(x, y + height, x, y + height - radius);
    this.canvasContext.lineTo(x, y + radius);
    this.canvasContext.quadraticCurveTo(x, y, x + radius, y);
    this.canvasContext.closePath();
    this.canvasContext.fill();
  }

  @Builder
  private SpectrumView() {
    Column() {
      // Canvas频谱显示
      Canvas(this.canvasContext)
        .width('100%')
        .height(120)
        .backgroundColor('#000000')
        .borderRadius(12)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          // 更新Canvas尺寸
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          
          // 如果Canvas宽度为0，使用屏幕宽度计算
          if (this.canvasWidth === 0 && this.screenWidth > 0) {
            // 考虑系统边距(左右各12px)和组件内部padding(左右各16px)
            const systemMargin: number = 24;  // 左右各12px
            const componentPadding: number = 32;  // 左右各16px
            this.canvasWidth = this.screenWidth - systemMargin - componentPadding;
          }
          
          // Canvas内部padding
          const padding: number = 12;
          // 实际可用宽度
          const availableWidth: number = this.canvasWidth - (padding * 2);
          
          // 计算单个柱子的总宽度（包含间距）
          const totalBarWidth: number = availableWidth / this.TOTAL_BARS;
          
          // 柱子宽度占总宽度的80%，间距占20%
          this.barWidth = Math.max(1, Math.floor(totalBarWidth * 0.8));
          this.barGap = Math.max(1, Math.floor(totalBarWidth * 0.2));
          
          console.info(`[频谱图] 屏幕宽度: ${this.screenWidth}, Canvas宽度: ${this.canvasWidth}, 可用宽度: ${availableWidth}, 柱子宽度: ${this.barWidth}, 间距: ${this.barGap}`);
        })
        .onReady(() => {
          // 初始化完成后开始绘制
          this.drawSpectrum()
        })
      
      // 频率刻度
      Row() {
        ForEach([0, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], (freq: number) => {
          Text(freq === 0 ? '0' : freq >= 1000 ? `${freq/1000}k` : freq.toString())
            .fontSize(10)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('10%')
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4 })
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

  aboutToAppear() {
    // 获取屏幕信息
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      console.info(`[频谱图] 获取屏幕宽度: ${this.screenWidth}`);
      
      // 初始计算柱子尺寸
      this.calculateBarDimensions();
    } catch (error) {
      console.error('[频谱图] 获取屏幕信息失败:', error);
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
      console.info('[DecibelMeter] 音频采集启动成功');
      // 直接开始检测
      this.startRecording();
    }).catch((error: BusinessError) => {
      console.error('[DecibelMeter] 音频采集启动失败:', error);
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
        undefined // audioFilePath
      );

      // 如果启用了录音功能，开始录音
      if (this.isRecordEnabled) {
        this.audioService.startRecording();
      }

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 计算分贝值
        const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
        
        if (db > 0) {
          this.currentDecibel = Math.round(db);
          this.values.push(this.currentDecibel);
          this.updateStatistics(this.currentDecibel);
        } else {
          this.currentDecibel = 0;
        }
        
        // 获取频谱数据
        const rawSpectrum = FrequencyWeighting.getSpectrumData(buffer);
        
        // 设置显示参数
        const maxDisplayDb: number = 130;    // 最大显示分贝值
        const minDisplayDb: number = 0;      // 最小显示分贝值
        const maxHeight: number = 100;       // 最大高度百分比
        const minHeight: number = 2;         // 最小高度百分比
        const heightRange: number = maxHeight - minHeight;
        
        // 定义频率点
        const sampleRate: number = 44100;    // 采样率
        const fftSize: number = this.audioService.getCurrentFFTSize();
        const minFreq: number = 20;          // 最小频率 20Hz
        const maxFreq: number = 20000;       // 最大频率 20kHz
        
        // 计算频谱高度
        const newDisplayBars = new Array<number>(this.TOTAL_BARS);
        let maxValue: number = -Infinity;    // 记录最大分贝值
        let maxIndex: number = -1;
        this.peakFreq = 0;
        let firstValidBar: number = -1;      // 记录第一个有效柱子的位置
        let lastValidBar: number = -1;       // 记录最后一个有效柱子的位置
        
        // 第一遍扫描：找出最大分贝值
        let maxDb: number = -Infinity;
        for (let i = 0; i < this.TOTAL_BARS; i++) {
          const freq: number = minFreq * Math.pow(maxFreq / minFreq, i / (this.TOTAL_BARS - 1));
          const lowerFreq: number = i === 0 ? minFreq : minFreq * Math.pow(maxFreq / minFreq, (i - 0.5) / (this.TOTAL_BARS - 1));
          const upperFreq: number = i === this.TOTAL_BARS - 1 ? maxFreq : minFreq * Math.pow(maxFreq / minFreq, (i + 0.5) / (this.TOTAL_BARS - 1));
          const lowerBin: number = Math.floor(lowerFreq * fftSize / sampleRate);
          const upperBin: number = Math.min(Math.floor(upperFreq * fftSize / sampleRate), rawSpectrum.length - 1);
          
          let sum: number = 0;
          let count: number = 0;
          
          for (let bin = lowerBin; bin <= upperBin; bin++) {
            const value: number = rawSpectrum[bin];
            if (isFinite(value)) {
              sum += value;
              count++;
            }
          }
          
          if (count > 0) {
            const avgDb: number = sum / count;
            if (avgDb > maxDb) {
              maxDb = avgDb;
            }
          }
        }
        
        // 根据最大分贝值确定显示策略
        const highDbThreshold: number = 80;  // 高分贝阈值
        const lowDbThreshold: number = 40;   // 低分贝阈值
        let displayStrategy: number;         // 显示策略系数
        
        if (maxDb > highDbThreshold) {
          // 有高分贝信号，使用线性映射
          displayStrategy = 1.0;
        } else if (maxDb < lowDbThreshold) {
          // 整体是低分贝，使用较大的放大系数
          displayStrategy = 0.3;
        } else {
          // 中等分贝，使用适中的放大系数
          const ratio: number = (maxDb - lowDbThreshold) / (highDbThreshold - lowDbThreshold);
          displayStrategy = 0.3 + ratio * 0.7; // 在0.3到1.0之间平滑过渡
        }
        
        // 第二遍扫描：应用显示策略
        for (let i = 0; i < this.TOTAL_BARS; i++) {
          const freq: number = minFreq * Math.pow(maxFreq / minFreq, i / (this.TOTAL_BARS - 1));
          const lowerFreq: number = i === 0 ? minFreq : minFreq * Math.pow(maxFreq / minFreq, (i - 0.5) / (this.TOTAL_BARS - 1));
          const upperFreq: number = i === this.TOTAL_BARS - 1 ? maxFreq : minFreq * Math.pow(maxFreq / minFreq, (i + 0.5) / (this.TOTAL_BARS - 1));
          const lowerBin: number = Math.floor(lowerFreq * fftSize / sampleRate);
          const upperBin: number = Math.min(Math.floor(upperFreq * fftSize / sampleRate), rawSpectrum.length - 1);
          
          let sum: number = 0;
          let count: number = 0;
          
          for (let bin = lowerBin; bin <= upperBin; bin++) {
            const value: number = rawSpectrum[bin];
            if (isFinite(value)) {
              sum += value;
              count++;
              if (value > maxValue) {
                maxValue = value;
                maxIndex = bin;
                this.peakFreq = (bin * sampleRate / fftSize);
              }
            }
          }
          
          if (count > 0) {
            const avgDb: number = sum / count;
            
            if (avgDb > minDisplayDb) {
              const dbValue: number = Math.min(maxDisplayDb, Math.max(minDisplayDb, avgDb));
              const normalizedValue: number = (dbValue - minDisplayDb) / (maxDisplayDb - minDisplayDb);
              
              // 根据显示策略调整显示高度
              const heightValue: number = Math.pow(normalizedValue, displayStrategy);
              newDisplayBars[i] = minHeight + heightRange * heightValue;
              
              // 记录有效值的位置
              if (heightValue > 0.05) {
                if (firstValidBar === -1) {
                  firstValidBar = i;
                }
                lastValidBar = i;
              }
            } else {
              newDisplayBars[i] = 0;
            }
          } else {
            newDisplayBars[i] = 0;
          }
        }
        
        // 处理左右两侧的快速衰减
        const minWaveHeight: number = 5; // 最小波动高度
        
        // 处理左侧衰减
        if (firstValidBar > 0) {
          const startHeight: number = newDisplayBars[firstValidBar];
          const emptyBars: number = firstValidBar;
          const decayFactor: number = Math.pow(minWaveHeight / startHeight, 1 / emptyBars);
          
          for (let i = firstValidBar - 1; i >= 0; i--) {
            const decay: number = Math.pow(decayFactor, firstValidBar - i);
            const baseHeight: number = startHeight * decay;
            newDisplayBars[i] = Math.max(minWaveHeight, baseHeight);
          }
        }
        
        // 处理右侧衰减
        if (lastValidBar < this.TOTAL_BARS - 1) {
          const startHeight: number = newDisplayBars[lastValidBar];
          const emptyBars: number = this.TOTAL_BARS - lastValidBar - 1;
          const decayFactor: number = Math.pow(minWaveHeight / startHeight, 1 / emptyBars);
          
          for (let i = lastValidBar + 1; i < this.TOTAL_BARS; i++) {
            const decay: number = Math.pow(decayFactor, i - lastValidBar);
            const baseHeight: number = startHeight * decay;
            newDisplayBars[i] = Math.max(minWaveHeight, baseHeight);
          }
        }
        
        // 确保所有值都在有效范围内
        for (let i = 0; i < this.TOTAL_BARS; i++) {
          newDisplayBars[i] = Math.max(minHeight, Math.min(maxHeight, newDisplayBars[i]));
        }
        
        // 更新显示数据
        for (let i = 0; i < this.TOTAL_BARS; i++) {
          this.displayBars[i] = newDisplayBars[i];
        }
        
        // 更新调试信息
        const debugInfo = `当前分贝: ${this.currentDecibel}dB\n` +
          `最大频率: ${this.peakFreq.toFixed(1)}Hz (${maxValue.toFixed(1)}dB)\n` +
          `频谱范围: ${minDisplayDb}dB ~ ${maxDisplayDb}dB\n` +
          `高度范围: ${minHeight}% ~ ${maxHeight}%\n` +
          `FFT大小: ${fftSize}, 频谱长度: ${rawSpectrum.length}`;
        
        this.debugText = debugInfo;

        // 更新计时器
        this.recordingTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
        
        // 重新绘制频谱
        this.drawSpectrum()
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
      console.info('停止检测 - 开始');

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        console.info('位置信息:', locationInfo);
        
        // 计算检测时长
        const duration = new Date().getTime() - this.startTime;
        console.info('检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath = '';
        if (this.isRecordEnabled) {
          try {
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(this.fileService);
          } catch (error) {
            console.error('获取或保存WAV音频数据失败:', error);
          }
        }

        console.info('准备创建记录');
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
          console.info('记录保存成功');

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
        console.error('保存记录失败:', error);
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
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = seconds % 60;
    
    let result = '';
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