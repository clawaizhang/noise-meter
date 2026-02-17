import { IAudioService, AudioData } from '../../core/interfaces/IAudioService';
import { IAlertService } from '../../core/interfaces/IAlertService';
import { WatchAudioService } from '../../wearable/impl/WatchAudioService';
import {
  useAudioService, useAlertService
} from '../../core/factory/ServiceFactory';
import { AudioCapabilityChecker } from '../../common/utils/AudioCapabilityChecker';
import { PermissionUtil, AppUtil } from '@pura/harmony-utils';
import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';
import vibrator from '@ohos.vibrator';
import deviceInfo from '@ohos.deviceInfo';
import { router, promptAction } from '@kit.ArkUI';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { WatchUsageManager, UsageState } from '../../wearable/impl/WatchUsageManager';
import { WatchUsageData } from '../../models/WatchUsageData';

const TAG = 'WatchIndex';

/**
 * 权限状态枚举
 */
enum PermissionState {
  CHECKING, // 检查中
  GRANTED, // 已授权
  DENIED, // 已拒绝
  SHOW_RATIONALE // 需要显示理由
}

/**
 * 手表端主页面 - Apple Watch 风格
 * 自动检测音频能力，申请权限，gracefully 降级
 * 移除停止按钮，手表端一直检测
 * 适配圆形和方形屏幕
 *
 * 会员限制：非会员每日限3次，每次60秒
 */
@Entry
@ComponentV2
struct WatchIndex {
  private audioService: IAudioService = useAudioService();
  private alertService: IAlertService = useAlertService();
  private usageManager!: WatchUsageManager;
  // UI状态
  @Local preferenceKeys: WatchPreferenceKeys = WatchPreferenceKeys.getInstance();
  @Local currentDecibel: number = 0;
  @Local avgDecibel: number = 0;
  @Local maxDecibel: number = 0;
  @Local isAlerting: boolean = false;
  @Local noiseLevelDesc: string = '准备中';
  @Local noiseLevelColor: ResourceColor = '#999999';
  @Local isReady: boolean = false;
  @Local hasError: boolean = false;
  @Local errorMessage: string = '';
  @Local isAudioSupported: boolean = true;
  @Local permissionState: PermissionState = PermissionState.CHECKING;
  @Local calibrationValue: number = 0;
  @Local isRoundScreen: boolean = false;
  // 会员和使用限制状态
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local usageData!: WatchUsageData;
  @Local remainingSeconds: number = 60;
  @Local usageState: UsageState = UsageState.READY;
  @Local remainingTimes: number = 3;

  get isMember(): boolean {
    return this.pk.member_ship.can;
  }

  async aboutToAppear() {
    console.info(`[${TAG}] Watch page appeared, deviceType: ${deviceInfo.deviceType}`);

    // 初始化使用数据（PersistenceV2）
    this.usageData = PersistenceV2.connect(WatchUsageData, () => new WatchUsageData())!;

    // 初始化使用管理器
    this.usageManager = new WatchUsageManager(this.usageData);

    // 读取校准值并设置到音频服务
    this.calibrationValue = this.preferenceKeys.calibrationValue;
    (this.audioService as WatchAudioService).setCalibration(this.calibrationValue);

    // 检测屏幕形状
    this.checkScreenShape();

    // 恢复使用状态（根据持久化数据）
    this.restoreUsageState();

    // 首先检查并申请权限
    await this.handlePermissionFlow();
  }

  aboutToDisappear() {
    console.info(`[${TAG}] Watch page disappearing`);
    this.audioService.release();
    this.alertService.stopAlert();
    if (this.usageManager) {
      this.usageManager.stopCountdown();
    }
  }

  // 页面显示时刷新（从设置返回时会触发）
  onPageShow(): void {
    // 刷新校准值显示
    const newCalibration = this.preferenceKeys.calibrationValue;
    if (newCalibration !== this.calibrationValue) {
      this.calibrationValue = newCalibration;
      (this.audioService as WatchAudioService).setCalibration(newCalibration);
      console.info(`[${TAG}] Calibration refreshed: ${newCalibration}`);
    }

    // 如果从设置页面返回，重新检查权限
    if (this.permissionState === PermissionState.DENIED || this.permissionState === PermissionState.CHECKING) {
      PermissionUtil.checkPermissions('ohos.permission.MICROPHONE').then((hasPermission) => {
        if (hasPermission) {
          console.info(`[${TAG}] 从设置返回，权限已开启`);
          this.permissionState = PermissionState.GRANTED;
          this.hasError = false;
          this.errorMessage = '';
          this.initAudioAndStart();
        }
      });
      return;
    }

    // 刷新使用状态
    this.restoreUsageState();
  }

