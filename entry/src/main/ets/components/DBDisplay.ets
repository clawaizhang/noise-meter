import { PermissionUtil } from '@pura/harmony-utils'
import audio from '@ohos.multimedia.audio'
import { AudioService } from '../services/AudioService'

@Component
export struct DBDisplay {
  @Link minDB: number
  @Link maxDB: number
  @Link avgDB: number
  @Link currentDB: number
  @Link
  @Watch('onRecordingStateChange')
  isRecording: boolean
  @Link hasMicPermission: boolean
  getDBColor: (db: number) => string = () => '#666666'
  @State permissionError: string = ''
  private sampleCount: number = 0
  private sampleSum: number = 0
  private audioService: AudioService | null = null
  private isFirstMeasurement: boolean = true

  aboutToAppear() {
    this.maxDB = 0
    this.minDB = 0
    this.currentDB = 0
    this.sampleCount = 0
    this.sampleSum = 0
    this.avgDB = 0
    
    this.initAudioService()
    this.checkAndRequestPermission()
  }

  aboutToDisappear() {
    try {
      // 先停止录音
      this.audioService?.stopRecording()
      // 释放音频捕获器资源
      this.audioService?.release()
      // 清空音频服务实例
      this.audioService = null
      // 重置状态
      this.isRecording = false
      this.hasMicPermission = false
    } catch (err) {
      console.error('释放录音资源失败:', JSON.stringify(err))
    }
  }

  private async onRecordingStateChange() {
    if (this.isRecording) {
      // 开始测量时重置第一次测量标志
      this.isFirstMeasurement = true
    }
  }

  @Builder
  ErrorMessage() {
    if (this.permissionError) {
      Row() {
        Text(this.permissionError)
          .fontSize(14)
          .fontColor('#FF4081')
        if (this.permissionError.includes('手动开启')) {
          Text('去设置')
            .fontSize(14)
            .fontColor('#2196F3')
            .margin({ left: 4 })
            .onClick(async () => {
              await PermissionUtil.requestPermissionsEasy(['ohos.permission.MICROPHONE'])
              this.checkAndRequestPermission()
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })
    }
  }

  @Builder
  DBValue() {
    Row() {
      Column() {
        Text(this.currentDB.toFixed(1))
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.currentDB))
        Text('dB')
          .fontSize(24)
          .fontColor('#666666')
          .margin({ top: 8 })
        Text(this.getNoiseLevel())
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(200)
    .backgroundColor('#F5F5F5')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 20 })
  }

  private initAudioService() {
    this.audioService = new AudioService({
      sampleRate: 44100,
      channels: 1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      bufferSize: 2048
    })

    this.isFirstMeasurement = true

    this.audioService.setListener({
      onDBValueChange: (db: number) => {
        // 只在测量状态时更新数据
        if (this.isRecording) {
          this.currentDB = db
          // 每次开始新的测量时，第一个数据作为初始值
          if (this.isFirstMeasurement) {
            this.maxDB = db
            this.minDB = db
            this.avgDB = db
            this.sampleSum = db
            this.sampleCount = 1
            this.isFirstMeasurement = false
          } else {
            if (db > this.maxDB) {
              this.maxDB = db
            }
            if (db < this.minDB) {
              this.minDB = db
            }
            this.sampleSum += db
            this.sampleCount++
            this.avgDB = Math.round(this.sampleSum / this.sampleCount)
          }
        }
      },
      onError: (error: string) => {
        console.error(error)
        this.permissionError = error
      }
    })

    // 初始化后立即开始录音
    this.startRecording()
  }

  private async checkAndRequestPermission() {
    try {
      const hasMicPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE')
      if (hasMicPermission) {
        this.hasMicPermission = true
        this.permissionError = ''
        try {
          await this.audioService?.initAudioCapture()
          // 权限获取后立即开始录音
          await this.startRecording()
        } catch (err) {
          console.error('初始化音频捕获器失败:', JSON.stringify(err))
          this.permissionError = '初始化音频捕获器失败，请重试'
          this.hasMicPermission = false
        }
        return
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE'])
      if (granted) {
        this.hasMicPermission = true
        this.permissionError = ''
        try {
          await this.audioService?.initAudioCapture()
          // 权限获取后立即开始录音
          await this.startRecording()
        } catch (err) {
          console.error('初始化音频捕获器失败:', JSON.stringify(err))
          this.permissionError = '初始化音频捕获器失败，请重试'
          this.hasMicPermission = false
        }
      } else {
        this.permissionError = '获取麦克风权限失败，请在设置中手动开启'
      }
    } catch (err) {
      this.permissionError = '麦克风权限检查失败'
      console.error('麦克风权限检查失败:', JSON.stringify(err))
    }
  }

  private async startRecording() {
    if (!this.hasMicPermission) {
      await this.checkAndRequestPermission()
      if (!this.hasMicPermission) {
        this.isRecording = false
        return
      }
    }

    try {
      // 确保音频捕获器已初始化
      if (!this.audioService?.isInitialized()) {
        await this.audioService?.initAudioCapture()
      }

      await this.audioService?.startRecording()
      if (!(this.audioService?.isCurrentlyRecording() ?? false)) {
        this.isRecording = false
      }
    } catch (err) {
      console.error('启动录音失败:', JSON.stringify(err))
      this.permissionError = '启动录音失败，请重试'
      this.hasMicPermission = false
      this.isRecording = false
    }
  }

  private async stopRecording() {
    try {
      await this.audioService?.stopRecording()
      // 停止录音时不重置分贝值，保留最后的状态
    } catch (err) {
      console.error('停止录音失败:', JSON.stringify(err))
      this.permissionError = '停止录音失败，请重试'
    }
  }

  private getNoiseLevel(): string {
    if (this.currentDB < 30) return '安静环境'
    if (this.currentDB < 60) return '正常对话'
    if (this.currentDB < 90) return '城市喧闹'
    if (this.currentDB < 100) return '工业噪音'
    return '危险噪音'
  }

  build() {
    Column() {
      this.ErrorMessage()
      this.DBValue()
    }
  }
} 