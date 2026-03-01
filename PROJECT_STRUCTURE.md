# 项目完整结构 - 单包多设备适配

## 目录结构概览

```
noise-meter/                                    # 项目根目录
│
├── build-profile.json5                         # 构建配置（entry + shared）
├── hvigorfile.ts
├── oh-package.json5
│
├── shared/                                     # 【共享业务模块】
│   ├── src/main/ets/
│   │   ├── services/
│   │   │   └── AudioCoreService.ets           # 音频采集核心
│   │   └── utils/
│   │       ├── DecibelCalculator.ets          # 分贝计算
│   │       └── NoiseLevelHelper.ets           # 噪音等级
│   ├── Index.ets                              # 模块导出
│   ├── build-profile.json5
│   └── oh-package.json5
│
└── entry/                                      # 【主模块 - 单包多设备】
    ├── build-profile.json5
    ├── hvigorfile.ts
    ├── oh-package.json5                        # 依赖 shared 模块
    │
    ├── src/main/ets/                           # 【ETS 代码】
    │   │
    │   ├── entryability/
    │   │   └── EntryAbility.ets               # 入口：判断设备类型，加载对应页面
    │   │
    │   ├── pages/                              # 【页面层】
    │   │   │
    │   │   ├── Index.ets                      # 手机/平板主页面（完整功能）
    │   │   ├── MainPage.ets
    │   │   │
    │   │   └── wearable/                       # 【手表专用页面】
    │   │       └── WatchIndex.ets             # 手表主页面（简洁界面）
    │   │
    │   ├── services/                           # 【服务层】
    │   │   │
    │   │   ├── AudioControllerService.ets     # 手机端音频服务（复杂功能）
    │   │   ├── WatchAudioService.ets          # 手表端音频服务（调用 shared）
    │   │   ├── VibrateService.ets             # 振动服务（手表专用）
    │   │   └── ...                            # 其他服务
    │   │
    │   ├── models/                             # 【数据模型层】
    │   │   │
    │   │   ├── AppKeys.ets                    # 手机端状态管理（@ObservedV2）
    │   │   ├── PreferenceKeys.ets             # 手机端持久化配置
    │   │   ├── WatchAppKeys.ets               # 手表端状态管理（简化版）
    │   │   └── WatchPreferenceKeys.ets        # 手表端持久化配置
    │   │
    │   ├── components/                         # 【组件层】
    │   │   ├── decibel-meter/                  # 手机端组件
    │   │   │   ├── DecibelDisplayComponent.ets
    │   │   │   ├── Dashboard.ets
    │   │   │   └── ...
    │   │   └── ...
    │   │
    │   └── utils/                              # 【工具类】
    │       ├── WindowManager.ets
    │       └── ...
    │
    └── src/main/resources/                     # 【资源文件】
        │
        ├── base/                               # 【基础资源 - 所有设备通用】
        │   ├── element/
        │   │   ├── string.json                # 默认文本
        │   │   └── color.json                 # 默认颜色
        │   ├── media/                         # 默认图片
        │   │   └── app_icon.png
        │   └── profile/
        │       └── main_pages.json
        │
        ├── phone/                              # 【手机专用资源】（可选）
        │   └── element/
        │       └── string.json
        │
        ├── tablet/                             # 【平板专用资源】（可选）
        │   └── element/
        │       └── string.json
        │
        ├── wearable/                           # 【手表专用资源】⭐
        │   ├── element/
        │   │   ├── string.json                # 手表文本（简洁）
        │   │   └── color.json                 # 手表颜色（深色主题）
        │   └── media/                         # 手表专用图片
        │
        └── rawfile/                            # 【原始文件 - 通用】
            └── anima/
```

## 设备适配流程

```
应用启动
    ↓
EntryAbility.onWindowStageCreate()
    ↓
获取 deviceInfo.deviceType
    ↓
    ├─→ wearable（手表）
    │   ├─ 初始化 WatchAppKeys、WatchPreferenceKeys
    │   └─ 加载 pages/wearable/WatchIndex
    │       └─ 使用 resources/wearable/ 资源
    │
    └─→ phone/tablet/2in1（手机/平板）
        ├─ 初始化 AppKeys、PreferenceKeys
        └─ 加载 pages/Index
            └─ 使用 resources/base/ 资源
```

## 关键文件说明

### 1. EntryAbility.ets（设备判断入口）

