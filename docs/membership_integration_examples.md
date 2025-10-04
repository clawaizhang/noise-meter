# 会员系统集成使用示例

## 概述

本文档展示了如何在现有功能中集成新的会员系统，包括频率加权、音频分析模式、自定义模式等专业功能的会员控制。

## 1. 频率加权功能集成

### 原始代码（免费版）
```typescript
// 在FrequencyWeightingDialog.ets中的原始实现
@Builder
private buildWeightingTab(weighting: WeightingType, displayName: string, description: string) {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text(displayName)
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontWeight(FontWeight.Medium)
    
    Text(description)
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
    
    // 功能实现...
  }
}
```

### 集成会员控制后的代码
```typescript
// 集成PremiumFeature组件
@Builder
private buildWeightingTab(weighting: WeightingType, displayName: string, description: string, isPremium: boolean) {
  if (isPremium) {
    // 专业功能使用PremiumFeature包装
    PremiumFeature({
      featureName: displayName,
      featureDesc: description,
      icon: this.getWeightingIcon(weighting),
      onUpgrade: () => {
        // 升级成功后重新加载功能
        this.loadWeightingFunction(weighting);
      },
      showTrialOption: true,
      content: () => this.buildProWeightingContent(weighting, displayName)
    })
  } else {
    // 免费功能直接显示
    this.buildFreeWeightingContent(weighting, displayName, description)
  }
}

// 专业功能内容
@Builder
private buildProWeightingContent(weighting: WeightingType, displayName: string) {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text(displayName)
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontWeight(FontWeight.Medium)
    
    // 专业功能的具体实现
    this.buildAdvancedWeightingControls(weighting)
    this.buildRealTimeAnalysis(weighting)
    this.buildExportOptions(weighting)
  }
}

// 免费功能内容
@Builder
private buildFreeWeightingContent(weighting: WeightingType, displayName: string, description: string) {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text(displayName)
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontWeight(FontWeight.Medium)
    
    Text(description)
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
    
    // 基础功能实现
    this.buildBasicWeightingControls(weighting)
  }
}
```

## 2. 音频分析模式集成

### 集成示例
```typescript
// 在音频分析页面中使用
@Builder
private buildAudioAnalysisSection() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 快速响应模式（免费）
    this.buildAnalysisMode('fast', '快速响应', '适用于实时监测', false)
    
    // 慢速响应模式（专业）
    this.buildAnalysisMode('slow', '慢速响应', '适用于精密测量', true)
    
    // 脉冲响应模式（专业）
    this.buildAnalysisMode('impulse', '脉冲响应', '适用于冲击噪声分析', true)
  }
}

@Builder
private buildAnalysisMode(mode: string, displayName: string, description: string, isPremium: boolean) {
  if (isPremium) {
    PremiumFeature({
      featureName: displayName,
      featureDesc: description,
      icon: $r('app.media.ic_audio_analysis'),
      onUpgrade: () => {
        this.activateAnalysisMode(mode);
      },
      content: () => this.buildProAnalysisMode(mode, displayName)
    })
  } else {
    this.buildFreeAnalysisMode(mode, displayName, description)
  }
}
```

## 3. 自定义模式集成

### 集成示例
```typescript
// 自定义模式设置页面
@Builder
private buildCustomModeSettings() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // FFT更新间隔设置（专业）
    PremiumFeature({
      featureName: 'FFT更新间隔',
      featureDesc: '自定义FFT分析更新频率',
      icon: $r('app.media.ic_settings'),
      onUpgrade: () => {
        this.enableCustomFFTSettings();
      },
      content: () => this.buildFFTIntervalSettings()
    })
    
    // 窗函数选择（专业）
    PremiumFeature({
      featureName: '窗函数选择',
      featureDesc: '选择不同的窗函数优化频谱分析',
      icon: $r('app.media.ic_settings'),
      onUpgrade: () => {
        this.enableWindowFunctionSettings();
      },
      content: () => this.buildWindowFunctionSettings()
    })
    
    // 平滑因子设置（专业）
    PremiumFeature({
      featureName: '平滑因子',
      featureDesc: '调整数据平滑程度',
      icon: $r('app.media.ic_settings'),
      onUpgrade: () => {
        this.enableSmoothingSettings();
      },
      content: () => this.buildSmoothingSettings()
    })
    
    // 重叠率设置（专业）
    PremiumFeature({
      featureName: '重叠率',
      featureDesc: '设置FFT分析重叠比例',
      icon: $r('app.media.ic_settings'),
      onUpgrade: () => {
        this.enableOverlapSettings();
      },
      content: () => this.buildOverlapSettings()
    })
  }
}
```

## 4. 智能时段警报集成

