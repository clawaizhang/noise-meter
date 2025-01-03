import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import common from '@ohos.app.ability.common';
import { FileService } from '../../../library/ets/services/FileService';
import { DaoMaster, DaoSession, BaseDao, Property, GlobalContext } from '@ohos/dataorm';

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private fileService: FileService;
  private daoSession: DaoSession | null = null;
  private decibelRecordDao: BaseDao<DecibelRecord, string> | null = null;

  constructor(context: common.Context) {
    this.context = context;
    this.fileService = new FileService(context);
  }

  /**
   * 确保数据库已初始化
   */
  private async ensureInitialized(): Promise<void> {
    if (!this.daoSession) {
      try {
        console.info('从全局上下文获取 DaoSession');
        this.daoSession = GlobalContext.getContext().getValue('daoSession') as DaoSession;
        if (!this.daoSession) {
          throw new Error('DaoSession not found in GlobalContext');
        }
        
        // 获取DAO
        this.decibelRecordDao = this.daoSession.getBaseDao(DecibelRecord);
        console.info('获取DAO成功');
      } catch (error) {
        console.error('初始化数据库失败:', error);
        throw new Error('初始化数据库失败: ' + (error instanceof Error ? error.message : String(error)));
      }
    }
  }

  /**
   * 保存记录
   * @param record 要保存的记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      // 确保数据库已初始化
      await this.ensureInitialized();

      // 保存记录
      if (this.decibelRecordDao) {
        await this.decibelRecordDao.insert(record);
      } else {
        throw new Error('DecibelRecordDao is null');
      }
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
      // 确保数据库已初始化
      await this.ensureInitialized();

      if (!this.decibelRecordDao) {
        throw new Error('DecibelRecordDao is null');
      }

      // 查询记录
      const entityClass = GlobalContext.getContext().getValue(GlobalContext.KEY_CLS) as Record<string, Object>;
      const properties = entityClass.DecibelRecord as Record<string, Property>;
      const query = this.decibelRecordDao.queryBuilder()
        .orderDesc(properties.timestamp)
        .limit(100)
        .buildCursor();
      return await query.list();
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
      // 确保数据库已初始化
      await this.ensureInitialized();

      if (!this.decibelRecordDao) {
        throw new Error('DecibelRecordDao is null');
      }

      // 先获取所有非收藏的记录，用于删除音频文件
      const entityClass = GlobalContext.getContext().getValue(GlobalContext.KEY_CLS) as Record<string, Object>;
      const properties = entityClass.DecibelRecord as Record<string, Property>;
      const query = this.decibelRecordDao.queryBuilder()
        .where(properties.isFavorite.eq(0))
        .buildCursor();
      const records = await query.list();

      // 删除所有相关的音频文件
      for (const record of records) {
        if (record.audioFilePath) {
          try {
            await this.fileService.deleteFile(record.audioFilePath);
          } catch (error) {
            console.error('删除音频文件失败:', error);
          }
        }
      }

      // 删除非收藏记录
      const deleteQuery = this.decibelRecordDao.queryBuilder()
        .where(properties.isFavorite.eq(0))
        .buildDelete();
      await deleteQuery.executeDeleteWithoutDetachingEntities();
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
      // 确保数据库已初始化
      await this.ensureInitialized();

      if (!this.decibelRecordDao) {
        throw new Error('DecibelRecordDao is null');
      }

      // 更新记录
      await this.decibelRecordDao.updateAsync(record);
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
      // 确保数据库已初始化
      await this.ensureInitialized();

      if (!this.decibelRecordDao) {
        throw new Error('DecibelRecordDao is null');
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
      await this.decibelRecordDao.deleteByKeyAsync(id);
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
      // 确保数据库已初始化
      await this.ensureInitialized();

      if (!this.decibelRecordDao) {
        throw new Error('DecibelRecordDao is null');
      }

      // 查询记录
      return await this.decibelRecordDao.load(id);
    } catch (error) {
      console.error('获取记录失败:', error);
      throw new Error('获取记录失败');
    }
  }
} 