import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { relationalStore } from '@kit.ArkData';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 初始化数据库
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'decibel_records.db',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false
    };

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

    try {
      // 获取数据库实例
      const store = await new Promise<relationalStore.RdbStore>((resolve, reject) => {
        relationalStore.getRdbStore(this.context, STORE_CONFIG, (err, store) => {
          if (err) {
            reject(new Error(`获取数据库实例失败: ${err.message}`));
            return;
          }
          resolve(store);
        });
      });
      hilog.info(DOMAIN, TAG, 'Succeeded in getting RdbStore.');

      // 当数据库创建时，数据库默认版本为0
      if (store.version === 0) {
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
        hilog.info(DOMAIN, TAG, 'Created table successfully.');

        // 设置数据库的版本
        store.version = 1;
        hilog.info(DOMAIN, TAG, 'Set database version to 1.');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化数据库失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    // 加载页面内容
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
