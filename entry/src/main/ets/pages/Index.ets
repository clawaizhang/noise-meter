import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { MainPage } from 'entry/MainPageInfo';

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

  aboutToAppear() {
    this.initializeDatabase();
  }

  private async initializeDatabase() {
    try {
      hilog.info(DOMAIN, TAG, '开始初始化数据库');
      
      // 数据库配置
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'decibel_records.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: false
      };

      // 建表 SQL
      const SQL_CREATE_TABLE = `
        CREATE TABLE IF NOT EXISTS decibel_records (
          id TEXT PRIMARY KEY NOT NULL,
          timestamp INTEGER NOT NULL,
          minDecibel REAL NOT NULL,
          maxDecibel REAL NOT NULL,
          avgDecibel REAL NOT NULL,
          duration INTEGER NOT NULL,
          decibelValues TEXT NOT NULL,
          location TEXT,
          audioFilePath TEXT,
          isFavorite INTEGER DEFAULT 0
        )
      `;

      // 获取数据库实例
      const store = await new Promise<relationalStore.RdbStore>((resolve, reject) => {
        relationalStore.getRdbStore(getContext(this), STORE_CONFIG, (err, store) => {
          if (err) {
            reject(new Error(`获取数据库实例失败: ${err.message}`));
            return;
          }
          resolve(store);
        });
      });
      hilog.info(DOMAIN, TAG, '获取数据库实例成功');

      // 创建表
      await new Promise<void>((resolve, reject) => {
        store.executeSql(SQL_CREATE_TABLE, null, (err) => {
          if (err) {
            reject(new Error(`创建表失败: ${err.message}`));
            return;
          }
          resolve();
        });
      });
      hilog.info(DOMAIN, TAG, '创建表成功');

      // 设置数据库版本
      if (store.version === 0) {
        store.version = 1;
        hilog.info(DOMAIN, TAG, '设置数据库版本为 1');
      }

      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, '数据库初始化完成');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化数据库失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
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
          // Image($r('app.media.ic_error'))
          //   .width(64)
          //   .height(64)
          //   .fillColor('#999999')
          Text('初始化失败')
            .fontSize(16)
            .margin({ top: 12 })
          Button('重试')
            .margin({ top: 24 })
            .onClick(() => {
              this.isLoading = true;
              this.initializeDatabase();
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