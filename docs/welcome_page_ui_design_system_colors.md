# 欢迎页UI设计规范（使用系统颜色）

## 颜色系统说明
所有颜色都使用项目中的系统颜色资源，确保深色模式适配。

## 第1页：欢迎页设计（使用系统颜色）

### 视觉布局
```
┌─────────────────────────────────────────┐
│          系统渐变背景                    │
│                                          │
│                                          │
│           ┌─────────────┐               │
│           │             │               │
│           │   APP图标   │               │
│           │             │               │
│           └─────────────┘               │
│                                          │
│          静喵Sound                      │
│          专业的噪音检测专家              │
│                                          │
│  精准测量环境噪音，保护您的听力健康     │
│                                          │
│                                          │
│        ┌─────────────┐                  │
│        │   开始探索   │                  │
│        └─────────────┘                  │
│                                          │
│              [跳过]                      │
│                                          │
└─────────────────────────────────────────┘
```

### 设计细节（系统颜色）
- **背景**：使用系统渐变或 `$r('sys.color.background_primary')`
- **图标**：应用图标 (`$r('app.media.app_icon_fore')`)，尺寸120x120，圆角16px
- **标题**：静喵Sound，字体大小24px，粗体，`$r('sys.color.font_emphasize')`
- **副标题**：专业的噪音检测专家，字体大小18px，`$r('sys.color.font_primary')`
- **描述**：精准测量环境噪音，保护您的听力健康，字体大小14px，`$r('sys.color.font_secondary')`
- **主按钮**：开始探索，胶囊形状，宽度80%，高度56px，`$r('sys.color.interactive_active')`，`$r('sys.color.font_on_primary')`
- **跳过按钮**：跳过，字体大小14px，`$r('sys.color.font_secondary')`

## 第2页：实时检测页设计（使用系统颜色）

### 视觉布局
```
┌─────────────────────────────────────────┐
│          系统背景色                      │
│  ┌─返回─┐        空白        [跳过]      │
│                                          │
│                                          │
│                85                        │
│                分贝                      │
│              [非常嘈杂]                   │
│                                          │
│        ┌─────────────────┐              │
│        │■■■■■■■■■        │              │
│        └─────────────────┘              │
│                                          │
│          实时精准检测                    │
│                                          │
│  • 毫秒级响应，实时显示分贝值            │
│  • 智能识别噪音等级，颜色直观提示        │
│  • 支持多种环境场景检测                  │
│                                          │
│  ┌─图书馆─┐ ┌─办公室─┐ ┌─街道─┐          │
│  │  35dB  │ │  65dB  │ │ 85dB │          │
│  └───────┘ └───────┘ └──────┘          │
│                                          │
│        ┌─────────────┐                  │
│        │   下一页    │                  │
│        └─────────────┘                  │
│                                          │
└─────────────────────────────────────────┘
```

### 设计细节（系统颜色）
- **背景**：`$r('sys.color.background_primary')`
- **导航**：
  - 返回按钮：`$r('sys.color.comp_background_secondary')`
  - 跳过文字：`$r('sys.color.font_secondary')`
- **分贝显示**：
  - 数值：85，字体大小32px，粗体，使用分贝颜色系统
  - 单位：分贝，字体大小16px，`$r('sys.color.font_secondary')`
  - 等级：非常嘈杂，字体大小14px，使用分贝颜色系统
- **进度条**：
  - 背景：`$r('sys.color.comp_background_secondary')`，宽度200px，高度12px，圆角6px
  - 进度：使用分贝颜色系统，根据分贝值动态变化
- **标题**：实时精准检测，字体大小20px，粗体，`$r('sys.color.font_emphasize')`
- **功能描述**：列表形式，字体大小14px，`$r('sys.color.font_secondary')`
- **场景示例**：
  - 使用项目现有的分贝颜色系统：
    - 安静：`$r('app.color.decibel_safe')` 或 `$r('app.color.decibel_very_quiet')`
    - 正常：`$r('app.color.decibel_warning')` 或 `$r('app.color.decibel_normal')`
    - 嘈杂：`$r('app.color.decibel_danger')` 或 `$r('app.color.decibel_very_noisy')`
- **按钮**：下一页，胶囊形状，宽度100%，高度56px，`$r('sys.color.interactive_active')`，`$r('sys.color.font_on_primary')`

## 第3页：高级功能页设计（使用系统颜色）

### 视觉布局
```
┌─────────────────────────────────────────┐
│          系统背景色                      │
│  ┌─返回─┐        空白        [跳过]      │
│                                          │
│       ┌─────────────────┐               │
│       │  频谱波浪图     │               │
│       │   动画效果      │               │
│       └─────────────────┘               │
│                                          │
│          专业分析工具                    │
│                                          │
│  • 实时频谱分析 - 可视化音频频率分布     │
│  • 智能数据记录 - 自动保存检测历史       │
│  • 多种加权模式 - A/C/Z专业计权         │
│                                          │
│  ┌─频谱─┐ ┌─记录─┐ ┌─加权─┐ ┌─自定义─┐   │
│  │  📊  │ │  📝  │ │  ⚖️  │ │  ⚙️   │   │
│  │频谱分析│ │数据记录│ │加权模式│ │自定义│  │
│  └─────┘ └─────┘ └─────┘ └──────┘   │
│                                          │
│        ┌─────────────┐                  │
│        │   下一页    │                  │
│        └─────────────┘                  │
│                                          │
└─────────────────────────────────────────┘
```

