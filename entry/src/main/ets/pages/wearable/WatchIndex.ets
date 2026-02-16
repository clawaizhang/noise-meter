import { IAudioService, AudioData } from '../../core/interfaces/IAudioService';
import { IAlertService } from '../../core/interfaces/IAlertService';
import { WatchAudioService } from '../../wearable/impl/WatchAudioService';
import { 
  useAudioService, 
  useAlertService
} from '../../core/factory/ServiceFactory';
import { AudioCapabilityChecker } from '../../common/utils/AudioCapabilityChecker';
import { PermissionUtil } from '@pura/harmony-utils';
import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';
import vibrator from '@ohos.vibrator';
import deviceInfo from '@ohos.deviceInfo';
import { router } from '@kit.ArkUI';

const TAG = 'WatchIndex';

/**
 * 权限状态枚举
 */
enum PermissionState {
  CHECKING,      // 检查中
  GRANTED,       // 已授权
  DENIED,        // 已拒绝
  SHOW_RATIONALE // 需要显示理由
}

/**
 * 手表端主页面 - Apple Watch 风格
 * 自动检测音频能力，申请权限，gracefully 降级
 * 移除停止按钮，手表端一直检测
 * 适配圆形和方形屏幕
 */
@Entry
@Component
struct WatchIndex {
  private audioService: IAudioService = useAudioService();
  private alertService: IAlertService = useAlertService();
  private preferenceKeys = WatchPreferenceKeys.getInstance();
  
  @State currentDecibel: number = 0;
  @State avgDecibel: number = 0;
  @State maxDecibel: number = 0;
  @State isAlerting: boolean = false;
  @State noiseLevelDesc: string = '准备中';
  @State noiseLevelColor: ResourceColor = '#999999';
  @State isReady: boolean = false;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State isAudioSupported: boolean = true;
  @State permissionState: PermissionState = PermissionState.CHECKING;
  @State calibrationValue: number = 0;
  @State isRoundScreen: boolean = false;

  async aboutToAppear() {
    console.info(`[${TAG}] Watch page appeared, deviceType: ${deviceInfo.deviceType}`);
    
    // 读取校准值并设置到音频服务
    this.calibrationValue = this.preferenceKeys.calibrationValue;
    (this.audioService as WatchAudioService).setCalibration(this.calibrationValue);
    
    // 检测屏幕形状（通过设备名称粗略判断）
    this.checkScreenShape();
    
    // 首先检查并申请权限
    await this.handlePermissionFlow();
  }

  aboutToDisappear() {
    console.info(`[${TAG}] Watch page disappearing`);
    this.audioService.release();
    this.alertService.stopAlert();
  }

  // 页面显示时刷新（从其他页面返回时触发）
  onPageShow(): void {
    // 刷新校准值显示
    const newCalibration = this.preferenceKeys.calibrationValue;
    if (newCalibration !== this.calibrationValue) {
      this.calibrationValue = newCalibration;
      (this.audioService as WatchAudioService).setCalibration(newCalibration);
      console.info(`[${TAG}] Calibration refreshed: ${newCalibration}`);
    }
  }

  /**
   * 检测屏幕形状
   */
  private checkScreenShape() {
    // 华为手表圆形屏幕的设备型号通常包含特定标识
    // 简化处理：手表设备默认使用圆形布局优化
    // 实际屏幕形状检测可以通过窗口尺寸比例判断
    this.isRoundScreen = true; // 默认圆形，方形手表也能正常显示
    console.info(`[${TAG}] Screen shape: round (default for wearable)`);
  }

