import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import { DatabaseUpgradeConfig } from '../interfaces/DatabaseInterfaces';

const TAG = 'RelationalStoreService';
const DOMAIN = 0x0000;

/**
 * 关系型数据库服务
 */
export class RelationalStoreService {
  private static instance: RelationalStoreService;
  private context: common.Context | null = null;
  private store: relationalStore.RdbStore | null = null;
  private databaseName: string = '';
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 获取RelationalStoreService实例
   */
  public static getInstance(): RelationalStoreService {
    if (!RelationalStoreService.instance) {
      RelationalStoreService.instance = new RelationalStoreService();
    }
    return RelationalStoreService.instance;
  }

  /**
   * 初始化数据库
   * @param context 上下文
   * @param databaseName 数据库名称
   * @param upgradeConfigs 数据库版本升级配置数组,按版本号从小到大排序
   */
  public async init(context: common.Context, databaseName: string, upgradeConfigs: DatabaseUpgradeConfig[]): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.context = context;
      this.databaseName = databaseName;
      hilog.info(DOMAIN, TAG, '开始初始化数据库');
      
      // 数据库配置
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: databaseName,
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: false
      };

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
      hilog.info(DOMAIN, TAG, '获取数据库实例成功');

      // 获取当前数据库版本
      const currentVersion = store.version;
      hilog.info(DOMAIN, TAG, `当前数据库版本: ${currentVersion}`);

      // 按版本号升序排序
      upgradeConfigs.sort((a, b) => a.version - b.version);

      // 执行版本升级
      for (const config of upgradeConfigs) {
        if (currentVersion < config.version) {
          hilog.info(DOMAIN, TAG, `开始升级到版本 ${config.version}`);
          
          // 开始事务
          store.beginTransaction();
          
          try {
            // 执行该版本的所有SQL
            for (const sql of config.sqls) {
              await new Promise<void>((resolve, reject) => {
                store.executeSql(sql, null, (err) => {
                  if (err) {
                    reject(new Error(`执行SQL失败: ${err.message}, SQL: ${sql}`));
                    return;
                  }
                  resolve();
                });
              });
            }
            
            // 更新版本号
            store.version = config.version;
            
            // 提交事务
            store.commit();
            hilog.info(DOMAIN, TAG, `升级到版本 ${config.version} 成功`);
          } catch (error) {
            // 回滚事务
            store.rollBack();
            throw error instanceof Error ? error : new Error(String(error));
          }
        }
      }

      this.store = store;
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, '数据库初始化完成');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化数据库失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
      return false;
    }
  }

  /**
   * 获取数据库实例
   */
  private async getStore(): Promise<relationalStore.RdbStore> {
    if (this.store !== null) {
      return this.store;
    }

    throw new Error('数据库未初始化');
  }

  /**
   * 执行SQL查询
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   * @returns 查询结果集
   */
  async query(sql: string, bindArgs: Array<relationalStore.ValueType> = []): Promise<relationalStore.ResultSet> {
    try {
      console.info('执行查询:', sql, '参数:', bindArgs);
      const store = await this.getStore();
      const resultSet = await store.querySql(sql, bindArgs);
      console.info('查询执行成功');
      return resultSet;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`查询失败: ${businessError.code} - ${businessError.message}, SQL: ${sql}, 参数:`, bindArgs);
      throw new Error(`查询失败: ${businessError.message}`);
    }
  }

  /**
   * 执行SQL语句
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   */
  async execute(sql: string, bindArgs: Array<relationalStore.ValueType> = []): Promise<void> {
    try {
      console.info('执行SQL:', sql, '参数:', bindArgs);
      const store = await this.getStore();
      await store.executeSql(sql, bindArgs);
      console.info('SQL执行成功');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`执行SQL失败: ${businessError.code} - ${businessError.message}, SQL: ${sql}, 参数:`, bindArgs);
      throw new Error(`执行SQL失败: ${businessError.message}`);
    }
  }

  /**
   * 批量执行SQL语句
   * @param sqls SQL语句数组
   */
  async batchExecute(sqls: string[]): Promise<void> {
    try {
      const store = await this.getStore();
      await store.executeSql('BEGIN TRANSACTION');
      for (const sql of sqls) {
        await store.executeSql(sql);
      }
      await store.executeSql('COMMIT TRANSACTION');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`批量执行SQL失败: ${businessError.message}`);
      const store = await this.getStore();
      await store.executeSql('ROLLBACK TRANSACTION');
      throw new Error('批量执行SQL失败');
    }
  }

  /**
   * 插入数据
   * @param tableName 表名
   * @param values 要插入的数据
   */
  async insert(tableName: string, values: relationalStore.ValuesBucket): Promise<number> {
    try {
      const store = await this.getStore();
      const rowId = await store.insert(tableName, values);
      return rowId;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`插入数据失败: ${businessError}`);
      throw new Error('插入数据失败');
    }
  }

  /**
   * 批量插入数据
   * @param tableName 表名
   * @param values 要插入的数据数组
   */
  async batchInsert(tableName: string, values: Array<relationalStore.ValuesBucket>): Promise<void> {
    try {
      const store = await this.getStore();
      await store.executeSql('BEGIN TRANSACTION');
      for (const value of values) {
        const rowId = await store.insert(tableName, value);
        if (rowId < 0) {
          throw new Error('批量插入数据失败');
        }
      }
      await store.executeSql('COMMIT TRANSACTION');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`批量插入数据失败: ${businessError}`);
      const store = await this.getStore();
      await store.executeSql('ROLLBACK TRANSACTION');
      throw new Error('批量插入数据失败');
    }
  }

  /**
   * 更新数据
   * @param tableName 表名
   * @param values 要更新的数据
   * @param predicates 更新条件
   */
  async update(
    tableName: string,
    values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    try {
      const store = await this.getStore();
      return await store.update(values, predicates);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`更新数据失败: ${businessError.message}`);
      throw new Error('更新数据失败');
    }
  }

  /**
   * 删除数据
   * @param tableName 表名
   * @param predicates 删除条件
   */
  async delete(
    tableName: string,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    try {
      const store = await this.getStore();
      return await store.delete(predicates);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`删除数据失败: ${businessError.message}`);
      throw new Error('删除数据失败');
    }
  }
} 