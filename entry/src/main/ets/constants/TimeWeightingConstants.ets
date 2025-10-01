/**
 * 时间计权模式相关常量
 * 包含专业的声学理论解释、技术参数和应用场景
 */

import { AudioAnalysisMode } from '../common/AudioConfig';

// 声学理论解释接口
export interface AcousticExplanation {
  timeConstant: string;           // 时间常数
  responseCharacteristic: string; // 响应特性
  frequencyResponse: string;      // 频率响应
  standardReference: string;      // 标准依据
  physicalPrinciple: string;      // 物理原理
}

// 技术参数接口
interface TechnicalParams {
  fftSize: number;               // FFT大小
  updateInterval: number;        // 更新间隔(ms)
  frequencyResolution: number;   // 频率分辨率(Hz)
  timeResolution: number;        // 时间分辨率(ms)
  windowType: string;            // 窗函数类型
  overlapRate: number;           // 重叠率
  bufferSize: number;            // 缓冲区大小
}

// 应用场景接口
export interface ApplicationScenario {
  title: string;                 // 场景标题
  description: string;           // 场景描述
  example: string;               // 实际示例
}

export class TimeWeightingConstants {
  // 声学理论解释
  static readonly ACOUSTIC_EXPLANATIONS: Record<AudioAnalysisMode, AcousticExplanation> = {
    [AudioAnalysisMode.FAST_TIME_WEIGHTING]: {
      timeConstant: '125ms (符合IEC 61672-1标准)',
      responseCharacteristic: '快速响应声压级变化，适合测量瞬时噪声，对快速变化的信号有良好跟踪能力',
      frequencyResponse: '平坦的频率响应，在20Hz-20kHz范围内保持稳定',
      standardReference: 'GB/T 3785.1-2010, IEC 61672-1 Class 1',
      physicalPrinciple: '基于指数衰减函数，时间常数τ=125ms，响应函数为e^(-t/τ)'
    },
    [AudioAnalysisMode.SLOW_TIME_WEIGHTING]: {
      timeConstant: '1s (符合IEC 61672-1标准)',
      responseCharacteristic: '平滑响应，减少瞬时波动，适合稳态噪声测量，对稳态信号有更好的平均效果',
      frequencyResponse: '对低频信号有更好的平均效果，减少高频波动影响',
      standardReference: 'GB/T 3785.1-2010, IEC 61672-1 Class 1',
      physicalPrinciple: '基于指数衰减函数，时间常数τ=1s，响应函数为e^(-t/τ)，提供更平滑的测量结果'
    },
    [AudioAnalysisMode.IMPULSE_TIME_WEIGHTING]: {
      timeConstant: '35ms上升，1.5s下降 (符合IEC 61672-1标准)',
      responseCharacteristic: '专门设计用于测量脉冲噪声，快速上升缓慢下降，能准确捕捉瞬时峰值',
      frequencyResponse: '对脉冲信号有特殊加权处理，优化瞬时信号的检测能力',
      standardReference: 'GB/T 3785.1-2010, IEC 61672-1 Class 1',
      physicalPrinciple: '双时间常数设计，上升时间常数τ₁=35ms，下降时间常数τ₂=1.5s，专门针对脉冲信号优化'
    }
  };

  // 技术参数配置
  static readonly TECHNICAL_PARAMS: Record<AudioAnalysisMode, TechnicalParams> = {
    [AudioAnalysisMode.FAST_TIME_WEIGHTING]: {
      fftSize: 2048,
      updateInterval: 200,
      frequencyResolution: 21.5,
      timeResolution: 46.4,
      windowType: '布莱克曼窗',
      overlapRate: 0.4,
      bufferSize: 4096
    },
    [AudioAnalysisMode.SLOW_TIME_WEIGHTING]: {
      fftSize: 4096,
      updateInterval: 500,
      frequencyResolution: 10.8,
      timeResolution: 92.9,
      windowType: '汉宁窗',
      overlapRate: 0.6,
      bufferSize: 8192
    },
    [AudioAnalysisMode.IMPULSE_TIME_WEIGHTING]: {
      fftSize: 1024,
      updateInterval: 35,
      frequencyResolution: 43.1,
      timeResolution: 23.2,
      windowType: '布莱克曼窗',
      overlapRate: 0.75,
      bufferSize: 2048
    }
  };

  // 应用场景配置
  static readonly APPLICATION_SCENARIOS: Record<AudioAnalysisMode, ApplicationScenario[]> = {
    [AudioAnalysisMode.FAST_TIME_WEIGHTING]: [
      {
        title: '交通噪声监测',
        description: '测量车辆经过时的瞬时噪声变化',
        example: '高速公路、城市道路的交通噪声评估'
      },
      {
        title: '机械冲击声检测',
        description: '检测机械设备运行时的冲击噪声',
        example: '冲压机、锻造设备的噪声测量'
      },
      {
        title: '环境噪声快速变化',
        description: '监测环境噪声的快速波动',
        example: '建筑工地、公共场所的噪声监测'
      }
    ],
    [AudioAnalysisMode.SLOW_TIME_WEIGHTING]: [
      {
        title: '办公室环境监测',
        description: '测量稳态的办公环境噪声',
        example: '写字楼、会议室的噪声评估'
      },
      {
        title: '住宅区噪声评估',
        description: '评估居民区的长期噪声水平',
        example: '小区、公寓的环境噪声监测'
      },
      {
        title: '工业设备稳态噪声',
        description: '测量运行稳定的工业设备噪声',
        example: '空调系统、通风设备的噪声测量'
      }
    ],
    [AudioAnalysisMode.IMPULSE_TIME_WEIGHTING]: [
      {
        title: '枪声爆炸声测量',
        description: '专门用于测量瞬时高强度噪声',
        example: '射击场、爆破现场的噪声监测'
      },
      {
        title: '冲击机械噪声',
        description: '检测冲击式机械设备的噪声',
        example: '冲床、锻锤的噪声测量'
      },
      {
        title: '警报器声评估',
        description: '评估警报器、警笛的脉冲特性',
        example: '消防车、救护车警报声检测'
      }
    ]
  };

  // 模式显示名称
  static readonly MODE_DISPLAY_NAMES: Record<AudioAnalysisMode, string> = {
    [AudioAnalysisMode.FAST_TIME_WEIGHTING]: '快速(F)',
    [AudioAnalysisMode.SLOW_TIME_WEIGHTING]: '慢速(S)',
    [AudioAnalysisMode.IMPULSE_TIME_WEIGHTING]: '脉冲(I)'
  };

  // 模式简要描述
  static readonly MODE_DESCRIPTIONS: Record<AudioAnalysisMode, string> = {
    [AudioAnalysisMode.FAST_TIME_WEIGHTING]: '时间常数125ms，适合测量快速变化的噪声',
    [AudioAnalysisMode.SLOW_TIME_WEIGHTING]: '时间常数1s，适合测量稳态噪声',
    [AudioAnalysisMode.IMPULSE_TIME_WEIGHTING]: '时间常数35ms/1.5s，适合测量脉冲噪声'
  };

  // 获取模式图标资源
  static getModeIcon(mode: AudioAnalysisMode): Resource {
    // 这里使用现有的图标资源，可以根据需要添加专门的图标
    return $r('app.media.ic_time_weighting');
  }

  // 获取所有可用模式
  static getAvailableModes(): AudioAnalysisMode[] {
    return [
      AudioAnalysisMode.FAST_TIME_WEIGHTING,
      AudioAnalysisMode.SLOW_TIME_WEIGHTING,
      AudioAnalysisMode.IMPULSE_TIME_WEIGHTING
    ];
  }
}