# 静喵 · 噪音检测分贝仪 (Noise Meter Pro)

> 基于 HarmonyOS 的智能噪音监测与分析系统，支持手机、平板、手表、车机等全场景设备。
>
> 包名：`yu.zhang.myapplication.noise_meter_pro` | 版本：2.0.0 | API：20+

![HarmonyOS](https://img.shields.io/badge/HarmonyOS-6.0-blue)
![API](https://img.shields.io/badge/API-20-green)
![License](https://img.shields.io/badge/License-MIT-orange)

---

## 📱 功能概览

| 功能 | 描述 |
|------|------|
| **实时噪音检测** | 高精度分贝测量，支持 A/C/Z 频率加权 & 快/慢/脉冲时间加权 |
| **频谱分析** | FFT 实时频谱图，带平滑处理、峰值追踪、瀑布图可视化 |
| **噪音警报** | 可自定义阈值，超限触发通知/振动/记录，支持历史查询 |
| **数据记录** | 本地持久化存储（RDB），支持筛选、统计、导出 |
| **地理位置** | 噪音数据自动地理位置标记，查看时空分布 |
| **健康暴露** | 基于 NIOSH/OSHA 标准的噪音暴露评估与建议 |
| **频谱设置** | 窗口函数选择、采样率/FFT 点数配置、动态分辨率调节 |
| **音频录制** | 噪音环境 WAV 录制与回放 |
| **会员福利** | 连续签到奖励、抽奖活动、会员权益升级 |
| **全场景适配** | 手机 / 平板 / 手表 / 车机 / 2合1 设备自适应 |

---

## 🏗️ 技术架构

```
entry/src/main/ets/
├── core/                  # 核心业务逻辑与抽象接口
│   ├── SpectrumAnalysisCore.ets  # FFT 频谱分析引擎
│   ├── components/               # 核心组件
│   ├── factory/                  # 服务工厂 (DI)
│   └── interfaces/              # 抽象接口定义
├── services/              # 应用服务层 (27个)
│   ├── AudioControllerService.ets # 音频控制器
│   ├── AlertService.ets          # 警报服务
│   ├── DecibelService.ets        # 分贝测量
│   ├── ExposureStatisticsService.ets # 暴露统计
│   ├── LocationService.ets       # 位置服务
│   ├── RelationalStoreService.ets # 数据库服务
│   └── ...
├── pages/                 # 页面导航
│   ├── Index.ets                 # 首页入口
│   ├── noisemeter/              # 噪音计主页面 & 弹窗
│   ├── settings/                # 设置页面
│   ├── alerts/                  # 警报页面
│   └── wearable/               # 手表专属页面
├── components/            # UI 组件 (25个分类)
│   ├── decibel-meter/            # 分贝表盘、仪表板
│   ├── dashboard/               # 首页看板
│   ├── frequency-weighting/     # 频率加权
│   ├── time-weighting/          # 时间加权
│   ├── calibration/             # 校准
│   ├── spectrum/                # 频谱图
│   ├── exposure/                # 健康暴露
│   ├── membership/              # 会员系统
│   └── ...
├── models/                # 数据模型 & 状态管理 (@ObservedV2 / @AppStorageV2)
├── constants/             # 常量定义 (16个)
├── utils/                 # 工具类 (26个)
├── concurrent/            # 并发任务 (FFT / 色图生成)
├── phone/impl/            # 手机端服务实现
├── wearable/impl/         # 手表端服务实现
└── entryability/          # 应用入口
```

### 核心依赖

| 包 | 用途 |
|---|------|
| `@pura/harmony-utils` | HarmonyOS 工具库 (AppUtil, PermissionUtil) |
| `@ohos/lottie-turbo` | 高性能 Lottie 动画渲染 |
| `@hadss/dialoghub` | 弹窗管理 |
| `rxjs` | 响应式编程 |
| `@ohos/mpchart` | 图表渲染 (统计/报告) |
| `@ohos/hypium` | 单元测试框架 |

---

## 🔧 开发环境

| 工具 | 版本 |
|------|------|
| HarmonyOS | 6.0.0 (API 20) |
| ArkTS | Stage 模型 |
| DevEco Studio | 5.0+ |
| Hvigor | 最新 |
| Node.js | 18+ |

---

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/clawaizhang/noise-meter.git

# 打开项目
# 使用 DevEco Studio 打开项目根目录

# 安装依赖
ohpm install

# 构建 & 运行
# DevEco Studio → 运行 → 选择目标设备
```

---

## 📦 构建发布

```bash
# 调试构建
hvigorw assembleHap --mode module -p product=default

# 正式构建 (noise_meter_pro)
hvigorw assembleHap --mode module -p product=noise_meter_pro

# 构建 App Pack (发布)
hvigorw assembleApp --mode project -p product=noise_meter_pro
```

---

## 📋 功能详情

### 🔊 噪音检测
- 实时分贝值显示（数字 + 指针表盘）
- 多种频率加权：A 加权（人耳模拟）、C 加权（低频）、Z 加权（全频平直）
- 时间加权：快 (125ms) / 慢 (1s) / 脉冲
- 校准功能：自动校准 & 手动偏移补偿

### 📊 频谱分析
- FFT 实时频谱图（16Hz - 16kHz）
- 峰值频率追踪与标记
- 瀑布图（时间-频率三维可视化）
- 窗口函数选择（Hanning / Hamming / Blackman / 矩形）
- 频谱平滑处理
- 自适应分辨率调节
- 动态色图渲染（并发 Worker 优化）

### ⚠️ 噪音警报
- 自定义阈值（支持多次阈值设置）
- 超限触发：通知栏提醒 + 振动 + 自动记录
- 警报历史查询与管理
- 健康暴露评估（NIOSH / OSHA 标准）

### 📈 数据管理
- 本地 RDB 数据库存储
- 历史记录查询（按时间/地点/加权方式筛选）
- 噪音暴露统计图表（日/周/月/年）
- 数据导出

### 🌍 位置服务
- 自动获取地理位置
- 噪音数据地图标记
- 位置信息可视化

### 👤 会员系统
- 会员权益与等级
- 连续签到奖励（7 天签到最高获 1095 天会员）
- 抽奖活动
- 五星好评引导

---

## 📱 多设备适配

应用通过 `deviceInfo.deviceType` 在运行时自动识别设备类型：

| 设备类型 | 界面 | 功能 |
|---------|------|------|
| **Phone** | 全功能 UI | 完整噪音检测、频谱、警报、会员等 |
| **Tablet** | 自适应布局 | 同上，利用大屏优势 |
| **Wearable** | 精简 UI | WatchIndex + WatchSettings + 阈值/校准配置 |
| **Car / 2in1** | 自适应 | 根据屏幕尺寸调整布局 |

---

## 🔒 权限说明

| 权限 | 用途 |
|------|------|
| `MICROPHONE` | 环境噪音采集 |
| `LOCATION` | 噪音地理位置标记 |
| `KEEP_BACKGROUND_RUNNING` | 后台持续监测 |
| `CAMERA` | 手电筒控制 |
| `VIBRATE` | 警报振动反馈 |
| `INTERNET` | 定位服务网络请求 |

---

## 📄 开源协议

本项目采用 MIT 协议 — 详见 [LICENSE](LICENSE) 文件。