```typescript
import deviceInfo from '@ohos.deviceInfo';

onWindowStageCreate(windowStage: window.WindowStage) {
  const deviceType = deviceInfo.deviceType;
  
  // 动态选择页面
  const targetPage = deviceType === 'wearable' 
    ? 'pages/wearable/WatchIndex' 
    : 'pages/Index';
  
  // 动态初始化状态
  if (deviceType === 'wearable') {
    AppStorageV2.connect(WatchAppKeys, () => new WatchAppKeys())!;
  } else {
    AppStorageV2.connect(AppKeys, () => new AppKeys())!;
  }
  
  windowStage.loadContent(targetPage);
}
```

### 2. module.json5（设备类型配置）

```json
{
  "module": {
    "deviceTypes": [
      "phone",
      "tablet", 
      "wearable",
      "car",
      "2in1"
    ]
  }
}
```

### 3. 资源加载机制

| 设备类型 | 资源加载优先级 | 示例 |
|---------|---------------|------|
| 手表 | 1. resources/wearable/<br>2. resources/base/ | `$r('app.color.background_primary')` → 先查 wearable，再查 base |
| 手机 | 1. resources/phone/<br>2. resources/base/ | 同上 |
| 平板 | 1. resources/tablet/<br>2. resources/base/ | 同上 |

## 代码复用关系

```
┌─────────────────────────────────────────┐
│           shared 模块                    │
│  AudioCoreService（音频采集核心）         │
│  DecibelCalculator（分贝计算）            │
│  NoiseLevelHelper（噪音等级）             │
└─────────────────────────────────────────┘
              ↑         ↑
              │         │
    ┌─────────┘         └─────────┐
    │                             │
┌───┴─────────────────┐  ┌────────┴────────────────┐
│   entry/ets/        │  │   entry/ets/            │
│   services/         │  │   services/             │
│                     │  │                         │
│ AudioController     │  │ WatchAudioService       │
│ Service.ets         │  │ .ets                    │
│ （手机端复杂功能）    │  │ （手表端简化封装）       │
│                     │  │                         │
│ 调用 shared 核心    │  │ 调用 shared 核心         │
│ + 复杂频谱分析       │  │ + 振动提醒服务           │
└─────────────────────┘  └─────────────────────────┘
```

## 多设备资源对比

### 颜色资源

| 资源名 | base (通用) | wearable (手表) | 用途 |
|-------|-------------|-----------------|------|
| background_primary | #FFFFFF | #000000 | 主背景（手表用黑色省电） |
| text_primary | #000000 | #FFFFFF | 主文字 |
| button_primary | #0A59F7 | #0A59F7 | 按钮颜色 |

### 文本资源

| 资源名 | base (通用) | wearable (手表) | 用途 |
|-------|-------------|-----------------|------|
| start_button | 开始检测 | 开始 | 按钮文字（手表更简洁） |
| stop_button | 停止检测 | 停止 | 按钮文字 |
| app_name | 静喵-噪音检测分贝仪 Pro | 静喵-噪音检测分贝仪 | 应用名称 |

## 构建与运行

### 构建命令

```bash
# 构建完整应用（单包支持所有设备）
hvigor build

# 清理构建
hvigor clean
```

### IDE 运行

1. 连接设备（手机或手表）
2. 选择运行配置：`entry` 或 `entry.default`
3. 点击运行

系统自动根据连接的设备类型加载对应页面和资源。

## 添加新设备支持

以添加车机支持为例：

### 1. 创建车机资源

```
resources/car/element/string.json
resources/car/element/color.json
```

### 2. 创建车机页面

```
pages/car/CarIndex.ets
```

### 3. 创建车机服务

```
services/CarAudioService.ets
```

### 4. 修改 EntryAbility

```typescript
switch(deviceType) {
  case 'wearable':
    targetPage = 'pages/wearable/WatchIndex';
    break;
  case 'car':
    targetPage = 'pages/car/CarIndex';
    break;
  default:
    targetPage = 'pages/Index';
}
```

### 5. 更新 module.json5

```json
"deviceTypes": ["phone", "tablet", "wearable", "car", "2in1"]
```

## 总结

这种结构的优势：

1. **单包发布**：一个 HAP 包支持所有设备
2. **自动适配**：系统根据设备自动加载对应资源
3. **代码复用**：共享模块避免重复代码
4. **独立优化**：各端页面和服务可以独立优化
5. **易于扩展**：新增设备只需添加对应目录
