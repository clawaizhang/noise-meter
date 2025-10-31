/**
 * 统一健康影响数据模型
 * 基于暴露数据和阈值配置，提供完整的健康风险评估
 */

// 健康风险等级枚举
export enum HealthRiskLevel {
  EXCELLENT = 'excellent',     // 优秀
  GOOD = 'good',               // 良好  
  ATTENTION = 'attention',     // 注意
  WARNING = 'warning',         // 警告
  DANGER = 'danger'            // 危险
}

// 特殊噪音检测类型
export enum SpecialNoiseType {
  NONE = 'none',               // 无特殊噪音
  IMPULSE = 'impulse',         // 脉冲噪音
  LOW_FREQUENCY = 'low_frequency', // 低频共振噪音
  COMBINED = 'combined'        // 复合噪音
}

// 特殊噪音检测结果
@ObservedV2
export class SpecialNoiseDetection {
  @Trace noiseType: SpecialNoiseType = SpecialNoiseType.NONE;  // 噪音类型
  @Trace intensity: number = 0;                                // 强度 (0-100)
  @Trace duration: number = 0;                                 // 持续时间 (毫秒)
  @Trace frequency: number = 0;                                // 主要频率 (Hz)
  @Trace detectedAt: number = 0;                               // 检测时间戳

  constructor(
    noiseType: SpecialNoiseType = SpecialNoiseType.NONE,
    intensity: number = 0,
    duration: number = 0,
    frequency: number = 0
  ) {
    this.noiseType = noiseType;
    this.intensity = intensity;
    this.duration = duration;
    this.frequency = frequency;
    this.detectedAt = Date.now();
  }

  /**
   * 检查是否为有效检测
   */
  public isValid(): boolean {
    return this.intensity > 0 && 
           this.duration > 0 && 
           this.detectedAt > 0;
  }

  /**
   * 获取噪音类型描述
   */
  public getTypeDescription(): string {
    switch (this.noiseType) {
      case SpecialNoiseType.IMPULSE:
        return '脉冲噪音';
      case SpecialNoiseType.LOW_FREQUENCY:
        return '低频共振噪音';
      case SpecialNoiseType.COMBINED:
        return '复合噪音';
      default:
        return '无特殊噪音';
    }
  }

  /**
   * 获取风险等级
   */
  public getRiskLevel(): HealthRiskLevel {
    if (this.intensity < 30) {
      return HealthRiskLevel.EXCELLENT;
    } else if (this.intensity < 60) {
      return HealthRiskLevel.GOOD;
    } else if (this.intensity < 80) {
      return HealthRiskLevel.ATTENTION;
    } else if (this.intensity < 95) {
      return HealthRiskLevel.WARNING;
    } else {
      return HealthRiskLevel.DANGER;
    }
  }

  /**
   * 重置检测数据
   */
  public reset(): void {
    this.noiseType = SpecialNoiseType.NONE;
    this.intensity = 0;
    this.duration = 0;
    this.frequency = 0;
    this.detectedAt = Date.now();
  }
}

@ObservedV2
export class HealthImpactData {
  @Trace exposurePercentage: number = 0;                       // 暴露剂量百分比 (0-100)
  @Trace currentDecibel: number = 0;                           // 当前分贝值
  @Trace riskLevel: HealthRiskLevel = HealthRiskLevel.EXCELLENT; // 健康风险等级
  @Trace specialNoiseDetection: SpecialNoiseDetection = new SpecialNoiseDetection(); // 特殊噪音检测
  @Trace lastUpdateTime: number = 0;                           // 最后更新时间
  @Trace healthScore: number = 100;                            // 健康评分 (0-100)
  @Trace recommendation: string = '';                          // 健康建议

  constructor(
    exposurePercentage: number = 0,
    currentDecibel: number = 0,
    riskLevel: HealthRiskLevel = HealthRiskLevel.EXCELLENT,
    specialNoiseDetection: SpecialNoiseDetection = new SpecialNoiseDetection()
  ) {
    this.exposurePercentage = exposurePercentage;
    this.currentDecibel = currentDecibel;
    this.riskLevel = riskLevel;
    this.specialNoiseDetection = specialNoiseDetection;
    this.lastUpdateTime = Date.now();
    this.calculateHealthScore();
    this.generateRecommendation();
  }

  /**
   * 计算健康评分
   */
  private calculateHealthScore(): void {
    let score = 100;

    // 基于暴露剂量扣分
    if (this.exposurePercentage > 0) {
      score -= Math.min(this.exposurePercentage * 0.5, 50);
    }

    // 基于当前分贝值扣分
    if (this.currentDecibel > 60) {
      const excess = this.currentDecibel - 60;
      score -= Math.min(excess * 0.5, 30);
    }

    // 基于特殊噪音检测扣分
    if (this.specialNoiseDetection.isValid()) {
      score -= Math.min(this.specialNoiseDetection.intensity * 0.3, 20);
    }

    this.healthScore = Math.max(0, Math.round(score));
  }

