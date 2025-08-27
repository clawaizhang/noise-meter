# 响应式布局命名重构计划

## 目标
将 `HistoryLayoutMode` 及相关命名改为 `ListItemLayoutMode`，使其更准确地反映列表项布局的功能。

## 需要重命名的内容

### 1. 枚举类型重命名
- `HistoryLayoutMode` → `ListItemLayoutMode`
- 枚举值保持不变（LIST, GRID, DETAIL, COMPACT）

### 2. 变量和属性重命名
- `historyLayoutMode` → `listItemLayoutMode`
- `currentHistoryLayoutMode` → `currentListItemLayoutMode`

### 3. 方法重命名
- `getHistoryLayoutMode()` → `getListItemLayoutMode()`
- `getCurrentHistoryLayoutMode()` → `getCurrentListItemLayoutMode()`
- `responsiveHistoryItemWidth()` → `responsiveListItemWidth()`
- `responsiveHistorySpacing()` → `responsiveListItemSpacing()`
- `responsiveHistoryPadding()` → `responsiveListItemPadding()`
- `responsiveHistoryMargin()` → `responsiveListItemMargin()`

### 4. 类型定义重命名
- `HistoryLayoutChangeListener` → `ListItemLayoutChangeListener`

### 5. 导出函数重命名
- `responsiveHistoryItemWidth()` → `responsiveListItemWidth()`
- `responsiveHistorySpacing()` → `responsiveListItemSpacing()`
- `responsiveHistoryPadding()` → `responsiveListItemPadding()`
- `responsiveHistoryMargin()` → `responsiveListItemMargin()`
- `getCurrentHistoryLayoutMode()` → `getCurrentListItemLayoutMode()`
- `addHistoryLayoutChangeListener()` → `addListItemLayoutChangeListener()`
- `removeHistoryLayoutChangeListener()` → `removeListItemLayoutChangeListener()`

### 6. 常量重命名
- `BREAKPOINT_TO_HISTORY_LAYOUT` → `BREAKPOINT_TO_LIST_ITEM_LAYOUT`

## 需要更新的文件

1. `entry/src/main/ets/utils/ResponsiveLayout.ets` - 主要修改文件
2. `entry/src/main/ets/pages/noisemeter/DecibelHistoryNavigation.ets` - 使用这些API的文件

## 实施步骤

1. 首先重命名枚举和类型定义
2. 然后重命名类方法和属性
3. 接着重命名导出函数
4. 最后更新所有使用这些名称的地方
5. 验证编译和功能正常