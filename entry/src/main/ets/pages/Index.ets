import hilog from '@ohos.hilog';
import { MainPage } from 'entry/MainPageInfo';
import { RelationalStoreService } from '../../../library/ets/services/RelationalStoreService';
import { DatabaseConstants } from '../../../library/ets/constants/DatabaseConstants';
import { TableCreateSql } from '../../../library/ets/constants/TableCreateSql';
import { DatabaseUpgradeConfig } from '../../../library/ets/interfaces/DatabaseInterfaces';
import { PreferenceService, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { noiseMeterNavStack } from '../../../noise_meter/ets/constant/ProviderConstant';
import { Theme } from '../../../noise_meter/ets/utils/Theme';
import { commonEventManager } from '@kit.BasicServicesKit';
import { privacyManager } from '@kit.StoreKit';

const TAG = 'Index';
const DOMAIN = 0x0000;

@Builder
function IndexBuilder() {
  Index()
}

@Entry
@ComponentV2
struct Index {
  @Provider(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local isInitialized: boolean = false;
  @Local isLoading: boolean = true;
  @Local privacyAgreed: boolean = false;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private readonly eventId = 'usual.event.PRIVACY_STATE_CHANGED';
  // 订阅者信息, 用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
  private subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  // 事件列表
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [this.eventId]
  };

  async aboutToAppear() {
    if (!this.privacyAgreed) {
      this.subscribe();
    }
    this.initialize();
  }

  private async initialize() {
    try {
      let appPrivacyResults: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult();
      this.privacyAgreed = appPrivacyResults[0]?.result === 1;
      PreferenceService.getInstance().setBoolean(PreferenceKeyConstants.PRIVACY_AGREED, this.privacyAgreed);
      // 初始化数据库
      const upgradeConfigs: DatabaseUpgradeConfig[] = [
        {
          version: 1,
          sqls: [TableCreateSql.DECIBEL_RECORDS]
        },
        {
          version: 2,
          sqls: [TableCreateSql.ADD_WEIGHTING_TYPES_COLUMN]
        },
        {
          version: 3,
          sqls: [TableCreateSql.ADD_COMMENT_COLUMN]
        }
      ];

      const dbResult =
        await this.relationalStoreService.init(getContext(this), DatabaseConstants.NOISE_METER_DB, upgradeConfigs);
      if (!dbResult) {
        throw new Error('数据库初始化失败');
      }

      // 初始化加权类型
      if (!this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING)) {
        this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, WeightingType.A);
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
            this.privacyAgreed = true;
          }
        });
      } catch (error) {
        hilog.error(0, TAG,
          "init createSubscriber failed, exception code: " + error.code + ", exception message: " + error.message);
      }
    });
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
          Text('初始化失败')
            .fontSize(16)
            .margin({ top: 12 })
          Button('重试')
            .margin({ top: 24 })
            .onClick(() => {
              this.isLoading = true;
              this.initialize();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // 显示正常内容
        Navigation(this.navStack) {
          if (this.privacyAgreed) {
            MainPage()
          } else {
            Column() {
              Image($r('app.media.app_icon_fore'))
                .width(120).height(120)
            }.justifyContent(FlexAlign.Center)
          }
        }
        .size({ width: '100%', height: '100%' })
        .hideTitleBar(true)
        .titleMode(NavigationTitleMode.Mini)
        .mode(NavigationMode.Stack)
        .backgroundColor(Theme.getColor('background_primary'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.getColor('background_primary'))
  }
}