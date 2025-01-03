import { Id, NotNull, Entity, Columns, ColumnType, Index } from '@ohos/dataorm';
import util from '@ohos.util';

@Entity('DECIBEL_RECORDS')
@ObservedV2
export class DecibelRecord {
  @Id()
  @Columns({ columnName: 'ID', types: ColumnType.str })
  id: string;

  @NotNull()
  @Index()
  @Columns({ columnName: 'TIMESTAMP', types: ColumnType.num })
  timestamp: number;

  @NotNull()
  @Columns({ columnName: 'MIN_DECIBEL', types: ColumnType.real })
  minDecibel: number;

  @NotNull()
  @Columns({ columnName: 'MAX_DECIBEL', types: ColumnType.real })
  maxDecibel: number;

  @NotNull()
  @Columns({ columnName: 'AVG_DECIBEL', types: ColumnType.real })
  avgDecibel: number;

  @NotNull()
  @Columns({ columnName: 'DURATION', types: ColumnType.num })
  duration: number;

  @NotNull()
  @Columns({ columnName: 'VALUES', types: ColumnType.str })
  values: number[];

  @Columns({ columnName: 'LOCATION', types: ColumnType.str })
  location?: string;

  @Columns({ columnName: 'AUDIO_FILE_PATH', types: ColumnType.str })
  audioFilePath?: string;

  @Trace
  @NotNull()
  @Columns({ columnName: 'IS_FAVORITE', types: ColumnType.num })
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
} 