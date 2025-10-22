import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';
import { Throttle } from '../../utils/Debounce';
import { WeightingType } from '../../constants/WeightingConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import {
  AudioCalibrationProps,
  AudioCalibrationSettingsBuilder
} from '../../pages/settings/AudioCalibrationNavigation';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../../pages/settings/AlertsSettingsNavigation';
import {
  FrequencyWeightingDialogBuilder,
  FrequencyWeightingDialogParams,
} from '../frequency-weighting/FrequencyWeightingDialog';
import {
  AutoSaveDialogParams,
  AutoSaveSettings,
  AutoSaveSettingsDialogBuilder,
} from '../auto-save/AutoSaveSettingsDialog';
import {
  TimeWeightingDialogBuilder, TimeWeightingDialogParams,
} from '../time-weighting/TimeWeightingDialog';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { AudioControllerService } from '../../services/AudioControllerService';
import { AudioService, AudioServiceState } from '../../services/AudioService';
import { InputDialog } from '../decibel-meter/InputDialog';
import {
  AudioControllerEventType,
  StartRecordingEvent,
  PauseRecordingEvent,
  ResetDataEvent,
  StopRecordingEvent,
  StopRecordingPayload
} from '../../models/AudioControllerEvents';
import { AudioControllerLifecycleState, StateTransitionEvent } from '../../models/AudioControllerLifecycleState';

// 工具功能卡片配置
interface ToolCardConfig {
  title: string;
  icon: Resource;
  description: string;
  status?: string;
  statusColor?: Resource;
  onTap: () => void;
}

// 按钮状态配置
interface ButtonState {
  enabled: boolean;
  text: string;
  backgroundColor: Resource;
}

// 按钮状态集合
interface ButtonStates {
  startButton: ButtonState;
  pauseButton: ButtonState;
  resetButton: ButtonState;
  saveButton: ButtonState;
}

