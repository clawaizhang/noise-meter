// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
// 导入错误处理模块
import { BusinessError } from '@ohos.base'
// 导入权限相关模块
import bundleManager from '@ohos.bundle.bundleManager'
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
// 导入音频服务
import { AudioService } from '../services/AudioService'
// 导入广告模块
import { advertising, AutoAdComponent } from '@kit.AdsKit'

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
  // 添加平均分贝值状态
  @State avgDB: number = 0
  // 添加采样总数和总和用于计算平均值
  private sampleCount: number = 0
  private sampleSum: number = 0
  // 是否正在录音
  @State isRecording: boolean = false
  // 波形图数据数组
  @State waveData: Array<number> = new Array<number>(100).fill(0)
  // 音频服务实例
  private audioService: AudioService | null = null
  // 权限状态
  @State hasPermission: boolean = false
  // 添加权限检查错误信息
  @State permissionError: string = ''

  // 组件生命周期-创建
  aboutToAppear(): void {
    // 创建音频服务实例
    this.audioService = new AudioService({
      sampleRate: 44100,
      channels: 1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      bufferSize: 2048
    })

    // 设置音频服务监听器
    this.audioService.setListener({
      onDBValueChange: (db: number) => {
        this.currentDB = db
        this.maxDB = Math.max(this.maxDB, db)
        this.minDB = Math.min(this.minDB, db)
        // 更新平均值计算
        this.sampleSum += db
        this.sampleCount++
        this.avgDB = Math.round(this.sampleSum / this.sampleCount)
        // 更新波形图数据
        this.waveData.shift()
        this.waveData.push(db)
      },
      onError: (error: string) => {
        console.error(error)
        this.permissionError = error
      }
    })

    // 检查并请求权限
    this.checkAndRequestPermission()
  }

  // 组件生命周期-销毁
  aboutToDisappear(): void {
    // 释放音频服务资源
    this.audioService?.release()
  }

  // 检查并请求麦克风权限
  private async checkAndRequestPermission() {
    try {
      // 获取应用程序的bundleInfo
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId

      // 创建AtManager实例
      const atManager = abilityAccessCtrl.createAtManager()

      // 检查是否已有权限
      const result = await atManager.checkAccessToken(tokenId, 'ohos.permission.MICROPHONE')
      if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.hasPermission = true
        // 初始化音频服务
        await this.audioService?.initAudioCapture()
        return
      }

      // 请求权限
      try {
        await atManager.requestPermissionsFromUser(getContext(this), ['ohos.permission.MICROPHONE'])
        this.hasPermission = true
        // 初始化音频服务
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

  // 开始录音
  private async startRecording(): Promise<void> {
    if (!this.hasPermission) {
      await this.checkAndRequestPermission()
      if (!this.hasPermission) {
        return
      }
    }

    // 重置平均值计算
    this.sampleCount = 0
    this.sampleSum = 0
    this.avgDB = 0

    // 启动录音
    await this.audioService?.startRecording()
    this.isRecording = this.audioService?.isCurrentlyRecording() ?? false
  }

  // 停止录音
  private async stopRecording(): Promise<void> {
    await this.audioService?.stopRecording()
    this.isRecording = this.audioService?.isCurrentlyRecording() ?? false
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

      // 权限误示
      if (this.permissionError !== '') {
        Text(this.permissionError)
          .fontSize(16)
          .fontColor('#F44336')
          .margin({ bottom: 20 })
      }

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

      // 控制按钮
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
      .onClick(() => {
        if (this.isRecording) {
          this.stopRecording()
        } else {
          this.startRecording()
        }
      })
      .margin({ bottom: 20 })

      // 底部广告
      AutoAdComponent({
        adParam: {
          adId: 'testw6vs28auh3', // 广告位ID，需替换为实际的广告位ID
          adType: 1 // 广告类型为横幅广告，使用数字类型
        },
        adOptions: {
          // 广告选项配置
          height: 150, // 广告高度
          width: 1080 // 广告宽度，使用数字类型
        },
        displayOptions: {
          // 广告显示选项
          backgroundColor: '#F5F5F5' // 广告背景色
        },
        interactionListener: {
          // 广告交互监听器
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
                console.info('广告被打开')
                break
            }
          }
        }
      })
      .width('100%')
      .height(150)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding(20)
  }

  // 获取分贝值对应的颜色
  private getDBColor(db: number = this.currentDB): string {
    if (db < 30) {
      return '#4CAF50' // 绿色 - 安静
    }
    if (db < 60) {
      return '#2196F3' // 蓝色 - 正常
    }
    if (db < 90) {
      return '#FFC107' // 黄色 - 较吵
    }
    if (db < 100) {
      return '#FF9800' // 橙色 - 吵闹
    }
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