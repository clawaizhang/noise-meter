# 更新后的会员功能字符串资源

## 根据新价格和功能调整的字符串资源

需要在 `entry/src/main/resources/base/element/string.json` 中更新以下会员相关字符串：

```json
{
  "string": [
    // 会员相关字符串（更新价格）
    {
      "name": "membership_upgrade_title",
      "value": "升级到专业版"
    },
    {
      "name": "membership_upgrade_subtitle",
      "value": "解锁更多专业功能，提升测量体验"
    },
    {
      "name": "membership_benefits_title",
      "value": "专业版权益"
    },
    {
      "name": "membership_pricing_title",
      "value": "选择方案"
    },
    {
      "name": "membership_comparison_title",
      "value": "功能对比"
    },
    {
      "name": "membership_premium_badge",
      "value": "专业版"
    },
    {
      "name": "membership_most_popular",
      "value": "最受欢迎"
    },
    {
      "name": "membership_monthly_plan",
      "value": "月度方案"
    },
    {
      "name": "membership_yearly_plan",
      "value": "年度方案"
    },
    {
      "name": "membership_lifetime_plan",
      "value": "永久方案"
    },
    {
      "name": "membership_trial_option",
      "value": "7天免费试用"
    },
    {
      "name": "membership_trial_note",
      "value": "试用结束后自动续费"
    },
    {
      "name": "membership_upgrade_now",
      "value": "立即升级"
    },
    {
      "name": "membership_later",
      "value": "稍后再说"
    },
    {
      "name": "membership_save_percentage",
      "value": "节省{0}%"
    },
    
    // 更新后的权益描述
    {
      "name": "benefit_frequency_weighting_title",
      "value": "多频率加权"
    },
    {
      "name": "benefit_frequency_weighting_desc",
      "value": "A/C/Z计权模式，满足不同场景需求"
    },
    {
      "name": "benefit_audio_analysis_title",
      "value": "音频分析模式"
    },
    {
      "name": "benefit_audio_analysis_desc",
      "value": "快速/慢速/脉冲响应，精准音频分析"
    },
    {
      "name": "benefit_smart_alerts_title",
      "value": "智能时段警报"
    },
    {
      "name": "benefit_smart_alerts_desc",
      "value": "基于时间段的智能提醒系统"
    },
    {
      "name": "benefit_custom_mode_title",
      "value": "自定义模式"
    },
    {
      "name": "benefit_custom_mode_desc",
      "value": "FFT参数自定义，个性化测量配置"
    },
    {
      "name": "benefit_history_reports_title",
      "value": "历史记录报告"
    },
    {
      "name": "benefit_history_reports_desc",
      "value": "完整测量历史，趋势分析可视化"
    },
    {
      "name": "benefit_no_ads_title",
      "value": "无广告体验"
    },
    {
      "name": "benefit_no_ads_desc",
      "value": "纯净使用环境，专注测量"
    },
    
    // 自定义模式详细说明
    {
      "name": "custom_mode_fft_interval",
      "value": "FFT更新间隔"
    },
    {
      "name": "custom_mode_window_function",
      "value": "窗函数选择"
    },
    {
      "name": "custom_mode_smoothing_factor",
      "value": "平滑因子"
    },
    {
      "name": "custom_mode_overlap_rate",
      "value": "重叠率设置"
    },
    {
      "name": "custom_mode_advanced_settings",
      "value": "高级参数设置"
    },
    
    // 更新后的功能对比
    {
      "name": "comparison_feature_column",
      "value": "功能特性"
    },
    {
      "name": "comparison_free_column",
      "value": "免费版"
    },
    {
      "name": "comparison_pro_column",
      "value": "专业版"
    },
    {
      "name": "comparison_frequency_weighting",
      "value": "频率加权"
    },
    {
      "name": "comparison_audio_analysis",
      "value": "音频分析"
    },
    {
      "name": "comparison_alerts_system",
      "value": "警报系统"
    },
    {
      "name": "comparison_custom_mode",
      "value": "自定义设置"
    },
    {
      "name": "comparison_history_reports",
      "value": "历史报告"
    },
    {
      "name": "comparison_ads",
      "value": "广告显示"
    },
    {
      "name": "comparison_free_frequency",
      "value": "仅A计权"
    },
    {
      "name": "comparison_pro_frequency",
      "value": "A/C/Z计权"
    },
    {
      "name": "comparison_free_audio",
      "value": "基础模式"
    },
    {
      "name": "comparison_pro_audio",
      "value": "快速/慢速/脉冲"
    },
    {
      "name": "comparison_free_alerts",
      "value": "基础警报"
    },
    {
      "name": "comparison_pro_alerts",
      "value": "智能时段警报"
    },
    {
      "name": "comparison_free_custom",
      "value": "不支持"
    },
    {
      "name": "comparison_pro_custom",
      "value": "FFT参数自定义"
    },
    {
      "name": "comparison_free_history",
      "value": "基础查看"
    },
    {
      "name": "comparison_pro_history",
      "value": "完整趋势分析"
    },
    {
      "name": "comparison_free_ads",
      "value": "有广告"
    },
    {
      "name": "comparison_pro_ads",
      "value": "无广告"
    },
    
    // 价格方案描述
    {
      "name": "pricing_monthly_description",
      "value": "¥6/月，灵活选择"
    },
    {
      "name": "pricing_yearly_description",
      "value": "¥58/年，节省20%"
    },
    {
      "name": "pricing_lifetime_description",
      "value": "¥88，永久拥有"
    },
    {
      "name": "pricing_daily_cost",
      "value": "日均¥{0}"
    },
    {
      "name": "pricing_best_value",
      "value": "性价比最高"
    },
    
    // 购买流程
    {
      "name": "purchase_loading",
      "value": "正在处理..."
    },
    {
      "name": "purchase_success",
      "value": "购买成功！"
    },
    {
      "name": "purchase_failed",
      "value": "购买失败，请重试"
    },
    {
      "name": "purchase_restore",
      "value": "恢复购买"
    },
    {
      "name": "purchase_terms",
      "value": "购买即表示同意服务条款和隐私政策"
    },
    
    // 价格优势说明
    {
      "name": "price_advantage_yearly",
      "value": "相比月度方案每年节省¥14"
    },
    {
      "name": "price_advantage_lifetime",
      "value": "相当于1.5年的年度会员"
    },
    {
      "name": "value_proposition_affordable",
      "value": "亲民价格享受专业功能"
    }
  ]
}
```

