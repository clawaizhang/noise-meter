# 五星好评功能升级实施计划

## 项目概述
为现有的五星好评功能添加应用内评论能力，根据设备版本自动选择使用新的commentManager API或保持原有的应用市场跳转方式。

## 当前状态分析

### 现有实现位置
1. **MyContentComponent.ets** - 我的内容页面
2. **AboutSettingsNavigation.ets** - 关于页面

### 当前实现方式
```typescript
const want: Want = {
  action: 'ohos.want.action.appdetail',
  uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter_pro&action=write-review'
};
context.startAbility(want)
```

### 设备版本检测模式
项目中已有使用 `deviceInfo.distributionOSApiVersion >= 60000` 进行版本判断的模式。

## 技术方案

### 1. 依赖配置
**文件**: `entry/oh-package.json5`
```json5
{
  "dependencies": {
    "@pura/harmony-utils": "^1.0.0",
    "@kit.AppGalleryKit": "^1.0.0"
  }
}
```

### 2. 评论服务工具类
**文件**: `entry/src/main/ets/services/CommentService.ets`

功能：
- 封装设备版本检测逻辑
- 提供统一的评论接口
- 处理异常情况
- 记录日志

### 3. 功能集成点

#### MyContentComponent.ets
- 替换现有的 `navigateToAppStoreRating` 方法
- 使用新的 `CommentService.showCommentDialog` 方法

#### AboutSettingsNavigation.ets
- 替换现有的应用市场跳转逻辑
- 使用新的 `CommentService.showCommentDialog` 方法

## 实施完成总结

### 已完成的步骤

#### 步骤1: 添加依赖 ✅
已修改 `entry/oh-package.json5` 文件，添加了 `@kit.AppGalleryKit` 依赖

#### 步骤2: 创建评论服务 ✅
已创建 `entry/src/main/ets/services/CommentService.ets` 文件，包含：
- 设备版本检测（deviceInfo.distributionOSApiVersion >= 60000）
- 评论功能封装（支持应用内评论和应用市场评论）
- 完整的错误处理和日志记录
- 支持多个应用ID（noise_meter_pro 和 device_manager）

#### 步骤3: 修改现有实现 ✅
已更新三个位置的五星好评功能：
1. **MyContentComponent.ets** - 我的内容页面
2. **AboutSettingsNavigation.ets** - 关于页面
3. **SettingsDeviceManager.ets** - 设备管理器设置页面

### 功能特性

#### 智能版本检测
- 设备API版本 ≥ 60000：使用 `commentManager.showCommentDialog` 应用内评论
- 设备API版本 < 60000：使用原有的应用市场跳转

#### 多应用支持
- 默认应用ID：`yu.zhang.myapplication.noise_meter_pro`
- 设备管理器应用ID：`yu.zhang.myapplication.device_manager`

#### 错误处理
- 完整的异常捕获机制
- 应用内评论失败时自动回退到应用市场评论
- 详细的日志记录

### 代码架构

```typescript
// 使用示例
const commentService = CommentService.getInstance();
await commentService.showCommentDialog(context);
// 或指定应用ID
await commentService.showCommentDialog(context, 'yu.zhang.myapplication.device_manager');
```

## 代码实现要点

### CommentService 类设计
```typescript
export class CommentService {
  private static instance: CommentService;
  
  public static getInstance(): CommentService {
    // 单例实现
  }
  
  public async showCommentDialog(context: common.UIAbilityContext): Promise<void> {
    // 版本检测逻辑
    // 调用相应的评论API
  }
}
```

### 版本检测逻辑
```typescript
if (deviceInfo.distributionOSApiVersion >= 60000) {
  // 使用 commentManager.showCommentDialog
} else {
  // 使用原有的应用市场跳转
}
```

## 错误处理策略
- 捕获所有可能的异常
- 提供用户友好的错误提示
- 记录详细的错误日志

## 测试方案
1. 模拟高版本设备行为
2. 模拟低版本设备行为
3. 测试异常情况处理