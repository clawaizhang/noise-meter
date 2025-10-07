import { AppStorageV2, PersistenceV2, promptAction, EditableTitleBar, EditableLeftIconType } from '@kit.ArkUI';
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
export struct AudioCalibrationSettings {
  @Event onSave: () => void;
  @Event onClose: () => void;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local gridColumns: number = 1;
  @Local environmentNoise: number = 25; // 模拟环境噪声
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  // 临时状态变量
  @Local private tempCalibrationValue: number = 0;

  aboutToAppear() {
    // 初始化临时状态
    this.tempCalibrationValue = this.pk.calibration_value;
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
      totalDecibel += this.ak.dataProcessingState.processingDb;
      sampleCount += 1;

      if (this.calibrationProgress >= calibrationDuration) {
        clearInterval(calibrationInterval);
        this.finishCalibration(totalDecibel / sampleCount);
      }
    }, 1000);
  }

  private finishCalibration(averageDecibel: number) {
    this.isAutoCalibrating = false;
    const currentCalibrationValue = this.pk.calibration_value;
    
    // 正确的校准计算逻辑：
    // 设备读数 = 原始读数 + 当前校准值
    // 因此：原始读数 = 设备读数 - 当前校准值
    const rawDecibel = averageDecibel - currentCalibrationValue;
    
    // 新的校准值应该使：设备读数 ≈ 参考声级 + 新校准值
    // 所以：新校准值 = 参考声级 - 原始读数
    const newCalibrationValue = CALIBRATION_CONFIG.REFERENCE_LEVEL - rawDecibel;
    
    // 限制校准值在有效范围内
    const clampedValue = Math.max(
      CALIBRATION_CONFIG.MIN_CALIBRATION_VALUE,
      Math.min(CALIBRATION_CONFIG.MAX_CALIBRATION_VALUE, newCalibrationValue)
    );
    
    this.tempCalibrationValue = Math.round(clampedValue * 10) / 10; // 保留1位小数

    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.tempCalibrationValue}dB`,
      duration: 3000
    });
  }

  // 手动校准值变化处理 - 只更新临时状态
  private onManualCalibrationChange(value: number) {
    this.tempCalibrationValue = value;
  }

  // 计算校准进度百分比
  private getCalibrationProgressPercent(): number {
    return Math.round((this.calibrationProgress / CALIBRATION_CONFIG.AUTO_CALIBRATION_DURATION) * 100);
  }

  build() {
    Column({ space: 0 }) {
      // 使用EditableTitleBar提供标准的编辑界面标题栏
      EditableTitleBar({
        leftIconStyle: EditableLeftIconType.Cancel,
        title: '声级校准',
        isSaveIconRequired: true,
        onSave: () => {
          this.handleConfirm();
        },
        onCancel: () => {
          this.onClose();
        }
      })

      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 状态反馈区域
          CalibrationStatusIndicator({
            currentDecibel: this.ak.uiDisplayState.displayDb
          })

          // 核心校准控制区域
          Column({ space: DesignConstants.SPACING_LG }) {
            // 手动校准组件
            EnhancedManualCalibration({
              calibrationValue: this.tempCalibrationValue,
              onValueChange: (value: number) => {
                this.onManualCalibrationChange(value);
              }
            })

            // 自动校准组件
            ImprovedAutoCalibration({
              onStartCalibration: () => {
                this.startAutoCalibration();
              },
              calibrationValue: this.tempCalibrationValue,
              isCalibrating: this.isAutoCalibrating,
              calibrationProgress: this.getCalibrationProgressPercent(),
              countdown: this.countdown,
              environmentNoise: this.ak.uiDisplayState.displayDb
            })
          }

          // 专业内容区域
          ProfessionalContentPanel()
        }
        .width('100%')
        .margin({ bottom: 72 })
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_secondary'))
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  // 处理确认操作
  private handleConfirm() {
    // 应用临时状态到持久化存储
    this.pk.calibration_value = this.tempCalibrationValue;
    
    // 显示保存成功提示，显示具体的设置结果
    promptAction.showToast({
      message: `声级校准值已设置为：${this.tempCalibrationValue}dB`,
      duration: 2000
    });
    
    // 关闭弹窗
    this.onSave();
  }
}

export interface AudioCalibrationProps{
  onSave: () => void;
  onClose: () => void;
}

@Builder
export function AudioCalibrationSettingsBuilder(props:AudioCalibrationProps) {
  AudioCalibrationSettings(props)
}