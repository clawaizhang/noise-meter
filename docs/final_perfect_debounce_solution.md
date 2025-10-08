# 最终完美防抖方案

## 修正后的多队列防抖工具类

```typescript
import { Subject, Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

/**
 * 完美防抖工具类
 * 内部维护多个防抖队列，支持应用退出时清理
 */
export class Debounce {
  // 内部维护的三个防抖队列
  private static normalClickSubject = new Subject<() => void>();
  private static fastClickSubject = new Subject<() => void>();
  private static importantClickSubject = new Subject<() => void>();

  // 订阅管理
  private static normalSubscription: Subscription;
  private static fastSubscription: Subscription;
  private static importantSubscription: Subscription;

  // 静态初始化 - 创建三个防抖队列
  static {
    // 普通点击队列 - 300ms防抖
    this.normalSubscription = this.normalClickSubject.pipe(
      debounceTime(300)
    ).subscribe((clickHandler) => {
      clickHandler();
    });

    // 快速点击队列 - 150ms防抖
    this.fastSubscription = this.fastClickSubject.pipe(
      debounceTime(150)
    ).subscribe((clickHandler) => {
      clickHandler();
    });

    // 重要点击队列 - 500ms防抖
    this.importantSubscription = this.importantClickSubject.pipe(
      debounceTime(500)
    ).subscribe((clickHandler) => {
      clickHandler();
    });
  }

  /**
   * 普通点击 - 300ms防抖
   * 适用于大部分按钮操作
   */
  static click(clickHandler: () => void): void {
    this.normalClickSubject.next(clickHandler);
  }

  /**
   * 快速点击 - 150ms防抖
   * 适用于切换、轻量操作
   */
  static fastClick(clickHandler: () => void): void {
    this.fastClickSubject.next(clickHandler);
  }

  /**
   * 重要点击 - 500ms防抖
   * 适用于确认、删除等重要操作
   */
  static importantClick(clickHandler: () => void): void {
    this.importantClickSubject.next(clickHandler);
  }

  /**
   * 应用退出时调用，清理所有防抖队列
   * 释放内存，防止内存泄漏
   */
  static unsubscribe(): void {
    // 取消所有订阅
    if (this.normalSubscription) {
      this.normalSubscription.unsubscribe();
    }
    if (this.fastSubscription) {
      this.fastSubscription.unsubscribe();
    }
    if (this.importantSubscription) {
      this.importantSubscription.unsubscribe();
    }

    // 完成所有Subject
    this.normalClickSubject.complete();
    this.fastClickSubject.complete();
    this.importantClickSubject.complete();

    console.log('防抖队列已清理，内存已释放');
  }
}
```

## 使用方式

### 1. 普通点击 - 300ms防抖
```typescript
// 重置、保存等普通按钮
.onClick(() => {
  Debounce.click(() => {
    this.onResetButtonClicked();
  });
})
```

### 2. 快速点击 - 150ms防抖
```typescript
// 切换、轻量操作
.onClick(() => {
  Debounce.fastClick(() => {
    this.toggleTorch();
  });
})
```

### 3. 重要点击 - 500ms防抖
```typescript
// 确认、删除等重要操作
.onClick(() => {
  Debounce.importantClick(() => {
    this.confirmDelete();
  });
})
```

## 应用退出时清理

### 在应用主入口清理
```typescript
// 在 Index.ets 或应用主入口的 aboutToDisappear 中调用
aboutToDisappear(): void {
  // 清理防抖队列，释放内存
  Debounce.unsubscribe();
  
  // 其他清理逻辑...
}
```

### 完整的生命周期管理
```typescript
@ComponentV2
export struct Index {
  aboutToAppear() {
    // 应用启动 - 防抖队列自动初始化
  }

  aboutToDisappear() {
    // 应用退出 - 清理防抖队列
    Debounce.unsubscribe();
    
    // 其他资源清理...
    const usageTrackingService = UsageTrackingService.getInstance();
    usageTrackingService.destroy();
    
    const commonEventService = CommonEventService.getInstance();
    commonEventService.destroy();
  }
}
```

## 技术优势

### 1. 无内存泄漏
- 应用退出时自动清理所有订阅
- 释放Subject占用的内存
- 符合HarmonyOS内存管理规范

### 2. 防抖特性保持
- 不使用customClick，避免重新创建Subject
- 三个固定队列保持防抖特性
- 队列隔离，互不影响

### 3. 性能优秀
- 只有三个固定的Subject
- 无需重复创建和销毁
- 内存占用固定且很小

## 防抖队列说明

### 三个内置队列

| 队列类型 | 防抖时间 | 适用场景 | 快捷方法 |
|---------|---------|---------|----------|
| **普通队列** | 300ms | 大部分按钮操作 | `Debounce.click()` |
| **快速队列** | 150ms | 切换、轻量操作 | `Debounce.fastClick()` |
| **重要队列** | 500ms | 确认、删除等 | `Debounce.importantClick()` |

### 队列隔离效果
- 每个队列独立防抖，互不影响
- 快速队列的操作不会阻塞普通队列
- 重要队列有更长的防抖时间

## 改造指南

### 1. 创建工具类
创建 `Debounce.ets` 文件。

### 2. 在主入口添加清理
在 `Index.ets` 的 `aboutToDisappear` 中添加：
```typescript
Debounce.unsubscribe();
```

### 3. 批量替换点击事件
根据操作类型选择合适的防抖方法：

- **普通按钮** → `Debounce.click()`
- **切换操作** → `Debounce.fastClick()`  
- **重要确认** → `Debounce.importantClick()`

### 4. 替换模式
```typescript
// 搜索
.onClick(() => { 

// 根据业务逻辑替换为
.onClick(() => { Debounce.click(() => { 
.onClick(() => { Debounce.fastClick(() => { 
.onClick(() => { Debounce.importantClick(() => { 
```

## 总结

这个最终方案完全解决了您提出的两个问题：

1. ✅ **移除customClick** - 避免重新创建Subject丢失防抖特性
2. ✅ **添加unsubscribe** - 应用退出时清理所有订阅，释放内存
3. ✅ **保持防抖特性** - 三个固定队列确保防抖效果
4. ✅ **内存安全** - 完整的生命周期管理

现在这个方案既简单实用，又完全符合HarmonyOS的内存管理要求！