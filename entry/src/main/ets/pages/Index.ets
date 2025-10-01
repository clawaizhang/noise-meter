import { navigationStack } from '../constants/ProviderConstant'
import { RelationalStoreService } from '../services/RelationalStoreService'
import { commonEventManager } from '@kit.BasicServicesKit'
import { privacyManager } from '@kit.StoreKit'
import { PreferenceKeys } from '../models/PreferenceKeys'
import { DatabaseUpgradeConfig, DbConfig } from '../interfaces/DatabaseInterfaces'
import hilog from '@ohos.hilog'
import { MainPage, dbConfig } from 'entry/MainPage'
import { common, ConfigurationConstant, Want } from '@kit.AbilityKit'
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI'
import { WindowManager } from '../utils/WindowManager'
import { AudioAnalysisMode } from '../common/AudioConfig'
import { AudioService } from '../services/AudioService'
import { NotificationHelper } from '../utils/NotificationHelper'
import { AppKeys } from '../models/AppKeys'
import { FileUtils } from '../utils/FileUtils'
import { PermissionService } from '../services/PermissionService'

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
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys,() => new PreferenceKeys())!;
  @Local as: AppKeys = AppStorageV2.connect(AppKeys, () => new AppKeys())!;
  usePrivacy: boolean = true;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private readonly eventId = 'usual.event.PRIVACY_STATE_CHANGED';
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  // 订阅者信息, 用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
  private subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  // 事件列表
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [this.eventId]
  };

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

  @Monitor('pk.keep_screen_on')
  keepScreenOnChange(monitor: IMonitor) {
    let keepScreenOn = monitor.value<boolean>()?.now!;
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(keepScreenOn);
  }

  @Monitor('pk.privacy_agreed')
  privacy_agreedChange(monitor: IMonitor) {
    let privacy_agreed = monitor.value<boolean>()?.now!;
    if (privacy_agreed) {
      // 请求通知权限
      const notificationHelper = NotificationHelper.getInstance(this.context);
      notificationHelper.checkAndRequestPermission();
    }
  }

  async aboutToAppear() {
    FileUtils.init(this.getUIContext().getHostContext());
    this.setDisplayMode(this.pk.display_mode);
    if (!this.pk.privacy_agreed) {
      this.subscribe();
    }
    
    // 初始化权限状态
    const permissionService = PermissionService.getInstance();
    await permissionService.initializePermissionState();
    
    this.initialize();
  }

  aboutToDisappear(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(false);
  }

  private setDisplayMode(displayMode: string) {
    let applicationContext = this.context.getApplicationContext();
    if (displayMode == 'default') {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    }
    if (displayMode == 'light') {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
    }
    if (displayMode == 'dark') {
      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    }
  }

  private async initialize() {
    try {
      if (canIUse('SystemCapability.AppGalleryService.PrivacyManager') && this.usePrivacy) {
        if (privacyManager.getAppPrivacyMgmtInfo().type == privacyManager.AppPrivacyMgmtType.FULL_MODE) {
          let appPrivacyResults: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult();
          this.pk.privacy_agreed = appPrivacyResults[0]?.result === 1;
        } else {
          this.pk.privacy_agreed = true;
        }
      } else {
        this.pk.privacy_agreed = true;
      }
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

  public subscribe(): void {
    hilog.info(0, TAG, "subscribe");
    // 创建订阅者
    if (canIUse('SystemCapability.Notification.CommonEvent') && this.usePrivacy) {

      commonEventManager.createSubscriber(this.subscribeInfo).then((commonEventSubscriber) => {
        hilog.info(0, TAG, "createSubscriber");
        this.subscriber = commonEventSubscriber;

        // 订阅公共事件
        try {
          commonEventManager.subscribe(this.subscriber, (err, data) => {
            if (err) {
              hilog.error(0, TAG, `subscribe failed, code is ${err?.code}, message is ${err?.message}`);
              return;
            }

            let result = JSON.parse(data?.data ?? '{}')?.resultType as number;
            if (result === 1) {
              // 隐私同意处理
              this.pk.privacy_agreed = true;
            }
          });
        } catch (error) {
          hilog.error(0, TAG,
            "init createSubscriber failed, exception code: " + error.code + ", exception message: " + error.message);
        }
      });
    }

  }

  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中
        Column() {
          Image($r('app.media.app_icon_fore'))
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
        }

        .justifyContent(FlexAlign.Center)
      } else {
        // 显示正常内容
        Navigation(this.navStack) {
          if (this.pk.privacy_agreed) {
            MainPage()
          } else {
            Column() {
              Image($r('app.media.app_icon_fore'))
                .width(120).height(120)
            }.justifyContent(FlexAlign.Center)
          }
        }
        .size({ width: '100%' })
        .hideTitleBar(true)
        .titleMode(NavigationTitleMode.Free)
        .backgroundColor($r('sys.color.background_primary'))
        .mode(NavigationMode.Stack)
      }
    }
  }
}