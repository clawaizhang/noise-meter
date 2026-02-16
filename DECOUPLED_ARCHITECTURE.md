# 解耦的多设备适配架构

## 核心思想

**面向接口编程 + 工厂模式 + 运行时装配**

各端实现完全独立，通过接口定义契约，工厂负责装配，UI层只依赖接口。

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         UI 层                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  DecibelMeter.ets (通用组件)                          │  │
│  │  - 只依赖 IAudioService, IAlertService               │  │
│  │  - 不依赖任何具体实现                                  │  │
│  │  - 通过 DisplayConfig 自动适配布局                     │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │ 使用接口
┌───────────────────────────▼─────────────────────────────────┐
│                     工厂层 (Factory)                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  ServiceFactory                                       │  │
│  │  - 检测设备类型 (deviceInfo.deviceType)               │  │
│  │  - 创建对应服务实例                                    │  │
│  │  - 提供 useAudioService() 等便捷方法                   │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │ 创建实例
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   Phone Impl  │   │  Tablet Impl  │   │  Watch Impl   │
│               │   │               │   │               │
│ PhoneAudio    │   │ (继承Phone或  │   │ WatchAudio    │
│ Service       │   │  独立实现)     │   │ Service       │
│               │   │               │   │               │
│ PhoneAlert    │   │               │   │ WatchAlert    │
│ Service       │   │               │   │ Service       │
│               │   │               │   │               │
│ - 频谱分析     │   │               │   │ - 振动反馈     │
│ - 历史记录     │   │               │   │ - 省电优化     │
│ - 复杂配置     │   │               │   │ - 标记功能     │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │ 实现接口
┌───────────────────────────▼─────────────────────────────────┐
│                   接口层 (Interfaces)                        │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐     │
│  │ IAudioService │ │ IAlertService │ │ IDisplayConfig│     │
│  │               │ │               │ │               │     │
│  │ + init()      │ │ + setThreshold│ │ deviceType    │     │
│  │ + start()     │ │ + checkAlert()│ │ supportXXX    │     │
│  │ + stop()      │ │ + startAlert()│ │ fontSize      │     │
│  │ + getCurrent()│ │ + stopAlert() │ │ ...           │     │
│  └───────────────┘ └───────────────┘ └───────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构

```
entry/src/main/ets/
│
├── core/                           # 【核心层】
│   ├── interfaces/                 # 接口定义
│   │   ├── IAudioService.ets       # 音频服务接口
│   │   ├── IAlertService.ets       # 警报服务接口
│   │   └── IDisplayConfig.ets      # 显示配置接口
│   │
│   ├── factory/                    # 工厂层
│   │   └── ServiceFactory.ets      # 服务工厂
│   │
│   └── components/                 # 通用组件（只依赖接口）
│       └── DecibelMeter.ets        # 解耦的分贝检测组件
│
├── common/                         # 【通用实现】
│   ├── services/
│   │   └── AudioCoreService.ets    # 音频采集核心
│   └── utils/
│       └── DecibelCalculator.ets   # 分贝计算工具
│
├── phone/                          # 【手机端实现】
│   └── impl/
│       ├── PhoneAudioService.ets   # 实现 IAudioService
│       └── PhoneAlertService.ets   # 实现 IAlertService
│
├── wearable/                       # 【手表端实现】
│   └── impl/
│       ├── WatchAudioService.ets   # 实现 IAudioService
│       └── WatchAlertService.ets   # 实现 IAlertService
│
├── pages/                          # 【页面层】
│   ├── Index.ets                   # 手机主页面
│   └── wearable/
│       └── WatchIndex.ets          # 手表主页面
│
└── ...
```

## 关键设计

### 1. 接口定义（只定义能力，不涉及实现）

```typescript
// core/interfaces/IAudioService.ets
export interface IAudioService {
  init(): Promise<boolean>;
  start(): Promise<boolean>;
  stop(): Promise<void>;
  getCurrentDecibel(): number;
  onDataUpdate(callback: (data: AudioData) => void): void;
  // ...
}
```

### 2. 工厂装配（集中管理对象创建）

```typescript
// core/factory/ServiceFactory.ets
export class ServiceFactory {
  getAudioService(): IAudioService {
    switch (this.deviceType) {
      case 'wearable': return new WatchAudioService();
      default: return new PhoneAudioService();
    }
  }
}

// 便捷方法
export function useAudioService(): IAudioService {
  return ServiceFactory.getInstance().getAudioService();
}
```

### 3. 各端实现（完全独立，互不知晓）

