import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import common from '@ohos.app.ability.common';
import { FileService } from '../../../library/ets/services/FileService';
import relationalStore from '@ohos.data.relationalStore';

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private fileService: FileService;
  private rdbStore: relationalStore.RdbStore | null = null;
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'decibel_records.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  constructor(context: common.Context) {
    this.context = context;
    this.fileService = new FileService(context);
  }

  /**
   * 确保数据库已初始化
   */
  private async ensureInitialized(): Promise<void> {
    if (!this.rdbStore) {
      try {
        // 获取数据库实例
        this.rdbStore = await relationalStore.getRdbStore(this.context, DecibelRecordService.STORE_CONFIG);
        
        // 创建表
        await this.rdbStore.executeSql(DecibelRecord.getCreateTableSql());
        console.info('数据库初始化成功');
      } catch (error) {
        console.error('初始化数据库失败:', error);
        throw new Error('初始化数据库失败: ' + (error instanceof Error ? error.message : String(error)));
      }
    }
  }

  /**
   * 保存记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      const valueBucket = record.toValuesBucket();
      await this.rdbStore.insert(DecibelRecord.getTableName(), valueBucket);
    } catch (error) {
      console.error('保存记录失败:', error);
      throw new Error('保存记录失败');
    }
  }

  /**
   * 获取所有历史记录，按时间倒序排列
   */
  async getRecords(): Promise<DecibelRecord[]> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      const sql = `SELECT * FROM ${DecibelRecord.getTableName()} ORDER BY timestamp DESC LIMIT 100`;
      const resultSet = await this.rdbStore.querySql(sql);
      
      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DecibelRecord.fromResultSet(resultSet));
      }
      resultSet.close();
      return records;
    } catch (error) {
      console.error('获取历史记录失败:', error);
      throw new Error('获取历史记录失败');
    }
  }

  /**
   * 清空非收藏记录
   */
  async clearUnfavoriteRecords(): Promise<void> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      // 先获取所有非收藏的记录，用于删除音频文件
      const sql = `SELECT * FROM ${DecibelRecord.getTableName()} WHERE isFavorite = 0`;
      const resultSet = await this.rdbStore.querySql(sql);
      
      while (resultSet.goToNextRow()) {
        const record = DecibelRecord.fromResultSet(resultSet);
        if (record.audioFilePath) {
          try {
            await this.fileService.deleteFile(record.audioFilePath);
          } catch (error) {
            console.error('删除音频文件失败:', error);
          }
        }
      }
      resultSet.close();

      // 删除非收藏记录
      const deleteSql = `DELETE FROM ${DecibelRecord.getTableName()} WHERE isFavorite = 0`;
      await this.rdbStore.executeSql(deleteSql);
    } catch (error) {
      console.error('清空非收藏记录失败:', error);
      throw new Error('清空非收藏记录失败');
    }
  }

  /**
   * 更新记录
   */
  async updateRecord(record: DecibelRecord): Promise<void> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      const valueBucket = record.toValuesBucket();
      const predicates = new relationalStore.RdbPredicates(DecibelRecord.getTableName());
      predicates.equalTo('id', record.id);
      
      await this.rdbStore.update(valueBucket, predicates);
    } catch (error) {
      console.error('更新记录失败:', error);
      throw new Error('更新记录失败');
    }
  }

  /**
   * 删除记录
   */
  async deleteRecord(id: string): Promise<void> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      // 先获取记录信息
      const record = await this.getRecordById(id);
      if (!record) {
        throw new Error('记录不存在');
      }

      // 如果有音频文件，先删除音频文件
      if (record.audioFilePath) {
        try {
          await this.fileService.deleteFile(record.audioFilePath);
        } catch (error) {
          console.error('删除音频文件失败:', error);
        }
      }

      // 删除数据库记录
      const predicates = new relationalStore.RdbPredicates(DecibelRecord.getTableName());
      predicates.equalTo('id', id);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      console.error('删除记录失败:', error);
      throw new Error('删除记录失败');
    }
  }

  /**
   * 根据ID获取记录
   */
  async getRecordById(id: string): Promise<DecibelRecord | null> {
    try {
      await this.ensureInitialized();
      if (!this.rdbStore) {
        throw new Error('数据库未初始化');
      }

      const sql = `SELECT * FROM ${DecibelRecord.getTableName()} WHERE id = ?`;
      const resultSet = await this.rdbStore.querySql(sql, [id]);
      
      if (resultSet.goToFirstRow()) {
        const record = DecibelRecord.fromResultSet(resultSet);
        resultSet.close();
        return record;
      }
      
      resultSet.close();
      return null;
    } catch (error) {
      console.error('获取记录失败:', error);
      throw new Error('获取记录失败');
    }
  }
} 