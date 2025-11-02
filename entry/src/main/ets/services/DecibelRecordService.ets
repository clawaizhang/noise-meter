import common from '@ohos.app.ability.common';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { FileUtils } from '../utils/FileUtils';
import { RelationalStoreService } from './RelationalStoreService';
import { DecibelRecord } from '../models/DecibelRecord';
import { FilterConfig, FilterManager } from '../models/FilterConfig';

const TAG = 'DecibelRecordService';
const DOMAIN = 0x0000;

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private relationalStoreService: RelationalStoreService;

  constructor(context: common.Context) {
    this.context = context;
    this.relationalStoreService = RelationalStoreService.getInstance();
  }

  /**
   * 保存记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '准备保存记录: %{public}s', JSON.stringify(record));
      let decibelValues = JSON.stringify(record.decibelValues) as string;
      const valueBucket: relationalStore.ValuesBucket = {
        'id': record.id,
        'timestamp': record.timestamp,
        'minDecibel': record.minDecibel,
        'maxDecibel': record.maxDecibel,
        'avgDecibel': record.avgDecibel,
        'duration': record.duration,
        'decibelValues': decibelValues,
        'location': record.location ?? null,
        'audioFilePath': record.audioFilePath ?? null,
        'isFavorite': record.isFavorite ? 1 : 0,
        'comment': record.comment,
        'weightingTypes': JSON.stringify(record.weightingTypes) // 确保正确处理 weightingTypes
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
   * 分页获取历史记录，按时间倒序排列
   * @param limit 限制返回的记录数
   * @param offset 偏移量
   */
  async getRecordsPaged(limit: number = 10, offset: number = 0): Promise<DecibelRecord[]> {
    try {
      const sql = 'SELECT * FROM decibel_records ORDER BY timestamp DESC LIMIT ? OFFSET ?';
      const resultSet = await this.relationalStoreService.query(sql, [limit, offset]);

      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DecibelRecord.fromResultSet(resultSet));
      }
      resultSet.close();
      hilog.info(DOMAIN, TAG, '分页获取到 %{public}d 条记录 (limit: %{public}d, offset: %{public}d)',
        records.length, limit, offset);
      return records;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '分页获取历史记录失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      throw new Error('分页获取历史记录失败');
    }
  }

  /**
   * 获取记录总数
   */
  async getTotalCount(): Promise<number> {
    try {
      const sql = 'SELECT COUNT(*) as total FROM decibel_records';
      const resultSet = await this.relationalStoreService.query(sql);

      let total = 0;
      if (resultSet.goToFirstRow()) {
        total = resultSet.getLong(resultSet.getColumnIndex('total'));
      }
      resultSet.close();
      hilog.info(DOMAIN, TAG, '总记录数: %{public}d', total);
      return total;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取记录总数失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('获取记录总数失败');
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
            await FileUtils.deleteFile(record.audioFilePath);
          } catch (error) {
            hilog.error(DOMAIN, TAG, '删除音频文件失败: %{public}s',
              error instanceof Error ? error.message : String(error));
          }
        }
      }
      resultSet.close();

      // 删除非收藏记录
      const deleteSql = 'DELETE FROM decibel_records WHERE isFavorite = 0';
      await this.relationalStoreService.execute(deleteSql);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '清空非收藏记录失败: %{public}s',
        error instanceof Error ? error.message : String(error));
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
          await FileUtils.deleteFile(record.audioFilePath);
        } catch (error) {
          hilog.error(DOMAIN, TAG, '删除音频文件失败: %{public}s',
            error instanceof Error ? error.message : String(error));
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

  /**
   * 根据过滤器配置获取记录
   */
  async getFilteredRecords(filters: FilterConfig): Promise<DecibelRecord[]> {
    try {
      // 构建动态SQL查询
      let sql = 'SELECT * FROM decibel_records WHERE 1=1';
      const params: string[] = [];

      // 分贝范围过滤
      if (filters.decibelRange) {
        const decibelConditions: string[] = [];

        // 预设范围过滤
        if (filters.decibelRange.presetRanges.length > 0) {
          const rangeConditions = filters.decibelRange.presetRanges.map(range => {
            if (range.max === Infinity) {
              return `(avgDecibel >= ${range.min})`;
            } else {
              return `(avgDecibel >= ${range.min} AND avgDecibel < ${range.max})`;
            }
          });
          decibelConditions.push(`(${rangeConditions.join(' OR ')})`);
        }

        // 自定义范围过滤
        if (filters.decibelRange.customMin !== undefined || filters.decibelRange.customMax !== undefined) {
          const min = filters.decibelRange.customMin ?? 0;
          const max = filters.decibelRange.customMax ?? 200; // 合理的最大值
          decibelConditions.push(`(avgDecibel >= ${min} AND avgDecibel <= ${max})`);
        }

        if (decibelConditions.length > 0) {
          sql += ` AND (${decibelConditions.join(' OR ')})`;
        }
      }

      // 收藏状态过滤
      if (filters.status?.favoriteOnly) {
        sql += ' AND isFavorite = 1';
      }

      // 音频文件存在过滤
      if (filters.status?.hasAudio) {
        sql += ' AND audioFilePath IS NOT NULL';
      }

      // 位置信息存在过滤
      if (filters.status?.hasLocation) {
        sql += ' AND location IS NOT NULL AND location != ""';
      }

      // 权重类型过滤
      if (filters.weighting && filters.weighting.types.length > 0) {
        const weightingConditions = filters.weighting.types.map(type =>
        `weightingTypes LIKE '%"${type}"%'`
        );
        sql += ` AND (${weightingConditions.join(' OR ')})`;
      }

      // 位置关键词搜索
      if (filters.textSearch?.locationKeyword) {
        sql += ' AND location LIKE ?';
        params.push(`%${filters.textSearch.locationKeyword}%`);
      }

      // 备注关键词搜索
      if (filters.textSearch?.commentKeyword) {
        sql += ' AND comment LIKE ?';
        params.push(`%${filters.textSearch.commentKeyword}%`);
      }

      // 时间范围过滤
      if (filters.timeRange) {
        if (filters.timeRange.startTime !== undefined) {
          sql += ' AND timestamp >= ?';
          params.push(filters.timeRange.startTime.toString());
        }
        if (filters.timeRange.endTime !== undefined) {
          sql += ' AND timestamp <= ?';
          params.push(filters.timeRange.endTime.toString());
        }
      }

      sql += ' ORDER BY timestamp DESC';

      const resultSet = await this.relationalStoreService.query(sql, params);

      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DecibelRecord.fromResultSet(resultSet));
      }
      resultSet.close();

      hilog.info(DOMAIN, TAG, '过滤查询返回 %{public}d 条记录', records.length);
      return records;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '过滤查询失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('过滤查询失败');
    }
  }

  /**
   * 分页获取过滤后的记录
   */
  async getFilteredRecordsPaged(filters: FilterConfig, limit: number = 10,
    offset: number = 0): Promise<DecibelRecord[]> {
    try {
      // 构建动态SQL查询
      let sql = 'SELECT * FROM decibel_records WHERE 1=1';
      const params: string[] = [];

      // 分贝范围过滤
      if (filters.decibelRange) {
        const decibelConditions: string[] = [];

        // 预设范围过滤
        if (filters.decibelRange.presetRanges.length > 0) {
          const rangeConditions = filters.decibelRange.presetRanges.map(range => {
            if (range.max === Infinity) {
              return `(avgDecibel >= ${range.min})`;
            } else {
              return `(avgDecibel >= ${range.min} AND avgDecibel < ${range.max})`;
            }
          });
          decibelConditions.push(`(${rangeConditions.join(' OR ')})`);
        }

        // 自定义范围过滤
        if (filters.decibelRange.customMin !== undefined || filters.decibelRange.customMax !== undefined) {
          const min = filters.decibelRange.customMin ?? 0;
          const max = filters.decibelRange.customMax ?? 200;
          decibelConditions.push(`(avgDecibel >= ${min} AND avgDecibel <= ${max})`);
        }

        if (decibelConditions.length > 0) {
          sql += ` AND (${decibelConditions.join(' OR ')})`;
        }
      }

      // 收藏状态过滤
      if (filters.status?.favoriteOnly) {
        sql += ' AND isFavorite = 1';
      }

      // 音频文件存在过滤
      if (filters.status?.hasAudio) {
        sql += ' AND audioFilePath IS NOT NULL AND audioFilePath != ""';
      }

      // 位置信息存在过滤
      if (filters.status?.hasLocation) {
        sql += ' AND location IS NOT NULL AND location != ""';
      }

      // 权重类型过滤
      if (filters.weighting && filters.weighting.types.length > 0) {
        const weightingConditions = filters.weighting.types.map(type =>
        `weightingTypes LIKE '%"${type}"%'`
        );
        sql += ` AND (${weightingConditions.join(' OR ')})`;
      }

      // 位置关键词搜索
      if (filters.textSearch?.locationKeyword) {
        sql += ' AND location LIKE ?';
        params.push(`%${filters.textSearch.locationKeyword}%`);
      }

      // 备注关键词搜索
      if (filters.textSearch?.commentKeyword) {
        // 支持搜索空备注记录（当用户明确搜索"无备注"时）
        if (['无备注','无','无备'].includes(filters.textSearch.commentKeyword.toLowerCase())) {
          sql += ' AND (comment IS NULL OR comment = "" OR comment LIKE ?)';
          params.push(`%${filters.textSearch.commentKeyword}%`);
        } else {
          // 普通关键词搜索，包括搜索"空"等关键词本身
          sql += ' AND comment LIKE ?';
          params.push(`%${filters.textSearch.commentKeyword}%`);
        }
      }

      sql += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
      params.push(limit + '', offset + '');

      const resultSet = await this.relationalStoreService.query(sql, params);

      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(DecibelRecord.fromResultSet(resultSet));
      }
      resultSet.close();

      hilog.info(DOMAIN, TAG, '分页过滤查询返回 %{public}d 条记录 (limit: %{public}d, offset: %{public}d)',
        records.length, limit, offset);
      return records;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '分页过滤查询失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('分页过滤查询失败');
    }
  }

  /**
   * 获取过滤后的记录总数
   */
  async getFilteredTotalCount(filters: FilterConfig): Promise<number> {
    try {
      let sql = 'SELECT COUNT(*) as total FROM decibel_records WHERE 1=1';
      const params: string[] = [];

      // 分贝范围过滤
      if (filters.decibelRange) {
        const decibelConditions: string[] = [];

        // 预设范围过滤
        if (filters.decibelRange.presetRanges.length > 0) {
          const rangeConditions = filters.decibelRange.presetRanges.map(range => {
            if (range.max === Infinity) {
              return `(avgDecibel >= ${range.min})`;
            } else {
              return `(avgDecibel >= ${range.min} AND avgDecibel < ${range.max})`;
            }
          });
          decibelConditions.push(`(${rangeConditions.join(' OR ')})`);
        }

        // 自定义范围过滤
        if (filters.decibelRange.customMin !== undefined || filters.decibelRange.customMax !== undefined) {
          const min = filters.decibelRange.customMin ?? 0;
          const max = filters.decibelRange.customMax ?? 200;
          decibelConditions.push(`(avgDecibel >= ${min} AND avgDecibel <= ${max})`);
        }

        if (decibelConditions.length > 0) {
          sql += ` AND (${decibelConditions.join(' OR ')})`;
        }
      }

      // 收藏状态过滤
      if (filters.status?.favoriteOnly) {
        sql += ' AND isFavorite = 1';
      }

      // 音频文件存在过滤
      if (filters.status?.hasAudio) {
        sql += ' AND audioFilePath IS NOT NULL';
      }

      // 位置信息存在过滤
      if (filters.status?.hasLocation) {
        sql += ' AND location IS NOT NULL AND location != ""';
      }

      // 权重类型过滤
      if (filters.weighting && filters.weighting.types.length > 0) {
        const weightingConditions = filters.weighting.types.map(type =>
        `weightingTypes LIKE '%"${type}"%'`
        );
        sql += ` AND (${weightingConditions.join(' OR ')})`;
      }

      // 位置关键词搜索
      if (filters.textSearch?.locationKeyword) {
        sql += ' AND location LIKE ?';
        params.push(`%${filters.textSearch.locationKeyword}%`);
      }

      // 备注关键词搜索
      if (filters.textSearch?.commentKeyword) {
        // 支持搜索空备注记录（当用户明确搜索"无备注"时）
        if (['无备注','无','无备'].includes(filters.textSearch.commentKeyword.toLowerCase())) {
          sql += ' AND (comment IS NULL OR comment = "" OR comment LIKE ?)';
          params.push(`%${filters.textSearch.commentKeyword}%`);
        } else {
          // 普通关键词搜索，包括搜索"空"等关键词本身
          sql += ' AND comment LIKE ?';
          params.push(`%${filters.textSearch.commentKeyword}%`);
        }
      }

      const resultSet = await this.relationalStoreService.query(sql, params);

      let total = 0;
      if (resultSet.goToFirstRow()) {
        total = resultSet.getLong(resultSet.getColumnIndex('total'));
      }
      resultSet.close();

      hilog.info(DOMAIN, TAG, '过滤后总记录数: %{public}d', total);
      return total;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取过滤后记录总数失败: %{public}s',
        error instanceof Error ? error.message : String(error));
      throw new Error('获取过滤后记录总数失败');
    }
  }
}