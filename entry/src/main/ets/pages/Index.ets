import { navigationStack } from '../constants/ProviderConstant'
import { RelationalStoreService } from '../services/RelationalStoreService'
import { PrivacyPolicyStandalone } from '../components/privacy/PrivacyPolicyStandalone'
import { PreferenceKeys } from '../models/PreferenceKeys'
import { DatabaseUpgradeConfig } from '../interfaces/DatabaseInterfaces'
import hilog from '@ohos.hilog'
import { common, Want } from '@kit.AbilityKit'
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI'
import { WindowManager } from '../utils/WindowManager'
import { AudioAnalysisMode } from '../common/AudioConfig'
import { AudioService } from '../services/AudioService'
import { AudioDeviceMonitorService } from '../services/AudioDeviceMonitorService'
import { NotificationHelper } from '../utils/NotificationHelper'
import { AppKeys } from '../models/AppKeys'
import { FileUtils } from '../utils/FileUtils'
import { PermissionService } from '../services/PermissionService'
import { DisplayManager } from '../utils/DisplayManager'
import { ColorModeManager } from '../utils/ColorModeManager'
import { DialogStyleManager } from '../utils/DialogStyleManager'
import { UsageTrackingService } from '../services/UsageTrackingService'
import { MembershipRewardService } from '../services/MembershipRewardService'
import { ContinuousUsageManager } from '../services/ContinuousUsageManager'
import { CommonEventService } from '../services/CommonEventService';
import { SecondTimerService } from '../services/SecondTimerService';
import { showRewardCompletionDialog } from '../components/membership/RewardCompletionDialog'
import { Throttle } from '../utils/Debounce'
import { WelcomeGuide } from '../components/welcome/WelcomeGuide'
import { dbConfig, MainPage } from './MainPage'

const TAG = 'Index';
const DOMAIN = 0x0000;

@Builder
function IndexBuilder() {
  Index()
}