```typescript
// phone/impl/PhoneAudioService.ets
export class PhoneAudioService implements IAudioService {
  // 手机特有：频谱分析
  getSpectrumData(): Float32Array { ... }
}

// wearable/impl/WatchAudioService.ets
export class WatchAudioService implements IAudioService {
  // 手表特有：振动反馈
  private vibrateStart(): void { ... }
}
```

### 4. UI组件（只依赖接口）

```typescript
// core/components/DecibelMeter.ets
@Component
export struct DecibelMeter {
  private audioService = useAudioService();  // 不依赖具体实现
  private displayConfig = useDisplayConfig(); // 自动获取设备配置
  
  build() {
    // 根据配置自动适配
    Text('...').fontSize(this.displayConfig.largeFontSize)
  }
}
```

## 解耦优势

### 1. 各端独立开发

```
手机团队修改 PhoneAudioService
    ↓
不影响 WatchAudioService
    ↓
手表功能正常运行
```

### 2. 新增设备不改动现有代码

添加车机支持：
1. 创建 `car/impl/CarAudioService.ts`
2. 在 Factory 中添加 case 'car'
3. 无需修改 phone/wearable 代码

### 3. 易于测试

```typescript
// 可以 mock 接口进行测试
class MockAudioService implements IAudioService {
  getCurrentDecibel() { return 60; }
}

// UI测试使用 mock，不依赖真实硬件
```

### 4. 运行时动态切换

```typescript
// 可以在运行时切换实现
if (userPreference.useSimpleMode) {
  return new SimpleAudioService();  // 简版
} else {
  return new PhoneAudioService();   // 完整版
}
```

## 代码示例对比

### ❌ 未解耦（紧耦合）

```typescript
// 直接依赖具体实现
import { WatchAudioService } from '../wearable/services/WatchAudioService';

@Component
struct WatchPage {
  private audioService = new WatchAudioService();  // 写死实现
  
  build() {
    // 只能用于手表
  }
}
```

### ✅ 已解耦（松耦合）

```typescript
// 只依赖接口和工厂
import { useAudioService } from '../core/factory/ServiceFactory';

@Component
struct DecibelMeter {
  private audioService = useAudioService();  // 运行时自动装配
  
  build() {
    // 自动适配手机/平板/手表
  }
}
```

## 使用方式

### 在页面中使用

```typescript
// pages/Index.ets (手机)
import { DecibelMeter } from '../core/components/DecibelMeter';

@Entry
@Component
struct PhonePage {
  build() {
    Column() {
      // 自动使用手机配置和服务
      DecibelMeter()
      
      // 手机特有功能
      SpectrumChart()  // 频谱图
      HistoryButton()  // 历史记录
    }
  }
}

// pages/wearable/WatchIndex.ets (手表)
import { DecibelMeter } from '../../core/components/DecibelMeter';

@Entry
@Component
struct WatchPage {
  build() {
    Column() {
      // 自动使用手表配置和服务
      DecibelMeter()
      
      // 手表特有功能
      MarkButton()  // 标记按钮
    }
  }
}
```

## 扩展指南

### 添加新设备（如车机）

1. **创建实现**
```typescript
// car/impl/CarAudioService.ets
export class CarAudioService implements IAudioService {
  // 实现接口方法
  // 车机特有：语音播报、驾驶模式等
}
```

2. **注册到工厂**
```typescript
// core/factory/ServiceFactory.ets
createAudioService() {
  switch (this.deviceType) {
    case 'car': return new CarAudioService();
    // ...
  }
}
```

3. **添加配置**
```typescript
// core/interfaces/IDisplayConfig.ets
DisplayConfigs = {
  car: {
    supportSpectrum: false,
    supportVibrate: false,
    largeFontSize: 72,  // 车机字体更大
    // ...
  }
}
```

4. **创建页面（可选）**
```typescript
// pages/car/CarIndex.ets
@Entry
@Component
struct CarPage {
  build() {
    DecibelMeter()  // 复用通用组件
    VoiceAlert()    // 车机特有
  }
}
```

完成！无需修改任何现有代码。

## 总结

| 维度 | 解耦前 | 解耦后 |
|------|-------|-------|
| 依赖关系 | UI → 具体实现 | UI → 接口 ← 具体实现 |
| 修改影响 | 改动一处影响多处 | 各端独立，互不影响 |
| 新增设备 | 需修改多处代码 | 只添加新实现 |
| 测试难度 | 需真实设备/服务 | 可 mock 接口测试 |
| 代码复用 | 低 | 高（通用组件） |
