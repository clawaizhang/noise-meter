import { AudioAnalysisMode } from '../common/AudioConfig';
import {
  BehaviorSubject,
  Subject,
  Subscription,
  interval,
  map,
  scan,
  tap,
  filter,
  switchMap,
  takeUntil,
  distinctUntilChanged
} from 'rxjs';

/**
 * 统计状态接口
 */
export interface StatisticsState {
  minDecibel: number;
  maxDecibel: number;
  avgDecibel: number;
  dbCount: number;
  dbSum: number;
  values: number[];
}

/**
 * 报警状态接口
 */
export interface AlarmState {
  isNoiseAlarm: boolean;
  isAlarmActive: boolean;
}

/**
 * RxJS 统计服务类
 * 使用响应式编程处理分贝统计和报警逻辑
 */
export class StatisticsService {
  // 输入数据流
  private decibelValueSubject = new Subject<number>();
  // 状态管理
  private statisticsStateSubject = new BehaviorSubject<StatisticsState>({
    minDecibel: 0,
    maxDecibel: 0,
    avgDecibel: 0,
    dbCount: 0,
    dbSum: 0,
    values: []
  });
  private alarmStateSubject = new BehaviorSubject<AlarmState>({
    isNoiseAlarm: false,
    isAlarmActive: false
  });
  // 配置
  private currentAudioAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
  private noiseThreshold: number = 80;
  private noiseAlarmEnabled: boolean = true;
  // 订阅管理
  private statisticsSubscription?: Subscription;
  private alarmSubscription?: Subscription;
  private alarmBlinkSubscription?: Subscription;
  // 公共可观察对象
  public statisticsState$ = this.statisticsStateSubject.asObservable();
  public alarmState$ = this.alarmStateSubject.asObservable();

  /**
   * 更新分贝值
   */
  public updateDecibelValue(value: number): void {
    this.decibelValueSubject.next(value);
  }

  /**
   * 设置音频分析模式
   */
  public setAudioAnalysisMode(mode: AudioAnalysisMode): void {
    this.currentAudioAnalysisMode = mode;
  }

  /**
   * 设置噪音报警配置
   */
  public setAlarmConfig(threshold: number, enabled: boolean): void {
    this.noiseThreshold = threshold;
    this.noiseAlarmEnabled = enabled;
  }

  /**
   * 启动统计服务
   */
  public start(): void {
    this.stop(); // 确保先停止之前的订阅

    // 统计计算管道
    this.statisticsSubscription = this.decibelValueSubject.pipe(
      filter(value => value > 0), // 只处理有效值
      scan((state: StatisticsState, value: number) => {
        return this.calculateStatistics(state, value);
      }, this.statisticsStateSubject.value),
      distinctUntilChanged((prev, curr) =>
      prev.minDecibel === curr.minDecibel &&
        prev.maxDecibel === curr.maxDecibel &&
        prev.avgDecibel === curr.avgDecibel
      )
    ).subscribe(state => {
      this.statisticsStateSubject.next(state);
    });

    // 报警处理管道
    this.alarmSubscription = this.decibelValueSubject.pipe(
      filter(value => value > 0 && this.noiseAlarmEnabled),
      map(value => value > this.noiseThreshold),
      distinctUntilChanged(),
      switchMap(shouldAlarm => {
        if (shouldAlarm) {
          // 启动闪烁效果
          return interval(300).pipe(
            map((index) => {
              let alarm: AlarmState = {
                isNoiseAlarm: index % 2 === 0,
                isAlarmActive: true
              };
              return alarm;
            }),
            takeUntil(this.decibelValueSubject.pipe(
              filter(value => value <= this.noiseThreshold || !this.noiseAlarmEnabled)
            ))
          );
        } else {
          // 停止报警
          return [{
            isNoiseAlarm: false,
            isAlarmActive: false
          }];
        }
      })
    ).subscribe(alarmState => {
      this.alarmStateSubject.next(alarmState);
    });
  }

  /**
   * 停止统计服务
   */
  public stop(): void {
    if (this.statisticsSubscription) {
      this.statisticsSubscription.unsubscribe();
      this.statisticsSubscription = undefined;
    }

    if (this.alarmSubscription) {
      this.alarmSubscription.unsubscribe();
      this.alarmSubscription = undefined;
    }

    if (this.alarmBlinkSubscription) {
      this.alarmBlinkSubscription.unsubscribe();
      this.alarmBlinkSubscription = undefined;
    }

    // 重置报警状态
    this.alarmStateSubject.next({
      isNoiseAlarm: false,
      isAlarmActive: false
    });
  }

  /**
   * 重置统计状态
   */
  public reset(): void {
    this.statisticsStateSubject.next({
      minDecibel: 0,
      maxDecibel: 0,
      avgDecibel: 0,
      dbCount: 0,
      dbSum: 0,
      values: []
    });

    this.alarmStateSubject.next({
      isNoiseAlarm: false,
      isAlarmActive: false
    });
  }

  /**
   * 获取当前统计状态
   */
  public getStatisticsState(): StatisticsState {
    return this.statisticsStateSubject.value;
  }

  /**
   * 获取当前报警状态
   */
  public getAlarmState(): AlarmState {
    return this.alarmStateSubject.value;
  }

  /**
   * 计算统计信息
   */
  private calculateStatistics(state: StatisticsState, value: number): StatisticsState {
    let newState: StatisticsState = {
      minDecibel: state.minDecibel,
      maxDecibel: state.maxDecibel,
      avgDecibel: state.avgDecibel,
      dbCount: state.dbCount,
      dbSum: state.dbSum,
      values: state.values
    };
    if (newState.dbCount === 0) {
      // 第一次检测到的值作为初始值
      newState.minDecibel = value;
      newState.maxDecibel = value;
      newState.avgDecibel = value;
    } else {
      // 更新最小值
      if (value < newState.minDecibel) {
        newState.minDecibel = value;
      }
      // 更新最大值
      if (value > newState.maxDecibel) {
        newState.maxDecibel = value;
      }
    }

    // 时间计权模式特殊处理
    if (this.currentAudioAnalysisMode === AudioAnalysisMode.FAST_TIME_WEIGHTING && newState.dbCount <= 5) {
      newState.maxDecibel = newState.minDecibel;
      if (newState.values.length > 0) {
        newState.values.shift();
        newState.values.unshift(newState.minDecibel);
      }
    } else if (this.currentAudioAnalysisMode === AudioAnalysisMode.IMPULSE_TIME_WEIGHTING && newState.dbCount <= 10) {
      newState.maxDecibel = newState.minDecibel;
      if (newState.values.length > 0) {
        newState.values.shift();
        newState.values.unshift(newState.minDecibel);
      }
    }

    // 更新平均值
    newState.dbSum += value;
    newState.dbCount++;
    newState.avgDecibel = Math.round(newState.dbSum / newState.dbCount);

    // 更新值数组
    newState.values.push(value);

    return newState;
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    this.stop();
    this.decibelValueSubject.complete();
    this.statisticsStateSubject.complete();
    this.alarmStateSubject.complete();
  }
}