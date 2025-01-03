/**
 * 分贝记录模型
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
  @Trace isFavorite: boolean;

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    values: number[],
    location?: string,
    audioFilePath?: string,
    isFavorite: boolean = false
  ) {
    this.id = new Date().getTime().toString();
    this.timestamp = new Date().getTime();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.values = values;
    this.location = location;
    this.audioFilePath = audioFilePath;
    this.isFavorite = isFavorite;
  }
} 