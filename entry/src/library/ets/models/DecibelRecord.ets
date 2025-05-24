import util from '@ohos.util';
import relationalStore from '@ohos.data.relationalStore';
import { WeightingType } from '../constants/WeightingConstants';

/**
 * 分贝值范围定义
 */
interface DecibelRange {
  min: number;
  max: number;
  desc: string;
}

/**
 * 分贝值统计信息
 */
interface DecibelCount extends DecibelRange {
  count: number;
}

/**
 * 分贝值百分比信息
 */
interface DecibelPercentage extends DecibelCount {
  percentage: number;
}

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
  decibelValues: number[];
  location?: string;
  audioFilePath?: string;
  @Trace
  isFavorite: boolean;
  weightingTypes: WeightingType[];
  comment: string; // 备注字段

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    decibelValues: number[],
    location?: string,
    audioFilePath?: string,
    comment: string = ''
  ) {
    this.id = util.generateRandomUUID();
    this.timestamp = Date.now();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.decibelValues = decibelValues;
    this.location = location;
    this.audioFilePath = audioFilePath;
    this.isFavorite = false;
    this.weightingTypes = [];
    this.comment = comment;
  }

  static getTableName(): string {
    return 'decibel_records';
  }

  static fromResultSet(resultSet: relationalStore.ResultSet): DecibelRecord {
    const record = new DecibelRecord(
        resultSet.getDouble(resultSet.getColumnIndex('minDecibel')),
        resultSet.getDouble(resultSet.getColumnIndex('maxDecibel')),
        resultSet.getDouble(resultSet.getColumnIndex('avgDecibel')),
        resultSet.getLong(resultSet.getColumnIndex('duration')),
        JSON.parse(resultSet.getString(resultSet.getColumnIndex('decibelValues'))),
        resultSet.getString(resultSet.getColumnIndex('location')),
        resultSet.getString(resultSet.getColumnIndex('audioFilePath')),
        resultSet.getString(resultSet.getColumnIndex('comment')) || ''
    );
    record.id = resultSet.getString(resultSet.getColumnIndex('id'));
    record.timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
    record.isFavorite = resultSet.getLong(resultSet.getColumnIndex('isFavorite')) === 1;
    const weightingTypesStr = resultSet.getString(resultSet.getColumnIndex('weightingTypes'));
    record.weightingTypes = weightingTypesStr ? JSON.parse(weightingTypesStr) : [];
    return record;
  }

  toValuesBucket(): relationalStore.ValuesBucket {
    const valueBucket: relationalStore.ValuesBucket = {
      'id': this.id,
      'timestamp': this.timestamp,
      'minDecibel': this.minDecibel,
      'maxDecibel': this.maxDecibel,
      'avgDecibel': this.avgDecibel,
      'duration': this.duration,
      'decibelValues': JSON.stringify(this.decibelValues),
      'location': this.location ?? null,
      'audioFilePath': this.audioFilePath ?? null,
      'isFavorite': this.isFavorite ? 1 : 0,
      'weightingTypes': JSON.stringify(this.weightingTypes),
      'comment': this.comment || null
    };
    return valueBucket;
  }

  /**
   * 获取分贝值分布描述
   */
  getDecibelDistributionDescription(): string {
    if (!this.decibelValues || this.decibelValues.length === 0) {
      return '';
    }

    // 定义分贝值范围
    const ranges: DecibelRange[] = [
      { min: 0, max: 30, desc: '安静环境' },
      { min: 30, max: 50, desc: '低噪音环境' },
      { min: 50, max: 60, desc: '普通室内环境' },
      { min: 60, max: 70, desc: '正常交谈环境' },
      { min: 70, max: 80, desc: '嘈杂环境' },
      { min: 80, max: 90, desc: '很吵环境' },
      { min: 90, max: Infinity, desc: '高噪音环境' }
    ];

    // 统计每个范围的数量
    const counts: DecibelCount[] = ranges.map(range => {
      const count: DecibelCount = {
        min: range.min,
        max: range.max,
        desc: range.desc,
        count: this.decibelValues.filter(v => v >= range.min && v < range.max).length
      };
      return count;
    });

    // 计算百分比
    const total = this.decibelValues.length;
    const percentages: DecibelPercentage[] = counts.map(item => {
      const percentage: DecibelPercentage = {
        min: item.min,
        max: item.max,
        desc: item.desc,
        count: item.count,
        percentage: (item.count / total) * 100
      };
      return percentage;
    });

    // 找出主要噪音范围（占比超过20%的）
    const mainRanges = percentages.filter(item => item.percentage >= 20)
      .sort((a, b) => b.percentage - a.percentage);

    // 生成描述
    let description = '在检测期间，';
    
    if (mainRanges.length === 0) {
      description += '噪音水平变化较大，没有明显的主导范围。';
    } else if (mainRanges.length === 1) {
      description += `主要处于${mainRanges[0].desc}，占总时长的${Math.round(mainRanges[0].percentage)}%。`;
    } else {
      const rangeDescs = mainRanges.map(range => 
        `${range.desc}(${Math.round(range.percentage)}%)`
      );
      description += `噪音水平主要分布在${rangeDescs.join('和')}。`;
    }

    // 添加最大值描述
    if (this.maxDecibel >= 90) {
      description += '期间出现了较大的噪音峰值，可能会对听力造成损害，建议采取防护措施。';
    } else if (this.maxDecibel >= 80) {
      description += '噪音峰值较高，长期处于该环境可能会感到不适，建议减少停留时间。';
    } else if (this.maxDecibel >= 70) {
      description += '最大噪音在可接受范围内，但仍建议注意噪音防护。';
    } else {
      description += '整体噪音水平适中，属于较为舒适的声音环境。';
    }

    return description;
  }
} 