import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { GlobalContext, DaoMaster, Database } from '@ohos/dataorm';
import { DecibelRecordOpenHelper } from '../../../library/ets/services/DecibelRecordOpenHelper';
import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    console.info('EntryAbility onCreate');

    // 创建数据库帮助类
    const helper: DecibelRecordOpenHelper = new DecibelRecordOpenHelper(this.context, 'decibel_records.db');

    // 设置数据库不加密
    helper.setEncrypt(false);

    // 设置数据库版本
    await helper.setVersion(1);

    // 设置实体类
    helper.setEntities(DecibelRecord);

    // 获取数据库实例
    const db: Database = await helper.getWritableDb();
    db.name = 'decibel_records.db';

    // 创建 DaoSession 并存储到全局上下文
    GlobalContext.getContext().setValue('daoSession', new DaoMaster(db).newSession());
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
