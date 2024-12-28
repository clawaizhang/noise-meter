import { DecibelRecord } from '../models/DecibelRecord';
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const STORE_NAME = 'decibel_records';
const RECORDS_KEY = 'records';

/**
 * 噪音检测历史记录服务
 */
export class DecibelRecordService {
  private context: common.Context;
  private preferences?: dataPreferences.Preferences;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * 初始化存储服务
   */
  private async ensurePreferences(): Promise<dataPreferences.Preferences> {
    if (!this.preferences) {
      try {
        this.preferences = await dataPreferences.getPreferences(this.context, STORE_NAME);
      } catch (error) {
        console.error('初始化存储服务失败:', error);
        throw new Error('初始化存储服务失败');
      }
    }
    return this.preferences;
  }

  /**
   * 保存历史记录
   */
  async saveRecord(record: DecibelRecord): Promise<void> {
    const preferences = await this.ensurePreferences();

    try {
      // 获取现有记录
      const recordsStr = await preferences.get(RECORDS_KEY, '[]') as string;
      const records: DecibelRecord[] = JSON.parse(recordsStr);

      // 添加新记录到开头
      records.unshift(record);

      // 只保留最近100条记录
      if (records.length > 100) {
        records.length = 100;
      }

      // 保存记录
      await preferences.put(RECORDS_KEY, JSON.stringify(records));
      await preferences.flush();
    } catch (error) {
      console.error('保存历史记录失败:', error);
      throw new Error('保存历史记录失败');
    }
  }

  /**
   * 获取所有历史记录
   */
  async getRecords(): Promise<DecibelRecord[]> {
    const preferences = await this.ensurePreferences();

    try {
      const recordsStr = await preferences.get(RECORDS_KEY, '[]') as string;
      return JSON.parse(recordsStr);
    } catch (error) {
      console.error('获取历史记录失败:', error);
      throw new Error('获取历史记录失败');
    }
  }

  /**
   * 清空历史记录
   */
  async clearRecords(): Promise<void> {
    const preferences = await this.ensurePreferences();

    try {
      await preferences.put(RECORDS_KEY, '[]');
      await preferences.flush();
    } catch (error) {
      console.error('清空历史记录失败:', error);
      throw new Error('清空历史记录失败');
    }
  }
} 