  /**
   * 生成健康建议
   */
  private generateRecommendation(): void {
    if (this.healthScore >= 90) {
      this.recommendation = '环境优秀，继续保持';
    } else if (this.healthScore >= 75) {
      this.recommendation = '环境良好，注意监测';
    } else if (this.healthScore >= 60) {
      this.recommendation = '环境一般，建议适当休息';
    } else if (this.healthScore >= 40) {
      this.recommendation = '环境较差，建议离开或采取防护措施';
    } else {
      this.recommendation = '环境危险，请立即离开';
    }

    // 添加特殊噪音建议
    if (this.specialNoiseDetection.isValid()) {
      switch (this.specialNoiseDetection.noiseType) {
        case SpecialNoiseType.IMPULSE:
          this.recommendation += '，检测到脉冲噪音，请注意保护听力';
          break;
        case SpecialNoiseType.LOW_FREQUENCY:
          this.recommendation += '，检测到低频共振，可能引起不适';
          break;
        case SpecialNoiseType.COMBINED:
          this.recommendation += '，检测到复合噪音，建议全面防护';
          break;
      }
    }
  }

  /**
   * 计算健康风险等级
   */
  public calculateRiskLevel(): HealthRiskLevel {
    // 基于健康评分确定风险等级
    if (this.healthScore >= 90) {
      return HealthRiskLevel.EXCELLENT;
    } else if (this.healthScore >= 75) {
      return HealthRiskLevel.GOOD;
    } else if (this.healthScore >= 60) {
      return HealthRiskLevel.ATTENTION;
    } else if (this.healthScore >= 40) {
      return HealthRiskLevel.WARNING;
    } else {
      return HealthRiskLevel.DANGER;
    }
  }

  /**
   * 更新数据
   */
  public update(
    exposurePercentage: number,
    currentDecibel: number,
    specialNoiseDetection?: SpecialNoiseDetection
  ): void {
    this.exposurePercentage = exposurePercentage;
    this.currentDecibel = currentDecibel;
    
    if (specialNoiseDetection) {
      this.specialNoiseDetection = specialNoiseDetection;
    }

    this.calculateHealthScore();
    this.riskLevel = this.calculateRiskLevel();
    this.generateRecommendation();
    this.lastUpdateTime = Date.now();
  }

  /**
   * 复制数据到目标对象
   */
  public copyTo(target: HealthImpactData): void {
    target.exposurePercentage = this.exposurePercentage;
    target.currentDecibel = this.currentDecibel;
    target.riskLevel = this.riskLevel;
    target.healthScore = this.healthScore;
    target.recommendation = this.recommendation;
    target.lastUpdateTime = this.lastUpdateTime;
    
    // 复制特殊噪音检测
    const noiseDetection = new SpecialNoiseDetection();
    noiseDetection.noiseType = this.specialNoiseDetection.noiseType;
    noiseDetection.intensity = this.specialNoiseDetection.intensity;
    noiseDetection.duration = this.specialNoiseDetection.duration;
    noiseDetection.frequency = this.specialNoiseDetection.frequency;
    noiseDetection.detectedAt = this.specialNoiseDetection.detectedAt;
    target.specialNoiseDetection = noiseDetection;
  }

  /**
   * 重置数据
   */
  public reset(): void {
    this.exposurePercentage = 0;
    this.currentDecibel = 0;
    this.riskLevel = HealthRiskLevel.EXCELLENT;
    this.specialNoiseDetection.reset();
    this.healthScore = 100;
    this.recommendation = '环境优秀，继续保持';
    this.lastUpdateTime = Date.now();
  }

  /**
   * 检查数据是否有效
   */
  public isValid(): boolean {
    return this.lastUpdateTime > 0 && 
           this.exposurePercentage >= 0 && 
           this.exposurePercentage <= 100 &&
           this.currentDecibel >= 0 &&
           this.healthScore >= 0 &&
           this.healthScore <= 100;
  }

  /**
   * 获取风险等级颜色
   */
  public getRiskColor(): Resource {
    switch (this.riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return $r('sys.color.confirm');     // 绿色
      case HealthRiskLevel.GOOD:
        return $r('sys.color.ohos_id_color_palette5'); // 浅蓝色
      case HealthRiskLevel.ATTENTION:
        return $r('sys.color.warning');     // 黄色
      case HealthRiskLevel.WARNING:
        return $r('sys.color.alert');       // 橙色
      case HealthRiskLevel.DANGER:
        return $r('sys.color.alert');       // 红色
      default:
        return $r('sys.color.confirm');
    }
  }

  /**
   * 获取风险等级描述
   */
  public getRiskDescription(): string {
    switch (this.riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return '优秀';
      case HealthRiskLevel.GOOD:
        return '良好';
      case HealthRiskLevel.ATTENTION:
        return '注意';
      case HealthRiskLevel.WARNING:
        return '警告';
      case HealthRiskLevel.DANGER:
        return '危险';
      default:
        return '未知';
    }
  }
}

// 默认健康影响数据实例
export const DEFAULT_HEALTH_IMPACT_DATA: HealthImpactData = new HealthImpactData();