# 自动保存功能设计文档

## 功能概述

为噪音检测应用添加用户可配置的自动保存功能，替换原有的60分钟固定限制。

## 核心设计

### 1. 数据模型

在 `PreferenceKeys.ets` 中添加两个字段：

```typescript
// 自动保存开关
@Trace
auto_save_enabled: boolean = PreferencesUtil.getBooleanSync('auto_save_enabled', false);

// 自动保存间隔（分钟）
@Trace  
auto_save_interval: number = PreferencesUtil.getNumberSync('auto_save_interval', 5);
```

### 2. 预设间隔选项

| 间隔 | 描述 | 适用场景 |
|------|------|----------|
| 3分钟 | 工业环境监测 | 捕捉快速变化的工业噪音 |
| 5分钟 | 综合应用 | 平衡数据完整性和存储效率 |
| 10分钟 | 社区噪音投诉 | 记录噪音事件的时间分布 |
| 20分钟 | 个人健康监测 | 减少存储占用，关注长期趋势 |
| 自定义 | 用户自定义 | 1-60分钟自由设置 |

### 3. 界面设计

#### 3.1 设置页面入口

在设置页面添加自动保存设置项：

```
[图标] 自动保存设置
     每5分钟自动保存（综合应用） >
```

#### 3.2 自动保存设置弹框

```
┌─────────────────────────────┐
│  自动保存设置               │
├─────────────────────────────┤
│  □ 启用自动保存             │
│                             │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │3分│ │5分│ │10分││20分│   │
│  │工业│ │综合│ │社区││健康│   │
│  └───┘ └───┘ └───┘ └───┘   │
│                             │
│  自定义间隔：[ 5 ] 分钟     │
│  （1-60分钟）               │
│                             │
│  ┌──────┐    ┌──────┐       │
│  │  确认  │    │  取消  │       │
│  └──────┘    └──────┘       │
└─────────────────────────────┘
```

### 4. 技术实现

#### 4.1 替换60分钟限制

删除原有的60分钟固定限制逻辑，完全使用新的自动保存定时器：

```typescript
// 在 AudioController.ets 中
private autoSaveTimer?: number;

private startAutoSave() {
  this.stopAutoSave();
  if (this.pk.auto_save_enabled && this.isRecording) {
    const interval = this.pk.auto_save_interval * 60 * 1000;
    this.autoSaveTimer = setInterval(() => {
      if (this.values.length > 0) {
        this.performSave('自动保存');
      }
    }, interval);
  }
}

private stopAutoSave() {
  if (this.autoSaveTimer) {
    clearInterval(this.autoSaveTimer);
  }
}
```

#### 4.2 集成点

- **录音开始**：调用 `this.startAutoSave()`
- **录音停止**：调用 `this.stopAutoSave()`
- **设置变化**：自动监听首选项变化

### 5. 文件修改清单

1. **entry/src/main/ets/models/PreferenceKeys.ets**
   - 添加 auto_save_enabled 和 auto_save_interval 字段

2. **entry/src/main/ets/components/auto-save/AutoSaveSettingsDialog.ets**
   - 新建自动保存设置弹框组件

3. **entry/src/main/ets/pages/noisemeter/SettingsNavigation.ets**
   - 添加自动保存设置入口
   - 添加弹框调用逻辑

4. **entry/src/main/ets/components/decibel-meter/AudioController.ets**
   - 删除60分钟限制逻辑
   - 添加自动保存定时器逻辑
   - 集成到录音生命周期

### 6. 用户体验

- **默认设置**：自动保存关闭，间隔5分钟
- **状态显示**：设置页面清晰显示当前配置
- **实时生效**：设置更改立即应用到当前录音
- **保存提示**：自动保存时显示友好提示

## 优势

1. **简洁性**：代码改动最小，逻辑清晰
2. **灵活性**：用户完全控制保存频率
3. **兼容性**：无缝替换原有功能
4. **实用性**：基于实际应用场景设计间隔选项