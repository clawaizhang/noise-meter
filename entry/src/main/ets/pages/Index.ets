// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
import { BusinessError } from '@ohos.base'
import bundleManager from '@ohos.bundle.bundleManager'
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import { AudioService } from '../services/AudioService'
import { advertising, AutoAdComponent } from '@kit.AdsKit'

// 波形图点的接口定义
interface WavePoint {
  x: number
  y: number
}

// 顶部标题组件
@Component
struct HeaderTitle {
  build() {
    Row() {
      Text('噪音分贝仪')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
    }
    .margin({ top: 20, bottom: 20 })
  }
}

// 权限错误提示组件
@Component
struct PermissionError {
  @Prop errorMessage: string

  build() {
    if (this.errorMessage !== '') {
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#F44336')
        .margin({ bottom: 20 })
    }
  }
}

// 主要分贝显示组件
@Component
struct DBDisplay {
  @Prop currentDB: number
  getDBColor: (db?: number) => string = () => '#4CAF50'
  getNoiseLevel: () => string = () => '安静环境'

  build() {
    Column() {
      Text(`${this.currentDB}`)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDBColor())
      Text('dB')
        .fontSize(20)
        .margin({ top: 5 })
      Text(this.getNoiseLevel())
        .fontSize(16)
        .margin({ top: 10 })
        .fontColor('#666666')
    }
    .margin({ top: 20, bottom: 20 })
  }
}

// 波形图组件
@Component
struct WaveformView {
  @Prop waveData: Array<number>

  build() {
    Row() {
      Polyline({ width: '100%', height: '100%' })
        .points(this.waveData.map((value: number, index: number): WavePoint => {
          return {
            x: index * (100 / this.waveData.length),
            y: 50 - (value * 0.4)
          }
        }))
        .stroke(Color.Blue)
        .strokeWidth(2)
    }
    .width('100%')
    .height(100)
    .backgroundColor('#f5f5f5')
  }
}

// 统计数据显示组件
@Component
struct StatisticsView {
  @Prop minDB: number
  @Prop avgDB: number
  @Prop maxDB: number
  getDBColor: (db: number) => string = () => '#4CAF50'

  build() {
    Row() {
      Column() {
        Text('最小值')
          .fontSize(16)
        Text(`${this.minDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.minDB))
      }
      .margin({ right: 40 })

      Column() {
        Text('平均值')
          .fontSize(16)
        Text(`${this.avgDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.avgDB))
      }
      .margin({ right: 40 })

      Column() {
        Text('最大值')
          .fontSize(16)
        Text(`${this.maxDB}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDBColor(this.maxDB))
      }
    }
    .margin({ top: 20, bottom: 30 })
  }
}

// 控制按钮组件
@Component
struct ControlButton {
  @Prop isRecording: boolean
  @Prop hasPermission: boolean
  onToggleRecording: () => void = () => {}

  build() {
    Button() {
      Text(this.isRecording ? '停止测量' : '开始测量')
        .fontSize(18)
        .fontColor(Color.White)
    }
    .width(200)
    .height(50)
    .backgroundColor(this.isRecording ? '#FF4081' : '#2196F3')
    .enabled(this.hasPermission)
    .opacity(this.hasPermission ? 1 : 0.5)
    .onClick(this.onToggleRecording)
    .margin({ bottom: 20 })
  }
}

// 广告组件
@Component
struct AdView {
  build() {
    AutoAdComponent({
      adParam: {
        adId: 'testw6vs28auh3',
        adType: 1
      },
      adOptions: {
        height: 150,
        width: 1080
      },
      displayOptions: {
        backgroundColor: '#F5F5F5'
      },
      interactionListener: {
        onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
          switch (status) {
            case 'AD_LOAD':
              console.info('广告加载成功')
              break
            case 'AD_FAIL':
              console.error('广告加载失败:', data)
              break
            case 'AD_CLOSED':
              console.info('广告被关闭')
              break
            case 'AD_CLICKED':
              console.info('广告被点击')
              break
            case 'AD_OPEN':
              console.info('广���被打开')
              break
          }
        }
      }
    })
    .width('100%')
    .height(150)
  }
}

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
        this.maxDB = Math.max(this.maxDB, db)
        this.minDB = Math.min(this.minDB, db)
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
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.checkAccessToken(tokenId, 'ohos.permission.MICROPHONE')
      
      if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.hasPermission = true
        await this.audioService?.initAudioCapture()
        return
      }

      try {
        await atManager.requestPermissionsFromUser(getContext(this), ['ohos.permission.MICROPHONE'])
        this.hasPermission = true
        await this.audioService?.initAudioCapture()
      } catch (err) {
        this.permissionError = '获取麦克风权限失败，请在系统设置中授予权限'
        console.error('请求权限失败:', err.message)
      }
    } catch (err) {
      this.permissionError = '权限检查失败，请重试'
      console.error('权限检查失败:', err.message)
    }
  }

  private async startRecording(): Promise<void> {
    if (!this.hasPermission) {
      await this.checkAndRequestPermission()
      if (!this.hasPermission) {
        return
      }
    }

    this.sampleCount = 0
    this.sampleSum = 0
    this.avgDB = 0

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
      
      PermissionError({ errorMessage: this.permissionError })
      
      DBDisplay({
        currentDB: this.currentDB,
        getDBColor: this.getDBColor,
        getNoiseLevel: this.getNoiseLevel
      })
      
      WaveformView()
      
      StatisticsView({
        minDB: this.minDB,
        avgDB: this.avgDB,
        maxDB: this.maxDB,
        getDBColor: this.getDBColor
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
      
      AdView()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding(20)
  }
}