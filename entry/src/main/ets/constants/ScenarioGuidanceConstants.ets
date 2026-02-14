/**
 * 场景建议内容配置
 * 根据预设类型和当前分贝状态，提供个性化的环境建议
 */

import { PresetType } from '../models/ThresholdConfig';

// 分贝区间类型
export enum DecibelZone {
  BELOW = 'below',      // 低于阈值（安全）
  WARNING = 'warning',  // 接近阈值（警告）
  ABOVE = 'above'       // 超过阈值（警报）
}

// 场景建议内容
export interface ScenarioGuidance {
  title: string;           // 主标题：一句话总结环境状态
  description: string;     // 描述：对环境的具体说明
  suggestion: string;      // 建议：用户应该做什么
  reference?: string;      // 参考：标准或数据来源（可选）
  icon: string;            // 图标
}

// 场景建议映射表
export const SCENARIO_GUIDANCE_MAP: Record<PresetType, Record<DecibelZone, ScenarioGuidance>> = {
  // ========== 安静环境：图书馆、卧室 ==========
  [PresetType.QUIET_ENVIRONMENT]: {
    [DecibelZone.BELOW]: {
      title: '非常适合休息',
      description: '当前环境安静，噪音水平适合睡眠、阅读或深度专注工作',
      suggestion: '可以开始需要高度专注的任务，或安心休息',
      reference: 'WHO 建议睡眠环境噪声 < 40dB',
      icon: '🌙'
    },
    [DecibelZone.WARNING]: {
      title: '可能干扰轻睡眠者',
      description: '噪音已接近舒适阈值，敏感人群可能感到轻微干扰',
      suggestion: '检查是否有突发噪音源（电器、门窗、邻居），必要时使用耳塞',
      icon: '⚠️'
    },
    [DecibelZone.ABOVE]: {
      title: '已不适合安静活动',
      description: '噪音已超过安静环境标准，可能影响睡眠质量和休息效果',
      suggestion: '建议关闭门窗、使用降噪设备，或寻找更安静的场所',
      reference: '长期暴露可能影响睡眠健康',
      icon: '🚨'
    }
  },

  // ========== 一般环境：办公室、教室 ==========
  [PresetType.GENERAL_ENVIRONMENT]: {
    [DecibelZone.BELOW]: {
      title: '理想的办公环境',
      description: '环境安静舒适，适合专注工作、电话会议和团队协作',
      suggestion: '当前环境非常适合深度工作，建议优先处理复杂任务',
      reference: 'GB 3096-2008 2类声环境功能区标准',
      icon: '✅'
    },
    [DecibelZone.WARNING]: {
      title: '略有干扰，需注意',
      description: '噪音接近办公舒适上限，可能影响电话沟通或专注度',
      suggestion: '建议关闭门窗，或使用降噪耳机进行重要通话',
      icon: '⚡'
    },
    [DecibelZone.ABOVE]: {
      title: '超过办公舒适标准',
      description: '噪音已超过一般办公环境标准，长期工作可能引起疲劳',
      suggestion: '建议控制连续工作时长不超过4小时，适时休息或寻找安静区域',
      reference: '长期暴露可能引起工作效率下降',
      icon: '⚠️'
    }
  },

  // ========== 嘈杂环境：街道、商场 ==========
  [PresetType.NOISY_ENVIRONMENT]: {
    [DecibelZone.BELOW]: {
      title: '相对安静的时刻',
      description: '当前噪音低于预期，是嘈杂环境中难得的安静时段',
      suggestion: '抓紧这个时间进行需要集中注意力的活动',
      icon: '👍'
    },
    [DecibelZone.WARNING]: {
      title: '典型的嘈杂环境',
      description: '噪音水平符合街道、商场等环境的正常范围',
      suggestion: '如需长时间停留，建议佩戴耳塞或降噪耳机保护听力',
      reference: '建议每日累计暴露不超过 8 小时',
      icon: '🔊'
    },
    [DecibelZone.ABOVE]: {
      title: '噪音已达警戒水平',
      description: '噪音已超过街道环境舒适阈值，可能对听力造成影响',
      suggestion: '建议缩短停留时间，或佩戴听力保护设备，注意让耳朵休息',
      reference: '超过 70dB 环境建议控制暴露时长',
      icon: '🛡️'
    }
  },

  // ========== 危险环境：工厂、工地 ==========
  [PresetType.DANGEROUS_ENVIRONMENT]: {
    [DecibelZone.BELOW]: {
      title: '难得的安静时刻',
      description: '噪音暂时处于安全水平，是嘈杂环境中的喘息机会',
      suggestion: '如需沟通或休息，请抓紧这个相对安静的时间窗口',
      icon: '⏸️'
    },
    [DecibelZone.WARNING]: {
      title: '接近听力损伤阈值',
      description: '噪音已接近危险水平，长期暴露可能造成听力损伤',
      suggestion: '必须佩戴专业听力防护设备（耳塞/耳罩），严格控制暴露时间',
      reference: 'GBZ 2.2-2007 工作场所噪声职业接触限值',
      icon: '⚠️'
    },
    [DecibelZone.ABOVE]: {
      title: '听力损伤风险区域',
      description: '噪音已超过安全标准，短时间暴露也可能损伤听力',
      suggestion: '立即佩戴专业防护设备，或离开该区域，避免无保护暴露',
      reference: '85dB 以上属职业危害环境，需强制防护措施',
      icon: '🚨'
    }
  },

  // ========== 自定义环境：通用建议 ==========
  [PresetType.CUSTOM]: {
    [DecibelZone.BELOW]: {
      title: '环境舒适',
      description: '当前噪音水平低于您的设定阈值，环境处于舒适范围',
      suggestion: '当前环境适合您预设的活动需求',
      icon: '✅'
    },
    [DecibelZone.WARNING]: {
      title: '接近设定阈值',
      description: '噪音已接近您设定的阈值，可能即将触发警报',
      suggestion: '留意环境变化，根据需要采取相应措施',
      icon: '⚡'
    },
    [DecibelZone.ABOVE]: {
      title: '已超过设定阈值',
      description: '噪音已超过您设定的阈值，触发了警报',
      suggestion: '建议根据您的需求采取降噪措施或更换环境',
      icon: '🚨'
    }
  }
};

// 获取当前分贝区间
export function getDecibelZone(
  currentDecibel: number, 
  threshold: number, 
  warningOffset: number = 10
): DecibelZone {
  if (currentDecibel >= threshold) {
    return DecibelZone.ABOVE;
  } else if (currentDecibel >= threshold - warningOffset) {
    return DecibelZone.WARNING;
  }
  return DecibelZone.BELOW;
}

// 获取场景建议
export function getScenarioGuidance(
  presetType: PresetType,
  currentDecibel: number,
  threshold: number,
  warningOffset: number = 10
): ScenarioGuidance {
  const zone = getDecibelZone(currentDecibel, threshold, warningOffset);
  return SCENARIO_GUIDANCE_MAP[presetType]?.[zone] || SCENARIO_GUIDANCE_MAP[PresetType.CUSTOM][zone];
}
