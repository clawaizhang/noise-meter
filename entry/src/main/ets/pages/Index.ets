// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
// 导入错误处理模块
import { BusinessError } from '@ohos.base'

// 波形图点的接口定义
interface WavePoint {
  x: number
  y: number
}

@Entry
@Component
struct Index {
  // 当前分贝值
  @State currentDB: number = 0
  // 最大分贝值
  @State maxDB: number = 0
  // 最小分贝值
  @State minDB: number = 100
  // 是否正在录音
  @State isRecording: boolean = false
  // 波形图数据数组
  @State waveData: Array<number> = new Array<number>(100).fill(0)
  // 音频捕获器实例
  private audioCapture: audio.AudioCapturer | null = null
  // 定时器ID
  private timer: number = -1
  // 音频采样率
  private readonly SAMPLE_RATE: number = 44100
  // 音频通道数
  private readonly CHANNELS: number = 1
  // 音频采样格式
  private readonly SAMPLE_FORMAT: audio.AudioSampleFormat = audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE
  // 缓冲区大小
  private readonly BUFFER_SIZE: number = 2048

  // 组件生命周期-创建
  aboutToAppear(): void {
    // 初始化音频捕获器
    this.initAudioCapture()
  }

  // 组件生命周期-销毁
  aboutToDisappear(): void {
    // 停止录音
    this.stopRecording()
  }

  // 初始化音频捕获器
  async initAudioCapture(): Promise<void> {
    try {
      // 创建音频捕获器配置
      const capturerOptions: audio.AudioCapturerOptions = {
        streamInfo: {
          samplingRate: this.SAMPLE_RATE,
          channels: this.CHANNELS,
          sampleFormat: this.SAMPLE_FORMAT,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        capturerInfo: {
          source: audio.SourceType.SOURCE_TYPE_MIC,
          capturerFlags: 0
        }
      }

      // 创建音频捕获器
      this.audioCapture = await audio.createAudioCapturer(capturerOptions)

    } catch (err) {
      console.error('初始化音频捕获器失败:', err.message)
    }
  }

  // 计算音频数据的分贝值
  private calculateDB(buffer: ArrayBuffer, length: number): number {
    // 将缓冲区数据转换为16位整数数组
    const samples: Int16Array = new Int16Array(buffer, 0, length / 2)
    let sum: number = 0

    // 计算均方根（RMS）
    for (let i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i]
    }
    const rms: number = Math.sqrt(sum / samples.length)

    // 将RMS转换为分贝值（参考值：16位音频的最大值是32767）
    const db: number = 20 * Math.log10(rms / 32767)

    // 归一化到0-120分贝范围
    return Math.max(0, Math.min(120, Math.round(db + 120)))
  }

  // 开始录音
  async startRecording(): Promise<void> {
    if (!this.audioCapture || this.isRecording) {
      return
    }

    try {
      // 启动音频捕获
      await this.audioCapture.start()
      this.isRecording = true

      // 创建定时器定期读取音频数据
      this.timer = setInterval((): void => {
        this.readAudioData()
      }, 50)

    } catch (err) {
      console.error('启动音频捕获失败:', err.message)
    }
  }

  // 读取音频数据
  private readAudioData(): void {
    if (!this.audioCapture || !this.isRecording) {
      return
    }

    try {
      // 直接读取指定大小的数据
      this.audioCapture.read(this.BUFFER_SIZE, false, (error: BusinessError | null, buffer: ArrayBuffer): void => {
        if (error) {
          console.error('读取音频数据失败:', error.message)
          return
        }

        // 检查是否成功读取数据
        if (buffer && buffer.byteLength > 0) {
          // 计算分贝值
          const db: number = this.calculateDB(buffer, buffer.byteLength)
          this.currentDB = db
          this.maxDB = Math.max(this.maxDB, db)
          this.minDB = Math.min(this.minDB, db)

          // 更新波形图数据
          this.waveData.shift()
          this.waveData.push(db)
        }
      })
    } catch (err) {
      console.error('读取音频数据失败:', err.message)
    }
  }

  // 停止录音
  async stopRecording(): Promise<void> {
    // 清除定时器
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }

    // 停止音频捕获
    if (this.audioCapture && this.isRecording) {
      try {
        await this.audioCapture.stop()
        this.isRecording = false
      } catch (err) {
        console.error('停止音频捕获失败:', err.message)
      }
    }
  }

  // 构建波形图组件
  @Builder
  WaveformView() {
    // 波形图容器
    Row() {
      // 绘制波形线
      Polyline({ width: '100%', height: '100%' })
        .points(this.waveData.map((value: number, index: number): WavePoint => {
          return {
            x: index * (100 / this.waveData.length),
            y: 50 - (value * 0.4) // 缩放以适应视图高度
          }
        }))
        .stroke(Color.Blue)
        .strokeWidth(2)
    }
    .width('100%')
    .height(100)
    .backgroundColor('#f5f5f5')
  }

  // 构建主界面
  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('噪音分贝仪')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
      }
      .margin({ top: 20, bottom: 20 })

      // 主要分贝显示区域
      Column() {
        Text(`${this.currentDB}`)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor())
        Text('dB')
          .fontSize(20)
          .margin({ top: 5 })

        // 噪音级别说明
        Text(this.getNoiseLevel())
          .fontSize(16)
          .margin({ top: 10 })
          .fontColor('#666666')
      }
      .margin({ top: 20, bottom: 20 })

      // 波形图区域
      Row() {
        this.WaveformView()
      }
      .margin({ top: 20, bottom: 20 })

      // 最大最小值显示区域
      Row() {
        Column() {
          Text('最小值')
            .fontSize(16)
          Text(`${this.minDB}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ right: 40 })

        Column() {
          Text('最大值')
            .fontSize(16)
          Text(`${this.maxDB}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
        }
      }
      .margin({ top: 20, bottom: 30 })

      // 控制按钮
      Button() {
        Text(this.isRecording ? '停止测量' : '开始测量')
          .fontSize(18)
          .fontColor(Color.White)
      }
      .width(200)
      .height(50)
      .backgroundColor(this.isRecording ? '#FF4081' : '#2196F3')
      .onClick(() => {
        if (this.isRecording) {
          this.stopRecording()
        } else {
          this.startRecording()
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding(20)
  }

  // 获取分贝值对应的颜色
  private getDBColor(): string {
    if (this.currentDB < 30) {
      return '#4CAF50'
    } // 绿色 - 安静
    if (this.currentDB < 60) {
      return '#2196F3'
    } // 蓝色 - 正常
    if (this.currentDB < 90) {
      return '#FFC107'
    } // 黄色 - 较吵
    if (this.currentDB < 100) {
      return '#FF9800'
    } // 橙色 - 吵闹
    return '#F44336' // 红色 - 危险
  }

  // 获取噪音级别说明
  private getNoiseLevel(): string {
    if (this.currentDB < 30) {
      return '安静环境'
    }
    if (this.currentDB < 60) {
      return '正常对话'
    }
    if (this.currentDB < 90) {
      return '城市喧闹'
    }
    if (this.currentDB < 100) {
      return '工业噪音'
    }
    return '危险噪音'
  }
}