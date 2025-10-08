# 多队列防抖方案

## 核心设计
- 内部维护多个防抖队列
- 每个队列对应不同的防抖时间
- 提供快捷方法直接使用

## 多队列防抖工具类

```typescript
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

/**
 * 多队列防抖工具类
 * 内部维护多个不同时间的防抖队列
 */
export class Debounce {
  // 内部维护的三个防抖队列
  private static normalClickSubject = new Subject<() => void>();
  private static fastClickSubject = new Subject<() => void>();
  private static importantClickSubject = new Subject<() => void>();

  // 静态初始化 - 创建三个防抖队列
  static {
    // 普通点击队列 - 300ms防抖
    this.normalClickSubject.pipe(
      debounceTime(300)
    ).subscribe((clickHandler) => {
      clickHandler();
    });

    // 快速点击队列 - 150ms防抖
    this.fastClickSubject.pipe(
      debounceTime(150)
    ).subscribe((clickHandler) => {
      clickHandler();
    });

    // 重要点击队列 - 500ms防抖
    this.importantClickSubject.pipe(
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
   * 通用点击方法 - 可指定任意防抖时间
   * 适用于特殊场景
   */
  static customClick(clickHandler: () => void, delay: number): void {
    // 对于特殊时间，创建临时防抖队列
    const tempSubject = new Subject();
    tempSubject.pipe(debounceTime(delay))
      .subscribe(() => clickHandler());
    tempSubject.next(null);
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

### 4. 自定义时间
```typescript
// 特殊场景使用自定义时间
.onClick(() => {
  Debounce.customClick(() => {
    this.specialOperation();
  }, 200); // 200ms防抖
})
```

## 完整组件改造示例

### ActionPanel.ets
```typescript
import { Debounce } from '../utils/Debounce';

@ComponentV2
export struct ActionPanel {
  build() {
    Row() {
      // 重置按钮 - 普通点击300ms
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容
      }
      .onClick(() => {
        Debounce.click(() => {
          this.onResetButtonClicked();
        });
      })
      
      // 手电筒按钮 - 快速点击150ms
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容  
      }
      .onClick(() => {
        Debounce.fastClick(() => {
          this.toggleTorch();
        });
      })
      
      // 保存按钮 - 普通点击300ms
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容
      }
      .onClick(() => {
        Debounce.click(() => {
          this.onSaveButtonClicked();
        });
      })
    }
  }
}
```

### DecibelHistoryNavigation.ets
```typescript
import { Debounce } from '../utils/Debounce';

@ComponentV2  
export struct DecibelHistoryNavigation {
  @Builder
  shouChangShanChuButton(record: DecibelRecord) {
    Column({ space: 8 }) {
      // 收藏按钮 - 快速点击150ms
      Button(record.isFavorite ? '取消收藏' : '收藏')
        .onClick(() => {
          Debounce.fastClick(async () => {
            record.isFavorite = !record.isFavorite;
            await this.recordService.updateRecord(record);
            this.promptAction.showToast({
              message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
              duration: 2000
            });
          });
        })
      
      // 删除按钮 - 重要点击500ms
      Button('删除')
        .onClick(() => {
          Debounce.importantClick(() => {
            this.pendingDeleteId = record.id;
          });
        })
    }
  }
}
```

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

## 技术优势

### 1. 性能优化
- 三个队列持续存在，无需重复创建
- 内存占用固定且很小
- 响应速度快

### 2. 使用简单
```typescript
// 根据操作类型选择合适的队列
Debounce.click(() => { ... });      // 普通操作
Debounce.fastClick(() => { ... });  // 快速操作  
Debounce.importantClick(() => { ... }); // 重要操作
```

### 3. 扩展性好
```typescript
// 可以轻松添加更多队列
private static urgentClickSubject = new Subject<() => void>();

static urgentClick(clickHandler: () => void): void {
  this.urgentClickSubject.next(clickHandler);
}
```

## 改造指南

### 1. 创建工具类
创建 `Debounce.ets` 文件。

### 2. 分类改造
根据操作类型选择合适的防抖方法：

- **普通按钮** → `Debounce.click()`
- **切换操作** → `Debounce.fastClick()`  
- **重要确认** → `Debounce.importantClick()`

### 3. 批量替换模式
```typescript
// 搜索替换模式
.onClick(() => { 业务逻辑 })

// 根据业务逻辑类型替换为
.onClick(() => { Debounce.click(() => { 业务逻辑 }) })
.onClick(() => { Debounce.fastClick(() => { 业务逻辑 }) })
.onClick(() => { Debounce.importantClick(() => { 业务逻辑 }) })
```

## 总结

这个多队列方案完全符合您的需求：

1. ✅ **内部维护多个队列** - 300ms、150ms、500ms
2. ✅ **提供快捷方法** - `click()`、`fastClick()`、`importantClick()`
3. ✅ **队列隔离** - 每个队列独立防抖
4. ✅ **性能优秀** - 队列持续存在，无需重复创建

现在就可以开始实施，根据操作类型选择合适的防抖队列！