### 集成示例
```typescript
// 警报设置页面
@Builder
private buildAlarmSettings() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 基础警报（免费）
    this.buildBasicAlarmSettings()
    
    // 智能时段警报（专业）
    PremiumFeature({
      featureName: '智能时段警报',
      featureDesc: '基于时间段的智能提醒系统',
      icon: $r('app.media.ic_alarm'),
      onUpgrade: () => {
        this.enableSmartAlarmSystem();
      },
      content: () => this.buildSmartAlarmSettings()
    })
    
    // 多条件警报（专业）
    PremiumFeature({
      featureName: '多条件警报',
      featureDesc: '支持多个条件的复杂警报规则',
      icon: $r('app.media.ic_alarm'),
      onUpgrade: () => {
        this.enableMultiConditionAlarms();
      },
      content: () => this.buildMultiConditionAlarmSettings()
    })
  }
}
```

## 5. 完整的功能权限检查

### 权限检查工具类
```typescript
// 功能权限管理工具
export class FeaturePermissionManager {
  /**
   * 检查功能权限
   */
  static hasPermission(feature: string): boolean {
    const proFeatures = {
      // 频率加权相关
      'frequency_weighting_c': true,
      'frequency_weighting_z': true,
      
      // 音频分析相关
      'audio_analysis_slow': true,
      'audio_analysis_impulse': true,
      
      // 自定义模式相关
      'custom_fft_interval': true,
      'custom_window_function': true,
      'custom_smoothing_factor': true,
      'custom_overlap_rate': true,
      
      // 警报系统相关
      'smart_time_alarms': true,
      'multi_condition_alarms': true,
      
      // 数据管理相关
      'advanced_export': true,
      'detailed_reports': true
    };
    
    if (proFeatures[feature]) {
      return MembershipManager.hasProFeature();
    }
    
    // 基础功能对所有用户开放
    return true;
  }
  
  /**
   * 获取功能状态描述
   */
  static getFeatureStatus(feature: string): string {
    if (this.hasPermission(feature)) {
      return '已解锁';
    } else {
      return '需要专业版';
    }
  }
  
  /**
   * 显示功能升级提示
   */
  static showUpgradePrompt(featureName: string, featureDesc: string, icon: Resource) {
    // 使用新的UpgradeContent组件显示升级提示
    // 实现略...
  }
}
```

## 6. 会员状态监听

### 状态监听示例
```typescript
// 会员状态变化监听
@ComponentV2
export struct ProFeatureContainer {
  @State isProMember: boolean = MembershipManager.hasProFeature();
  
  aboutToAppear() {
    // 监听会员状态变化
    MembershipManager.onMembershipChange(() => {
      this.isProMember = MembershipManager.hasProFeature();
    });
  }
  
  build() {
    Column() {
      if (this.isProMember) {
        // 显示所有专业功能
        this.buildAllProFeatures()
      } else {
        // 显示基础功能 + 升级提示
        this.buildFreeFeaturesWithUpgrade()
      }
    }
  }
  
  @Builder
  private buildFreeFeaturesWithUpgrade() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 基础功能
      this.buildBasicFeatures()
      
      // 专业功能预览（置灰）
      this.buildProFeaturesPreview()
      
      // 升级提示横幅
      this.buildUpgradeBanner()
    }
  }
  
  @Builder
  private buildUpgradeBanner() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Image($r('app.media.ic_vip'))
        .width(DesignConstants.ICON_SIZE_LG)
        .height(DesignConstants.ICON_SIZE_LG)
        .fillColor($r('sys.color.ohos_id_color_palette1'))
      
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('升级到专业版')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Text('解锁所有专业功能')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      
      Button('立即升级')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.ohos_id_color_palette1'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          showFullMembershipUpgrade();
        })
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
  }
}
```

## 7. 测试和调试

### 测试工具
```typescript
// 会员功能测试工具
export class MembershipTestUtils {
  /**
   * 模拟会员状态（仅用于测试）
   */
  static mockProMember(isPro: boolean) {
    // 在测试环境中模拟会员状态
    console.info(`模拟会员状态: ${isPro ? '专业版' : '免费版'}`);
    // 实际实现应该更新MembershipManager的状态
  }
  
  /**
   * 测试功能权限
   */
  static testFeaturePermissions() {
    const testFeatures = [
      'frequency_weighting_c',
      'audio_analysis_slow', 
      'custom_fft_interval',
      'smart_time_alarms'
    ];
    
    testFeatures.forEach(feature => {
      const hasPermission = FeaturePermissionManager.hasPermission(feature);
      console.info(`功能 "${feature}" 权限: ${hasPermission}`);
    });
  }
  
  /**
   * 显示所有升级弹窗（用于UI测试）
   */
  static showAllUpgradeDialogs() {
    showFrequencyWeightingUpgrade();
    // 延迟显示其他弹窗
    setTimeout(() => {
      showAudioAnalysisUpgrade();
    }, 3000);
    setTimeout(() => {
      showCustomModeUpgrade();
    }, 6000);
    setTimeout(() => {
      showSmartAlertsUpgrade();
    }, 9000);
  }
}
```

## 总结

通过以上集成示例，可以：

1. **渐进式升级**：用户可以先体验基础功能，再决定是否升级
2. **价值展示**：清晰展示专业功能的优势和价值
3. **无缝体验**：升级后功能立即可用，无需重新启动
4. **灵活配置**：可以根据不同功能设置不同的会员权限

这些集成模式确保了良好的用户体验，同时为应用的商业化提供了坚实的基础。