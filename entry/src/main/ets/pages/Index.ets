// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
import { BusinessError } from '@ohos.base'
import common from '@ohos.app.ability.common'
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { AudioService } from '../services/AudioService'
import { PermissionService } from '../services/PermissionService'
import { HeaderTitle } from '../components/HeaderTitle'
import { PermissionError } from '../components/PermissionError'
import { DBDisplay } from '../components/DBDisplay'
import { WaveformView } from '../components/WaveformView'
import { StatisticsView } from '../components/StatisticsView'
import { ControlButton } from '../components/ControlButton'
import { AdView } from '../components/AdView'

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
  @State waveData: Array<number> = new Array<number>(100).fill(0)
  private audioService: AudioService | null = null
  private permissionService: PermissionService | null = null
  @State hasPermission: boolean = false
  @State permissionError: string = ''

  aboutToAppear(): void {
    this.permissionService = new PermissionService(getContext(this) as common.UIAbilityContext)
    
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
        this.waveData.shift()
        this.waveData.push(db)
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
      const hasPermission = await this.permissionService?.checkPermission('ohos.permission.MICROPHONE')
      
      if (hasPermission) {
        this.hasPermission = true
        await this.audioService?.initAudioCapture()
        return
      }

      const granted = await this.permissionService?.requestPermissions(['ohos.permission.MICROPHONE'])
      if (granted) {
        this.hasPermission = true
        await this.audioService?.initAudioCapture()
      } else {
        this.permissionError = '获取麦克风权限失败，请在系统设置中授予权限'
      }
    } catch (err) {
      this.permissionError = '权限检查失败'
      console.error('权限检查失败:', err)
    }
  }

  private async startRecording(): Promise<void> {
    if (!this.hasPermission) {
      await this.checkAndRequestPermission()
      if (!this.hasPermission) {
        return
      }
    }

    // 重置所有统计数据
    this.maxDB = 0
    this.minDB = 0
    this.currentDB = 0
    this.sampleCount = 0
    this.sampleSum = 0
    this.avgDB = 0
    this.waveData = new Array<number>(100).fill(0)

    await this.audioService?.startRecording()
    this.isRecording = this.audioService?.isCurrentlyRecording() ?? false
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
      
      PermissionError({ 
        errorMessage: this.permissionError,
        permissionService: this.permissionService
      })
      
      DBDisplay({
        currentDB: this.currentDB,
        getDBColor: this.getDBColor.bind(this),
        getNoiseLevel: this.getNoiseLevel.bind(this)
      })
      
      Row() {
        WaveformView({ waveData: this.waveData })
      }
      
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