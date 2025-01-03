import common from '@ohos.app.ability.common';
import { OpenHelper, Database, DaoMaster } from '@ohos/dataorm';

/**
 * 数据库帮助类
 */
export class DecibelRecordOpenHelper extends OpenHelper {
  constructor(context: common.Context, name: string) {
    super(context, name);
  }

  /**
   * 创建数据库
   */
  public async onCreateDatabase(db: Database): Promise<void> {
    console.info('创建数据库');
    await DaoMaster.createAllTables(db, false);
  }

  /**
   * 升级数据库
   */
  async onUpgradeDatabase(db: Database, oldVersion: number, newVersion: number): Promise<void> {
    console.info('升级数据库');
    await DaoMaster.dropAllTablesAsync(db, false);
    await DaoMaster.createAllTables(db, false);
  }

  /**
   * 降级数据库
   */
  async onDowngradeDatabase(db: Database, oldVersion: number, newVersion: number): Promise<void> {
    console.info('降级数据库');
    await DaoMaster.dropAllTablesAsync(db, false);
    await DaoMaster.createAllTables(db, false);
  }
} 