/**
 * 数据库表创建SQL常量
 */
export class TableCreateSql {
  /**
   * 分贝记录表
   */
  static readonly DECIBEL_RECORDS = `
    CREATE TABLE IF NOT EXISTS decibel_records (
      id TEXT PRIMARY KEY NOT NULL,
      timestamp INTEGER NOT NULL,
      minDecibel REAL NOT NULL,
      maxDecibel REAL NOT NULL,
      avgDecibel REAL NOT NULL,
      duration INTEGER NOT NULL,
      decibelValues TEXT NOT NULL,
      location TEXT,
      audioFilePath TEXT,
      isFavorite INTEGER DEFAULT 0
    )
  `;

  /**
   * 添加 weightingTypes 列到 decibel_records 表
   */
  static readonly ADD_WEIGHTING_TYPES_COLUMN = `
    ALTER TABLE decibel_records
    ADD COLUMN weightingTypes TEXT
  `;

  /**
   * 添加 comment 列到 decibel_records 表
   */
  static readonly ADD_COMMENT_COLUMN = `
    ALTER TABLE decibel_records
    ADD COLUMN comment TEXT
  `;

  /**
   * 为timestamp字段添加索引，加速排序查询
   */
  static readonly ADD_TIMESTAMP_INDEX = `
    CREATE INDEX IF NOT EXISTS idx_decibel_records_timestamp
    ON decibel_records(timestamp DESC)
  `;

  /**
   * 警报历史记录表
   * 存储所有触发的警报事件
   */
  static readonly ALERT_HISTORY = `
    CREATE TABLE IF NOT EXISTS alert_history (
      id TEXT PRIMARY KEY NOT NULL,
      startTime INTEGER NOT NULL,
      endTime INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      peakDecibel REAL NOT NULL,
      avgDecibel REAL NOT NULL,
      minDecibel REAL NOT NULL,
      threshold REAL NOT NULL,
      location TEXT,
      latitude REAL,
      longitude REAL,
      alertType TEXT NOT NULL,
      status TEXT NOT NULL,
      severity INTEGER NOT NULL,
      extraData TEXT,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL
    )
  `;

  /**
   * 为alert_history表的startTime字段添加索引
   */
  static readonly ADD_ALERT_HISTORY_STARTTIME_INDEX = `
    CREATE INDEX IF NOT EXISTS idx_alert_history_startTime
    ON alert_history(startTime DESC)
  `;

  /**
   * 为alert_history表的severity字段添加索引
   */
  static readonly ADD_ALERT_HISTORY_SEVERITY_INDEX = `
    CREATE INDEX IF NOT EXISTS idx_alert_history_severity
    ON alert_history(severity)
  `;

  /**
   * 警报历史采样数据表
   * 存储警报期间的详细分贝采样数据
   */
  static readonly ALERT_HISTORY_SAMPLES = `
    CREATE TABLE IF NOT EXISTS alert_history_samples (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      alertId TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      decibel REAL NOT NULL,
      FOREIGN KEY (alertId) REFERENCES alert_history(id) ON DELETE CASCADE
    )
  `;

  /**
   * 为alert_history_samples表的alertId字段添加索引
   */
  static readonly ADD_ALERT_HISTORY_SAMPLES_ALERTID_INDEX = `
    CREATE INDEX IF NOT EXISTS idx_alert_history_samples_alertId
    ON alert_history_samples(alertId)
  `;
}