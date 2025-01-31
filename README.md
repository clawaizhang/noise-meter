# 噪音监测与分析系统

基于HarmonyOS的专业噪音监测与分析系统，采用ArkTS开发框架，提供实时分贝检测、频谱分析、数据记录等功能。

## 核心功能

1. **实时音频分析**
   - 多种加权方式(A/C/Z)支持
   - 实时频谱分析与显示
   - 快速/慢速时间加权选项

2. **数据管理**
   - 本地数据持久化存储
   - 历史记录查询与统计
   - 数据导出功能

3. **位置服务**
   - 噪音数据地理位置标记
   - 位置信息可视化

4. **音频处理**
   - WAV文件生成与保存
   - FFT频谱分析
   - 音频增强处理

## 技术架构

### 开发环境
- HarmonyOS API 9
- DevEco Studio 3.1+
- Node.js 16+

### 核心依赖
```json
{
  "@pura/harmony-utils": "^1.0.0",
  "@ohos.multimedia.audio": "9.0.0",
  "@ohos.data.relationalStore": "9.0.0"
}
```

## 项目结构

```bash
entry/
├── src/
│   ├── library/ets/           # 核心库
│   │   ├── components/        # 组件
│   │   │   ├── business/     # 业务组件
│   │   │   └── common/       # 通用组件
│   │   ├── services/         # 服务层
│   │   │   ├── AudioService.ets        # 音频服务
│   │   │   ├── LocationService.ets     # 位置服务
│   │   │   └── RelationalStoreService.ets  # 数据库服务
│   │   └── utils/            # 工具类
│   │       ├── FFTAnalyzer.ets         # FFT分析器
│   │       └── WavFileGenerator.ets     # WAV文件生成器
│   └── main/
│       └── ets/
│           ├── pages/        # 页面
│           └── entryability/ # 入口能力
```

## 数据存储

### 数据库结构
```sql
-- 分贝记录表
CREATE TABLE IF NOT EXISTS DecibelRecords (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  value REAL NOT NULL,                    -- 分贝值
  timestamp INTEGER,                      -- 记录时间
  weighting TEXT,                         -- 加权类型(A/C/Z)
  location TEXT,                          -- 位置信息
  note TEXT,                             -- 备注
  spectrum BLOB                          -- 频谱数据
);
```

### 首选项配置
```typescript
// 音频分析配置
const PREF_ANALYSIS_MODE = 'audio_analysis_mode';    // 分析模式
const PREF_TARGET_SAMPLES = 'audio_target_samples';  // 目标采样数
const PREF_PROCESS_INTERVAL = 'audio_process_interval'; // 处理间隔
```

## 音频处理流程

1. **采集初始化**
   ```typescript
   audioCapturerOptions = {
     streamInfo: {
       samplingRate: 44100,
       channels: CHANNEL_1,
       sampleFormat: SAMPLE_FORMAT_S16LE,
       encodingType: ENCODING_TYPE_RAW
     }
   };
   ```

2. **实时处理**
   - 音频数据缓冲
   - FFT频谱分析
   - 分贝值计算
   - 数据持久化

3. **数据输出**
   - 实时显示
   - 文件保存
   - 数据库存储

## 安全特性

1. **数据安全**
   - 数据库加密（SecurityLevel.S1）
   - 事务完整性保护
   - SQL注入防护

2. **权限管理**
   - 麦克风权限
   - 位置权限
   - 存储权限

## 使用说明

1. **环境准备**
   ```bash
   # 安装依赖
   npm install
   ```

2. **开发调试**
   - 使用DevEco Studio打开项目
   - 选择目标设备或模拟器
   - 点击运行按钮

3. **发布部署**
   ```bash
   # 构建发布包
   npm run build
   ```

## 调试工具

### 数据库调试
```bash
# 查看数据库结构
adb shell "run-as com.example.myapplication6 sqlite3 
  /data/app/el2/100/database/NoiseMeterDb/NoiseMeter.db 
  '.schema'"
```

### 日志查看
```bash
# 查看应用日志
hdc shell hilog | grep com.example.myapplication6
```

## 版本历史

### v2.1.0 (2025-01-31)
- 新增频谱分析功能
- 优化音频处理性能
- 添加位置服务支持

### v2.0.0
- 实现多种加权方式
- 重构音频处理模块
- 优化数据存储结构

### v1.0.0
- 基础噪音检测
- 数据库支持
- 配置管理

## 参与贡献

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 开源协议

本项目采用 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。
