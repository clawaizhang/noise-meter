# Emoji到图标替换实施计划

## 概述
本计划旨在将APP中使用的emoji表情替换为项目中已定义的图标资源，以保持UI设计的一致性和专业性。

## 当前emoji使用情况分析

### 1. WelcomePage组件
- 🎯 实时精准检测 → `ic_meter`
- 📊 智能数据分析 → `ic_stats`  
- 🔔 智能提醒保护 → `ic_alarm`

### 2. RealTimeDetectionPage组件
- 😊 实时守护您的听力健康 → `ic_smile`
- 🎵 即时响应，随时了解环境噪音 → `ic_audio_analysis`
- 🎯 智能识别，贴心提醒 → `ic_meter`
- 🏠 支持多种环境场景检测 → `ic_home`
- 📚 图书馆场景 → `ic_document_edit`
- 💼 办公室场景 → `ic_user`
- 🚗 街道场景 → `ic_location`

### 3. AdvancedFeaturesPage组件
- 📊 频谱分析 → `ic_stats`
- ⚖️ 计权模式 → `ic_weighting`
- 🔔 智能警报 → `ic_alarm`
- 📝 历史记录 → `ic_document_edit`
- ⏰ 时段调度 → `ic_time_weighting`
- 📋 专业报告 → `ic_info`

### 4. Statistics组件
- 🔊 噪音组合 → `ic_audio_analysis`
- ⚠️ 危险噪音警告 → `ic_alarm`
- 🔉 商业区标准 → `ic_audio_analysis`
- 🗣️ 居民区标准 → `ic_user`
- 🤫 疗养区标准 → `ic_moon`
- 🌙 环境非常安静 → `ic_moon`
- 📝 建议 → `ic_document_edit`

## 实施步骤

### 第一步：创建图标映射工具函数
创建 `entry/src/main/ets/utils/IconMapper.ets` 文件，包含emoji到图标资源的映射关系。

### 第二步：修改组件文件
逐个修改以下文件中的emoji使用：
1. `entry/src/main/ets/components/welcome/WelcomePage.ets`
2. `entry/src/main/ets/components/welcome/RealTimeDetectionPage.ets`
3. `entry/src/main/ets/components/welcome/AdvancedFeaturesPage.ets`
4. `entry/src/main/ets/components/noise-dialogs/Statistics.ets`

### 第三步：测试验证
- 验证所有图标正确显示
- 检查不同设备上的兼容性
- 确保动画效果不受影响

## 技术实现细节

### IconMapper.ets 文件内容
```typescript
export class IconMapper {
  static getIconForEmoji(emoji: string): Resource {
    const iconMap: Record<string, Resource> = {
      '🎯': $r('app.media.ic_meter'),
      '📊': $r('app.media.ic_stats'),
      '🔔': $r('app.media.ic_alarm'),
      '😊': $r('app.media.ic_smile'),
      '🎵': $r('app.media.ic_audio_analysis'),
      '🏠': $r('app.media.ic_home'),
      '📚': $r('app.media.ic_document_edit'),
      '💼': $r('app.media.ic_user'),
      '🚗': $r('app.media.ic_location'),
      '⚖️': $r('app.media.ic_weighting'),
      '📝': $r('app.media.ic_document_edit'),
      '⏰': $r('app.media.ic_time_weighting'),
      '📋': $r('app.media.ic_info'),
      '🔊': $r('app.media.ic_audio_analysis'),
      '⚠️': $r('app.media.ic_alarm'),
      '🔉': $r('app.media.ic_audio_analysis'),
      '🗣️': $r('app.media.ic_user'),
      '🤫': $r('app.media.ic_moon'),
      '🌙': $r('app.media.ic_moon')
    };
    
    return iconMap[emoji] || $r('app.media.ic_info');
  }
}
```

### 组件修改模式
将原来的：
```typescript
Text('🎯 实时精准检测')
```
改为：
```typescript
Row({ space: DesignConstants.SPACING_SM }) {
  Image($r('app.media.ic_meter'))
    .width(DesignConstants.ICON_SIZE_MD)
  Text('实时精准检测')
}
```

## 预期效果
- 统一的图标设计风格
- 更好的跨平台兼容性
- 更专业的UI视觉效果
- 保持原有的功能性和用户体验