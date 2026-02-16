# 简化版项目结构

所有代码都在 `entry` 模块内，通过目录分类管理不同设备。

## 目录结构

```
entry/src/main/ets/
│
├── entryability/
│   └── EntryAbility.ets           # 入口：判断设备类型，加载对应页面
│
├── pages/                          # 页面层
│   ├── Index.ets                  # 手机主页面
│   ├── MainPage.ets
│   └── wearable/
│       └── WatchIndex.ets         # 手表主页面
│
├── common/                         # 【通用代码】
│   ├── services/
│   │   └── AudioCoreService.ets   # 音频采集核心（手机+手表共用）
│   └── utils/
│       └── DecibelCalculator.ets  # 分贝计算工具（手机+手表共用）
│
├── phone/                          # 【手机专用】
│   └── services/
│       └── (手机端复杂服务，如需拆分可放这里)
│
├── wearable/                       # 【手表专用】
│   └── services/
│       ├── WatchAudioService.ets  # 手表音频服务
│       └── VibrateService.ets     # 手表振动服务
│
├── services/                       # 原有的手机端服务
│   └── AudioControllerService.ets
│
├── models/                         # 数据模型
│   ├── AppKeys.ets                # 手机状态
│   ├── PreferenceKeys.ets
│   ├── WatchAppKeys.ets           # 手表状态
│   └── WatchPreferenceKeys.ets
│
├── components/                     # 组件
│   └── ...
│
└── utils/                          # 工具类
    └── ...
```

## 代码引用方式

### 通用代码引用
```typescript
// 手表服务引用通用服务
import { AudioCoreService } from '../../common/services/AudioCoreService';
import { DecibelCalculator } from '../../common/utils/DecibelCalculator';
```

### EntryAbility 判断设备
```typescript
import deviceInfo from '@ohos.deviceInfo';

onWindowStageCreate(windowStage: window.WindowStage) {
  const deviceType = deviceInfo.deviceType;
  const isWearable = deviceType === 'wearable';
  
  // 加载对应页面
  const targetPage = isWearable 
    ? 'pages/wearable/WatchIndex' 
    : 'pages/Index';
  
  windowStage.loadContent(targetPage);
}
```

## 优势

1. **配置简单**：只有一个 entry 模块，无多模块依赖问题
2. **代码清晰**：通过目录名就能知道代码用途
3. **易于维护**：不用处理模块间的依赖关系
4. **构建快速**：单模块构建速度快

## 构建命令

```bash
# 构建应用
hvigor build

# 或指定模块（也是 entry）
hvigor build --module entry
```

## 添加新设备

如需添加车机支持：

```
entry/src/main/ets/
├── car/                            # 新建车机目录
│   └── services/
│       └── CarAudioService.ets
├── pages/
│   └── car/
│       └── CarIndex.ets
```

EntryAbility 中添加判断：
```typescript
if (deviceType === 'wearable') {
  targetPage = 'pages/wearable/WatchIndex';
} else if (deviceType === 'car') {
  targetPage = 'pages/car/CarIndex';
} else {
  targetPage = 'pages/Index';
}
```
