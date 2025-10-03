# 系统通知权限架构设计方案

## 架构概述

使用响应式计算属性来管理权限状态，实现自动化的权限提醒显示。

## 核心组件

### 1. AppKeys模型扩展
在AppKeys中添加系统通知权限状态字段：

```typescript
@ObservedV2
export class AppKeys {
  // 现有字段...
  
  @Trace
  systemNotificationPermissionGranted: boolean = false; // 系统通知权限状态
}
```

### 2. 权限状态计算属性
使用@Computer来监测两个开关状态：

```typescript
@Computer
get shouldShowPermissionWarning(): boolean {
  // 应用内开关开启 且 系统权限被拒绝
  return this.pk.system_notification_enabled && !this.as.systemNotificationPermissionGranted;
}
```

### 3. 权限检查时机
- **应用启动时**：检查系统通知权限状态
- **权限申请回调**：记录权限申请结果
- **界面显示时**：实时更新权限状态

## 实现方案

### 步骤1：扩展AppKeys模型
在AppKeys中添加系统通知权限状态字段。

### 步骤2：修改AlertService
- 添加权限状态更新方法
- 在权限申请回调中更新AppKeys状态

### 步骤3：更新UI组件
- 使用@Computer计算属性替代手动检查
- 移除异步权限检查逻辑

### 步骤4：应用启动时初始化
在EntryAbility中检查系统通知权限状态。

## 优势

1. **响应式更新**：权限状态变化时自动更新UI
2. **性能优化**：避免频繁的异步权限检查
3. **状态一致**：确保整个应用使用相同的权限状态
4. **简化逻辑**：UI组件只需关注计算属性

## 代码结构

```
AppKeys
├── systemNotificationPermissionGranted: boolean

AlertService
├── updateSystemPermissionStatus(): void
├── requestNotificationPermission(): Promise<void>

UI Components
├── @Computer shouldShowPermissionWarning
└── 条件渲染权限警告卡片
```

这个架构将提供更高效和一致的权限状态管理。