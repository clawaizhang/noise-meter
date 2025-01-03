import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import common from '@ohos.app.ability.common';
import { RelationalStoreService } from '../../../library/ets/services/RelationalStoreService';
import relationalStore from '@ohos.data.relationalStore';
import { FileService } from '../../../library/ets/services/FileService';

const DATABASE_NAME = 'decibel_records.db';
const TABLE_NAME = 'decibel_records';

// 建表SQL
const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id TEXT PRIMARY KEY NOT NULL,
    timestamp INTEGER NOT NULL,
    min_decibel REAL NOT NULL,
    max_decibel REAL NOT NULL,
    avg_decibel REAL NOT NULL,
    duration INTEGER NOT NULL,
    values TEXT NOT NULL,
    location TEXT,
    audio_file_path TEXT,
    is_favorite INTEGER DEFAULT 0
  )
`;

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private dbService: RelationalStoreService;
  private fileService: FileService;

  constructor(context: common.Context) {
    this.context = context;
    this.dbService = new RelationalStoreService(context, DATABASE_NAME);
    this.fileService = new FileService(context);
  }

  /**
   * 初始化数据库
   */
  async init(): Promise<void> {
    await this.dbService.execute(CREATE_TABLE_SQL);
  }

  /**
   * 将DecibelRecord对象转换为数据库记录
   */
  private toRecord(record: DecibelRecord): relationalStore.ValuesBucket {
    return {
      id: record.id,
      timestamp: record.timestamp,
      min_decibel: record.minDecibel,
      max_decibel: record.maxDecibel,
      avg_decibel: record.avgDecibel,
      duration: record.duration,
      values: JSON.stringify(record.values),
      location: record.location ?? null,
      audio_file_path: record.audioFilePath ?? null,
      is_favorite: record.isFavorite ? 1 : 0
    };
  }

  /**
   * 将数据库记录转换为DecibelRecord对象
   */
  private fromRecord(resultSet: relationalStore.ResultSet): DecibelRecord {
    const record = new DecibelRecord(
      resultSet.getDouble(resultSet.getColumnIndex('min_decibel')),
      resultSet.getDouble(resultSet.getColumnIndex('max_decibel')),
      resultSet.getDouble(resultSet.getColumnIndex('avg_decibel')),
      resultSet.getLong(resultSet.getColumnIndex('duration')),
      JSON.parse(resultSet.getString(resultSet.getColumnIndex('values'))),
      resultSet.getString(resultSet.getColumnIndex('location')),
      resultSet.getString(resultSet.getColumnIndex('audio_file_path'))
    );
    
    // 设置其他属性
    record.id = resultSet.getString(resultSet.getColumnIndex('id'));
    record.timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
    record.isFavorite = resultSet.getLong(resultSet.getColumnIndex('is_favorite')) === 1;
    
    return record;
  }

  /**
   * 保存记录
   * @param record 要保存的记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      // 使用toRecord方法转换数据
      const recordToSave = this.toRecord(record);

      // 保存到数据库
      await this.dbService.insert(TABLE_NAME, recordToSave);
    } catch (err) {
      const error = new Error('保存记录失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }

  /**
   * 获取所有历史记录，按时间倒序排列
   */
  async getRecords(): Promise<DecibelRecord[]> {
    try {
      const resultSet = await this.dbService.query(
        `SELECT * FROM ${TABLE_NAME} ORDER BY timestamp DESC LIMIT 100`
      );

      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.fromRecord(resultSet));
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
      // 先获取所有非收藏的记录，用于删除音频文件
      const resultSet = await this.dbService.query(
        `SELECT audio_file_path FROM ${TABLE_NAME} WHERE is_favorite = 0`
      );

      // 删除所有相关的音频文件
      while (resultSet.goToNextRow()) {
        const audioFilePath = resultSet.getString(resultSet.getColumnIndex('audio_file_path'));
        if (audioFilePath) {
          try {
            await this.fileService.deleteFile(audioFilePath);
          } catch (error) {
            console.error('删除音频文件失败:', error);
          }
        }
      }
      resultSet.close();

      // 使用WHERE条件只删除非收藏记录
      const predicatesForDelete = new relationalStore.RdbPredicates(TABLE_NAME);
      predicatesForDelete.equalTo('is_favorite', 0);
      const rowsAffected = await this.dbService.delete(TABLE_NAME, predicatesForDelete);
      if (rowsAffected < 0) {
        throw new Error('清空非收藏记录失败');
      }
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
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', record.id);
      
      const rowsAffected = await this.dbService.update(
        TABLE_NAME,
        this.toRecord(record),
        predicates
      );

      if (rowsAffected <= 0) {
        throw new Error('更新记录失败');
      }
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
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('id', id);
      
      const rowsAffected = await this.dbService.delete(TABLE_NAME, predicates);
      if (rowsAffected <= 0) {
        throw new Error('删除记录失败');
      }
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
      const resultSet = await this.dbService.query(
        `SELECT * FROM ${TABLE_NAME} WHERE id = ?`,
        [id]
      );

      if (!resultSet.goToFirstRow()) {
        resultSet.close();
        return null;
      }

      const record = this.fromRecord(resultSet);
      resultSet.close();
      return record;
    } catch (error) {
      console.error('获取记录失败:', error);
      throw new Error('获取记录失败');
    }
  }
} 