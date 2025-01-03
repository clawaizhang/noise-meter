import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

/**
 * 关系型数据库服务
 */
export class RelationalStoreService {
  private context: common.Context;
  private store: relationalStore.RdbStore | null = null;
  private readonly databaseName: string;

  constructor(context: common.Context, databaseName: string) {
    this.context = context;
    this.databaseName = databaseName;
  }

  /**
   * 获取数据库实例
   */
  private async getStore(sqlCreateTable: string): Promise<relationalStore.RdbStore> {
    if (this.store !== null) {
      return this.store;
    }

    try {
      // 数据库配置
      const config: relationalStore.StoreConfig = {
        name: this.databaseName,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      // 获取数据库连接
      this.store = await relationalStore.getRdbStore(this.context, config);

      // 执行建表SQL
      await this.store.executeSql(sqlCreateTable);

      return this.store;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`获取数据库实例失败: ${businessError.message}`);
      throw new Error('获取数据库实例失败');
    }
  }

  /**
   * 执行SQL查询
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   * @returns 查询结果集
   */
  async query(sql: string, bindArgs: Array<relationalStore.ValueType> = []): Promise<relationalStore.ResultSet> {
    try {
      const store = await this.getStore('');
      return await store.querySql(sql, bindArgs);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`查询失败: ${businessError.message}`);
      throw new Error('查询失败');
    }
  }

  /**
   * 执行SQL语句
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   */
  async execute(sql: string, bindArgs: Array<relationalStore.ValueType> = []): Promise<void> {
    try {
      const store = await this.getStore('');
      await store.executeSql(sql, bindArgs);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`执行SQL失败: ${businessError.message}`);
      throw new Error('执行SQL失败');
    }
  }

  /**
   * 批量执行SQL语句
   * @param sqls SQL语句数组
   */
  async batchExecute(sqls: string[]): Promise<void> {
    try {
      const store = await this.getStore('');
      await store.executeSql('BEGIN TRANSACTION');
      for (const sql of sqls) {
        await store.executeSql(sql);
      }
      await store.executeSql('COMMIT TRANSACTION');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`批量执行SQL失败: ${businessError.message}`);
      const store = await this.getStore('');
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
      const store = await this.getStore('');
      const rowId = await store.insert(tableName, values);
      return rowId;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`插入数据失败: ${businessError.message}`);
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
      const store = await this.getStore('');
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
      console.error(`批量插入数据失败: ${businessError.message}`);
      const store = await this.getStore('');
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
      const store = await this.getStore('');
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
      const store = await this.getStore('');
      return await store.delete(predicates);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`删除数据失败: ${businessError.message}`);
      throw new Error('删除数据失败');
    }
  }
} 