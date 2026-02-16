# 鸿蒙多端适配方案 - 噪音检测专业版

## 📋 架构总览

本项目采用 **"共享模块 + 独立 UI"** 的多端适配方案：

```
┌─────────────────────────────────────────────────────────────┐
│                      共享业务层 (shared)                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  AudioCoreService    - 音频采集核心服务              │    │
│  │  DecibelCalculator   - 分贝计算工具类                │    │
│  │  NoiseLevelHelper    - 噪音等级辅助类                │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     entry       │  │ entry_wearable  │  │  entry_pad      │
│   (手机/平板)    │  │    (手表)        │  │   (折叠屏)      │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│ 完整功能界面     │  │ 简洁检测界面     │  │ 适配大屏界面     │
│ - 频谱分析       │  │ - 实时分贝       │  │ - 双栏布局       │
│ - 历史记录       │  │ - 振动提醒       │  │ - 图表增强       │
│ - 专业报告       │  │ - 快速标记       │  │ - 多窗口支持     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 🎯 方案优势

| 优势 | 说明 |
|------|------|
| **代码复用** | 核心音频逻辑只写一次，多端共享 |
| **独立优化** | 各端 UI 完全独立，体验最优化 |
| **并行开发** | 各端团队可独立开发，互不干扰 |
| **渐进扩展** | 新增设备端只需新增模块，不影响现有代码 |

## 📁 模块结构

### 1. shared（共享模块）

```
shared/
├── src/main/ets/
│   ├── services/
│   │   └── AudioCoreService.ets    # 音频采集服务
│   └── utils/
│       ├── DecibelCalculator.ets   # 分贝计算
│       └── NoiseLevelHelper.ets    # 噪音等级
└── Index.ets                        # 模块导出
```

**特点**：
- 纯业务逻辑，无 UI 代码
- 被 entry 和 entry_wearable 依赖
- 可独立测试

### 2. entry（手机/平板端）

```
entry/
├── deviceTypes: phone, tablet, car, 2in1
├── 完整的功能实现
└── 依赖 shared 模块
```

### 3. entry_wearable（手表端）

```
entry_wearable/
├── deviceTypes: wearable
├── 简化的检测界面
├── 特有的振动服务
└── 依赖 shared 模块
```

## 🔧 开发配置

### 构建命令

```bash
# 1. 构建共享模块
hvigor build --module shared

# 2. 构建手机端
hvigor build --module entry

# 3. 构建手表端
hvigor build --module entry_wearable

# 4. 构建全部
hvigor build
```

### IDE 运行配置

#### 场景1：只运行手机端
1. 选择设备：**华为手机/平板**
2. 运行配置：**entry**（或 entry.default / entry.noise_meter_pro）

#### 场景2：只运行手表端
1. 选择设备：**华为手表**
2. 运行配置：**entry_wearable**

> ⚠️ **重要**：不要选择 "APP" 配置运行，因为那样会尝试构建所有模块

#### 场景3：创建专门的运行配置
1. 点击右上角运行配置下拉框 → **Edit Configurations...**
2. 点击 **+** → **HarmonyOS App**
3. 配置参数：

**手机端配置：**
```
Name: NoiseMeter-Phone
Module: entry
Target: default (或 noise_meter_pro)
```

**手表端配置：**
```
Name: NoiseMeter-Watch
Module: entry_wearable
Target: default
```

## 📝 代码示例

### 在 entry 或 entry_wearable 中使用共享模块

```typescript
// 导入共享模块
import { AudioCoreService, DecibelCalculator, NoiseLevelHelper } from 'shared';

// 使用音频服务
const audioService = AudioCoreService.getInstance();
audioService.init();
audioService.start((buffer, size) => {
  // 计算分贝
  const db = DecibelCalculator.calculate(buffer, size, 0);
  
  // 获取噪音等级
  const level = NoiseLevelHelper.getLevelInfo(db);
  console.log(`当前噪音: ${db}dB, 等级: ${level.description}`);
});
```

### 添加新的设备端（示例：折叠屏）

1. **创建新模块**
```bash
mkdir entry_pad
# 复制 entry_wearable 结构并修改
```

2. **配置 module.json5**
```json
{
  "module": {
    "name": "entry_pad",
    "deviceTypes": ["tablet"],
    // ... 其他配置
  }
}
```

3. **添加依赖**
```json
// entry_pad/oh-package.json5
{
  "dependencies": {
    "shared": "file:../shared"
  }
}
```

4. **注册到 build-profile.json5**
```json
{
  "name": "entry_pad",
  "srcPath": "./entry_pad",
  "targets": [{ "name": "default" }]
}
```

## 🎨 UI 适配建议

### 各端设计原则

| 设备 | 设计重点 | 布局特点 |
|------|---------|---------|
| **手机** | 功能完整，信息丰富 | 单/双栏自适应 |
| **平板** | 利用大屏空间 | 双栏/三栏布局 |
| **手表** | 核心信息，快速操作 | 垂直居中，大字体 |
| **折叠屏** | 展开/折叠状态切换 | 动态布局调整 |

### 设备类型检测

```typescript
import deviceInfo from '@ohos.deviceInfo';

// 获取设备类型
const deviceType = deviceInfo.deviceType;

switch(deviceType) {
  case 'phone':
  case 'tablet':
    // 手机/平板逻辑
    break;
  case 'wearable':
    // 手表逻辑
    break;
  case '2in1':
    // 折叠屏逻辑
    break;
}
```

## 📊 模块依赖图

```
build-profile.json5
├── shared (HAR - 静态共享库)
│   └── 无依赖
├── entry (HAP - 主模块)
│   └── 依赖: shared
└── entry_wearable (HAP - 手表模块)
    └── 依赖: shared
```

## 🔍 常见问题

### Q1: 构建时提示 "device type does not match"
**原因**：IDE 尝试构建所有模块，但当前选择的设备类型不匹配某些模块
**解决**：
- 方法1：命令行只构建指定模块 `hvigor build --module entry_wearable`
- 方法2：IDE 中选择正确的运行配置

### Q2: shared 模块修改后没有生效
**解决**：
```bash
# 清理缓存后重新构建
hvigor clean
hvigor build
```

### Q3: 如何在共享模块中使用 UI 能力
**建议**：
- 共享模块应该保持纯逻辑
- 如果需要 UI 相关工具，在各端模块中实现
- 或使用条件编译隔离平台相关代码

## 🚀 后续扩展

### 计划支持的设备

- [x] 手机 (phone)
- [x] 平板 (tablet)
- [x] 手表 (wearable)
- [ ] 折叠屏 (2in1)
- [ ] 车机 (car)
- [ ] 智慧屏 (tv)

### 扩展步骤

1. 创建 entry_{device} 模块
2. 配置 deviceTypes
3. 添加 shared 依赖
4. 实现该端特有 UI
5. 注册到 build-profile.json5

## 📚 参考文档

- [鸿蒙多设备适配指南](https://developer.harmonyos.com/)
- [HAP/HAR 模块开发](https://developer.harmonyos.com/)
- [ArkUI 多端适配](https://developer.harmonyos.com/)
