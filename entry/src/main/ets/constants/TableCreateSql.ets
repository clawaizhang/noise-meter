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
}