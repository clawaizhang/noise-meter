import { AppStorageV2, PersistenceV2, promptAction } from '@kit.ArkUI';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppKeys } from '../../models/AppKeys';
import { CALIBRATION_CONFIG } from '../../constants/CalibrationConstants';
import { EnhancedManualCalibration } from '../../components/calibration/EnhancedManualCalibration';
import { ImprovedAutoCalibration } from '../../components/calibration/ImprovedAutoCalibration';
import { CalibrationStatusIndicator } from '../../components/calibration/CalibrationStatusIndicator';
import { ProfessionalContentPanel } from '../../components/calibration/ProfessionalContentPanel';

@ComponentV2
export struct AudioAnalysisSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local gridColumns: number = 1;
  @Local environmentNoise: number = 25; // 模拟环境噪声
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  private startAutoCalibration() {
    this.isAutoCalibrating = true;
    this.countdown = CALIBRATION_CONFIG.COUNTDOWN_DURATION;

    // 倒计时
    const countdownInterval = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(countdownInterval);
        this.beginCalibration();
      }
    }, 1000);
  }

  private beginCalibration() {
    const calibrationDuration = CALIBRATION_CONFIG.AUTO_CALIBRATION_DURATION;
    this.calibrationProgress = 0;
    let totalDecibel = 0;
    let sampleCount = 0;

    // 开始校准
    const calibrationInterval = setInterval(() => {
      this.calibrationProgress += 1;
      totalDecibel += this.as.db;
      sampleCount += 1;

      if (this.calibrationProgress >= calibrationDuration) {
        clearInterval(calibrationInterval);
        this.finishCalibration(totalDecibel / sampleCount);
      }
    }, 1000);
  }

  private finishCalibration(averageDecibel: number) {
    this.isAutoCalibrating = false;
    const newCalibrationValue = CALIBRATION_CONFIG.REFERENCE_LEVEL - averageDecibel;
    this.pk.calibration_value = Math.round(newCalibrationValue * 10) / 10; // 保留1位小数

    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.pk.calibration_value}dB`,
      duration: 3000
    });
  }

  // 手动校准值变化处理
  private onManualCalibrationChange(value: number) {
    this.pk.calibration_value = value;
  }

  // 计算校准进度百分比
  private getCalibrationProgressPercent(): number {
    return Math.round((this.calibrationProgress / CALIBRATION_CONFIG.AUTO_CALIBRATION_DURATION) * 100);
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 状态反馈区域
      CalibrationStatusIndicator({
        calibrationProgress: this.getCalibrationProgressPercent(),
        currentDecibel: this.as.db,
        isCalibrating: this.isAutoCalibrating
      })

      // 核心校准控制区域
      Column({ space: DesignConstants.SPACING_LG }) {
        // 手动校准组件
        EnhancedManualCalibration({
          calibrationValue: this.pk.calibration_value,
          onValueChange: (value: number) => {
            this.onManualCalibrationChange(value);
          }
        })

        // 自动校准组件
        ImprovedAutoCalibration({
          onStartCalibration: () => {
            this.startAutoCalibration();
          },
          calibrationValue: this.pk.calibration_value,
          isCalibrating: this.isAutoCalibrating,
          calibrationProgress: this.getCalibrationProgressPercent(),
          countdown: this.countdown,
          environmentNoise: this.as.db
        })
      }

      // 专业内容区域
      ProfessionalContentPanel()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}


@Builder
export function AudioAnalysisSettingsBuilder() {
  AudioAnalysisSettings()
}