## 价格方案配置数据

### 更新后的价格方案配置

```typescript
const pricingPlans: PricingPlan[] = [
  {
    type: 'monthly',
    price: 6,
    isRecommended: false,
    features: [
      '所有专业功能',
      '月度更新支持',
      '灵活选择'
    ]
  },
  {
    type: 'yearly',
    price: 58,
    originalPrice: 72, // 6 * 12 = 72
    discount: '节省20%',
    isRecommended: true,
    features: [
      '所有专业功能',
      '年度更新支持',
      '价格优惠',
      '最受欢迎'
    ]
  },
  {
    type: 'lifetime',
    price: 88,
    isRecommended: false,
    features: [
      '所有专业功能',
      '永久使用',
      '最佳性价比',
      '一次购买永久拥有'
    ]
  }
];
```

### 权益展示配置

```typescript
const benefits: BenefitItem[] = [
  {
    icon: $r('app.media.ic_frequency_weighting'),
    title: $r('app.string.benefit_frequency_weighting_title'),
    description: $r('app.string.benefit_frequency_weighting_desc')
  },
  {
    icon: $r('app.media.ic_audio_analysis'),
    title: $r('app.string.benefit_audio_analysis_title'),
    description: $r('app.string.benefit_audio_analysis_desc')
  },
  {
    icon: $r('app.media.ic_alarm'),
    title: $r('app.string.benefit_smart_alerts_title'),
    description: $r('app.string.benefit_smart_alerts_desc')
  },
  {
    icon: $r('app.media.ic_settings'),
    title: $r('app.string.benefit_custom_mode_title'),
    description: $r('app.string.benefit_custom_mode_desc')
  },
  {
    icon: $r('app.media.ic_history'),
    title: $r('app.string.benefit_history_reports_title'),
    description: $r('app.string.benefit_history_reports_desc')
  },
  {
    icon: $r('app.media.ic_vip'),
    title: $r('app.string.benefit_no_ads_title'),
    description: $r('app.string.benefit_no_ads_desc')
  }
];
```

## 自定义模式详细参数

### 技术参数配置字符串

```typescript
// 自定义模式参数描述
const customModeParams = {
  fftInterval: {
    label: $r('app.string.custom_mode_fft_interval'),
    range: { min: 50, max: 5000, step: 50 },
    unit: 'ms'
  },
  windowFunction: {
    label: $r('app.string.custom_mode_window_function'),
    options: [
      { value: 'hann', label: '汉宁窗' },
      { value: 'hamming', label: '汉明窗' },
      { value: 'rectangular', label: '矩形窗' }
    ]
  },
  smoothingFactor: {
    label: $r('app.string.custom_mode_smoothing_factor'),
    range: { min: 0.1, max: 1.0, step: 0.1 }
  },
  overlapRate: {
    label: $r('app.string.custom_mode_overlap_rate'),
    range: { min: 0, max: 0.75, step: 0.05 },
    unit: '%'
  }
};
```

## 营销文案优化

### 价值主张文案

```typescript
const valuePropositions = {
  affordable: $r('app.string.value_proposition_affordable'),
  professional: '专业工具满足精密测量需求',
  customizable: '完全个性化的测量配置体验',
  adFree: '纯净环境专注专业测量'
};
```

### 价格优势文案

```typescript
const priceAdvantages = {
  yearly: $r('app.string.price_advantage_yearly'),
  lifetime: $r('app.string.price_advantage_lifetime'),
  dailyCost: (cost: number) => 
    $r('app.string.pricing_daily_cost', cost.toFixed(2))
};
```

这个更新后的字符串资源文件完全反映了新的价格策略和功能调整，为会员升级页面提供了完整的本地化支持。