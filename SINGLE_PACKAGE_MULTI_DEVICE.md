# 单包多设备适配方案

## 概述

本项目采用**单 HAP 包支持多设备**的方案，一个安装包同时支持：
- 📱 手机 (phone)
- 📱 平板 (tablet)
- ⌚ 手表 (wearable)
- 🚗 车机 (car)
- 📱 折叠屏 (2in1)

## 架构设计

```
entry (HAP - 主模块)
├── deviceTypes: phone, tablet, wearable, car, 2in1
│
├── EntryAbility.ets
│   └── 根据 deviceType 动态加载对应页面
│       ├── phone/tablet/2in1 → pages/Index (完整功能)
│       └── wearable → pages/wearable/WatchIndex (简化界面)
│
├── pages/
│   ├── Index.ets                      # 手机/平板主页面
│   └── wearable/
│       └── WatchIndex.ets             # 手表主页面
│
├── services/
│   ├── AudioControllerService.ets     # 手机端音频服务
│   ├── WatchAudioService.ets          # 手表端音频服务
│   └── VibrateService.ets             # 振动服务（手表专用）
│
├── models/
│   ├── AppKeys.ets                    # 手机端状态管理
│   ├── PreferenceKeys.ets             # 手机端持久化
│   ├── WatchAppKeys.ets               # 手表端状态管理
│   └── WatchPreferenceKeys.ets        # 手表端持久化
│
└── 依赖: shared (共享业务模块)

shared (HAR - 共享模块)
├── AudioCoreService.ets               # 音频采集核心
├── DecibelCalculator.ets              # 分贝计算
└── NoiseLevelHelper.ets               # 噪音等级
```

## 核心实现

### 1. 设备类型判断 (EntryAbility)

```typescript
import deviceInfo from '@ohos.deviceInfo';

onWindowStageCreate(windowStage: window.WindowStage): void {
  // 判断设备类型
  const deviceType = deviceInfo.deviceType;
  const isWearable = deviceType === 'wearable';
  
  // 根据设备类型加载不同页面
  const targetPage = isWearable ? 'pages/wearable/WatchIndex' : 'pages/Index';
  
  // 初始化对应的状态管理
  if (isWearable) {
    AppStorageV2.connect(WatchAppKeys, () => new WatchAppKeys())!;
    PersistenceV2.connect(WatchPreferenceKeys, () => new WatchPreferenceKeys())!;
  } else {
    // 手机/平板端初始化...
  }
  
  // 加载页面
  windowManager.loadContent(targetPage, ...);
}
```

### 2. 设备类型配置 (module.json5)

```json
{
  "module": {
    "deviceTypes": [
      "phone",
      "tablet",
      "car",
      "2in1",
      "wearable"
    ]
  }
}
```

### 3. 代码复用策略

**共享模块 (shared)**：
- 纯业务逻辑，无 UI 代码
- 被所有设备端复用

**设备专用代码**：
- `WatchIndex` - 手表专用 UI
- `WatchAudioService` - 手表专用音频服务（调用共享模块）
- `VibrateService` - 手表专用振动服务

## 构建与运行

### 构建命令

```bash
# 构建完整应用（单包包含所有设备支持）
hvigor build

# 构建特定 target
hvigor build --target entry-default
hvigor build --target entry-noise_meter_pro
```

### IDE 运行配置

由于是一个包支持多设备，只需一个运行配置：

1. **选择设备**：连接手机或手表
2. **运行配置**：选择 `entry` 或 `entry.default` / `entry.noise_meter_pro`
3. **自动适配**：EntryAbility 会自动判断设备类型并加载对应页面

## 各端功能对比

| 功能 | 手机/平板 | 手表 |
|------|----------|------|
| 实时分贝检测 | ✅ | ✅ |
| 频谱分析 | ✅ | ❌ |
| 历史记录 | ✅ | ❌ |
| 专业报告 | ✅ | ❌ |
| 振动提醒 | ❌ | ✅ |
| 快速标记 | ✅ | ✅ |
| 后台检测 | ✅ | ⚠️ 有限支持 |

## 添加新设备支持

以添加车机支持为例：

1. **创建车机专用页面**
```
pages/
└── car/
    └── CarIndex.ets
```

2. **修改 EntryAbility 判断逻辑**
```typescript
const deviceType = deviceInfo.deviceType;
let targetPage: string;

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

3. **创建车机专用服务（可选）**
```
services/
└── CarAudioService.ets
```

4. **添加车机状态管理（可选）**
```
models/
├── CarAppKeys.ets
└── CarPreferenceKeys.ets
```

## 优势对比

### 单包方案 vs 分包方案

| 维度 | 单包方案（当前） | 分包方案 |
|------|----------------|----------|
| **安装包数量** | 1个 | 多个（每个设备一个） |
| **应用商店发布** | 一次发布 | 多次发布 |
| **代码共享** | 容易（同一模块） | 较难（跨模块） |
| **包体积** | 较大（包含所有代码） | 较小（只包含当前设备代码） |
| **维护成本** | 低 | 高 |
| **用户体验** | 好（自动适配） | 需选择对应版本 |

## 注意事项

1. **包体积控制**
   - 共享模块保持精简
   - 各端代码按需引入
   - 资源文件使用动态加载

2. **设备特性检测**
   ```typescript
   // 推荐：运行时检测
   import deviceInfo from '@ohos.deviceInfo';
   const deviceType = deviceInfo.deviceType;
   
   // 不推荐：编译时条件编译
   // #ifdef wearable
   ```

3. **状态管理隔离**
   - 手机端和手表端使用不同的状态管理类
   - 避免状态冲突

4. **权限配置**
   - 在 module.json5 中配置所有设备需要的权限
   - 手表端不需要的权限可以不在代码中使用

## 常见问题

### Q1: 如何调试特定设备页面？

**A**: 连接对应设备运行即可，EntryAbility 会自动判断并加载对应页面。

### Q2: 手表端代码会增加手机端包体积吗？

**A**: 会，但影响有限。手表端代码主要是 UI 页面，体积不大。如果担心体积，可以使用动态特性（Dynamic Feature）。

### Q3: 能否根据设备类型动态下载代码？

**A**: 可以，使用 HarmonyOS 的 Dynamic Ability 特性，但实现较复杂。当前方案已满足大部分场景。

### Q4: 如何测试没有真机的情况？

**A**: 使用模拟器选择对应设备类型，或在 EntryAbility 中临时修改 deviceType 的值进行测试。

## 后续优化

1. **动态特性 (Dynamic Feature)**
   - 手表端代码作为动态模块
   - 首次运行在手表上时下载

2. **更多设备支持**
   - 智慧屏 (TV)
   - 智能眼镜 (glasses)

3. **代码按需加载**
   - 使用 ES 动态 import
   - 减少启动时间
