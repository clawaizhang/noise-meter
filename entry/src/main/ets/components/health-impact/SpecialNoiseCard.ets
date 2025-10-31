/**
 * 特殊噪音检测卡片组件
 * 统一健康影响UI的重要组成部分，展示三种特殊噪音检测结果
 */
import { HealthRiskLevel, SpecialNoiseDetection, SpecialNoiseType } from "../../models/HealthImpactData";


@ComponentV2
export struct SpecialNoiseCard {
  @Param @Require specialNoiseDetection: SpecialNoiseDetection;
  @Local private animationProgress: number = 0;

  aboutToAppear(): void {
    // 初始化动画进度
    this.animationProgress = this.specialNoiseDetection.intensity;
  }

  aboutToUpdate(): void {
    // 当数据更新时，触发动画
    this.animateProgress(this.specialNoiseDetection.intensity);
  }

  /**
   * 动画效果：平滑过渡到新的强度值
   */
  private animateProgress(targetIntensity: number): void {
    animateTo({
      duration: 500,
      curve: Curve.EaseOut
    }, () => {
      this.animationProgress = targetIntensity;
    });
  }

  /**
   * 获取噪音类型对应的图标
   */
  private getNoiseTypeIcon(): string {
    switch (this.specialNoiseDetection.noiseType) {
      case SpecialNoiseType.IMPULSE:
        return '⚡';
      case SpecialNoiseType.LOW_FREQUENCY:
        return '📳';
      case SpecialNoiseType.COMBINED:
        return '🔊';
      default:
        return '🔇';
    }
  }

  /**
   * 获取风险等级对应的颜色
   */
  private getRiskColor(): Resource {
    const riskLevel = this.specialNoiseDetection.getRiskLevel();
    switch (riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return $r('sys.color.confirm');
      case HealthRiskLevel.GOOD:
        return $r('sys.color.ohos_id_color_palette5');
      case HealthRiskLevel.ATTENTION:
        return $r('sys.color.warning');
      case HealthRiskLevel.WARNING:
        return $r('sys.color.alert');
      case HealthRiskLevel.DANGER:
        return $r('sys.color.alert');
      default:
        return $r('sys.color.confirm');
    }
  }

  /**
   * 获取风险等级对应的背景颜色
   */
  private getRiskBackgroundColor(): Resource {
    const riskLevel = this.specialNoiseDetection.getRiskLevel();
    switch (riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return $r('sys.color.confirm');
      case HealthRiskLevel.GOOD:
        return $r('sys.color.background_emphasize');
      case HealthRiskLevel.ATTENTION:
        return $r('sys.color.ohos_id_color_palette9');
      case HealthRiskLevel.WARNING:
        return $r('sys.color.alert');
      case HealthRiskLevel.DANGER:
        return $r('sys.color.warning');
      default:
        return $r('sys.color.ohos_id_color_palette1');
    }
  }

  /**
   * 获取健康影响描述
   */
  private getHealthImpactDescription(): string {
    const intensity = this.specialNoiseDetection.intensity;
    
    switch (this.specialNoiseDetection.noiseType) {
      case SpecialNoiseType.IMPULSE:
        if (intensity < 30) return '对听力影响轻微';
        if (intensity < 60) return '可能引起暂时性听力下降';
        if (intensity < 80) return '可能造成永久性听力损伤';
        if (intensity < 95) return '高风险听力损伤';
        return '极高风险听力损伤';
        
      case SpecialNoiseType.LOW_FREQUENCY:
        if (intensity < 30) return '舒适度影响轻微';
        if (intensity < 60) return '可能引起不适感';
        if (intensity < 80) return '可能引起头晕、恶心';
        if (intensity < 95) return '严重影响舒适度';
        return '极强不适感，建议立即离开';
        
      case SpecialNoiseType.COMBINED:
        if (intensity < 30) return '复合影响轻微';
        if (intensity < 60) return '复合影响中等';
        if (intensity < 80) return '复合影响显著';
        if (intensity < 95) return '复合影响严重';
        return '复合影响极其严重';
        
      default:
        return '无特殊健康影响';
    }
  }

  /**
   * 获取防护建议
   */
  private getProtectionAdvice(): string {
    const intensity = this.specialNoiseDetection.intensity;
    
    switch (this.specialNoiseDetection.noiseType) {
      case SpecialNoiseType.IMPULSE:
        if (intensity < 30) return '无需特殊防护';
        if (intensity < 60) return '建议佩戴耳塞';
        if (intensity < 80) return '建议佩戴专业防护耳罩';
        if (intensity < 95) return '立即佩戴专业防护设备';
        return '立即离开环境并就医检查';
        
      case SpecialNoiseType.LOW_FREQUENCY:
        if (intensity < 30) return '无需特殊防护';
        if (intensity < 60) return '建议适当休息';
        if (intensity < 80) return '建议离开环境休息';
        if (intensity < 95) return '立即离开环境';
        return '立即离开并寻求医疗帮助';
        
      case SpecialNoiseType.COMBINED:
        if (intensity < 30) return '无需特殊防护';
        if (intensity < 60) return '建议全面防护措施';
        if (intensity < 80) return '建议立即采取防护措施';
        if (intensity < 95) return '立即采取全面防护';
        return '立即离开环境并全面检查';
        
      default:
        return '保持良好环境监测';
    }
  }

