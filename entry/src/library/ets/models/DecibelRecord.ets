/**
 * 噪音检测历史记录
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
    audioFilePath?: string
  ) {
    const now = new Date().getTime();
    this.id = now.toString();
    this.timestamp = now;
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