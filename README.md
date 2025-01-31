# 分贝检测应用

基于HarmonyOS的环境噪音检测应用，采用ArkTS开发框架。

## 技术架构

- HarmonyOS API 9 开发平台
- ArkTS 声明式开发范式
- @pura/harmony-utils ^1.0.0 工具库
- RelationalStore 关系型数据库
- Preferences API 首选项存储

## 项目结构

```bash
entry/src/main/ets/          # 源码主目录
├── abilitystage/           # 应用生命周期管理
├── components/             # 界面组件
├── entryability/          # 入口能力
├── pages/                 # 页面文件
│   └── Index.ets          # 主页面入口
├── services/              # 服务层实现
└── utils/                 # 工具类

library/ets/                # 公共库目录
├── services/              # 服务实现
│   ├── RelationalStoreService.ets  # 数据库服务
│   └── PreferenceService.ets       # 配置服务
├── constants/             # 常量定义
│   ├── DatabaseConstants.ets       # 数据库常量
│   └── PreferenceKeyConstants.ets  # 配置项常量
└── interfaces/            # 接口定义
    └── DatabaseInterfaces.ets      # 数据库接口
```

## 数据存储实现

### 关系型数据库
```sql
-- 分贝记录表结构
CREATE TABLE IF NOT EXISTS DecibelRecords (
  id INTEGER PRIMARY KEY AUTOINCREMENT,  -- 主键，自增
  value REAL NOT NULL,                   -- 分贝值
  timestamp INTEGER DEFAULT (strftime('%s','now')),  -- 时间戳
  weighting TEXT CHECK(weighting IN ('A','C','Z'))   -- 加权类型
);
```

### 首选项配置
```typescript
// 配置键定义
static readonly WEIGHTING: string = 'weighting_type';  // 加权类型配置项
```

## 状态管理

```typescript
@Component
struct Index {
  // 初始化状态管理
  @State isInitialized: boolean = false;  // 初始化完成标志
  @State isLoading: boolean = true;       // 加载状态标志
  
  // 服务实例
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
}
```

## 开发指南

### 1. 环境要求
- DevEco Studio 3.1 或更高版本
- HarmonyOS SDK API 9
- Node.js 16+

### 2. 开发步骤
```bash
# 1. 克隆项目
git clone <仓库地址>

# 2. 安装依赖
npm install

# 3. 使用DevEco Studio打开项目
File > Open > 选择项目目录
```

### 3. 数据库升级流程
```typescript
// 版本升级配置
const upgradeConfigs: DatabaseUpgradeConfig[] = [
  {
    version: 1,  // 初始版本
    sqls: [TableCreateSql.DECIBEL_RECORDS]  // 创建表
  },
  {
    version: 2,  // 升级版本
    sqls: [TableCreateSql.ADD_WEIGHTING_TYPES_COLUMN]  // 添加列
  }
];
```

## 开发规范

### 1. 类型定义
```typescript
// 正确示例
private service: RelationalStoreService;  // 使用具体类型

// 错误示例
private service: any;  // 禁止使用any类型
```

### 2. 错误处理
```typescript
try {
  // 执行初始化
  await this.initialize();
} catch (error) {
  // 使用hilog记录错误
  hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', 
    error instanceof Error ? error.message : String(error));
}
```

### 3. 装饰器使用
```typescript
@Entry
@Component
struct MainPage {
  // 使用@State管理状态
  @State private isLoading: boolean = true;
}
```

## 安全说明

1. 数据安全
   - 使用SecurityLevel.S1加密级别
   - 事务保证数据一致性
   - SQL参数化查询防注入

2. 权限控制
   - 运行时权限申请
   - 异常状态处理
   - 降级方案支持

## 调试工具

### 数据库调试
```bash
# 查看表结构
adb shell "run-as com.example.myapplication6 sqlite3 
  /data/app/el2/100/database/NoiseMeterDb/NoiseMeter.db 
  '.schema'"
```

### 配置检查
```bash
# 查看配置文件
adb shell "run-as com.example.myapplication6 cat 
  /data/app/el2/100/preferences/NoiseMeterPref.xml"
```

## 版本记录

### v2.0 版本
- 新增加权类型(A/C/Z)支持
- 数据库结构升级
- 完善错误处理机制

### v1.0 版本
- 初始版本发布
- 基础数据库实现
- 配置管理支持
