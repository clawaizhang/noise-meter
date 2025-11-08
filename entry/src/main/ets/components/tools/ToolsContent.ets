import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
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
import {
  SpectrumDisplaySettingsBuilder,
  SpectrumDisplaySettingsParams,
} from '../decibel-meter/SpectrumDisplaySettingsDialog';
import {
  SpectrumDisplayService,
  SpectrumDisplayConfig
} from '../../services/SpectrumDisplayService';
import { LocationInfo, LocationService } from '../../services/LocationService';
import {
  SampleRateSettingsBuilder,
  SampleRateSettingsParams
} from './SampleRateSettingsDialog';
import { AudioService } from '../../services/AudioService';
import {
  WindowFunctionDialogBuilder,
  WindowFunctionDialogContent,
  WindowFunctionDialogParams,
} from './WindowFunctionDialog';
import {
  WindowFunctionParamsDialogBuilder,
  WindowFunctionParamsDialogParams,
  showWindowFunctionParamsDialog
} from './WindowFunctionParamsDialog';
import { WindowType } from '../../common/WindowType';

// 工具功能卡片配置
interface ToolCardConfig {
  title: string;
  icon: Resource;
  description: string;
  status?: string;
  statusColor?: Resource;
  onTap: () => void;
}


@ComponentV2
export struct ToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Local private isLocationRefreshing: boolean = false;
  private locationService: LocationService = LocationService.getInstance();

  aboutToAppear(): void {
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
  }

  aboutToDisappear(): void {
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {

        // 工具功能卡片区
        this.buildToolsCards()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .padding(DesignConstants.SPACING_MD)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)

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

      // 位置服务卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '位置服务',
          icon: $r('app.media.ic_location'),
          description: '记录位置信息',
          status: this.locationStatus,
          statusColor: this.locationStatusColor,
          onTap: () => {
            this.toggleLocationService()
          }
        })
      }

      // 频谱显示设置卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '频谱显示设置',
          icon: $r('app.media.ic_frequency_weighting'),
          description: '线形图/柱状图/混合模式',
          status: this.getSpectrumDisplayModeText(),
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToSpectrumDisplaySettings()
          }
        })
      }

      // 手电筒卡片
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

      // 采样率设置卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '采样率设置',
          icon: $r('app.media.ic_frequency_weighting'),
          description: '音频采样率和降采样',
          status: this.getSampleRateDisplayText(),
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToSampleRateSettings()
          }
        })
      }

      // 窗函数设置卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '窗函数设置',
          icon: $r('app.media.ic_filter'),
          description: 'FFT窗函数选择',
          status: this.getWindowFunctionDisplayName(this.pk.window_function_type),
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToWindowFunctionSettings()
          }
        })
      }

      // 窗函数参数设置卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '窗函数参数',
          icon: $r('app.media.ic_filter'),
          description: '可调窗函数参数',
          status: this.getWindowParamsDisplayName(),
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToWindowFunctionParamsSettings()
          }
        })
      }
    }
    .width('100%')
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
    .onClick(() => {
      Throttle.click(() => {
        config.onTap()
      });
    })
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
  
  // 应用频谱显示设置
  private applySpectrumDisplaySettings(config: SpectrumDisplayConfig) {
    // 使用SpectrumDisplayService应用配置
    const spectrumDisplayService = SpectrumDisplayService.getInstance();
    spectrumDisplayService.applyDisplayConfig(this.pk, config);
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

  // 位置状态计算属性 - 操作台只显示开启/关闭状态
  @Computed
  get locationStatus(): string {
    return this.pk.location_enabled ? '已开启' : '已关闭';
  }

  @Computed
  get locationStatusColor(): Resource {
    return this.pk.location_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary');
  }

  // 位置服务开关方法
  private toggleLocationService(): void {
    Throttle.click(() => {
      this.pk.location_enabled = !this.pk.location_enabled;
      // 如果开启位置服务，自动获取位置
      if (this.pk.location_enabled) {
        this.refreshLocation();
      } else {
      }
    });
  }

  // 刷新位置信息方法
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      // 检查定位服务是否开启
      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        return;
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
    } catch (error) {
      console.error('获取位置信息失败:', error);


    } finally {
      this.isLocationRefreshing = false;
    }
  }

  // 导航到频谱显示设置
  private navigateToSpectrumDisplaySettings = () => {
    let spectrumDialog: InfSheet;
    let param: SpectrumDisplaySettingsParams = {
      onClose: () => {
        spectrumDialog?.dismiss();

      },
      onSettingsApplied: (config: SpectrumDisplayConfig) => {
        // 应用频谱显示设置
        this.applySpectrumDisplaySettings(config);
      },
    }
    spectrumDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SpectrumDisplaySettingsBuilder), param)
      .build();

    spectrumDialog.show();
  }

  // 获取频谱显示模式显示名称
  private getSpectrumDisplayModeText(): string {
    switch (this.pk.spectrum_display_mode) {
      case 'line':
        return '线形图';
      case 'bar':
        return '柱状图';
      case 'hybrid':
        return '混合模式';
      default:
        return '线形图';
    }
  }

  // 监听位置服务开关变化
  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      if (newEnabled) {
        // 开启时自动刷新位置
        this.refreshLocation();
      } else {
      }
    }
  }

  // 导航到采样率设置
  private navigateToSampleRateSettings = () => {
    let sampleRateDialog: InfSheet;
    let param: SampleRateSettingsParams = {
      onClose: () => {
        sampleRateDialog?.dismiss();
      },
      onSettingsApplied: async (sampleRate: number, decimationEnabled: boolean, decimationFactor: number) => {
        // 应用采样率设置
        await this.applySampleRateSettings(sampleRate, decimationEnabled, decimationFactor);
      }
    }
    sampleRateDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SampleRateSettingsBuilder), param)
      .build();

    sampleRateDialog.show();
  }

  // 应用采样率设置
  private async applySampleRateSettings(sampleRate: number, decimationEnabled: boolean, decimationFactor: number): Promise<void> {
    // 更新持久化存储
    this.pk.audio_sample_rate = sampleRate;
    this.pk.audio_decimation_enabled = decimationEnabled;
    this.pk.audio_decimation_factor = decimationFactor;
    
    // 应用到AudioService
    const audioService = AudioService.getInstance(this.pk);
    await audioService.applySampleRateSettings(sampleRate, decimationEnabled, decimationFactor);
    
    console.info(`[采样率设置] 已应用: 采样率=${sampleRate}Hz, 降采样启用=${decimationEnabled}, 降采样因子=${decimationFactor}`);
  }

  // 获取采样率显示文本
  private getSampleRateDisplayText(): string {
    const sampleRateText = `${(this.pk.audio_sample_rate / 1000).toFixed(1)}kHz`;
    
    if (this.pk.audio_decimation_enabled && this.pk.audio_decimation_factor > 1) {
      // 计算降采样指数
      const decimationExponent = Math.round(Math.log2(this.pk.audio_decimation_factor));
      return `${sampleRateText} (降采样${decimationExponent}级/${this.pk.audio_decimation_factor}倍)`;
    } else {
      return sampleRateText;
    }
  }

  // 导航到窗函数设置
  private navigateToWindowFunctionSettings = () => {
    let windowFunctionDialog: InfSheet;
    let param: WindowFunctionDialogParams = {
      currentWindowType: this.pk.window_function_type,
      onSettingsApplied: async (selectedWindowType: WindowType) => {
        // 即时生效：立即应用新设置
        this.pk.window_function_type = selectedWindowType;
        
        // 应用到AudioService
        const audioService = AudioService.getInstance(this.pk);
        await audioService.applyWindowFunctionSettings(
          selectedWindowType,
          this.pk.window_kaiser_beta,
          this.pk.window_gaussian_sigma,
          this.pk.window_tukey_alpha,
          this.pk.window_chebyshev_attenuation
        );
        
        console.info(`[窗函数设置] 已应用: 窗函数类型=${selectedWindowType}`);
      },
      onClose: () => {
        windowFunctionDialog?.dismiss();
      }
    }
    windowFunctionDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary'),
        detents: [0.8, 1.0]
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(WindowFunctionDialogContent), param)
      .build();
    windowFunctionDialog.show();
  }

  // 获取窗函数显示名称
  private getWindowFunctionDisplayName(windowType: WindowType): string {
    switch (windowType) {
      case WindowType.HANNING:
        return '汉宁窗';
      case WindowType.BLACKMAN:
        return '布莱克曼窗';
      case WindowType.HAMMING:
        return '汉明窗';
      case WindowType.BARTLETT:
        return '巴特利特窗';
      case WindowType.KAISER:
        return '凯泽窗';
      case WindowType.FLATTOP:
        return '平顶窗';
      case WindowType.TRIANGULAR:
        return '三角窗';
      case WindowType.WELCH:
        return '韦尔奇窗';
      case WindowType.SINE:
        return '正弦窗';
      case WindowType.GAUSSIAN:
        return '高斯窗';
      case WindowType.TUKEY:
        return '图基窗';
      case WindowType.CHEBYSHEV:
        return '切比雪夫窗';
      default:
        return '汉宁窗';
    }
  }

  // 获取窗函数参数显示名称
  private getWindowParamsDisplayName(): string {
    switch (this.pk.window_function_type) {
      case WindowType.KAISER:
        return `Beta=${this.pk.window_kaiser_beta.toFixed(1)}`;
      case WindowType.GAUSSIAN:
        return `Sigma=${this.pk.window_gaussian_sigma.toFixed(2)}`;
      case WindowType.TUKEY:
        return `Alpha=${this.pk.window_tukey_alpha.toFixed(2)}`;
      case WindowType.CHEBYSHEV:
        return `${this.pk.window_chebyshev_attenuation.toFixed(0)}dB`;
      default:
        return '固定参数';
    }
  }

  // 导航到窗函数参数设置
  private navigateToWindowFunctionParamsSettings = () => {
    let windowFunctionParamsDialog: InfSheet;
    let param: WindowFunctionParamsDialogParams = {
      currentWindowType: this.pk.window_function_type,
      currentKaiserBeta: this.pk.window_kaiser_beta,
      currentGaussianSigma: this.pk.window_gaussian_sigma,
      currentTukeyAlpha: this.pk.window_tukey_alpha,
      currentChebyshevAttenuation: this.pk.window_chebyshev_attenuation,
      onSettingsApplied: async (windowType: WindowType, kaiserBeta?: number, gaussianSigma?: number,
        tukeyAlpha?: number, chebyshevAttenuation?: number) => {
        // 即时生效：立即应用新设置
        this.pk.window_function_type = windowType;
        if (kaiserBeta !== undefined) {
          this.pk.window_kaiser_beta = kaiserBeta;
        }
        if (gaussianSigma !== undefined) {
          this.pk.window_gaussian_sigma = gaussianSigma;
        }
        if (tukeyAlpha !== undefined) {
          this.pk.window_tukey_alpha = tukeyAlpha;
        }
        if (chebyshevAttenuation !== undefined) {
          this.pk.window_chebyshev_attenuation = chebyshevAttenuation;
        }
        
        // 应用到AudioService
        const audioService = AudioService.getInstance(this.pk);
        await audioService.applyWindowFunctionSettings(
          windowType,
          this.pk.window_kaiser_beta,
          this.pk.window_gaussian_sigma,
          this.pk.window_tukey_alpha,
          this.pk.window_chebyshev_attenuation
        );
        
        console.info(`[窗函数参数设置] 已应用: 窗函数类型=${windowType}, KaiserBeta=${this.pk.window_kaiser_beta}, GaussianSigma=${this.pk.window_gaussian_sigma}, TukeyAlpha=${this.pk.window_tukey_alpha}, ChebyshevAttenuation=${this.pk.window_chebyshev_attenuation}`);
      },
      onClose: () => {
        windowFunctionParamsDialog?.dismiss();
      }
    }
    windowFunctionParamsDialog = showWindowFunctionParamsDialog(param);
    windowFunctionParamsDialog.show();
  }
}