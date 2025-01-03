import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import { DecibelRecordOpenHelper } from '../../../library/ets/services/DecibelRecordOpenHelper';
import { Database, DaoMaster, GlobalContext } from '@ohos/dataorm';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    console.info('EntryAbility onCreate');
    try {
      // 初始化全局上下文
      GlobalContext.getContext().setValue(GlobalContext.KEY_CLS, { DecibelRecord });
      console.info('初始化全局上下文成功');

      // 创建数据库帮助类
      const helper = new DecibelRecordOpenHelper(this.context, 'decibel_records.db');
      console.info('创建 OpenHelper 成功');

      // 设置实体类
      helper.setEntities(DecibelRecord);
      console.info('设置实体类成功');

      // 获取数据库实例
      const db: Database = await helper.getWritableDb();
      console.info('获取数据库实例成功');

      // 创建 DaoSession 并存储到全局上下文
      const daoSession = new DaoMaster(db).newSession();
      GlobalContext.getContext().setValue('daoSession', daoSession);
      console.info('创建 DaoSession 成功');
    } catch (error) {
      console.error('初始化数据库失败:', error);
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