  /**
   * 渲染强度进度条
   */
  @Builder
  private renderIntensityProgress() {
    Column({ space: 8 }) {
      // 强度标签和数值
      Row({ space: 8 }) {
        Text('强度')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
        
        Text(`${Math.round(this.animationProgress)}%`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getRiskColor())
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      // 进度条背景
      Stack({ alignContent: Alignment.Start }) {
        // 背景条
        Row()
          .width('100%')
          .height(8)
          .backgroundColor($r('sys.color.comp_divider'))
          .borderRadius(4)

        // 进度条
        Row()
          .width(`${this.animationProgress}%`)
          .height(8)
          .backgroundColor(this.getRiskColor())
          .borderRadius(4)
      }
      .width('100%')
      .height(8)
    }
    .width('100%')
  }

  /**
   * 渲染脉冲噪音卡片
   */
  @Builder
  private renderImpulseNoiseCard() {
    Column({ space: 12 }) {
      // 标题行
      Row({ space: 8 }) {
        Text(this.getNoiseTypeIcon())
          .fontSize(20)
        
        Text('脉冲噪音检测')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 强度进度条
      this.renderIntensityProgress()

      // 详细信息
      Column({ space: 6 }) {
        // 持续时间
        Row({ space: 8 }) {
          Text('持续时间:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(`${this.specialNoiseDetection.duration}ms`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_primary'))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')

        // 检测状态
        Row({ space: 8 }) {
          Text('检测状态:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(this.specialNoiseDetection.isValid() ? '已检测' : '未检测')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.specialNoiseDetection.isValid() ? this.getRiskColor() : $r('sys.color.ohos_id_color_secondary'))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }
      .width('100%')

      // 健康影响
      Column({ space: 4 }) {
        Text('健康影响:')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .textAlign(TextAlign.Start)
          .width('100%')
        
        Text(this.getHealthImpactDescription())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getRiskColor())
          .textAlign(TextAlign.Start)
          .width('100%')
          .lineHeight(16)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(this.getRiskBackgroundColor())
    .borderRadius(12)
    .border({
      width: 1,
      color: this.getRiskColor()
    })
    .width('100%')
  }

  /**
   * 渲染低频共振卡片
   */
  @Builder
  private renderLowFrequencyCard() {
    Column({ space: 12 }) {
      // 标题行
      Row({ space: 8 }) {
        Text(this.getNoiseTypeIcon())
          .fontSize(20)
        
        Text('低频共振检测')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 强度进度条
      this.renderIntensityProgress()

      // 详细信息
      Column({ space: 6 }) {
        // 主要频率
        Row({ space: 8 }) {
          Text('主要频率:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(`${this.specialNoiseDetection.frequency.toFixed(1)} Hz`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_primary'))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')

        // 舒适度影响
        Row({ space: 8 }) {
          Text('舒适度影响:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(this.getHealthImpactDescription())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getRiskColor())
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')

        // 检测状态
        Row({ space: 8 }) {
          Text('检测状态:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(this.specialNoiseDetection.isValid() ? '共振检测中' : '未检测')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.specialNoiseDetection.isValid() ? this.getRiskColor() : $r('sys.color.ohos_id_color_secondary'))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(this.getRiskBackgroundColor())
    .borderRadius(12)
    .border({
      width: 1,
      color: this.getRiskColor()
    })
    .width('100%')
  }

  /**
   * 渲染持续暴露卡片
   */
  @Builder
  private renderContinuousExposureCard() {
    Column({ space: 12 }) {
      // 标题行
      Row({ space: 8 }) {
        Text(this.getNoiseTypeIcon())
          .fontSize(20)
        
        Text('持续暴露检测')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 强度进度条
      this.renderIntensityProgress()

      // 详细信息
      Column({ space: 6 }) {
        // 暴露时间
        Row({ space: 8 }) {
          Text('暴露时间:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(`${Math.round(this.specialNoiseDetection.duration / 1000)}s`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_primary'))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')

        // 风险等级
        Row({ space: 8 }) {
          Text('风险等级:')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text(this.specialNoiseDetection.getRiskLevel())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getRiskColor())
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }
      .width('100%')

      // 防护建议
      Column({ space: 4 }) {
        Text('防护建议:')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .textAlign(TextAlign.Start)
          .width('100%')
        
        Text(this.getProtectionAdvice())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getRiskColor())
          .textAlign(TextAlign.Start)
          .width('100%')
          .lineHeight(16)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(this.getRiskBackgroundColor())
    .borderRadius(12)
    .border({
      width: 1,
      color: this.getRiskColor()
    })
    .width('100%')
  }

  build() {
    Column({ space: 12 }) {
      if (!this.specialNoiseDetection.isValid()) {
        // 无特殊噪音检测时的显示
        Column({ space: 8 }) {
          Text('🔇')
            .fontSize(24)
          
          Text('无特殊噪音检测')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
          
          Text('当前环境未检测到特殊噪音类型')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .textAlign(TextAlign.Center)
        }
        .padding(24)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .borderRadius(12)
        .border({
          width: 1,
          color: $r('sys.color.comp_border_color')
        })
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 根据噪音类型显示对应的卡片 - 使用if-else条件语句
        if (this.specialNoiseDetection.noiseType === SpecialNoiseType.IMPULSE) {
          this.renderImpulseNoiseCard()
        } else if (this.specialNoiseDetection.noiseType === SpecialNoiseType.LOW_FREQUENCY) {
          this.renderLowFrequencyCard()
        } else if (this.specialNoiseDetection.noiseType === SpecialNoiseType.COMBINED) {
          this.renderContinuousExposureCard()
        } else {
          this.renderImpulseNoiseCard()
        }
      }
    }
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .borderRadius(16)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
    .onClick(() => {
      // 点击卡片可以查看详细信息
      console.log('特殊噪音检测卡片被点击:', this.specialNoiseDetection.getTypeDescription())
    })
  }
}