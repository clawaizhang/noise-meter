/**
 * 警报历史服务
 * 提供警报记录的存储、查询、统计和管理功能
 */

import { RelationalStoreService } from './RelationalStoreService';
import { LocationService } from './LocationService';
import { 
  AlertRecord, 
  AlertRecordStatus, 
  AlertType, 
  AlertSeverity,
  AlertSummary,
  AlertQueryOptions,
  AlertHistoryPage,
  DbValues,
  AlertRecordInit
} from '../models/AlertRecord';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@ohos.base';
import { generateUUID } from '../utils/UUIDGenerator';
import relationalStore from '@ohos.data.relationalStore';

const TAG = 'AlertHistoryService';
const DOMAIN = 0xFF00;

/**
 * 分贝采样点
 */
export interface DecibelSample {
  timestamp: number;  // 采样时间戳
  decibel: number;    // 分贝值
}

/**
 * 活跃警报会话
 * 用于跟踪正在进行的警报
 */
interface ActiveAlertSession {
  id: string;
  startTime: number;
  peakDecibel: number;
  minDecibel: number;
  decibelSum: number;
  decibelCount: number;
  threshold: number;
  alertType: AlertType;
  location: string;
  latitude: number;
  longitude: number;
  samples: DecibelSample[];  // 采样数据数组
  lastSampleTime: number;    // 上次采样时间（用于控制采样频率）
}

/**
 * 位置信息
 */
interface LocationInfoData {
  address: string;
  latitude: number;
  longitude: number;
}

/**
 * 活跃会话信息
 */
interface ActiveSessionInfo {
  id: string;
  startTime: number;
  duration: number;
}

/**
 * 每日统计
 */
interface DailyStats {
  count: number;
  duration: number;
  peak: number;
}

/**
 * 警报历史服务类
 * 单例模式，提供完整的警报数据管理功能
 */
export class AlertHistoryService {
  private static instance: AlertHistoryService;
  private dbService: RelationalStoreService;
  private locationService: LocationService;
  private activeSession: ActiveAlertSession | null = null;
  private isInitialized: boolean = false;

  private constructor() {
    this.dbService = RelationalStoreService.getInstance();
    this.locationService = LocationService.getInstance();
  }

  /**
   * 获取服务实例
   */
  public static getInstance(): AlertHistoryService {
    if (!AlertHistoryService.instance) {
      AlertHistoryService.instance = new AlertHistoryService();
    }
    return AlertHistoryService.instance;
  }

