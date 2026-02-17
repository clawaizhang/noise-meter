/**
 * PremiumFeature 组件使用示例
 * 
 * 展示如何在不同场景下使用升级后的 PremiumFeature 组件
 * 涵盖：历史记录限制、频谱自定义、暴露统计、自动保存等功能的分层设计
 */

import { 
  PremiumFeature, 
  PremiumLockMode, 
  LimitType,
  createFeatureLimit,
  createFeatureComparison,
  commonFeatureComparisons
} from './PremiumFeature';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';

// ==========================================
// 示例1：历史记录 - 软限制模式
// 免费用户只能看最近3条，专业版无限制
// ==========================================
@ComponentV2
export struct HistoryRecordsExample {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local totalRecords: number = 5; // 假设当前有5条记录
  
  build() {
    PremiumFeature({
      featureId: 'history_records',
      featureName: '历史记录',
      featureDesc: '查看和管理您的噪音检测历史记录',
      icon: $r('app.media.ic_history'),
      lockMode: PremiumLockMode.SOFT_LIMIT,
      // 软限制配置：免费3条，专业版无限制(-1)
      limit: createFeatureLimit(
        LimitType.COUNT,
        3,      // 免费限制3条
        -1,     // 专业版无限制
        this.totalRecords,
        '条'
      ),
      showTrialTip: true,
      trialDays: 7
    }) {
      // 免费版内容（超过3条后会显示限制提示）
      this.buildHistoryContent()
    }
    .onUnlock(() => {
      console.info('用户升级成功，刷新历史记录列表');
      // 重新加载所有记录
    })
  }
  
  @Builder
  buildHistoryContent() {
    Column() {
      Text('历史记录列表')
        .fontSize(DesignConstants.FONT_SIZE_MD)
      // 实际的记录列表...
    }
    .width('100%')
    .height('100%')
  }
}

// ==========================================
// 示例2：频谱自定义 - 完全锁定模式
// 基础频谱免费，自定义FFT参数需升级
// ==========================================
@ComponentV2
export struct SpectrumSettingsExample {
  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 基础频谱显示 - 免费功能，不使用PremiumFeature包裹
      Text('基础频谱分析')
        .fontSize(DesignConstants.FONT_SIZE_MD)
      // ... 基础频谱组件
      
      // 频谱自定义设置 - 专业版功能
      Text('高级频谱设置')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .margin({ top: DesignConstants.SPACING_LG })
      
      PremiumFeature({
        featureId: 'spectrum_customization',
        featureName: '频谱自定义',
        featureDesc: '自定义窗函数、采样率、FFT参数等专业设置',
        icon: $r('app.media.ic_audio_analysis'),
        lockMode: PremiumLockMode.FULL_LOCK,
        showTrialTip: true
      }) {
        // 锁定状态下的占位内容（置灰显示）
        this.buildSpectrumSettingsPlaceholder()
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }
  
  @Builder
  buildSpectrumSettingsPlaceholder() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('窗函数类型')
          .fontSize(DesignConstants.FONT_SIZE_MD)
        Blank()
        Text('Hanning')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('采样率')
          .fontSize(DesignConstants.FONT_SIZE_MD)
        Blank()
        Text('44100 Hz')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('FFT点数')
          .fontSize(DesignConstants.FONT_SIZE_MD)
        Blank()
        Text('2048')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  buildSpectrumSettingsReal() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 真实的设置控件...
      Text('这里是专业版的频谱设置界面')
        .fontSize(DesignConstants.FONT_SIZE_MD)
    }
    .width('100%')
  }
}

// ==========================================
// 示例3：频率加权切换 - 对比模式
// 让用户清楚看到免费版和专业版的区别
// ==========================================
@ComponentV2
export struct FrequencyWeightingExample {
  build() {
    PremiumFeature({
      featureId: 'frequency_weighting',
      featureName: '频率加权',
      featureDesc: '选择不同的频率加权模式以符合各种测量标准',
      icon: $r('app.media.ic_frequency_weighting'),
      lockMode: PremiumLockMode.COMPARISON,
      // 功能对比列表
      comparisonList: [
        createFeatureComparison('A计权', '✓ 可用', '✓ 可用', false),
        createFeatureComparison('C计权', '✗ 不可用', '✓ 可用', true),
        createFeatureComparison('Z计权', '✗ 不可用', '✓ 可用', true),
        createFeatureComparison('自定义加权', '✗ 不可用', '✓ 可用', true),
      ],
      showTrialTip: true
    }) {
      // 免费版：仅显示A计权
      this.buildAWeightingOnly()
    }
  }
  
