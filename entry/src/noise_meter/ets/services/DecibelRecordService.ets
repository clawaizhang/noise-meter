import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import common from '@ohos.app.ability.common';
import { FileService } from '../../../library/ets/services/FileService';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { RelationalStoreService } from '../../../library/ets/services/RelationalStoreService';

const TAG = 'DecibelRecordService';
const DOMAIN = 0x0000;

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private fileService: FileService;
  private relationalStoreService: RelationalStoreService;

  constructor(context: common.Context) {
    this.context = context;
    this.fileService = new FileService(context);
    this.relationalStoreService = RelationalStoreService.getInstance();
  }

  /**
   * 保存记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '准备保存记录: %{public}s', JSON.stringify(record));
      const valueBucket: relationalStore.ValuesBucket = {
        id: record.id,
        timestamp: record.timestamp,
        minDecibel: record.minDecibel,
        maxDecibel: record.maxDecibel,
        avgDecibel: record.avgDecibel,
        duration: record.duration,
        decibelValues: JSON.stringify(record.decibelValues),
        location: record.location ?? null,
        audioFilePath: record.audioFilePath ?? null,
        isFavorite: record.isFavorite ? 1 : 0,
        weightingTypes: JSON.stringify(record.weightingTypes) // 确保正确处理 weightingTypes
      };
      hilog.info(DOMAIN, TAG, '转换为 ValuesBucket: %{public}s', JSON.stringify(valueBucket));
      
      await this.relationalStoreService.insert('decibel_records', valueBucket);
      hilog.info(DOMAIN, TAG, '记录保存成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '保存记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
      throw new Error('保存记录失败: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 获取所有历史记录，按时间倒序排列
   */
  async getRecords(): Promise<DecibelRecord[]> {
    try {
      const sql = 'SELECT * FROM decibel_records ORDER BY timestamp DESC';
      const resultSet = await this.relationalStoreService.query(sql);
      
      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DecibelRecord.fromResultSet(resultSet));
      }
      resultSet.close();
      hilog.info(DOMAIN, TAG, '获取到 %{public}d 条记录', records.length);
      return records;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取历史记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('获取历史记录失败');
    }
  }

  /**
   * 清空非收藏记录
   */
  async clearUnfavoriteRecords(): Promise<void> {
    try {
      // 先获取所有非收藏的记录，用于删除音频文件
      const sql = 'SELECT * FROM decibel_records WHERE isFavorite = 0';
      const resultSet = await this.relationalStoreService.query(sql);
      
      while (resultSet.goToNextRow()) {
        const record = DecibelRecord.fromResultSet(resultSet);
        if (record.audioFilePath) {
          try {
            await this.fileService.deleteFile(record.audioFilePath);
          } catch (error) {
            hilog.error(DOMAIN, TAG, '删除音频文件失败: %{public}s', error instanceof Error ? error.message : String(error));
          }
        }
      }
      resultSet.close();

      // 删除非收藏记录
      const deleteSql = 'DELETE FROM decibel_records WHERE isFavorite = 0';
      await this.relationalStoreService.execute(deleteSql);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '清空非收藏记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('清空非收藏记录失败');
    }
  }

  /**
   * 更新记录
   */
  async updateRecord(record: DecibelRecord): Promise<void> {
    try {
      const valueBucket = record.toValuesBucket();
      const predicates = new relationalStore.RdbPredicates('decibel_records');
      predicates.equalTo('id', record.id);
      
      await this.relationalStoreService.update('decibel_records', valueBucket, predicates);
      hilog.info(DOMAIN, TAG, '记录更新成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '更新记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('更新记录失败');
    }
  }

  /**
   * 根据ID获取记录
   */
  async getRecordById(id: string): Promise<DecibelRecord | null> {
    try {
      const sql = 'SELECT * FROM decibel_records WHERE id = ?';
      const resultSet = await this.relationalStoreService.query(sql, [id]);
      
      let record: DecibelRecord | null = null;
      if (resultSet.goToFirstRow()) {
        record = DecibelRecord.fromResultSet(resultSet);
      }
      resultSet.close();
      return record;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('获取记录失败');
    }
  }

  /**
   * 删除记录
   */
  async deleteRecord(id: string): Promise<void> {
    try {
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
          hilog.error(DOMAIN, TAG, '删除音频文件失败: %{public}s', error instanceof Error ? error.message : String(error));
        }
      }

      // 删除数据库记录
      const predicates = new relationalStore.RdbPredicates('decibel_records');
      predicates.equalTo('id', id);
      
      await this.relationalStoreService.delete('decibel_records', predicates);
      hilog.info(DOMAIN, TAG, '记录删除成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '删除记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('删除记录失败');
    }
  }
} 