### 设计细节（系统颜色）
- **背景**：`$r('sys.color.background_primary')`
- **导航**：与第2页相同
- **频谱图**：
  - 高度：120px
  - 样式：`$r('sys.color.interactive_active')`，线宽2px
- **标题**：专业分析工具，字体大小20px，粗体，`$r('sys.color.font_emphasize')`
- **功能描述**：列表形式，字体大小14px，`$r('sys.color.font_secondary')`
- **功能图标网格**：
  - 所有图标：`$r('sys.color.interactive_active')`
  - 图标背景：`$r('sys.color.comp_background_secondary')`
  - 文字：`$r('sys.color.font_secondary')`
- **按钮**：下一页，样式与第2页相同

## 第4页：隐私政策页设计（使用系统颜色）

### 视觉布局
```
┌─────────────────────────────────────────┐
│          系统背景色                      │
│  ┌─返回─┐        空白        [跳过]      │
│                                          │
│          开始使用静喵Sound               │
│                                          │
│  为了提供准确的噪音检测服务，            │
│  我们需要以下必要权限：                  │
│                                          │
│  ┌─麦克风权限─┐    ┌─位置权限─┐          │
│  │   🎤      │    │   📍    │          │
│  │ 检测环境噪音 │  │ 记录检测地点 │       │
│  └──────────┘    └─────────┘          │
│                                          │
│  ┌─后台运行权限─┐                         │
│  │     🔄      │                         │
│  │  持续监测环境 │                        │
│  └───────────┘                         │
│                                          │
│  [✓] 我已阅读并同意隐私政策              │
│  您的数据安全是我们的首要任务            │
│                                          │
│        ┌─────────────┐                  │
│        │  同意并开始 │                  │
│        │    (禁用)   │                  │
│        └─────────────┘                  │
│                                          │
│              [取消]                      │
│                                          │
└─────────────────────────────────────────┘
```

### 设计细节（系统颜色）
- **背景**：`$r('sys.color.background_primary')`
- **导航**：与前面页面相同
- **标题**：开始使用静喵Sound，字体大小20px，粗体，`$r('sys.color.font_emphasize')`
- **描述**：字体大小14px，`$r('sys.color.font_secondary')`
- **权限卡片**：
  - 背景：`$r('sys.color.comp_background_secondary')`
  - 图标：`$r('sys.color.font_primary')`
  - 文字：`$r('sys.color.font_primary')`
- **隐私政策**：
  - 复选框：未选中时 `$r('sys.color.comp_border_color')`，选中时 `$r('sys.color.interactive_active')`
  - 文字：`$r('sys.color.font_primary')`
  - 链接：`$r('sys.color.interactive_active')`
- **信任声明**：字体大小12px，`$r('sys.color.font_tertiary')`
- **主按钮**：
  - 禁用状态：`$r('sys.color.comp_background_primary')`，`$r('sys.color.font_disabled')`
  - 启用状态：`$r('sys.color.interactive_active')`，`$r('sys.color.font_on_primary')`
- **取消按钮**：`$r('sys.color.font_secondary')`

## 页面指示器设计（使用系统颜色）

### 设计细节
- **激活状态**：实心圆，`$r('sys.color.interactive_active')`，直径8px
- **非激活状态**：空心圆，`$r('sys.color.comp_background_secondary')`，直径8px，透明度0.5

## 分贝颜色系统（使用项目现有颜色）

根据项目中的 [`color.json`](entry/src/main/resources/base/element/color.json)，使用以下分贝颜色：

```typescript
private getDecibelColor(decibel: number): Resource {
  if (decibel <= 40) return $r('app.color.decibel_very_quiet');    // 非常安静 - 绿色
  if (decibel <= 50) return $r('app.color.decibel_quiet');         // 安静 - 浅绿
  if (decibel <= 65) return $r('app.color.decibel_normal');        // 正常 - 黄色
  if (decibel <= 75) return $r('app.color.decibel_noisy');         // 嘈杂 - 橙色
  if (decibel <= 85) return $r('app.color.decibel_very_noisy');    // 非常嘈杂 - 红色
  return $r('app.color.decibel_unbearable');                       // 难以忍受 - 深红
}

private getDecibelLevelText(decibel: number): string {
  if (decibel <= 40) return '非常安静';
  if (decibel <= 50) return '安静';
  if (decibel <= 65) return '适中';
  if (decibel <= 75) return '嘈杂';
  if (decibel <= 85) return '非常嘈杂';
  return '难以忍受';
}
```

## 深色模式适配说明

通过使用系统颜色，欢迎页将自动适配深色模式：
- `background_primary` 在浅色模式是白色，在深色模式是深灰色
- `font_primary` 在浅色模式是黑色，在深色模式是白色
- `comp_background_secondary` 在浅色模式是浅灰色，在深色模式是中等灰色
- 所有交互元素使用 `interactive_active` 确保在两种模式下都有良好的对比度

这个设计规范确保了欢迎页在浅色和深色模式下都有良好的视觉效果和用户体验。