  @Builder
  buildAWeightingOnly() {
    Row() {
      Text('A计权')
        .fontSize(DesignConstants.FONT_SIZE_MD)
      
      Blank()
      
      // 选中状态
      Text('✓')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.confirm'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  buildAllWeightingOptions() {
    Column({ space: DesignConstants.SPACING_SM }) {
      ForEach(['A计权', 'C计权', 'Z计权'], (item: string) => {
        Row() {
          Text(item)
            .fontSize(DesignConstants.FONT_SIZE_MD)
          
          Blank()
          
          Radio({ value: item, group: 'weighting' })
            .checked(item === 'A计权')
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      })
    }
    .width('100%')
  }
}

// ==========================================
// 示例4：暴露统计 - 软限制（当日免费，历史付费）
// ==========================================
@ComponentV2
export struct ExposureStatsExample {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local todayStats: ExposureStats = { count: 3, maxDb: 75 };
  @Local historyDays: number = 7; // 历史数据天数
  
  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 今日暴露统计 - 免费功能
      Text('今日噪音暴露')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
      
      // 今日数据直接展示，不锁定
      this.buildTodayStats()
      
      // 历史趋势 - 软限制
      Text('历史趋势分析')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .margin({ top: DesignConstants.SPACING_LG })
      
      PremiumFeature({
        featureId: 'exposure_history',
        featureName: '历史暴露分析',
        featureDesc: '查看长期噪音暴露趋势和健康风险评估',
        icon: $r('app.media.ic_atom'),
        lockMode: PremiumLockMode.SOFT_LIMIT,
        limit: createFeatureLimit(
          LimitType.TIME,
          0,      // 免费版不可查看历史（0天）
          365,    // 专业版可查看1年
          this.historyDays,
          '天'
        ),
        showTrialTip: true
      }) {
        this.buildHistoryStatsPlaceholder()
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }
  
  @Builder
  buildTodayStats() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Column() {
        Text('3次')
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
        Text('检测次数')
          .fontSize(DesignConstants.FONT_SIZE_SM)
      }
      .layoutWeight(1)
      
      Column() {
        Text('75dB')
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
        Text('最高分贝')
          .fontSize(DesignConstants.FONT_SIZE_SM)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  buildHistoryStatsPlaceholder() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('📊')
        .fontSize(48)
      Text('历史趋势图表')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
      Text('开通会员查看长期数据分析')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .height(150)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  buildHistoryStatsReal() {
    Column() {
      Text('这里是真实的历史趋势图表')
        .fontSize(DesignConstants.FONT_SIZE_MD)
    }
    .width('100%')
    .height(150)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
}

// ==========================================
// 示例5：自动保存 - 仅标签模式
// 功能可用但显示PRO标签，引导升级
// ==========================================
@ComponentV2
export struct AutoSaveExample {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local autoSaveEnabled: boolean = false;
  @Local interval: number = 5;
  
  build() {
    PremiumFeature({
      featureId: 'auto_save',
      featureName: '自动保存',
      featureDesc: '按设定时间间隔自动保存检测数据',
      icon: $r('app.media.ic_save'),
      lockMode: PremiumLockMode.BADGE_ONLY, // 仅显示标签，不阻止使用
      showTrialTip: false // 不显示试用提示，保持界面简洁
    }) {
      this.buildAutoSaveSettings()
    }
  }
  
  @Builder
  buildAutoSaveSettings() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Toggle({ type: ToggleType.Switch, isOn: this.autoSaveEnabled })
        .onChange((isOn: boolean) => {
          // 免费版也可以使用，但会有功能限制
          this.autoSaveEnabled = isOn;
        })
      
      Text('自动保存')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .layoutWeight(1)
      
      if (this.autoSaveEnabled) {
        Text(`${this.interval}分钟`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      // 点击打开详细设置
    })
  }
}

// ==========================================
// 示例6：测量精度设置页 - 综合使用多种模式
// ==========================================
@ComponentV2
export struct MeasurementPrecisionPageExample {
  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        Text('测量精度设置')
          .fontSize(DesignConstants.FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
        
        // 1. 校准 - 免费功能（手动校准），专业版增加自动校准
        this.buildCalibrationSection()
        
        // 2. 频率加权 - 对比模式
        Text('频率加权')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        FrequencyWeightingExample()
        
        // 3. 时间加权/音频分析模式 - 对比模式
        Text('音频分析模式')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        this.buildAnalysisModeSection()
        
        // 4. FFT高级参数 - 完全锁定
        Text('高级FFT参数')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
        SpectrumSettingsExample()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildCalibrationSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 手动校准 - 免费
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('手动校准')
          .fontSize(DesignConstants.FONT_SIZE_MD)
        Blank()
        Button('去校准')
          .fontSize(DesignConstants.FONT_SIZE_SM)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      
      // 自动校准 - 完全锁定
      PremiumFeature({
        featureId: 'auto_calibration',
        featureName: '智能自动校准',
        featureDesc: '根据环境自动计算最佳校准值',
        icon: $r('app.media.ic_calibration'),
        lockMode: PremiumLockMode.FULL_LOCK
      }) {
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('智能自动校准')
            .fontSize(DesignConstants.FONT_SIZE_MD)
          Blank()
          Text('未开启')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
      }
    }
    .width('100%')
  }
  
  @Builder
  buildAnalysisModeSection() {
    PremiumFeature({
      featureId: 'analysis_mode',
      featureName: '音频分析模式',
      featureDesc: '选择不同的音频分析时间响应模式',
      icon: $r('app.media.ic_time_weighting'),
      lockMode: PremiumLockMode.COMPARISON,
      comparisonList: commonFeatureComparisons.measurementPrecision.slice(1, 3),
      showTrialTip: true
    }) {
      // 免费版只有快速模式
      this.buildModeSelector(['快速模式'])
    }
  }
  
  @Builder
  buildModeSelector(modes: string[]) {
    Column({ space: DesignConstants.SPACING_SM }) {
      ForEach(modes, (mode: string, index: number) => {
        Row() {
          Text(mode)
            .fontSize(DesignConstants.FONT_SIZE_MD)
          
          Blank()
          
          Radio({ value: mode, group: 'analysis_mode' })
            .checked(index === 0)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      })
    }
    .width('100%')
  }
}

// ==========================================
// 类型定义
// ==========================================
interface ExposureStats {
  count: number;
  maxDb: number;
}