@ComponentV2
export struct ToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Local private currentLocation: LocationInfo | null = null;
  @Local private controllerState: AudioControllerLifecycleState = AudioControllerLifecycleState.CONTROLLER_IDLE;
  @Local private isSaving: boolean = false;
  @Local private saveAnimationOpacity: number = 1.0;
  @Local private inputDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildInputDialog,
    cancel: () => {
      console.info('[ToolsContent] 输入对话框已取消');
    },
    autoCancel: true
  });
  @Local private confirmDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildConfirmDialog,
    cancel: () => {
      console.info('[ToolsContent] 确认对话框已取消');
    },
    autoCancel: true
  });

  aboutToAppear(): void {
    this.initializeStateListener();
  }

  aboutToDisappear(): void {
  }

  // 状态监听初始化
  private initializeStateListener(): void {
    const audioController = AudioControllerService.getInstance(this.ak, this.pk);
    audioController.onStateChangeFromExternal((event: StateTransitionEvent) => {
      this.controllerState = event.toState;
      console.info(`[ToolsContent] 状态机状态变更: ${event.fromState} -> ${event.toState}`);
    });
  }

  // 按钮状态计算函数
  @Computed
  private get ButtonStates(): ButtonStates {
    const startButton: ButtonState = {
      enabled: this.controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ||
               this.controllerState === AudioControllerLifecycleState.CONTROLLER_ERROR,
      text: '开始检测',
      backgroundColor: this.controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ?
                      $r('sys.color.font_emphasize') : $r('sys.color.font_secondary')
    };
    
    const pauseButton: ButtonState = {
      enabled: this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING,
      text: '暂停',
      backgroundColor: this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING ?
                      $r('sys.color.alert') : $r('sys.color.font_secondary')
    };
    
    const resetButton: ButtonState = {
      enabled: this.controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ||
               this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING ||
               this.controllerState === AudioControllerLifecycleState.CONTROLLER_ERROR,
      text: '重置',
      backgroundColor: $r('sys.color.comp_background_secondary')
    };
    
    const saveButton: ButtonState = {
      enabled: this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING,
      text: this.isSaving ? '保存中...' : '保存',
      backgroundColor: this.isSaving ? $r('sys.color.font_secondary') : $r('sys.color.confirm')
    };
    
    const buttonStates: ButtonStates = {
      startButton: startButton,
      pauseButton: pauseButton,
      resetButton: resetButton,
      saveButton: saveButton
    };
    
    return buttonStates;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 页面标题
      this.buildPageHeader()

      // 操作按钮区域
      this.buildActionButtons()

      // 工具功能卡片区
      this.buildToolsCards()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_MD)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildPageHeader() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('实用工具')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text('辅助功能和设备管理')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildActionButtons() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('音频检测控制')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Row({ space: DesignConstants.SPACING_MD }) {
        // 开始检测按钮
        Button(this.ButtonStates.startButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.ButtonStates.startButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.ButtonStates.startButton.enabled)
          .onClick(() => {
            this.startDetection();
          })

        // 暂停按钮
        Button(this.ButtonStates.pauseButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.ButtonStates.pauseButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.ButtonStates.pauseButton.enabled)
          .onClick(() => {
            this.pauseDetection();
          })

        // 重置按钮
        Button(this.ButtonStates.resetButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.ButtonStates.resetButton.backgroundColor)
          .fontColor($r('sys.color.font_primary'))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.ButtonStates.resetButton.enabled)
          .onClick(() => {
            this.showResetConfirmation();
          })

        // 保存按钮
        Button(this.ButtonStates.saveButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.ButtonStates.saveButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.ButtonStates.saveButton.enabled && !this.isSaving)
          .opacity(this.saveAnimationOpacity)
          .onClick(() => {
            this.showSaveDialog();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 状态显示
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('状态:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text(this.getDetectionStatusText())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.getDetectionStatusColor())
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildToolsCards() {
    GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
      // 测量工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '声级校准',
          icon: $r('app.media.ic_calibration'),
          description: '自动和手动校准',
          status: `当前: ${this.pk.calibration_value}dB`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAudioCalibration()
          }
        })
      }

      // 分析工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '频率加权',
          icon: $r('app.media.ic_frequency_weighting'),
          description: 'A/C/Z计权设置',
          status: `当前: ${this.getWeightingDisplayName(this.pk.weighting_type)}`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToFrequencyWeighting()
          }
        })
      }

      // 音频分析模式
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '音频分析模式',
          icon: $r('app.media.ic_time_weighting'),
          description: '快速/慢速/脉冲',
          status: `当前: ${this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode)}`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAudioAnalysisMode()
          }
        })
      }

      // 音频记录开关
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '音频记录',
          icon: $r('app.media.ic_mic'),
          description: '保存原始音频',
          status: this.pk.record_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.record_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.toggleAudioRecording()
          }
        })
      }

      // 警报工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '警报设置',
          icon: $r('app.media.ic_alarm'),
          description: '阈值和通知管理',
          status: `阈值: ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAlerts()
          }
        })
      }

      // 数据工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '自动保存',
          icon: $r('app.media.ic_save'),
          description: '自动保存设置',
          status: this.pk.auto_save_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.auto_save_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.navigateToAutoSave()
          }
        })
      }

      // 系统工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '位置服务',
          icon: $r('app.media.ic_location'),
          description: '当前位置显示',
          status: this.pk.location_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.location_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.toggleLocation()
          }
        })
      }

      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '手电筒',
          icon: $r('app.media.ic_flashlight_bold'),
          description: '开启/关闭手电筒',
          status: this.isTorchOn ? '开启' : '关闭',
          statusColor: this.isTorchOn ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.toggleTorch()
          }
        })
      }
    }
    .width('100%')

    // 位置显示区域（如果位置服务开启）
    if (this.pk.location_enabled) {
      this.buildLocationDisplay()
    }
  }

  @Builder
  private buildToolCard(config: ToolCardConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      Image(config.icon)
        .width(32)
        .height(32)
        .fillColor($r('sys.color.icon_primary'))

      // 右侧内容区域
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(config.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Blank()
        }
        .width('100%')

        // 描述行
        Row() {
          Text(config.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Blank()
        }
        .width('100%')

        // 状态显示区域
        if (config.status) {
          Row() {
            Text(config.status)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.statusColor || $r('sys.color.font_primary'))

            Blank()
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_XS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(config.onTap)
  }

  @Builder
  private buildLocationDisplay() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('当前位置信息')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      LocationDisplay({
        onLocationUpdate: (locationInfo: LocationInfo | null) => {
          // 更新本地位置状态
          this.currentLocation = locationInfo;
          console.info('[TOOLS][Location] 位置更新事件接收:', locationInfo);
        }
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .margin({ top: DesignConstants.SPACING_MD })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 导航到声级校准设置
  private navigateToAudioCalibration = () => {
    let calibrationDialog: InfSheet;
    let props: AudioCalibrationProps = {
      onSave: () => {
        calibrationDialog.dismiss();
      },
      onClose: () => {
        calibrationDialog.dismiss();
      }
    }
    calibrationDialog = DialogHub.getSheet()
      .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AudioCalibrationSettingsBuilder), props)
      .build();
    calibrationDialog.show();
  }
  // 导航到警报与通知设置
  private navigateToAlerts = () => {
    let alertsDialog: InfSheet;
    let props: AlertsSettingsProps = {
      onSave: () => {
        alertsDialog.dismiss();
      },
      onClose: () => {
        alertsDialog.dismiss();
      }
    }
    alertsDialog = DialogHub.getSheet()
      .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsSettingsBuilder), props)
      .build();
    alertsDialog.show();
  }
  // 导航到频率加权设置
  private navigateToFrequencyWeighting = () => {
    let frequencyDialog: InfSheet;
    let param: FrequencyWeightingDialogParams = {
      currentWeighting: this.pk.weighting_type,
      onSettingsApplied: (selectedWeighting: WeightingType) => {
        // 即时生效：立即应用新设置
        this.pk.weighting_type = selectedWeighting;
      },
      onClose: () => {
        frequencyDialog?.dismiss();
      }
    }
    frequencyDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(FrequencyWeightingDialogBuilder), param)
      .build();

    frequencyDialog.show();
  }
  // 导航到自动保存设置
  private navigateToAutoSave = () => {
    let autoSaveDialog: InfSheet;
    let param: AutoSaveDialogParams = {
      onClose: () => {
        autoSaveDialog?.dismiss();
      },
      onSettingsApplied: (settings: AutoSaveSettings) => {
        // 应用设置并显示统一提示
        this.applyAutoSaveSettings(settings);
      }
    }
    autoSaveDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AutoSaveSettingsDialogBuilder), param)
      .build();

    autoSaveDialog.show();
  }

  // 应用自动保存设置
  private applyAutoSaveSettings(settings: AutoSaveSettings) {
    // 更新持久化存储
    this.pk.auto_save_enabled = settings.enabled;
    this.pk.auto_save_interval = settings.interval;
  }

  // 获取计权类型显示名称
  private getWeightingDisplayName(weighting: WeightingType): string {
    switch (weighting) {
      case WeightingType.A:
        return 'A计权';
      case WeightingType.C:
        return 'C计权';
      case WeightingType.Z:
        return 'Z计权';
      default:
        return 'A计权';
    }
  }

  // 手电筒切换功能
  private toggleTorch() {
    Throttle.click(() => {
      let cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this) as common.UIAbilityContext);
      if (cameraManager.isTorchSupported()) {
        cameraManager.setTorchMode(this.isTorchOn ? camera.TorchMode.OFF : camera.TorchMode.ON);
        this.isTorchOn = !this.isTorchOn;
      }
    })
  }

  // 位置服务切换
  private toggleLocation() {
    Throttle.click(() => {
      this.pk.location_enabled = !this.pk.location_enabled;
    })
  }

  // 导航到音频分析模式设置
  private navigateToAudioAnalysisMode = () => {
    let audioAnalysisDialog: InfSheet;
    let param: TimeWeightingDialogParams = {
      currentMode: this.pk.audio_analysis_mode,
      onSettingsApplied: (selectedMode: AudioAnalysisMode) => {
        // 即时生效：立即应用新设置
        this.pk.audio_analysis_mode = selectedMode;
      },
      onClose: () => {
        audioAnalysisDialog?.dismiss();
      }
    }
    audioAnalysisDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(TimeWeightingDialogBuilder), param)
      .build();

    audioAnalysisDialog.show();
  }

  // 音频记录开关切换
  private toggleAudioRecording() {
    Throttle.click(() => {
      this.pk.record_enabled = !this.pk.record_enabled;
    })
  }

  // 获取音频分析模式显示名称
  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速(F)';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速(S)';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲(I)';
      default:
        return '自定义模式';
    }
  }

  // 构建输入对话框
  @Builder
  private buildInputDialog() {
    InputDialog({
      title: '保存数据',
      default: '',
      onConfirm: (comment: string) => {
        this.saveCurrentData(comment);
        this.inputDialogController.close();
      },
      onClose: () => {
        console.info('[ToolsContent] 输入对话框已关闭');
        this.inputDialogController.close();
      }
    })
  }

  // 构建确认对话框
  @Builder
  private buildConfirmDialog() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('确认重置')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text('确定要重置所有检测数据吗？此操作不可撤销。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            this.confirmDialogController.close();
          })

        Button('确认重置', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.alert'))
          .fontColor(Color.White)
          .onClick(() => {
            this.resetData();
            this.confirmDialogController.close();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  // 开始检测
  private startDetection(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.startRecordingFromExternal();
        console.info('[ToolsContent] 开始检测请求已通过状态机发送');
      } catch (error) {
        console.error('[ToolsContent] 启动检测失败:', error);
        // 可以在这里添加错误提示
      }
    });
  }

  // 暂停检测
  private pauseDetection(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.pauseRecordingFromExternal();
        console.info('[ToolsContent] 暂停检测请求已通过状态机发送');
      } catch (error) {
        console.error('[ToolsContent] 暂停检测失败:', error);
      }
    });
  }

  // 显示重置确认对话框
  private showResetConfirmation(): void {
    Throttle.click(() => {
      this.confirmDialogController.open();
    });
  }

  // 重置数据
  private resetData(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.resetStateFromExternal();
        console.info('[ToolsContent] 数据已通过状态机重置');
      } catch (error) {
        console.error('[ToolsContent] 重置数据失败:', error);
      }
    });
  }

  // 显示保存对话框
  private showSaveDialog(): void {
    Throttle.click(() => {
      this.inputDialogController.open();
    });
  }

  // 保存当前数据
  private saveCurrentData(comment: string): void {
    Throttle.click(async () => {
      this.startSaveAnimation();
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.stopRecordingFromExternal(comment);
        console.info('[ToolsContent] 数据已通过状态机保存，备注:', comment);
        // 延迟结束动画，让用户看到保存效果
        setTimeout(() => {
          this.endSaveAnimation();
          // 保存完成后自动重新开始检测
          this.startDetection();
        }, 1000);
      } catch (error) {
        console.error('[ToolsContent] 保存数据失败:', error);
        this.endSaveAnimation();
      }
    });
  }

  // 开始保存动画
  private startSaveAnimation(): void {
    this.isSaving = true;
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 0.7;
    });
    console.info('[ToolsContent] 开始保存动画');
  }

  // 结束保存动画
  private endSaveAnimation(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 1.0;
    });
    this.isSaving = false;
    console.info('[ToolsContent] 结束保存动画');
  }

  // 获取检测状态文本
  private getDetectionStatusText(): string {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_IDLE:
        return '空闲';
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
        return '启动中...';
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return '检测中';
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
        return '停止中...';
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return '暂停中...';
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return '错误 - 点击开始重试';
      default:
        return '未知状态';
    }
  }

  // 获取检测状态颜色
  private getDetectionStatusColor(): Resource {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return $r('sys.color.confirm');
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return $r('sys.color.alert');
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return $r('sys.color.alert');
      default:
        return $r('sys.color.font_secondary');
    }
  }
}