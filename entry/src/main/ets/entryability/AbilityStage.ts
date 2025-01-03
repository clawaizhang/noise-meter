import AbilityStage from '@ohos.app.ability.AbilityStage';
import { DecibelRecordOpenHelper } from '../../library/ets/services/DecibelRecordOpenHelper';
import { Database, DaoMaster } from '@ohos/dataorm';
import GlobalContext from '@ohos.app.ability.GlobalContext';

const DATABASE_NAME = 'decibel_records.db';

export default class MyAbilityStage extends AbilityStage {
  async onCreate() {
    try {
      // 初始化数据库
      const helper = new DecibelRecordOpenHelper(this.context, DATABASE_NAME);
      const db: Database = await helper.getWritableDatabase();
      const daoSession = new DaoMaster(db).newSession();
      GlobalContext.getContext().setValue('daoSession', daoSession);
      console.info('数据库初始化成功');
    } catch (error) {
      console.error('数据库初始化失败:', error);
    }
  }
} 