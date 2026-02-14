# 警报历史功能设计方案

## 一、功能概述

警报历史功能是一个完整的数据记录和展示系统，用于追踪和管理噪音检测过程中的所有警报事件。

### 核心特性
- **实时记录**: 自动检测并记录警报触发、持续和结束全过程
- **数据持久化**: 使用关系型数据库存储，支持应用重启后数据保留
- **统计分析**: 提供今日/历史统计数据，帮助用户了解噪音暴露情况
- **专业UI**: 时间线展示、严重程度分级、动画效果

---

## 二、架构设计

### 2.1 整体架构
```
┌─────────────────────────────────────────────────────────────┐
│                      UI 展示层                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 实时状态卡片  │  │ 警报历史列表  │  │ 统计摘要卡片  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    业务逻辑层                                │
│              AlertHistoryService                            │
│         ┌────────────────────────┐                         │
│         │   会话管理  │  数据CRUD  │  统计分析              │
│         └────────────────────────┘                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    数据访问层                                │
│         RelationalStoreService (RDB)                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    数据存储层                                │
│                alert_history 表                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流
```
噪音检测 ──> 状态机 ──> 超过阈值 ──> 开始警报会话
                              │
                              ▼
                    ┌──────────────────┐
                    │  记录峰值/平均值  │
                    │  获取位置信息     │
                    └──────────────────┘
                              │
            噪音恢复 <── 结束警报会话 <── 持续监控
                │
                ▼
        ┌───────────────┐
        │  计算统计数据  │
        │  保存到数据库  │
        └───────────────┘
                │
                ▼
        ┌───────────────┐
        │   刷新UI展示   │
        │   更新统计卡片 │
        └───────────────┘
```

---

## 三、数据库设计

### 3.1 表结构
```sql
CREATE TABLE alert_history (
    id TEXT PRIMARY KEY NOT NULL,           -- 唯一ID (UUID)
    startTime INTEGER NOT NULL,              -- 警报开始时间戳
    endTime INTEGER NOT NULL,                -- 警报结束时间戳
    duration INTEGER NOT NULL,               -- 持续时长(秒)
    peakDecibel REAL NOT NULL,               -- 峰值分贝
    avgDecibel REAL NOT NULL,                -- 平均分贝
    minDecibel REAL NOT NULL,                -- 最低分贝
    threshold REAL NOT NULL,                 -- 触发阈值
    location TEXT,                           -- 位置描述
    latitude REAL,                           -- 纬度
    longitude REAL,                          -- 经度
    alertType TEXT NOT NULL,                 -- 警报类型
    status TEXT NOT NULL,                    -- 记录状态
    severity INTEGER NOT NULL,               -- 严重程度(1-4)
    extraData TEXT,                          -- 扩展数据(JSON)
    createdAt INTEGER NOT NULL,              -- 创建时间
    updatedAt INTEGER NOT NULL               -- 更新时间
);
```

### 3.2 索引设计
```sql
-- 加速时间范围查询
CREATE INDEX idx_alert_history_startTime ON alert_history(startTime DESC);

-- 加速严重程度筛选
CREATE INDEX idx_alert_history_severity ON alert_history(severity);
```

---

## 四、数据模型

### 4.1 AlertRecord 警报记录
```typescript
class AlertRecord {
  id: string;                    // UUID
  startTime: number;             // 开始时间
  endTime: number;               // 结束时间
  duration: number;              // 持续秒数
  
  // 分贝数据
  peakDecibel: number;           // 峰值
  avgDecibel: number;            // 平均值
  minDecibel: number;            // 最低值
  threshold: number;             // 阈值
  
  // 位置信息
  location?: string;
  latitude?: number;
  longitude?: number;
  
  // 分类
  alertType: AlertType;          // 类型
  status: AlertRecordStatus;     // 状态
  severity: AlertSeverity;       // 严重程度
  
  // 方法
  getFormattedDuration(): string;
  getFormattedStartTime(): string;
  getFormattedDateTime(): string;
  static calculateSeverity(peak: number, threshold: number): AlertSeverity;
}
```

### 4.2 枚举类型
```typescript
enum AlertType {
  INSTANT_PEAK = 'instant_peak',         // 瞬时峰值
  CONTINUOUS_EXPOSURE = 'continuous_exposure', // 持续暴露
  THRESHOLD_BREACH = 'threshold_breach'  // 阈值突破
}

enum AlertSeverity {
  LOW = 1,      // 轻度 (< 5dB)
  MEDIUM = 2,   // 中度 (5-15dB)
  HIGH = 3,     // 重度 (15-25dB)
  CRITICAL = 4  // 严重 (> 25dB)
}

enum AlertRecordStatus {
  ACTIVE = 'active',       // 进行中
  COMPLETED = 'completed', // 已完成
  CANCELLED = 'cancelled'  // 已取消
}
```

---

## 五、服务层 API

### 5.1 AlertHistoryService

#### 核心方法
```typescript
class AlertHistoryService {
  // 会话管理
  async startAlertSession(threshold: number, currentDb: number, type: AlertType): Promise<string>;
  updateActiveSession(currentDb: number): void;
  async endAlertSession(finalDb: number): Promise<AlertRecord>;
  
  // CRUD 操作
  async saveAlertRecord(record: AlertRecord): Promise<boolean>;
  async queryAlertRecords(options: AlertQueryOptions): Promise<AlertRecord[]>;
  async getRecentAlerts(limit: number): Promise<AlertRecord[]>;
  async deleteAlertRecord(id: string): Promise<boolean>;
  async clearAllRecords(): Promise<boolean>;
  