  /**
   * 权限申请流程
   */
  private async handlePermissionFlow() {
    try {
      // 检查权限
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
      
      if (hasPermission) {
        this.permissionState = PermissionState.GRANTED;
        await this.initAudioAndStart();
        return;
      }
      
      // 申请权限
      console.info(`[${TAG}] 开始申请麦克风权限`);
      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);
      
      if (granted) {
        this.permissionState = PermissionState.GRANTED;
        await this.initAudioAndStart();
      } else {
        console.warn(`[${TAG}] 权限被拒绝`);
        this.permissionState = PermissionState.DENIED;
        this.hasError = true;
        this.errorMessage = '需要麦克风权限';
        this.noiseLevelDesc = '无权限';
      }
    } catch (error) {
      console.error(`[${TAG}] 权限处理失败:`, error);
      this.permissionState = PermissionState.DENIED;
      this.hasError = true;
      this.errorMessage = '权限申请失败';
    }
  }

  /**
   * 初始化音频并开始检测
   */
  private async initAudioAndStart() {
    // 检测音频能力
    this.isAudioSupported = await AudioCapabilityChecker.isAudioCaptureSupported();
    
    if (!this.isAudioSupported) {
      console.warn(`[${TAG}] Audio capture not supported on this device`);
      this.hasError = true;
      this.errorMessage = '该设备不支持音频采集';
      this.noiseLevelDesc = '不支持';
      return;
    }
    
    // 设置音频数据监听
    this.audioService.onDataUpdate((data: AudioData) => {
      this.currentDecibel = data.currentDecibel;
      this.avgDecibel = data.avgDecibel;
      this.maxDecibel = data.maxDecibel;
      this.updateNoiseLevel(data.currentDecibel);
      
      // 检查警报
      const shouldAlert = this.alertService.checkAlert(data.currentDecibel);
      if (shouldAlert && !this.isAlerting) {
        this.isAlerting = true;
        this.alertService.startAlert();
      } else if (!shouldAlert && this.isAlerting) {
        this.isAlerting = false;
        this.alertService.stopAlert();
      }
    });

    // 设置警报监听
    this.alertService.onAlertChange((isAlerting: boolean) => {
      this.isAlerting = isAlerting;
    });

    // 初始化并开始
    await this.startDetection();
  }

  private async startDetection() {
    // 初始化
    const inited = await this.audioService.init();
    if (!inited) {
      console.error(`[${TAG}] Failed to initialize audio service`);
      this.hasError = true;
      this.errorMessage = '初始化失败';
      this.noiseLevelDesc = '初始化失败';
      return;
    }

    // 自动开始检测
    const started = await this.audioService.start();
    if (started) {
      console.info(`[${TAG}] Auto started successfully`);
      this.isReady = true;
      this.noiseLevelDesc = '检测中';
      this.vibrateStart();
    } else {
      console.error(`[${TAG}] Failed to start detection`);
      this.hasError = true;
      this.errorMessage = '启动失败';
      this.noiseLevelDesc = '启动失败';
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 根据屏幕形状使用不同的容器
      if (this.isRoundScreen) {
        // 圆形屏幕 - 使用较小的安全区域
        Column() {
          this.buildContent()
        }
        .width('85%')
        .height('85%')
        .clip(true)
      } else {
        // 方形/矩形屏幕 - 全屏显示
        Column() {
          this.buildContent()
        }
        .width('100%')
        .height('100%')
        .padding({ top: 20, bottom: 20, left: 16, right: 16 })
      }
      
      // 设置按钮 - 右侧中间（圆形表盘黄金位置）
      if (this.isReady) {
        Button() {
          Image($r('app.media.ic_settings'))
            .width(18)
            .height(18)
            .opacity(0.5)
        }
        .width(36)
        .height(36)
        .backgroundColor('#2C2C2E')
        .position({ x: '100%', y: '50%' })
        .translate({ x: -44, y: -18 })
        .onClick((): void => {
          router.pushUrl({ url: 'pages/wearable/WatchSettings' });
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  buildContent() {
    Column({ space: this.isRoundScreen ? 2 : 4 }) {
      // 权限检查中
      if (this.permissionState === PermissionState.CHECKING) {
        this.buildStatusView('检测音频能力...', '#8E8E93')
      }
      // 权限被拒绝
      else if (this.permissionState === PermissionState.DENIED) {
        this.buildDeniedView()
      }
      // 不支持音频采集
      else if (!this.isAudioSupported) {
        this.buildStatusView(
          '该设备不支持噪音检测', 
          '#FF3B30', 
          '请在手机端使用完整功能'
        )
      }
      // 初始化错误
      else if (this.hasError) {
        this.buildErrorView()
      }
      // 正常运行
      else {
        this.buildNormalView()
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildNormalView() {
    // 顶部：校准值显示（如果有）
    if (this.calibrationValue !== 0) {
      Text(`校准: ${this.calibrationValue > 0 ? '+' : ''}${this.calibrationValue}分贝`)
        .fontSize(this.isRoundScreen ? 10 : 12)
        .fontColor('#8E8E93')
        .position({
          x: '50%',
          y: this.isRoundScreen ? '8%' : '5%'
        })
        .translate({ x: '-50%' })
    }

    // 中部：分贝值
    Column({ space: 0 }) {
      Text(this.isReady ? `${this.currentDecibel}` : '--')
        .fontSize(this.isRoundScreen ? 56 : 72)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isAlerting ? '#FF3B30' : this.getDecibelColor())
        .height(this.isRoundScreen ? 70 : 90);

      Row({ space: 4 }) {
        Text('dB')
          .fontSize(this.isRoundScreen ? 18 : 24)
          .fontColor('#8E8E93')
        

      }
      .margin({ top: this.isRoundScreen ? -4 : -8 })
    }
    .margin({ top: this.isRoundScreen ? 30 : 40 })

    // 统计数据
    if (this.isReady && this.avgDecibel > 0) {
      Row({ space: 16 }) {
        Column({ space: 2 }) {
          Text('平均')
            .fontSize(this.isRoundScreen ? 9 : 11)
            .fontColor('#8E8E93')
          Text(`${this.avgDecibel}`)
            .fontSize(this.isRoundScreen ? 14 : 16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }

        Column({ space: 2 }) {
          Text('峰值')
            .fontSize(this.isRoundScreen ? 9 : 11)
            .fontColor('#8E8E93')
          Text(`${this.maxDecibel}`)
            .fontSize(this.isRoundScreen ? 14 : 16)
            .fontColor('#FFCC00')
            .fontWeight(FontWeight.Medium)
        }
      }
      .margin({ top: this.isRoundScreen ? 8 : 12 })
    }

    // 噪音等级描述
    Text(this.noiseLevelDesc)
      .fontSize(this.isRoundScreen ? 16 : 18)
      .fontColor(this.isAlerting ? '#FF3B30' : this.noiseLevelColor)
      .fontWeight(FontWeight.Medium)
      .margin({ top: this.isRoundScreen ? 12 : 16 });

    // 警报提示
    if (this.isAlerting) {
      Row({ space: 4 }) {
        Circle()
          .width(8)
          .height(8)
          .fill('#FF3B30');
        Text('噪音过高')
          .fontSize(this.isRoundScreen ? 14 : 16)
          .fontColor('#FF3B30')
          .fontWeight(FontWeight.Medium);
      }
      .margin({ top: 8 })
      .padding({ top: 4, bottom: 4, left: 10, right: 10 })
      .backgroundColor('#1AFF3B30')
      .borderRadius(16);
    }

    // 算法说明
    if (this.isReady) {
      Text('A计权 · 快速响应')
        .fontSize(this.isRoundScreen ? 8 : 10)
        .fontColor('#666666')
        .margin({ top: this.isRoundScreen ? 8 : 12 })
    }
  }

  @Builder
  buildDeniedView() {
    Column({ space: 8 }) {
      Image($r('app.media.ic_mic'))
        .width(this.isRoundScreen ? 50 : 60)
        .height(this.isRoundScreen ? 50 : 60)
        .opacity(0.6)
        .margin({ bottom: 12 })
      
      Text('需要麦克风权限')
        .fontSize(this.isRoundScreen ? 16 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF3B30')
      
      Text('噪音检测需要访问麦克风')
        .fontSize(this.isRoundScreen ? 11 : 13)
        .fontColor('#8E8E93')
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })
        
      Button('申请权限')
        .fontSize(14)
        .height(36)
        .margin({ top: 16 })
        .onClick(() => this.handlePermissionFlow())
    }
  }

  @Builder
  buildErrorView() {
    Column({ space: 8 }) {
      Image($r('app.media.ic_info'))
        .width(this.isRoundScreen ? 50 : 60)
        .height(this.isRoundScreen ? 50 : 60)
        .opacity(0.8)
        .margin({ bottom: 12 })
      
      Text(this.errorMessage)
        .fontSize(this.isRoundScreen ? 16 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF3B30')
        .textAlign(TextAlign.Center)
      
      Button('重试')
        .fontSize(14)
        .height(36)
        .margin({ top: 12 })
        .onClick(() => {
          this.hasError = false;
          this.errorMessage = '';
          this.handlePermissionFlow();
        })
    }
  }

  @Builder
  buildStatusView(mainText: string, mainColor: string, subText?: string) {
    Column({ space: 8 }) {
      if (this.permissionState === PermissionState.CHECKING) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#34C759')
          .margin({ bottom: 12 })
      } else {
        Image($r('app.media.ic_meter'))
          .width(this.isRoundScreen ? 50 : 60)
          .height(this.isRoundScreen ? 50 : 60)
          .opacity(0.6)
          .margin({ bottom: 12 })
      }
      
      Text(mainText)
        .fontSize(this.isRoundScreen ? 16 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(mainColor)
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })
      
      if (subText) {
        Text(subText)
          .fontSize(this.isRoundScreen ? 11 : 13)
          .fontColor('#8E8E93')
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 20 })
      }
    }
  }

  private getDecibelColor(): ResourceColor {
    if (this.currentDecibel < 40) return '#34C759';
    if (this.currentDecibel < 60) return '#34C759';
    if (this.currentDecibel < 80) return '#FFCC00';
    return '#FF9500';
  }

  private updateNoiseLevel(db: number) {
    if (db < 40) {
      this.noiseLevelDesc = '安静';
      this.noiseLevelColor = '#34C759';
    } else if (db < 60) {
      this.noiseLevelDesc = '正常';
      this.noiseLevelColor = '#34C759';
    } else if (db < 80) {
      this.noiseLevelDesc = '吵闹';
      this.noiseLevelColor = '#FFCC00';
    } else if (db < 100) {
      this.noiseLevelDesc = '危险';
      this.noiseLevelColor = '#FF9500';
    } else {
      this.noiseLevelDesc = '极危险';
      this.noiseLevelColor = '#FF3B30';
    }
  }

  private vibrateStart() {
    try {
      vibrator.startVibration({ type: 'time', duration: 100 }, { id: 0, usage: 'alarm' });
    } catch (e) {
      console.error(`[${TAG}] Vibrate failed`);
    }
  }
}
