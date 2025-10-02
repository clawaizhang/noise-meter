/**
 * 警报状态指示器组件
 * 显示环形进度、当前声级和阈值对比
 */

import { ALERT_COLORS, EnvironmentNoiseLevel } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct AlertsStatusIndicator {
  @Param @Require currentDecibel: number = 0;             // 当前声级
  @Param @Require alertThreshold: number = 70;            // 警报阈值
  @Param @Require isAlertEnabled: boolean = true;         // 警报是否启用

  @Local private animationTime: number = 0;               // 动画时间状态
  private animationInterval?: number;                     // 动画定时器

  // 计算进度百分比
  private getProgressPercent(): number {
    if (this.currentDecibel >= this.alertThreshold) {
      return 100;
    }
    const safeRange = this.alertThreshold - 30; // 假设安全范围为阈值-30dB
    const progress = ((this.currentDecibel - 30) / safeRange) * 100;
    return Math.min(Math.max(progress, 0), 100);
  }

  // 获取环境噪声等级
  private getEnvironmentLevel(): EnvironmentNoiseLevel {
    if (this.currentDecibel < 30) {
      return EnvironmentNoiseLevel.EXCELLENT;
    } else if (this.currentDecibel < 50) {
      return EnvironmentNoiseLevel.GOOD;
    } else if (this.currentDecibel < 70) {
      return EnvironmentNoiseLevel.FAIR;
    } else if (this.currentDecibel < 85) {
      return EnvironmentNoiseLevel.POOR;
    } else {
      return EnvironmentNoiseLevel.DANGEROUS;
    }
  }

  // 获取环境颜色
  private getEnvironmentColor(): Resource {
    const level = this.getEnvironmentLevel();
    switch (level) {
      case EnvironmentNoiseLevel.EXCELLENT:
        return ALERT_COLORS.SUCCESS;
      case EnvironmentNoiseLevel.GOOD:
        return $r('sys.color.ohos_id_color_palette5'); // 浅绿色
      case EnvironmentNoiseLevel.FAIR:
        return ALERT_COLORS.WARNING;
      case EnvironmentNoiseLevel.POOR:
        return ALERT_COLORS.ERROR;
      default:
        return ALERT_COLORS.ERROR;
    }
  }

  // 获取环境描述
  private getEnvironmentDescription(): string {
    const level = this.getEnvironmentLevel();
    switch (level) {
      case EnvironmentNoiseLevel.EXCELLENT:
        return '环境非常安静';
      case EnvironmentNoiseLevel.GOOD:
        return '环境良好';
      case EnvironmentNoiseLevel.FAIR:
        return '环境一般';
      case EnvironmentNoiseLevel.POOR:
        return '环境嘈杂';
      default:
        return '环境危险';
    }
  }

  // 获取警报状态描述
  private getAlertStatusDescription(): string {
    if (!this.isAlertEnabled) {
      return '警报已关闭';
    }
    
    if (this.currentDecibel >= this.alertThreshold) {
      return '警报触发中';
    } else if (this.currentDecibel >= this.alertThreshold - 10) {
      return '接近警报阈值';
    } else {
      return '环境安全';
    }
  }

  // 获取警报状态颜色
  private getAlertStatusColor(): Resource {
    if (!this.isAlertEnabled) {
      return $r('sys.color.font_secondary');
    }
    
    if (this.currentDecibel >= this.alertThreshold) {
      return ALERT_COLORS.ERROR;
    } else if (this.currentDecibel >= this.alertThreshold - 10) {
      return ALERT_COLORS.WARNING;
    } else {
      return ALERT_COLORS.SUCCESS;
    }
  }

  // 启动动画定时器
  private startAnimation() {
    this.animationInterval = setInterval(() => {
      this.animationTime = Date.now();
    }, 100); // 每100ms更新一次
  }

  // 停止动画定时器
  private stopAnimation() {
    if (this.animationInterval) {
      clearInterval(this.animationInterval);
      this.animationInterval = undefined;
    }
  }

  aboutToAppear() {
    this.startAnimation();
  }

  aboutToDisappear() {
    this.stopAnimation();
  }

  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 外环 - 警报进度
      Stack({ alignContent: Alignment.Center }) {
        // 背景环
        Circle({ width: 100, height: 100 })
          .stroke(ALERT_COLORS.BACKGROUND)
          .strokeWidth(8)
          .fill(Color.Transparent)

        // 进度环
        Circle({ width: 100, height: 100 })
          .stroke(this.getEnvironmentColor())
          .strokeWidth(8)
          .fill(Color.Transparent)
          .strokeDashArray([this.getProgressPercent() * 3.14, 314]) // 2πr ≈ 314
          .rotate({ x: 0, y: 0, z: 1, angle: -90 })
          .animation({
            duration: 300,
            curve: curves.springMotion()
          })

        // 内环 - 阈值指示
        Circle({ width: 70, height: 70 })
          .stroke(ALERT_COLORS.PRIMARY)
          .strokeWidth(4)
          .fill(Color.Transparent)

        // 中心数值
        Column({ space: 2 }) {
          Text(`${this.currentDecibel.toFixed(1)}`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Text('dB')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
      }

      // 状态描述
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.getAlertStatusDescription())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.getAlertStatusColor())
          .fontWeight(FontWeight.Medium)

        Text(this.getEnvironmentDescription())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}