  /**
   * 初始化服务
   */
  public async initialize(): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, '警报历史服务初始化成功');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `初始化失败: ${err.message}`);
      return false;
    }
  }

  // ==================== 核心CRUD操作 ====================

  /**
   * 开始一个新的警报会话
   * 当检测到噪音超过阈值时调用
   */
  public async startAlertSession(
    threshold: number,
    currentDecibel: number,
    alertType: AlertType = AlertType.THRESHOLD_BREACH
  ): Promise<string> {
    try {
      // 如果已有活跃会话，先结束它
      if (this.activeSession) {
        await this.endAlertSession(currentDecibel);
      }

      // 获取当前位置
      const locationInfo = await this.getCurrentLocation();

      // 创建新会话
      const now = Date.now();
      const session: ActiveAlertSession = {
        id: generateUUID(),
        startTime: now,
        peakDecibel: currentDecibel,
        minDecibel: currentDecibel,
        decibelSum: currentDecibel,
        decibelCount: 1,
        threshold: threshold,
        alertType: alertType,
        location: locationInfo ? locationInfo.address : '',
        latitude: locationInfo ? locationInfo.latitude : 0,
        longitude: locationInfo ? locationInfo.longitude : 0,
        samples: [{ timestamp: now, decibel: currentDecibel }],  // 初始采样点
        lastSampleTime: now
      };

      this.activeSession = session;
      hilog.info(DOMAIN, TAG, `警报会话开始: ${session.id}, 阈值: ${threshold}dB`);

      return session.id;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `开始警报会话失败: ${err.message}`);
      return '';
    }
  }

  /**
   * 更新活跃警报会话的数据
   * 在警报持续期间定期调用
   */
  public updateActiveSession(currentDecibel: number): void {
    if (!this.activeSession) {
      return;
    }

    // 更新峰值
    if (currentDecibel > this.activeSession.peakDecibel) {
      this.activeSession.peakDecibel = currentDecibel;
    }

    // 更新最低值
    if (currentDecibel < this.activeSession.minDecibel) {
      this.activeSession.minDecibel = currentDecibel;
    }

    // 更新累加值用于计算平均值
    this.activeSession.decibelSum += currentDecibel;
    this.activeSession.decibelCount++;

    // 添加采样点（每3秒采样一次，避免数据量过大）
    const now = Date.now();
    if (now - this.activeSession.lastSampleTime >= 3000) {
      this.activeSession.samples.push({
        timestamp: now,
        decibel: currentDecibel
      });
      this.activeSession.lastSampleTime = now;
    }
  }

  /**
   * 结束当前警报会话
   * 当噪音恢复正常时调用
   */
  public async endAlertSession(finalDecibel: number): Promise<AlertRecord | null> {
    if (!this.activeSession) {
      return null;
    }

    try {
      const session = this.activeSession;
      const endTime = Date.now();
      const duration = Math.floor((endTime - session.startTime) / 1000);

      // 计算平均值
      let avgDecibel = finalDecibel;
      if (session.decibelCount > 0) {
        avgDecibel = Math.round((session.decibelSum / session.decibelCount) * 10) / 10;
      }

      // 创建警报记录
      const recordInit: AlertRecordInit = {
        id: session.id,
        startTime: session.startTime,
        endTime: endTime,
        duration: duration,
        peakDecibel: Math.max(session.peakDecibel, finalDecibel),
        minDecibel: session.minDecibel,
        avgDecibel: avgDecibel,
        threshold: session.threshold,
        location: session.location,
        latitude: session.latitude,
        longitude: session.longitude,
        alertType: session.alertType,
        status: AlertRecordStatus.COMPLETED,
        severity: AlertRecord.calculateSeverity(session.peakDecibel, session.threshold),
        createdAt: session.startTime,
        updatedAt: endTime
      };
      const record = new AlertRecord(recordInit);

      // 保存到数据库
      await this.saveAlertRecord(record);

      // 保存采样数据
      await this.saveAlertSamples(session.id, session.samples);

      // 清除活跃会话
      this.activeSession = null;

      hilog.info(DOMAIN, TAG, `警报会话结束: ${record.id}, 持续: ${duration}秒, 峰值: ${record.peakDecibel}dB`);

      return record;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `结束警报会话失败: ${err.message}`);
      return null;
    }
  }

  /**
   * 保存警报记录到数据库
   */
  public async saveAlertRecord(record: AlertRecord): Promise<boolean> {
    try {
      const values = record.toDbValues();
      
      const columns = 'id, startTime, endTime, duration, peakDecibel, avgDecibel, minDecibel, threshold, location, latitude, longitude, alertType, status, severity, extraData, createdAt, updatedAt';
      const placeholders = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?';
      
      const sql = `INSERT INTO alert_history (${columns}) VALUES (${placeholders})`;
      const params: Array<string | number | null> = [
        values.id,
        values.startTime,
        values.endTime,
        values.duration,
        values.peakDecibel,
        values.avgDecibel,
        values.minDecibel,
        values.threshold,
        values.location,
        values.latitude,
        values.longitude,
        values.alertType,
        values.status,
        values.severity,
        values.extraData,
        values.createdAt,
        values.updatedAt
      ];

      await this.dbService.execute(sql, params);
      hilog.info(DOMAIN, TAG, `保存警报记录成功: ${record.id}`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `保存警报记录失败: ${err.message}`);
      return false;
    }
  }

  /**
   * 查询警报记录
   */
  public async queryAlertRecords(options: AlertQueryOptions): Promise<AlertRecord[]> {
    try {
      let sql = 'SELECT * FROM alert_history WHERE 1=1';
      const params: Array<string | number> = [];

      // 应用查询条件
      if (options.startTime !== undefined) {
        sql += ' AND startTime >= ?';
        params.push(options.startTime);
      }

      if (options.endTime !== undefined) {
        sql += ' AND startTime <= ?';
        params.push(options.endTime);
      }

      if (options.alertType !== undefined) {
        sql += ' AND alertType = ?';
        params.push(options.alertType);
      }

      if (options.severity !== undefined) {
        sql += ' AND severity = ?';
        params.push(options.severity);
      }

      if (options.status !== undefined) {
        sql += ' AND status = ?';
        params.push(options.status);
      }

      // 排序
      const orderBy = options.orderBy || 'startTime';
      const direction = options.orderDirection || 'DESC';
      sql += ` ORDER BY ${orderBy} ${direction}`;

      // 分页
      if (options.limit !== undefined) {
        sql += ' LIMIT ?';
        params.push(options.limit);
      }

      if (options.offset !== undefined) {
        sql += ' OFFSET ?';
        params.push(options.offset);
      }

      const resultSet = await this.dbService.query(sql, params);
      const records: AlertRecord[] = [];

      while (resultSet.goToNextRow()) {
        const row: DbValues = {
          id: this.getStringFromResultSet(resultSet, 'id'),
          startTime: this.getNumberFromResultSet(resultSet, 'startTime'),
          endTime: this.getNumberFromResultSet(resultSet, 'endTime'),
          duration: this.getNumberFromResultSet(resultSet, 'duration'),
          peakDecibel: this.getNumberFromResultSet(resultSet, 'peakDecibel'),
          avgDecibel: this.getNumberFromResultSet(resultSet, 'avgDecibel'),
          minDecibel: this.getNumberFromResultSet(resultSet, 'minDecibel'),
          threshold: this.getNumberFromResultSet(resultSet, 'threshold'),
          location: this.getNullableStringFromResultSet(resultSet, 'location'),
          latitude: this.getNullableNumberFromResultSet(resultSet, 'latitude'),
          longitude: this.getNullableNumberFromResultSet(resultSet, 'longitude'),
          alertType: this.getStringFromResultSet(resultSet, 'alertType'),
          status: this.getStringFromResultSet(resultSet, 'status'),
          severity: this.getNumberFromResultSet(resultSet, 'severity'),
          extraData: this.getNullableStringFromResultSet(resultSet, 'extraData'),
          createdAt: this.getNumberFromResultSet(resultSet, 'createdAt'),
          updatedAt: this.getNumberFromResultSet(resultSet, 'updatedAt')
        };
        
        records.push(AlertRecord.fromResultSet(row));
      }

      resultSet.close();
      return records;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `查询警报记录失败: ${err.message}`);
      return [];
    }
  }

  /**
   * 从结果集获取字符串
   */
  private getStringFromResultSet(resultSet: relationalStore.ResultSet, columnName: string): string {
    const index = resultSet.getColumnIndex(columnName);
    const value = resultSet.getValue(index);
    return value ? String(value) : '';
  }

  /**
   * 从结果集获取可空字符串
   */
  private getNullableStringFromResultSet(resultSet: relationalStore.ResultSet, columnName: string): string | null {
    const index = resultSet.getColumnIndex(columnName);
    const value = resultSet.getValue(index);
    if (value === null || value === undefined) {
      return null;
    }
    return String(value);
  }

  /**
   * 从结果集获取数字
   */
  private getNumberFromResultSet(resultSet: relationalStore.ResultSet, columnName: string): number {
    const index = resultSet.getColumnIndex(columnName);
    const value = resultSet.getValue(index);
    return value ? Number(value) : 0;
  }

  /**
   * 从结果集获取可空数字
   */
  private getNullableNumberFromResultSet(resultSet: relationalStore.ResultSet, columnName: string): number | null {
    const index = resultSet.getColumnIndex(columnName);
    const value = resultSet.getValue(index);
    if (value === null || value === undefined) {
      return null;
    }
    return Number(value);
  }

  /**
   * 分页查询警报历史
   */
  public async queryAlertHistoryPage(
    page: number = 1,
    pageSize: number = 20,
    options: AlertQueryOptions = {}
  ): Promise<AlertHistoryPage> {
    try {
      const offset = (page - 1) * pageSize;
      
      // 查询总数
      let countSql = 'SELECT COUNT(*) as total FROM alert_history WHERE 1=1';
      const countParams: Array<string | number> = [];

      if (options.startTime !== undefined) {
        countSql += ' AND startTime >= ?';
        countParams.push(options.startTime);
      }
      if (options.endTime !== undefined) {
        countSql += ' AND startTime <= ?';
        countParams.push(options.endTime);
      }

      const countResult = await this.dbService.query(countSql, countParams);
      let total = 0;
      if (countResult.goToFirstRow()) {
        const totalValue = countResult.getValue(countResult.getColumnIndex('total'));
        total = totalValue ? Number(totalValue) : 0;
      }
      countResult.close();

      // 查询数据
      const queryOptions: AlertQueryOptions = {
        startTime: options.startTime,
        endTime: options.endTime,
        alertType: options.alertType,
        severity: options.severity,
        status: options.status,
        orderBy: options.orderBy,
        orderDirection: options.orderDirection,
        limit: pageSize,
        offset: offset
      };
      
      const records = await this.queryAlertRecords(queryOptions);

      return {
        records: records,
        total: total,
        hasMore: offset + records.length < total
      };
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `分页查询失败: ${err.message}`);
      return { records: [], total: 0, hasMore: false };
    }
  }

  /**
   * 根据ID获取单条记录
   */
  public async getAlertRecordById(id: string): Promise<AlertRecord | null> {
    try {
      const sql = 'SELECT * FROM alert_history WHERE id = ?';
      const resultSet = await this.dbService.query(sql, [id]);

      if (resultSet.goToFirstRow()) {
        const row: DbValues = {
          id: this.getStringFromResultSet(resultSet, 'id'),
          startTime: this.getNumberFromResultSet(resultSet, 'startTime'),
          endTime: this.getNumberFromResultSet(resultSet, 'endTime'),
          duration: this.getNumberFromResultSet(resultSet, 'duration'),
          peakDecibel: this.getNumberFromResultSet(resultSet, 'peakDecibel'),
          avgDecibel: this.getNumberFromResultSet(resultSet, 'avgDecibel'),
          minDecibel: this.getNumberFromResultSet(resultSet, 'minDecibel'),
          threshold: this.getNumberFromResultSet(resultSet, 'threshold'),
          location: this.getNullableStringFromResultSet(resultSet, 'location'),
          latitude: this.getNullableNumberFromResultSet(resultSet, 'latitude'),
          longitude: this.getNullableNumberFromResultSet(resultSet, 'longitude'),
          alertType: this.getStringFromResultSet(resultSet, 'alertType'),
          status: this.getStringFromResultSet(resultSet, 'status'),
          severity: this.getNumberFromResultSet(resultSet, 'severity'),
          extraData: this.getNullableStringFromResultSet(resultSet, 'extraData'),
          createdAt: this.getNumberFromResultSet(resultSet, 'createdAt'),
          updatedAt: this.getNumberFromResultSet(resultSet, 'updatedAt')
        };
        
        resultSet.close();
        return AlertRecord.fromResultSet(row);
      }

      resultSet.close();
      return null;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `获取记录失败: ${err.message}`);
      return null;
    }
  }

  /**
   * 删除警报记录
   */
  public async deleteAlertRecord(id: string): Promise<boolean> {
    try {
      const sql = 'DELETE FROM alert_history WHERE id = ?';
      await this.dbService.execute(sql, [id]);
      hilog.info(DOMAIN, TAG, `删除警报记录: ${id}`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `删除记录失败: ${err.message}`);
      return false;
    }
  }

  /**
   * 批量删除记录
   */
  public async deleteAlertRecords(ids: string[]): Promise<boolean> {
    try {
      if (ids.length === 0) return true;

      // 构建占位符
      let placeholders = '';
      for (let i = 0; i < ids.length; i++) {
        if (i > 0) placeholders += ',';
        placeholders += '?';
      }
      
      const sql = `DELETE FROM alert_history WHERE id IN (${placeholders})`;
      await this.dbService.execute(sql, ids);
      
      hilog.info(DOMAIN, TAG, `批量删除 ${ids.length} 条记录`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `批量删除失败: ${err.message}`);
      return false;
    }
  }

  /**
   * 清空所有记录
   */
  public async clearAllRecords(): Promise<boolean> {
    try {
      const sql = 'DELETE FROM alert_history';
      await this.dbService.execute(sql);
      hilog.info(DOMAIN, TAG, '清空所有警报记录');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `清空记录失败: ${err.message}`);
      return false;
    }
  }

  // ==================== 统计查询 ====================

  /**
   * 获取今日警报摘要
   */
  public async getTodaySummary(): Promise<AlertSummary> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const startOfDay = today.getTime();

    return this.getSummary(startOfDay, Date.now());
  }

  /**
   * 获取指定时间范围的警报摘要
   */
  public async getSummary(startTime: number, endTime: number): Promise<AlertSummary> {
    try {
      const summary = new AlertSummary();

      // 查询记录
      const queryOptions: AlertQueryOptions = {
        startTime: startTime,
        endTime: endTime,
        orderBy: 'startTime',
        orderDirection: 'DESC'
      };
      
      const records = await this.queryAlertRecords(queryOptions);

      summary.totalCount = records.length;

      if (records.length === 0) {
        return summary;
      }

      // 计算统计数据
      let totalDecibel = 0;
      let maxDecibel = 0;
      const hourDistribution: number[] = [];
      // 初始化24小时分布
      for (let i = 0; i < 24; i++) {
        hourDistribution.push(0);
      }

      for (const record of records) {
        summary.totalDuration += record.duration;
        totalDecibel += record.peakDecibel;
        
        if (record.peakDecibel > maxDecibel) {
          maxDecibel = record.peakDecibel;
        }

        // 严重程度分布
        if (record.severity === AlertSeverity.LOW) {
          summary.severityDistributionLow++;
        } else if (record.severity === AlertSeverity.MEDIUM) {
          summary.severityDistributionMedium++;
        } else if (record.severity === AlertSeverity.HIGH) {
          summary.severityDistributionHigh++;
        } else if (record.severity === AlertSeverity.CRITICAL) {
          summary.severityDistributionCritical++;
        }

        // 时段统计
        const hour = new Date(record.startTime).getHours();
        if (hour >= 0 && hour < 24) {
          hourDistribution[hour]++;
        }
      }

      summary.peakDecibel = maxDecibel;
      summary.avgDecibel = Math.round((totalDecibel / records.length) * 10) / 10;
      
      // 设置今日统计（当查询的是今日数据时）
      summary.todayCount = records.length;
      summary.todayDuration = summary.totalDuration;

      // 找出最常发生的时段
      let maxCount = 0;
      let mostFrequentHour = -1;
      for (let i = 0; i < 24; i++) {
        if (hourDistribution[i] > maxCount) {
          maxCount = hourDistribution[i];
          mostFrequentHour = i;
        }
      }
      summary.mostFrequentHour = mostFrequentHour;

      return summary;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `获取统计摘要失败: ${err.message}`);
      return new AlertSummary();
    }
  }

  /**
   * 获取指定日期的警报统计
   */
  public async getDailyStats(date: Date): Promise<DailyStats> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const queryOptions: AlertQueryOptions = {
      startTime: startOfDay.getTime(),
      endTime: endOfDay.getTime()
    };
    
    const records = await this.queryAlertRecords(queryOptions);

    let duration = 0;
    let peak = 0;

    for (const record of records) {
      duration += record.duration;
      if (record.peakDecibel > peak) {
        peak = record.peakDecibel;
      }
    }

    return {
      count: records.length,
      duration: duration,
      peak: peak
    };
  }

  /**
   * 获取最近的警报记录
   */
  public async getRecentAlerts(limit: number = 10, offset: number = 0): Promise<AlertRecord[]> {
    const queryOptions: AlertQueryOptions = {
      limit: limit,
      offset: offset,
      orderBy: 'startTime',
      orderDirection: 'DESC'
    };
    return this.queryAlertRecords(queryOptions);
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取当前位置信息
   */
  private async getCurrentLocation(): Promise<LocationInfoData | null> {
    try {
      // 这里简化处理，实际应该从LocationService获取
      // 考虑到权限和性能，可能在警报开始时不获取位置
      return null;
    } catch {
      return null;
    }
  }

  /**
   * 检查是否有活跃警报会话
   */
  public hasActiveSession(): boolean {
    return this.activeSession !== null;
  }

  /**
   * 获取活跃会话信息
   */
  public getActiveSession(): ActiveSessionInfo | null {
    if (!this.activeSession) {
      return null;
    }

    return {
      id: this.activeSession.id,
      startTime: this.activeSession.startTime,
      duration: Math.floor((Date.now() - this.activeSession.startTime) / 1000)
    };
  }

  /**
   * 强制取消当前警报会话（不保存）
   */
  public cancelActiveSession(): void {
    if (this.activeSession) {
      hilog.info(DOMAIN, TAG, `取消活跃警报会话: ${this.activeSession.id}`);
      this.activeSession = null;
    }
  }

  // ==================== 采样数据管理 ====================

  /**
   * 保存警报采样数据
   */
  private async saveAlertSamples(alertId: string, samples: DecibelSample[]): Promise<boolean> {
    if (samples.length === 0) {
      return true;
    }

    try {
      // 使用批量插入提高效率
      const placeholders = samples.map(() => '(?, ?, ?)').join(', ');
      const sql = `INSERT INTO alert_history_samples (alertId, timestamp, decibel) VALUES ${placeholders}`;
      
      const params: Array<string | number> = [];
      for (const sample of samples) {
        params.push(alertId, sample.timestamp, sample.decibel);
      }

      await this.dbService.execute(sql, params);
      hilog.info(DOMAIN, TAG, `保存警报采样数据: ${alertId}, ${samples.length} 个采样点`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `保存采样数据失败: ${err.message}`);
      return false;
    }
  }

  /**
   * 获取警报的采样数据
   */
  public async getAlertSamples(alertId: string): Promise<DecibelSample[]> {
    try {
      const sql = 'SELECT * FROM alert_history_samples WHERE alertId = ? ORDER BY timestamp ASC';
      const resultSet = await this.dbService.query(sql, [alertId]);
      
      const samples: DecibelSample[] = [];
      while (resultSet.goToNextRow()) {
        const timestamp = this.getNumberFromResultSet(resultSet, 'timestamp');
        const decibel = this.getNumberFromResultSet(resultSet, 'decibel');
        samples.push({ timestamp, decibel });
      }
      
      resultSet.close();
      return samples;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `获取采样数据失败: ${err.message}`);
      return [];
    }
  }

  /**
   * 删除警报的采样数据
   */
  public async deleteAlertSamples(alertId: string): Promise<boolean> {
    try {
      const sql = 'DELETE FROM alert_history_samples WHERE alertId = ?';
      await this.dbService.execute(sql, [alertId]);
      hilog.info(DOMAIN, TAG, `删除警报采样数据: ${alertId}`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `删除采样数据失败: ${err.message}`);
      return false;
    }
  }
}
