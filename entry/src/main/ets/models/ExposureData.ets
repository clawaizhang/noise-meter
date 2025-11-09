/**
 * 噪音暴露数据模型
 * 纯粹的暴露统计，不包含其他无关数据
 */

@ObservedV2
export class ExposureData {
  @Trace exposurePercentage: number = 0;  // 暴露剂量百分比 (0-100)
  @Trace remainingSafeTime: string = '';  // 剩余安全时间 (格式: "X小时Y分钟")
  @Trace todayPeak: number = 0;           // 今日峰值分贝
  @Trace todayAverage: number = 0;        // 今日平均分贝
  @Trace lastUpdateTime: number = 0;      // 最后更新时间

  constructor(
    exposurePercentage: number = 0,
    remainingSafeTime: string = '',
    todayPeak: number = 0,
    todayAverage: number = 0
  ) {
    this.exposurePercentage = exposurePercentage;
    this.remainingSafeTime = remainingSafeTime;
    this.todayPeak = todayPeak;
    this.todayAverage = todayAverage;
    this.lastUpdateTime = Date.now();
  }

  copyTo(target:ExposureData){
    target.exposurePercentage = this.exposurePercentage;
    target.remainingSafeTime = this.remainingSafeTime;
    target.todayPeak = this.todayPeak;
    target.todayAverage = this.todayAverage;
    target.lastUpdateTime = this.lastUpdateTime;
  }

  /**
   * 重置数据
   */
  public reset(): void {
    this.exposurePercentage = 0;
    this.remainingSafeTime = '';
    this.todayPeak = 0;
    this.todayAverage = 0;
    this.lastUpdateTime = Date.now();
  }

  /**
   * 检查数据是否有效
   */
  public isValid(): boolean {
    return this.lastUpdateTime > 0 && 
           this.exposurePercentage >= 0 && 
           this.exposurePercentage <= 100;
  }

  /**
   * 获取健康评级
   */
  public getHealthRating(): Resource {
    if (this.exposurePercentage < 30) {
      return $r('app.string.health_rating_excellent');
    } else if (this.exposurePercentage < 60) {
      return $r('app.string.health_rating_good');
    } else if (this.exposurePercentage < 80) {
      return $r('app.string.health_rating_fair');
    } else {
      return $r('app.string.health_rating_attention');
    }
  }

  /**
   * 获取暴露剂量颜色
   */
  public getExposureColor(): Resource {
    if (this.exposurePercentage < 30) {
      return $r('sys.color.confirm');     // 绿色
    } else if (this.exposurePercentage < 60) {
      return $r('sys.color.warning');     // 黄色
    } else if (this.exposurePercentage < 80) {
      return $r('sys.color.alert');       // 橙色
    } else {
      return $r('sys.color.alert');       // 红色
    }
  }
}