# 鸿蒙多设备资源组织规范

## 目录结构

鸿蒙使用**资源限定词**机制，根据设备类型自动加载对应资源：

```
entry/src/main/resources/
│
├── base/                          # 基础资源（所有设备通用）
│   ├── element/
│   │   ├── string.json            # 默认文本
│   │   └── color.json             # 默认颜色
│   ├── media/                     # 默认图片
│   └── profile/
│       └── main_pages.json
│
├── phone/                         # 手机专用资源
│   └── element/
│       ├── string.json            # 手机专用文本
│       └── color.json             # 手机专用颜色
│
├── tablet/                        # 平板专用资源
│   └── element/
│       ├── string.json
│       └── color.json
│
├── wearable/                      # 手表专用资源 ← 我们创建的
│   ├── element/
│   │   ├── string.json            # 手表专用文本（简洁）
│   │   └── color.json             # 手表专用颜色（深色主题）
│   └── media/                     # 手表专用图片（小尺寸）
│
└── rawfile/                       # 原始文件（所有设备通用）
    └── anima/
```

## 资源加载优先级

当应用运行在不同设备上时，系统按以下优先级加载资源：

```
高优先级 → 低优先级

1. resources/{deviceType}/   (设备专用)
   - 如 resources/wearable/
   
2. resources/base/           (基础资源)
   - 通用资源
```

**示例**：
- 手表上访问 `$r('app.string.app_name')` 
  - 先查找 `resources/wearable/element/string.json`
  - 如果没有，使用 `resources/base/element/string.json`

## 代码中的使用方式

### 1. 引用资源（统一方式）

```typescript
// 无论在手机还是手表，都使用相同的引用方式
Text($r('app.string.app_name'))
  .fontColor($r('app.color.text_primary'))
  .backgroundColor($r('app.color.background_primary'))
```

### 2. 系统自动适配

| 运行设备 | 实际加载的资源 |
|---------|---------------|
| 手机 | `resources/phone/` → `resources/base/` |
| 平板 | `resources/tablet/` → `resources/base/` |
| 手表 | `resources/wearable/` → `resources/base/` |

## 我们的实现

### 手表专用资源

**resources/wearable/element/string.json**
```json
{
  "string": [
    { "name": "app_name", "value": "静喵Sound" },
    { "name": "start_button", "value": "开始" },
    { "name": "stop_button", "value": "停止" }
  ]
}
```

**resources/wearable/element/color.json**
```json
{
  "color": [
    { "name": "background_primary", "value": "#000000" },  // 黑色背景（手表省电）
    { "name": "text_primary", "value": "#FFFFFF" },        // 白色文字
    { "name": "decibel_safe", "value": "#4CAF50" }
  ]
}
```

### 代码复用示例

```typescript
// WatchIndex.ets（同时用于手机和手表）
@Entry
@Component
struct WatchIndex {
  build() {
    Column() {
      // 使用资源引用，系统会自动加载对应设备的资源
      Text($r('app.string.start_button'))
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.background_primary'))
    }
  }
}
```

## 不同设备的差异化配置

### 手表端特点

| 特性 | 配置 |
|------|------|
| 背景色 | 纯黑 `#000000`（OLED省电） |
| 文字颜色 | 白色 `#FFFFFF` |
| 文字内容 | 简洁（如"开始"而非"开始检测"） |
| 图标尺寸 | 小尺寸（节省空间） |

### 手机端特点

| 特性 | 配置 |
|------|------|
| 背景色 | 浅色/深色主题 |
| 文字颜色 | 根据主题变化 |
| 文字内容 | 完整描述 |
| 图标尺寸 | 标准尺寸 |

## 进阶：代码层面的设备判断

如果需要在代码中判断设备类型：

```typescript
import deviceInfo from '@ohos.deviceInfo';

// 获取设备类型
const deviceType = deviceInfo.deviceType;

// 根据设备调整布局
if (deviceType === 'wearable') {
  // 手表布局
  this.fontSize = 24;
} else if (deviceType === 'phone') {
  // 手机布局
  this.fontSize = 16;
}
```

## 完整的多设备适配策略

### 1. 资源层（resources/）
- 不同设备使用不同资源文件
- 自动加载，代码无感知

### 2. 代码层（ets/）
- EntryAbility 判断设备类型
- 加载对应页面（pages/Index 或 pages/wearable/WatchIndex）

### 3. 服务层（services/）
- 共享核心逻辑（shared 模块）
- 设备特有逻辑分离（如 VibrateService）

## 文件组织总结

```
entry/src/main/
├── ets/
│   ├── pages/
│   │   ├── Index.ets              # 手机主页面
│   │   └── wearable/
│   │       └── WatchIndex.ets     # 手表主页面
│   ├── services/
│   │   ├── AudioControllerService.ets
│   │   ├── WatchAudioService.ets
│   │   └── VibrateService.ets
│   └── entryability/
│       └── EntryAbility.ets       # 设备判断入口
│
├── resources/
│   ├── base/                      # 基础资源
│   ├── phone/                     # 手机资源（可选）
│   ├── tablet/                    # 平板资源（可选）
│   └── wearable/                  # 手表资源
│       ├── element/
│       │   ├── string.json
│       │   └── color.json
│       └── media/
│
└── module.json5                   # deviceTypes 配置
```

这样组织的好处：
1. **代码清晰**：不同设备的资源分开管理
2. **自动适配**：系统根据设备自动加载对应资源
3. **易于维护**：修改某设备的资源不影响其他设备
4. **扩展性好**：新增设备只需添加对应目录