  /**
   * 恢复使用状态（从持久化数据）
   * 解决退出重进后状态丢失的问题
   */
  private restoreUsageState() {
    const data = this.usageManager.getData();
    this.remainingTimes = data.getRemainingTimes();
    this.remainingSeconds = data.remainingSeconds;

    // 根据持久化数据恢复状态
    if (this.remainingTimes === 0) {
      // 次数用完
      this.usageState = UsageState.LOCKED;
    } else if (this.remainingSeconds === 0) {
      // 单次时间到（倒计时结束）
      this.usageState = UsageState.PAUSED;
    } else if (this.remainingSeconds < 60) {
      // 有剩余秒数但不到60，说明是上次未完成的会话
      // 继续倒计时
      this.usageState = UsageState.RUNNING;
      this.startCountdown();
    } else {
      // 全新会话
      this.usageState = UsageState.READY;
    }

    console.info(`[${TAG}] Restored state: ${this.usageState}, remainingTimes: ${this.remainingTimes}, remainingSeconds: ${this.remainingSeconds}`);
  }

  /**
   * 检测屏幕形状
   */
  private checkScreenShape() {
    this.isRoundScreen = true;
    console.info(`[${TAG}] Screen shape: round (default for wearable)`);
  }

  /**
   * 权限申请流程
   */
  private async handlePermissionFlow() {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');

      if (hasPermission) {
        this.permissionState = PermissionState.GRANTED;
        await this.initAudioAndStart();
        return;
      }

      console.info(`[${TAG}] 开始申请麦克风权限`);
      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);

      if (granted) {
        this.permissionState = PermissionState.GRANTED;
        await this.initAudioAndStart();
      } else {
        console.warn(`[${TAG}] 权限被拒绝，跳转设置页面`);
        // 跳转到权限设置页面（同手机端逻辑）
        await PermissionUtil.requestPermissionOnSettingEasy(['ohos.permission.MICROPHONE']);
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

    // 初始化并开始（音频始终启动，不受限制影响）
    await this.startDetection();
  }

  private async startDetection() {
    // 初始化音频
    const inited = await this.audioService.init();
    if (!inited) {
      console.error(`[${TAG}] Failed to initialize audio service`);
      this.hasError = true;
      this.errorMessage = '初始化失败';
      this.noiseLevelDesc = '初始化失败';
      return;
    }

    // 自动开始检测（音频始终启动，无论是否会员、是否有剩余次数）
    const started = await this.audioService.start();
    if (started) {
      console.info(`[${TAG}] Auto started successfully`);
      this.isReady = true;
      this.noiseLevelDesc = '检测中';
      this.vibrateStart();

      // 非会员：检查使用限制并设置UI状态
      if (!this.isMember) {
        if (this.remainingTimes === 0) {
          // 次数用完，显示锁定，但音频继续
          this.usageState = UsageState.LOCKED;
          console.info(`[${TAG}] 次数已用完，音频继续运行`);
        } else if (this.remainingSeconds === 0) {
          // 单次时间到，显示暂停
          this.usageState = UsageState.PAUSED;
        } else if (this.remainingSeconds < 60) {
          // 继续之前的倒计时
          this.usageState = UsageState.RUNNING;
          this.startCountdown();
        } else {
          // 新会话
          if (this.usageManager.startSession()) {
            this.usageState = UsageState.RUNNING;
            this.startCountdown();
          }
        }
        this.refreshUsageState();
      }
    } else {
      console.error(`[${TAG}] Failed to start detection`);
      this.hasError = true;
      this.errorMessage = '启动失败';
      this.noiseLevelDesc = '启动失败';
    }
  }

