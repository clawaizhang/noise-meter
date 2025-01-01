/**
 * 噪音检测历史记录
 */
export class DecibelRecord {
  id: string;
  timestamp: number;
  minDecibel: number;
  maxDecibel: number;
  avgDecibel: number;
  duration: number;
  values: number[];
  location?: string;
  audioData?: ArrayBuffer[];
  isFavorite: boolean;

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    values: number[],
    location?: string,
    audioData?: ArrayBuffer[]
  ) {
    this.id = new Date().getTime().toString();
    this.timestamp = new Date().getTime();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.values = values;
    this.location = location;
    this.audioData = audioData;
    this.isFavorite = false;
  }
} 