import { WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { WindowType } from '../../common/WindowType';
import { PreferenceKeys } from '../../models/PreferenceKeys';

/**
 * 工具状态服务 - 统一管理所有工具的状态显示逻辑
 */
export class ToolStatusService {
  private pk: PreferenceKeys;

  constructor(pk: PreferenceKeys) {
    this.pk = pk;
  }

  // 获取计权类型显示名称
  getWeightingDisplayName(weighting: WeightingType): string {
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

  // 获取音频分析模式显示名称
  getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
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

  // 获取采样率显示文本
  getSampleRateDisplayText(): string {
    const sampleRateText = `${(this.pk.audio_sample_rate / 1000).toFixed(1)}kHz`;
    
    if (this.pk.audio_decimation_enabled && this.pk.audio_decimation_factor > 1) {
      // 计算降采样指数
      const decimationExponent = Math.round(Math.log2(this.pk.audio_decimation_factor));
      return `${sampleRateText} (降采样${decimationExponent}级/${this.pk.audio_decimation_factor}倍)`;
    } else {
      return sampleRateText;
    }
  }

  // 获取窗函数显示名称
  getWindowFunctionDisplayName(windowType: WindowType): string {
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
  getWindowParamsDisplayName(): string {
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

  // 位置状态计算属性
  getLocationStatus(): string {
    return this.pk.location_enabled ? '已开启' : '已关闭';
  }

  getLocationStatusColor(): Resource {
    return this.pk.location_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary');
  }
}