  /**
   * 开始倒计时
   */
  private startCountdown() {
    this.usageManager.startCountdown(
      (seconds) => {
        this.remainingSeconds = seconds;
      },
      () => {
        // 倒计时结束（单次60秒到）
        console.info(`[${TAG}] Countdown completed`);
        this.refreshUsageState();
        // 检查是否还有剩余次数
        if (this.remainingTimes === 0) {
          // 次数用完，显示锁定
          this.usageState = UsageState.LOCKED;
          console.info(`[${TAG}] 次数已用完，显示锁定`);
        } else {
          // 还有次数，显示暂停
          this.usageState = UsageState.PAUSED;
          console.info(`[${TAG}] 单次结束，显示暂停，剩${this.remainingTimes}次`);
        }
        // 注意：不停止音频，只改变UI状态
      }
    );
  }

  /**
   * 刷新使用状态显示
   */
  private refreshUsageState() {
    const data = this.usageManager.getData();
    this.remainingTimes = data.getRemainingTimes();
  }

  /**
   * 继续检测（点击重新检测）
   */
  private continueDetection() {
    if (this.remainingTimes > 0) {
      this.usageManager.resetCountdown();
      this.usageState = UsageState.RUNNING;
      this.startCountdown();
    }
  }

  /**
   * 显示升级对话框
   */
  private showUpgradeDialog() {
    // TODO: 跳转到升级页面或显示升级弹窗
    console.info(`[${TAG}] Show upgrade dialog`);
    // 暂时跳转到手机端（实际应该调起手表端的升级流程）
  }

