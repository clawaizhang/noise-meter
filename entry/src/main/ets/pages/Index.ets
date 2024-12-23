// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
import common from '@ohos.app.ability.common'
import { AudioService } from '../services/AudioService'
import { HeaderTitle } from '../components/HeaderTitle'
import { DBDisplay } from '../components/DBDisplay'
import { StatisticsView } from '../components/StatisticsView'
import { ControlButton } from '../components/ControlButton'
import { PermissionUtil } from '@pura/harmony-utils'

@Entry
@Component
struct Index {
  @State currentDB: number = 0
  @State maxDB: number = 0
  @State minDB: number = 100
  @State avgDB: number = 0
  private sampleCount: number = 0
  private sampleSum: number = 0
  @State isRecording: boolean = false
  private audioService: AudioService | null = null
  @State hasPermission: boolean = false
  @State permissionError: string = ''

  aboutToAppear(): void {
    this.audioService = new AudioService({
      sampleRate: 44100,
      channels: 1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      bufferSize: 2048
    })

    this.audioService.setListener({
      onDBValueChange: (db: number) => {
        this.currentDB = db
        if (this.sampleCount === 0) {
          this.maxDB = db
          this.minDB = db
        } else {
          if (db > this.maxDB) {
            this.maxDB = db
          }
          if (db < this.minDB) {
            this.minDB = db
          }
        }
        this.sampleSum += db
        this.sampleCount++
        this.avgDB = Math.round(this.sampleSum / this.sampleCount)
      },
      onError: (error: string) => {
        console.error(error)
        this.permissionError = error
      }
    })

    this.checkAndRequestPermission()
  }

  aboutToDisappear(): void {
    this.audioService?.release()
  }

  private async checkAndRequestPermission() {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE')
      
      if (hasPermission) {
        this.hasPermission = true
        this.permissionError = ''
        try {
          await this.audioService?.initAudioCapture()
        } catch (err) {
          console.error('初始化音频捕获器失败:', JSON.stringify(err))
          this.permissionError = '初始化音频捕获器失败，请重试'
          this.hasPermission = false
        }
        return
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE'])
      if (granted) {
        this.hasPermission = true
        this.permissionError = ''
        try {
          await this.audioService?.initAudioCapture()
        } catch (err) {
          console.error('初始化音频捕获器失败:', JSON.stringify(err))
          this.permissionError = '初始化音频捕获器失败，请重试'
          this.hasPermission = false
        }
      } else {
        this.permissionError = '获取麦克风权限失败，请在设置中手动开启'
      }
    } catch (err) {
      this.permissionError = '权限检查失败'
      console.error('权限检查失败:', JSON.stringify(err))
    }
  }

  private async startRecording(): Promise<void> {
    if (!this.hasPermission) {
      await this.checkAndRequestPermission()
      if (!this.hasPermission) {
        return
      }
    }

    try {
      // 确保音频捕获器已初始化
      if (!this.audioService?.isInitialized()) {
        await this.audioService?.initAudioCapture()
      }

      // 重置所有统计数据
      this.maxDB = 0
      this.minDB = 0
      this.currentDB = 0
      this.sampleCount = 0
      this.sampleSum = 0
      this.avgDB = 0

      await this.audioService?.startRecording()
      this.isRecording = this.audioService?.isCurrentlyRecording() ?? false
    } catch (err) {
      console.error('启动录音失败:', JSON.stringify(err))
      this.permissionError = '启动录音失败，请重试'
      this.hasPermission = false
    }
  }

  private async stopRecording(): Promise<void> {
    await this.audioService?.stopRecording()
    this.isRecording = this.audioService?.isCurrentlyRecording() ?? false
  }

  private getDBColor(db: number = this.currentDB): string {
    if (db < 30) return '#4CAF50'
    if (db < 60) return '#2196F3'
    if (db < 90) return '#FFC107'
    if (db < 100) return '#FF9800'
    return '#F44336'
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
      HeaderTitle()
      
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
              .onClick(() => {
                PermissionUtil.requestPermissionsEasy(['ohos.permission.MICROPHONE'])
              })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      }
      
      DBDisplay({
        currentDB: this.currentDB,
        getDBColor: this.getDBColor.bind(this),
        getNoiseLevel: this.getNoiseLevel.bind(this)
      })
      
      StatisticsView({
        minDB: this.minDB,
        avgDB: this.avgDB,
        maxDB: this.maxDB,
        getDBColor: this.getDBColor.bind(this)
      })
      
      ControlButton({
        isRecording: this.isRecording,
        hasPermission: this.hasPermission,
        onToggleRecording: () => {
          if (this.isRecording) {
            this.stopRecording()
          } else {
            this.startRecording()
          }
        }
      })
      
      // AdView()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding(20)
  }
}