@Entry
@ComponentV2
struct Index {
  @Provider(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local isInitialized: boolean = false;
  @Local isLoading: boolean = true;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  usePrivacy: boolean = true;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private audioService: AudioService = AudioService.getInstance(this.pk)
  private audioDeviceMonitorService: AudioDeviceMonitorService = AudioDeviceMonitorService.getInstance()

  @Monitor('pk.display_mode')
  displayModeChange(monitor: IMonitor) {
    let mode = monitor.value<string>()?.now!;
    this.setDisplayMode(mode);
  } // 初始化首选项默认值

  @Monitor('pk.audio_analysis_mode')
  audioAnalysisModeChange(monitor: IMonitor) {
    let mode = monitor.value<AudioAnalysisMode>()?.now!;
    this.audioService.handleModeChange(mode)
  }

  @Monitor('pk.show_welcome_guide')
  privacy_agreedChange(monitor: IMonitor) {
    let show_welcome_guide = monitor.value<boolean>()?.now!;
    if (!show_welcome_guide) {
      // 请求通知权限
      const notificationHelper = NotificationHelper.getInstance(this.context);
      notificationHelper.checkAndRequestPermission();
    }
  }

  @Monitor('pk.system_notification_enabled')
  system_notification_enabledChange(monitor: IMonitor) {
    let system_notification_enabled = monitor.value<boolean>()?.now!;
    if (system_notification_enabled) {
      // 请求通知权限
      const notificationHelper = NotificationHelper.getInstance(this.context);
      notificationHelper.checkAndRequestPermission();
    }
  }

  async aboutToAppear() {
    // 初始化颜色模式和Dialog样式管理器
    ColorModeManager.init();
    DialogStyleManager.init();
    ColorModeManager.setAppContext(this.context.getApplicationContext());

    FileUtils.init(this.getUIContext().getHostContext());
    this.setDisplayMode(this.pk.display_mode);

    // 初始化权限状态
    const permissionService = PermissionService.getInstance();
    await permissionService.initializePermissionState();

    // 初始化DisplayManager监听
    this.initDisplayManager();

    // 初始化使用追踪服务
    this.initUsageTracking();

    // 初始化音频设备监听服务
    this.initAudioDeviceMonitoring();

    // 启动全局秒定时器服务
    const secondTimerService = SecondTimerService.getInstance();
    secondTimerService.start();

    // 初始化AppKeys状态同步
    this.ak.initialize();

    this.initialize();
  }

  aboutToDisappear(): void {

    // 清理防抖队列资源
    Throttle.unsubscribe();

    // 清理使用追踪服务资源
    const usageTrackingService = UsageTrackingService.getInstance(this.pk);
    usageTrackingService.destroy();

    // 清理公共事件服务资源
    const commonEventService = CommonEventService.getInstance();
    commonEventService.destroy();
    
    // 清理秒定时器服务资源
    const secondTimerService = SecondTimerService.getInstance();
    secondTimerService.destroy();

    // 清理音频设备监听服务资源
    this.audioDeviceMonitorService.destroy();
  }

  private setDisplayMode(displayMode: string) {
    ColorModeManager.setColorMode(displayMode);
  }

  private async initialize() {
    try {

      // 初始化数据库
      const upgradeConfigs: DatabaseUpgradeConfig[] = dbConfig.upgradeConfigs;

      const dbResult =
        await this.relationalStoreService.init(getContext(this), dbConfig.dbName, upgradeConfigs);
      if (!dbResult) {
        throw new Error('数据库初始化失败');
      }

      this.isInitialized = true;

    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
      this.isInitialized = false;
    } finally {
      this.isLoading = false;
    }
  }

  // 初始化DisplayManager监听
  private initDisplayManager(): void {
    const displayManager: DisplayManager = DisplayManager.getInstance();
    displayManager.onDisplay(() => {
      this.ak.isDisplayApp = true;

      // APP显示时恢复使用追踪
      const usageTrackingService = UsageTrackingService.getInstance(this.pk);
      usageTrackingService.resumeTracking();

      // 立即检查日期变化（重要优化）
      usageTrackingService.immediateDateCheck();
    });
    displayManager.onHidden(() => {
      this.ak.isDisplayApp = false;

      // APP隐藏时暂停使用追踪
      const usageTrackingService = UsageTrackingService.getInstance(this.pk);
      usageTrackingService.pauseTracking();
    });
  }

  // 初始化音频设备监听服务
  private async initAudioDeviceMonitoring(): Promise<void> {
    try {
      // 初始化音频设备监听服务
      await this.audioDeviceMonitorService.initialize(this.context);

      // 添加设备变更监听回调
      this.audioDeviceMonitorService.addDeviceChangeListener((deviceInfo) => {
        hilog.info(DOMAIN, TAG,
          `音频设备状态变化: ${deviceInfo.deviceName} ${deviceInfo.connectionState === 0 ? '接入' : '断开'}`);

        // 可以在这里添加UI更新逻辑
        // 例如更新设备状态显示组件
      });

      // 开始监听设备状态变化
      await this.audioDeviceMonitorService.startMonitoring();

      hilog.info(DOMAIN, TAG, '音频设备监听服务启动成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `音频设备监听服务启动失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // 初始化使用追踪服务
  private initUsageTracking(): void {
    const usageTrackingService = UsageTrackingService.getInstance(this.pk);
    const continuousUsageManager = ContinuousUsageManager.getInstance(this.pk);

    // 初始化服务
    usageTrackingService.initialize();

    // 检查并更新连续使用天数
    continuousUsageManager.checkAndUpdateConsecutiveDays();

    // 设置使用秒数变化监听
    usageTrackingService.onSecondsChange((seconds: number) => {
      // 秒数变化时自动更新UI
      console.info(`[使用追踪] 当前使用秒数: ${seconds}`);
    });

    // 设置使用完成监听
    usageTrackingService.onUsageComplete((seconds: number) => {
      this.handleUsageCompletion();
    });

    // 开始追踪使用时长
    usageTrackingService.startTracking();
  }

  // 处理使用完成
  private async handleUsageCompletion(): Promise<void> {
    const continuousUsageManager = ContinuousUsageManager.getInstance(this.pk);
    const membershipRewardService = MembershipRewardService.getInstance(this.pk);

    // 获取连续天数
    const consecutiveDays = continuousUsageManager.getConsecutiveDays();

    // 检查用户是否已同意会员奖励协议
    if (!this.pk.has_agreed_membership_reward) {
      // 用户未同意协议，不主动弹出，只记录日志
      console.info(`[使用完成] 连续${consecutiveDays}天，用户未同意会员奖励协议，等待用户主动点击`);
      return;
    }

    // 用户已同意协议，应用会员奖励
    membershipRewardService.applyMembershipReward(consecutiveDays);

    // 获取奖励信息
    const rewardDays = membershipRewardService.calculateRewardDays(consecutiveDays);
    const expiryDate = this.pk.member_ship.expiryDate;

    // 显示完成弹窗
    showRewardCompletionDialog(consecutiveDays, rewardDays, expiryDate);

    console.info(`[使用完成] 连续${consecutiveDays}天，获得${rewardDays}天会员`);
  }

  build() {
    Column() {
      Column().id('mainId');
      if (this.isLoading) {
        // 显示加载中
        Column() {
          Image($r('app.media.app_icon_fore'))
            .backgroundColor('#e50D1B2A')
            .width(128)
            .height(128)
            .borderRadius(16)
          LoadingProgress()
            .width(64)
            .height(64)
          Text('正在初始化...')
            .fontSize(16)
            .margin({ top: 12 })
        }
        .justifyContent(FlexAlign.Center)
      } else if (!this.isInitialized) {
        // 显示错误状态
        Column() {
          Text('数据加载完成...')
            .fontSize(16)
            .margin({ top: 12 })
          Button('立即重启')
            .margin({ top: 24 })
            .onClick(async () => {
              Throttle.click(async () => {
                this.isLoading = true;
                await this.initialize();
                let applicationContext = this.context.getApplicationContext();
                let want: Want = {
                  bundleName: 'yu.zhang.myapplication.noise_meter_pro',
                  abilityName: 'EntryAbility'
                };
                try {
                  applicationContext.restartApp(want);
                  hilog.info(0x0000, 'testTag', '%{public}s', 'applicationContext.restartApp');
                } catch (error) {
                  console.error(`restartApp fail, error: ${JSON.stringify(error)}`);
                }
              })
            })
        }

        .justifyContent(FlexAlign.Center)
      } else {
        // 显示正常内容
        Navigation(this.navStack) {
          if (!this.pk.show_welcome_guide) {
            MainPage()
          }
          if (this.pk.show_welcome_guide) {
            // 显示欢迎引导页（隐私政策已同意）
            WelcomeGuide({
              onComplete: () => {
                // 用户完成欢迎引导，进入主应用
                this.pk.show_welcome_guide = false;
                hilog.info(DOMAIN, TAG, '用户完成欢迎引导，进入主应用');
              },
              onCancel: () => {
                // 用户取消欢迎引导，退出APP
                hilog.info(DOMAIN, TAG, '用户取消欢迎引导，退出APP');
                this.context.terminateSelf();
              }
            })
          }
        }
        .size({ width: '100%' })
        .hideTitleBar(true)
        .titleMode(NavigationTitleMode.Free)
        .backgroundColor($r('sys.color.background_primary'))
        .mode(NavigationMode.Stack)
      }
    }
    .backgroundColor(this.pk.show_welcome_guide ? $r('sys.color.background_primary') :
      $r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
    .width('100%')
  }
}