  /**
   * 显示限制说明
   */
  private showRestrictionInfo() {
    console.info(`[${TAG}] showRestrictionInfo clicked, usageState: ${this.usageState}`);

    // 根据当前状态显示不同的提示
    if (this.usageState === UsageState.PAUSED) {
      // 已暂停状态（单次60秒到）
      promptAction.showDialog({
        title: '使用限制',
        message: '非会员每次限60秒\n点击"继续检测"开始新的一次',
        buttons: [{ text: '知道了', color: '#34C759' }]
      });
    } else if (this.usageState === UsageState.LOCKED) {
      // 已停用状态（次数用完）
      promptAction.showDialog({
        title: '使用限制',
        message: '非会员每日限3次\n明日0点自动恢复',
        buttons: [{ text: '知道了', color: '#34C759' }]
      });
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 根据屏幕形状使用不同的容器
      if (this.isRoundScreen) {
        Column() {
          this.buildContent()
        }
        .width('85%')
        .height('85%')
        .clip(true)
      } else {
        Column() {
          this.buildContent()
        }
        .width('100%')
        .height('100%')
        .padding({
          top: 20,
          bottom: 20,
          left: 16,
          right: 16
        })
      }

      // 设置按钮（暂停或锁定状态下隐藏）
      if (this.isReady && this.usageState !== UsageState.PAUSED && this.usageState !== UsageState.LOCKED) {
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
    Stack({ alignContent: Alignment.Center }) {
      // 底层：正常显示的内容
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

      // 蒙层层：非会员限制（音频始终在后台运行）
      if (!this.isMember && this.isReady &&
        (this.usageState === UsageState.PAUSED || this.usageState === UsageState.LOCKED)) {
        if (this.usageState === UsageState.PAUSED) {
          this.buildPausedOverlay()
        } else if (this.usageState === UsageState.LOCKED) {
          this.buildLockedOverlay()
        }
      }
    }
    .width('100%')
    .height('100%')
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

    // 中部：分贝值（合并 dB，节省空间）
    Row({ space: 4 }) {
      Text(this.isReady ? `${this.currentDecibel}` : '--')
        .fontSize(this.isRoundScreen ? 52 : 64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isAlerting ? '#FF3B30' : this.getDecibelColor())

      Text('分贝')
        .fontSize(this.isRoundScreen ? 12 : 16)
        .fontColor('#8E8E93')
        .margin({ bottom: this.isRoundScreen ? 8 : 12 }) // 基线对齐微调
    }
    .margin({ top: this.isRoundScreen ? 24 : 32 })

    // 统计数据（更紧凑）
    if (this.isReady && this.avgDecibel > 0) {
      Row({ space: 20 }) {
        Column({ space: 1 }) {
          Text('平均')
            .fontSize(this.isRoundScreen ? 9 : 11)
            .fontColor('#8E8E93')
          Text(`${this.avgDecibel}`)
            .fontSize(this.isRoundScreen ? 14 : 16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }

        Column({ space: 1 }) {
          Text('峰值')
            .fontSize(this.isRoundScreen ? 9 : 11)
            .fontColor('#8E8E93')
          Text(`${this.maxDecibel}`)
            .fontSize(this.isRoundScreen ? 14 : 16)
            .fontColor('#FFCC00')
            .fontWeight(FontWeight.Medium)
        }
      }
      .margin({ top: this.isRoundScreen ? 6 : 10 })
    }

    // 噪音等级描述
    Text(this.noiseLevelDesc)
      .fontSize(this.isRoundScreen ? 15 : 17)
      .fontColor(this.isAlerting ? '#FF3B30' : this.noiseLevelColor)
      .fontWeight(FontWeight.Medium)
      .margin({ top: this.isRoundScreen ? 8 : 12 });

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
      .padding({
        top: 4,
        bottom: 4,
        left: 10,
        right: 10
      })
      .backgroundColor('#1AFF3B30')
      .borderRadius(16);
    }

    // 算法说明
    if (this.isReady) {
      Text('A计权 · 快速响应')
        .fontSize(this.isRoundScreen ? 8 : 10)
        .fontColor('#555555')
        .margin({ top: this.isRoundScreen ? 8 : 12 })
    }
  }

  // ========== 暂停蒙层（单次60秒到）==========
  @Builder
  buildPausedOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      // 毛玻璃效果背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .opacity(0.70)
        .backdropBlur(6)

      // 中心内容（放在前面，按钮在后面确保可点击）
      Column({ space: 12 }) {
        // 暂停符号
        Text('⏸')
          .fontSize(28)
          .fontColor('#FFCC00')

        Text('已暂停')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)

        // 主按钮：继续检测
        Button('继续检测', { type: ButtonType.Capsule })
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .width(140)
          .height(42)
          .backgroundColor('#34C759')
          .margin({ top: 8 })
          .onClick(() => this.continueDetection())

        // 剩余次数
        Text(`剩 ${this.remainingTimes} 次`)
          .fontSize(11)
          .fontColor('#8E8E93')
          .margin({ top: 6 })
      }

      // 信息按钮（放在内容后面，确保可点击）
      Button() {
        Text('ⓘ')
          .fontSize(20)
          .fontColor('#8E8E93')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .position({ x: '75%', y: '20%' })
      .zIndex(100)
      .onClick(() => {
        console.info(`[${TAG}] Info button clicked`);
        this.showRestrictionInfo();
      })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 锁定蒙层（次数用完）==========
  @Builder
  buildLockedOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      // 毛玻璃效果背景（同暂停蒙层一致）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .opacity(0.70)
        .backdropBlur(6)

      // 中心内容（放在前面，按钮在后面确保可点击）
      Column({ space: 12 }) {
        // 锁图标
        Text('🔒')
          .fontSize(28)

        Text('已停用')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)

        // 主按钮：开通会员
        Button('开通会员', { type: ButtonType.Capsule })
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .width(140)
          .height(42)
          .backgroundColor('#FF9500')
          .margin({ top: 8 })
          .onClick(() => this.showUpgradeDialog())

        // 明日恢复提示
        Text('明日自动恢复3次')
          .fontSize(11)
          .fontColor('#8E8E93')
          .margin({ top: 6 })
      }

      // 信息按钮（放在内容后面，确保可点击）
      Button() {
        Text('ⓘ')
          .fontSize(20)
          .fontColor('#8E8E93')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .position({ x: '75%', y: '20%' })
      .zIndex(100)
      .onClick(() => {
        console.info(`[${TAG}] Info button clicked (locked)`);
        this.showRestrictionInfo();
      })
    }
    .width('100%')
    .height('100%')
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
        .onClick(async () => {
          await this.handlePermissionFlow();
        })
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
    if (this.currentDecibel < 40) {
      return '#34C759';
    }
    if (this.currentDecibel < 60) {
      return '#34C759';
    }
    if (this.currentDecibel < 80) {
      return '#FFCC00';
    }
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
