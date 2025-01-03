import util from '@ohos.util';
import relationalStore from '@ohos.data.relationalStore';

/**
 * 分贝记录实体类
 */
@ObservedV2
export class DecibelRecord {
  id: string;
  timestamp: number;
  minDecibel: number;
  maxDecibel: number;
  avgDecibel: number;
  duration: number;
  values: number[];
  location?: string;
  audioFilePath?: string;
  @Trace
  isFavorite: boolean;

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    values: number[],
    location?: string,
    audioFilePath?: string
  ) {
    this.id = util.generateRandomUUID();
    this.timestamp = Date.now();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.values = values;
    this.location = location;
    this.audioFilePath = audioFilePath;
    this.isFavorite = false;
  }

  static getTableName(): string {
    return 'decibel_records';
  }

  static getCreateTableSql(): string {
    return `
      CREATE TABLE IF NOT EXISTS ${DecibelRecord.getTableName()} (
        id TEXT PRIMARY KEY NOT NULL,
        timestamp INTEGER NOT NULL,
        minDecibel REAL NOT NULL,
        maxDecibel REAL NOT NULL,
        avgDecibel REAL NOT NULL,
        duration INTEGER NOT NULL,
        values TEXT NOT NULL,
        location TEXT,
        audioFilePath TEXT,
        isFavorite INTEGER DEFAULT 0
      )
    `;
  }

  static fromResultSet(resultSet: relationalStore.ResultSet): DecibelRecord {
    const record = new DecibelRecord(
      resultSet.getDouble(resultSet.getColumnIndex('minDecibel')),
      resultSet.getDouble(resultSet.getColumnIndex('maxDecibel')),
      resultSet.getDouble(resultSet.getColumnIndex('avgDecibel')),
      resultSet.getLong(resultSet.getColumnIndex('duration')),
      JSON.parse(resultSet.getString(resultSet.getColumnIndex('values'))),
      resultSet.getString(resultSet.getColumnIndex('location')),
      resultSet.getString(resultSet.getColumnIndex('audioFilePath'))
    );
    record.id = resultSet.getString(resultSet.getColumnIndex('id'));
    record.timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
    record.isFavorite = resultSet.getLong(resultSet.getColumnIndex('isFavorite')) === 1;
    return record;
  }

  toValuesBucket(): relationalStore.ValuesBucket {
    const valueBucket: relationalStore.ValuesBucket = {
      id: this.id,
      timestamp: this.timestamp,
      minDecibel: this.minDecibel,
      maxDecibel: this.maxDecibel,
      avgDecibel: this.avgDecibel,
      duration: this.duration,
      values: JSON.stringify(this.values),
      location: this.location ?? null,
      audioFilePath: this.audioFilePath ?? null,
      isFavorite: this.isFavorite ? 1 : 0
    };
    return valueBucket;
  }
} 