  // 统计分析
  async getTodaySummary(): Promise<AlertSummary>;
  async getSummary(startTime: number, endTime: number): Promise<AlertSummary>;
  async getDailyStats(date: Date): Promise<{ count: number; duration: number; peak: number }>;
  
  // 状态查询
  hasActiveSession(): boolean;
  getActiveSession(): { id: string; startTime: number; duration: number } | null;
}
```

---

## 六、UI 设计

### 6.1 布局结构
```
┌─────────────────────────────────────┐
│  🔊 实时状态区                        │
│  ┌───────────────────────────────┐ │
│  │  75.5 dB    [警报触发中]        │ │
│  │  超过阈值 15.5dB               │ │
│  │  ████████████░░░░░░░░░░░░░░    │ │
│  └───────────────────────────────┘ │
├─────────────────────────────────────┤
│  ⚙️ 设置摘要: 一般环境 · 55dB       │
├─────────────────────────────────────┤
│  📊 警报历史                        │
│  ┌───────────────────────────────┐ │
│  │ 今日3次 │ 15分30秒 │ 最高82dB │ │
│  └───────────────────────────────┘ │
│  ● 14:32 ┬ 峰值 82dB [重度]        │
│  │        │ 持续 2分30秒            │
│  │        │ 北京市朝阳区...         │
│  ● 11:15 ┬ 峰值 78dB [中度]        │
│  │        │ 持续 45秒               │
│  │        │ 北京市海淀区...         │
├─────────────────────────────────────┤
│  💡 环境洞察                        │
│  危险 │ 已超过阈值 15.5dB          │
│  建议: 寻找更安静的环境             │
└─────────────────────────────────────┘
```

### 6.2 设计亮点

#### 实时状态区
- **大字号分贝显示**: 56px 主数字，便于快速读取
- **状态徽章**: 颜色随状态变化（绿/黄/红）
- **进度条**: 30-85dB 范围可视化，带阈值标记
- **脉冲动画**: 警报状态下呼吸灯效果

#### 警报历史列表
- **时间线设计**: 垂直时间轴，圆圈+连线
- **严重程度标签**: 彩色标签区分轻度/中度/重度/严重
- **滑动手势**: 左滑删除单条记录
- **活跃状态**: 脉动红点标识进行中的警报

#### 统计摘要
- **三栏布局**: 次数 | 时长 | 峰值
- **实时更新**: 每5秒自动刷新统计

---

## 七、关键交互流程

### 7.1 警报触发流程
```
用户打开警报中心
    │
    ▼
加载历史记录和今日统计
    │
    ▼
状态机监控噪音变化 ──> 超过阈值
    │
    ▼
触发系统通知
    │
    ▼
开始警报会话（记录开始时间、位置）
    │
    ▼
UI显示"进行中"脉动指示器
    │
    ▼
持续记录峰值和平均值...
```

### 7.2 警报结束流程
```
噪音恢复正常
    │
    ▼
状态机状态变更
    │
    ▼
结束警报会话
    │
    ▼
计算统计数据（峰值、均值、时长）
    │
    ▼
保存到数据库
    │
    ▼
更新UI列表和统计
    │
    ▼
显示完成提示
```

---

## 八、性能优化

### 8.1 数据库优化
- **索引**: startTime 和 severity 字段索引加速查询
- **分页加载**: 历史记录分页，避免一次性加载过多数据
- **批量操作**: 支持批量删除减少IO次数

### 8.2 UI 优化
- **懒加载**: 历史列表仅加载最近10条
- **增量更新**: 定时器仅刷新统计，不重新加载列表
- **动画优化**: 使用硬件加速的 transform 动画

### 8.3 内存优化
- **会话复用**: 活跃会话期间不创建新对象
- **结果集及时关闭**: 数据库查询后立即 close()

---

## 九、扩展性设计

### 9.1 未来可扩展功能
1. **数据导出**: 支持导出 CSV/Excel
2. **云端同步**: 多设备数据同步
3. **详细报告**: 生成日/周/月噪音暴露报告
4. **智能提醒**: 基于历史数据的预测性提醒
5. **地理位置分析**: 热力图展示高频警报地点

### 9.2 预留字段
- `extraData`: JSON 格式存储扩展信息
- `latitude`/`longitude`: 为未来地图功能预留

---

## 十、文件清单

| 文件路径 | 说明 |
|---------|------|
| `models/AlertRecord.ets` | 数据模型和枚举定义 |
| `services/AlertHistoryService.ets` | 核心业务逻辑服务 |
| `components/alerts/AlertsContent.ets` | UI组件（优化版） |
| `constants/TableCreateSql.ets` | 数据库建表语句 |
| `pages/MainPage.ets` | 数据库初始化配置 |
| `utils/UUIDGenerator.ets` | UUID生成工具 |

---

## 十一、数据库迁移

应用升级时会自动执行以下SQL（版本5）：
```sql
-- 创建警报历史表
CREATE TABLE IF NOT EXISTS alert_history (...);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_alert_history_startTime ON alert_history(startTime DESC);
CREATE INDEX IF NOT EXISTS idx_alert_history_severity ON alert_history(severity);
```

---

## 十二、使用示例

### 在组件中使用
```typescript
// 获取服务实例
const alertHistoryService = AlertHistoryService.getInstance();

// 加载今日数据
const summary = await alertHistoryService.getTodaySummary();
console.log(`今日警报: ${summary.todayCount}次`);

// 查询历史记录
const records = await alertHistoryService.getRecentAlerts(10);
```

---

## 十三、注意事项

1. **权限**: 位置信息需要用户授权
2. **存储**: 大量历史记录可能影响性能，建议定期清理
3. **电量**: 持续GPS定位会增加耗电，目前仅在警报开始时获取位置
4. **隐私**: 位置数据仅本地存储，不上传服务器
