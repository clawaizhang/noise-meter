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
import { AudioAnalysisMode, AudioPresets, PREF_ANALYSIS_MODE } from '../../../library/ets/common/AudioConfig';

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
  @Local private displayPoints: Array<number> = []  // 动态数组，大小将根据FFT size调整
  @Local private peakPoints: Array<number> = []     // 动态数组，大小将根据FFT size调整
  @Local private peakHoldTime: Array<number> = []   // 动态数组，大小将根据FFT size调整
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
  @Local private canvasWidth: number = 0   // Canvas宽度
  @Local private canvasHeight: number = 0  // Canvas高度
  private readonly ASPECT_RATIO: number = 1.5  // 宽高比改为3:2
  private readonly SIDE_MARGIN: number = 16    // 左右边距各16像素
  private readonly MIN_FREQ: number = 0      // 最小频率改为0Hz
  private readonly MAX_FREQ: number = 22050  // 最大频率改为采样率的一半
  private readonly SAMPLE_RATE: number = 44100  // 采样率
  private readonly MIN_DB: number = -90      // 最小分贝值
  private readonly MAX_DB: number = 120      // 最大分贝值
  private readonly DB_STEP: number = 30      // 分贝刻度步进
  @Local private currentFftSize: number = 2048  // 当前FFT大小
  private readonly PADDING_TOP: number = 8     // 顶部内边距8px
  private readonly PADDING_BOTTOM: number = 40  // 底部内边距40px，给频率标签留出空间
  private readonly PADDING_LEFT: number = 32    // 左侧内边距32px，给分贝值留出空间
  private readonly PADDING_RIGHT: number = 16    // 右侧内边距16px
  private readonly FONT_SIZE: number = 32      // 字体大小32px
  private readonly PEAK_HOLD_TIME: number = 30    // 峰值保持时间（帧数）
  private readonly PEAK_DROP_SPEED: number = 2    // 峰值下降速度（像素/帧）
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)  // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)  // Canvas上下文

  // 屏幕宽度
  @Local private screenWidth: number = 0   // 屏幕宽度

  // 计算Canvas尺寸
  private async calculateCanvasDimensions(): Promise<void> {
    try {
      // 获取屏幕信息
      const displayInfo = display.getDefaultDisplaySync();
      
      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();
      
      // 输出详细的显示设备信息
      console.info(`[显示设备信息] 
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
      console.info(`[显示设备信息] 实际可用显示区域(逻辑像素): ${realWidth}x${realHeight}`);
      
      // 计算Canvas宽度（实际宽度减去左右边距）
      this.canvasWidth = realWidth - (this.SIDE_MARGIN * 2);
      console.info(`[显示设备信息] Canvas宽度(减去边距): ${this.canvasWidth}`);
      
      // 根据宽高比计算高度
      this.canvasHeight = Math.round(this.canvasWidth / this.ASPECT_RATIO);
      console.info(`[显示设备信息] Canvas高度(宽高比${this.ASPECT_RATIO}): ${this.canvasHeight}`);
      
      console.info(`[显示设备信息] 最终Canvas尺寸(逻辑像素): ${this.canvasWidth}x${this.canvasHeight}`);
      
    } catch (error) {
      console.error('[显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  // 绘制频谱的方法
  private drawSpectrum(buffer: ArrayBuffer): void {
    if (this.canvasContext) {
      console.info(`[频谱图绘制] 开始绘制，Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}`);
      
      // 清除画布
      this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
      
      // 计算实际可用的绘制区域
      const effectiveWidth = this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT;
      const effectiveHeight = this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM;
      console.info(`[频谱图绘制] 实际可绘制区域: ${effectiveWidth}x${effectiveHeight}`);

      // 绘制分贝刻度
      this.canvasContext.strokeStyle = '#666666';
      this.canvasContext.fillStyle = '#FFFFFF';
      this.canvasContext.textAlign = 'right';
      this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;  // 使用32px字体

      // 计算分贝刻度
      for (let db = this.MIN_DB; db <= this.MAX_DB; db += this.DB_STEP) {
        const y = this.canvasHeight - this.PADDING_BOTTOM - 
          ((db - this.MIN_DB) * effectiveHeight / (this.MAX_DB - this.MIN_DB));
          
        // 绘制刻度文本
        this.canvasContext.fillStyle = '#FFFFFF';
        this.canvasContext.fillText(`${db}`, this.PADDING_LEFT - 8, y + this.FONT_SIZE/3);  // 调整文本位置
        
        // 绘制水平网格线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#333333';
        this.canvasContext.moveTo(this.PADDING_LEFT, y);
        this.canvasContext.lineTo(this.canvasWidth - this.PADDING_RIGHT, y);
        this.canvasContext.stroke();
      }

      // 绘制频率刻度（X轴）
      this.canvasContext.textAlign = 'center';
      this.canvasContext.font = `${this.FONT_SIZE}px sans-serif`;  // 使用32px字体
      const freqLabels = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      
      for (const freq of freqLabels) {
        // 使用对数刻度计算X坐标
        const logFreq = Math.log10(freq);
        const logMin = Math.log10(16);
        const logMax = Math.log10(16000);
        const x = this.PADDING_LEFT + ((logFreq - logMin) / (logMax - logMin)) * effectiveWidth;
        
        // 绘制频率文本
        this.canvasContext.fillStyle = '#FFFFFF';
        const label = freq >= 1000 ? `${freq/1000}k` : freq.toString();
        this.canvasContext.fillText(label, x, this.canvasHeight - 8);  // 调整文本位置，距离底部8px
        
        // 绘制垂直网格线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#333333';
        this.canvasContext.moveTo(x, this.PADDING_TOP);
        this.canvasContext.lineTo(x, this.canvasHeight - this.PADDING_BOTTOM);
        this.canvasContext.stroke();
      }

      // 获取频谱数据
      const rawSpectrum = FrequencyWeighting.getSpectrumData(buffer);
      
      // 绘制主频谱折线
      this.canvasContext.beginPath();
      this.canvasContext.strokeStyle = '#2196F3';  // 主曲线用蓝色
      this.canvasContext.lineWidth = 2;
      
      // 遍历所有FFT点，使用对数频率刻度
      for (let i = 0; i < this.currentFftSize; i++) {
        const freq = (i * this.SAMPLE_RATE) / (2 * this.currentFftSize);
        if (freq < 16 || freq > 16000) continue;  // 只显示16Hz-16kHz的范围
        
        const logFreq = Math.log10(freq);
        const logMin = Math.log10(16);
        const logMax = Math.log10(16000);
        const x = this.PADDING_LEFT + ((logFreq - logMin) / (logMax - logMin)) * (this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT);
        
        const value = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
        const normalizedValue = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
        const height = effectiveHeight * normalizedValue;
        const y = this.canvasHeight - this.PADDING_BOTTOM - height;
        
        if (i === 0 || freq === 16) {
          this.canvasContext.moveTo(x, y);
        } else {
          this.canvasContext.lineTo(x, y);
        }
      }
      this.canvasContext.stroke();

      // 更新调试信息
      const debugInfo = `当前分贝: ${this.currentDecibel}dB\n` +
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
          console.info(`[频谱图尺寸] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          console.info(`[频谱图尺寸] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth/this.canvasHeight).toFixed(2)}`);
        })
        .onReady(() => {
          // 初始化完成后开始绘制
          // 创建一个空的 ArrayBuffer 用于初始化显示
          const emptyBuffer = new ArrayBuffer(this.currentFftSize * 2);  // 每个点用2字节表示
          this.drawSpectrum(emptyBuffer)
        })
      
      // 频率刻度（按八度分频）
      Row() {
        ForEach([16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], (freq: number) => {
          Text(freq >= 1000 ? `${freq/1000}k` : freq.toString())
            .fontSize(10)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('9.09%')  // 11个刻度，每个占 100/11 的宽度
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

  async aboutToAppear() {
    try {
      // 获取屏幕信息并初始化Canvas尺寸
      await this.calculateCanvasDimensions();
      console.info(`[显示设备信息] aboutToAppear - 初始化后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}`);
    } catch (error) {
      console.error('[显示设备信息] 初始化失败:', error);
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
        
        this.currentDecibel = Math.round(db);
        this.values.push(this.currentDecibel);
        this.updateStatistics(this.currentDecibel);

        // 获取频谱数据
        const rawSpectrum = FrequencyWeighting.getSpectrumData(buffer);
        
        // 绘制主频谱折线
        this.canvasContext.beginPath();
        this.canvasContext.strokeStyle = '#2196F3';  // 主曲线用蓝色
        this.canvasContext.lineWidth = 2;
        
        // 遍历所有FFT点
        for (let i = 0; i < this.currentFftSize; i++) {
          const freq = (i * this.SAMPLE_RATE) / (2 * this.currentFftSize);
          if (freq < 16 || freq > 16000) continue;  // 只显示16Hz-16kHz的范围
          
          const logFreq = Math.log10(freq);
          const logMin = Math.log10(16);
          const logMax = Math.log10(16000);
          const x = this.PADDING_LEFT + ((logFreq - logMin) / (logMax - logMin)) * (this.canvasWidth - this.PADDING_LEFT - this.PADDING_RIGHT);
          
          const value = Math.max(this.MIN_DB, Math.min(this.MAX_DB, rawSpectrum[i]));
          const normalizedValue = (value - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
          const height = (this.canvasHeight - this.PADDING_TOP - this.PADDING_BOTTOM) * normalizedValue;
          const y = this.canvasHeight - this.PADDING_BOTTOM - height;
          
          if (i === 0 || freq === 16) {
            this.canvasContext.moveTo(x, y);
          } else {
            this.canvasContext.lineTo(x, y);
          }
        }
        this.canvasContext.stroke();

        // 更新调试信息
        const debugInfo = `当前分贝: ${this.currentDecibel}dB\n` +
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