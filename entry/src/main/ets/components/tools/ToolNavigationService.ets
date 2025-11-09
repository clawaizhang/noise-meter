import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { WindowType } from '../../common/WindowType';
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
import {
  SpectrumDisplaySettingsBuilder,
  SpectrumDisplaySettingsParams,
} from '../decibel-meter/SpectrumDisplaySettingsDialog';
import {
  SpectrumDisplayService,
  SpectrumDisplayConfig
} from '../../services/SpectrumDisplayService';
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
import { PreferenceKeys } from '../../models/PreferenceKeys';

/**
 * 工具导航服务 - 统一管理所有工具的导航逻辑
 */
export class ToolNavigationService {
  private pk: PreferenceKeys;

  constructor(pk: PreferenceKeys) {
    this.pk = pk;
  }

  // 导航到声级校准设置
  navigateToAudioCalibration = () => {
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
  navigateToAlerts = () => {
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
  navigateToFrequencyWeighting = () => {
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
  navigateToAutoSave = () => {
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

  // 导航到音频分析模式设置
  navigateToAudioAnalysisMode = () => {
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

  // 导航到频谱显示设置
  navigateToSpectrumDisplaySettings = () => {
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

  // 导航到采样率设置
  navigateToSampleRateSettings = () => {
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

  // 导航到窗函数设置
  navigateToWindowFunctionSettings = () => {
    let windowFunctionDialog: InfSheet;
    let param: WindowFunctionDialogParams = {
      currentWindowType: this.pk.window_function_type,
      onSettingsApplied: async (selectedWindowType: WindowType) => {
        // 即时生效：立即应用新设置到持久化存储
        this.pk.window_function_type = selectedWindowType;
        
        // 触发窗函数配置更新（不中断音频采集）
        const audioService = AudioService.getInstance(this.pk);
        audioService.updateWindowFunctionConfig();
        
        console.info(`[窗函数设置] 已更新持久化存储并触发配置更新: 窗函数类型=${selectedWindowType}`);
      },
      onClose: () => {
        windowFunctionDialog?.dismiss();
      }
    }
    windowFunctionDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.comp_background_primary'),
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(WindowFunctionDialogContent), param)
      .build();
    windowFunctionDialog.show();
  }

  // 导航到窗函数参数设置
  navigateToWindowFunctionParamsSettings = () => {
    let windowFunctionParamsDialog: InfSheet;
    let param: WindowFunctionParamsDialogParams = {
      currentWindowType: this.pk.window_function_type,
      currentKaiserBeta: this.pk.window_kaiser_beta,
      currentGaussianSigma: this.pk.window_gaussian_sigma,
      currentTukeyAlpha: this.pk.window_tukey_alpha,
      currentChebyshevAttenuation: this.pk.window_chebyshev_attenuation,
      onSettingsApplied: async (windowType: WindowType, kaiserBeta?: number, gaussianSigma?: number,
        tukeyAlpha?: number, chebyshevAttenuation?: number) => {
        // 即时生效：立即应用新设置到持久化存储
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

        // 触发窗函数配置更新（不中断音频采集）
        const audioService = AudioService.getInstance(this.pk);
        audioService.updateWindowFunctionConfig();

        console.info(`[窗函数参数设置] 已更新持久化存储并触发配置更新: 窗函数类型=${windowType}, KaiserBeta=${this.pk.window_kaiser_beta}, GaussianSigma=${this.pk.window_gaussian_sigma}, TukeyAlpha=${this.pk.window_tukey_alpha}, ChebyshevAttenuation=${this.pk.window_chebyshev_attenuation}`);
      },
      onClose: () => {
        windowFunctionParamsDialog?.dismiss();
      }
    }
    windowFunctionParamsDialog = showWindowFunctionParamsDialog(param);
    windowFunctionParamsDialog.show();
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

  // 音频记录开关切换
  toggleAudioRecording = () => {
    this.pk.record_enabled = !this.pk.record_enabled;
  }

  // 位置服务开关方法
  toggleLocationService = (refreshLocation: () => Promise<void>) => {
    this.pk.location_enabled = !this.pk.location_enabled;
    // 如果开启位置服务，自动获取位置
    if (this.pk.location_enabled) {
      refreshLocation();
    }
  }
}