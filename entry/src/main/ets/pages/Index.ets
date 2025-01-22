import hilog from '@ohos.hilog';
import { MainPage } from 'entry/MainPageInfo';
import { RelationalStoreService } from '../../../library/ets/services/RelationalStoreService';
import { DatabaseConstants } from '../../../library/ets/constants/DatabaseConstants';
import { TableCreateSql } from '../../../library/ets/constants/TableCreateSql';
import { DatabaseUpgradeConfig } from '../../../library/ets/interfaces/DatabaseInterfaces';
import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceStoreConstants } from '../../../library/ets/constants/PreferenceStoreConstants';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';

const TAG = 'Index';
const DOMAIN = 0x0000;

@Builder
function IndexBuilder() {
  Index()
}

@Entry
@Component
struct Index {
  @State isInitialized: boolean = false;
  @State isLoading: boolean = true;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  async aboutToAppear() {
    this.initialize();
  }

  private async initialize() {
    try {
      // 初始化数据库
      const upgradeConfigs: DatabaseUpgradeConfig[] = [
        {
          version: 1,
          sqls: [TableCreateSql.DECIBEL_RECORDS]
        }
      ];

      const dbResult = await this.relationalStoreService.init(getContext(this), DatabaseConstants.NOISE_METER_DB, upgradeConfigs);
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

  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中
        Column() {
          LoadingProgress()
            .width(64)
            .height(64)
          Text('正在初始化...')
            .fontSize(16)
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
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
        Navigation() {
          MainPage()
        }
        .size({ width: '100%', height: '100%' })
        .hideTitleBar(true)
        .titleMode(NavigationTitleMode.Mini)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}