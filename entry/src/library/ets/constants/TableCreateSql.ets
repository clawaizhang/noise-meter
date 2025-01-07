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
} 