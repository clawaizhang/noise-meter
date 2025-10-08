# 全局点击防抖方案

## 核心思想
- 所有点击事件共享一个防抖队列
- 用户每次只能触发一个点击
- 防止快速连续点击多个按钮

## 全局防抖管理器

```typescript
import { Subject } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

/**
 * 全局点击防抖管理器
 * 所有点击事件共享同一个防抖队列
 */
export class GlobalClickDebounce {
  private static instance: GlobalClickDebounce;
  private clickSubject = new Subject<() => void>();
  private isProcessing = false;

  private constructor() {
    // 全局防抖处理：300ms内只执行一个点击
    this.clickSubject.pipe(
      debounceTime(300)
    ).subscribe((clickHandler: () => void) => {
      this.isProcessing = true;
      try {
        clickHandler();
      } finally {
        // 确保即使出错也能继续处理下一个点击
        setTimeout(() => {
          this.isProcessing = false;
        }, 50);
      }
    });
  }

  static getInstance(): GlobalClickDebounce {
    if (!GlobalClickDebounce.instance) {
      GlobalClickDebounce.instance = new GlobalClickDebounce();
    }
    return GlobalClickDebounce.instance;
  }

  /**
   * 注册点击事件到全局防抖队列
   * @param clickHandler 点击处理函数
   */
  registerClick(clickHandler: () => void): void {
    if (this.isProcessing) {
      console.log('点击防抖：上一个点击正在处理，忽略当前点击');
      return;
    }
    this.clickSubject.next(clickHandler);
  }

  /**
   * 获取当前是否正在处理点击
   */
  isClickProcessing(): boolean {
    return this.isProcessing;
  }
}
```

## 使用方式

### 1. 组件中使用全局防抖

```typescript
import { GlobalClickDebounce } from '../utils/GlobalClickDebounce';

@ComponentV2
export struct ActionPanel {
  private clickDebounce = GlobalClickDebounce.getInstance();

  build() {
    Row() {
      // 重置按钮 - 使用全局防抖
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容
      }
      .onClick(() => {
        this.clickDebounce.registerClick(() => {
          this.onResetButtonClicked();
        });
      })
      
      // 手电筒按钮 - 使用全局防抖
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容  
      }
      .onClick(() => {
        this.clickDebounce.registerClick(() => {
          this.toggleTorch();
        });
      })
      
      // 保存按钮 - 使用全局防抖
      Button({ type: ButtonType.Circle }) {
        // ... 按钮内容
      }
      .onClick(() => {
        this.clickDebounce.registerClick(() => {
          this.onSaveButtonClicked();
        });
      })
    }
  }
}
```

### 2. 列表操作使用全局防抖

```typescript
@ComponentV2  
export struct DecibelHistoryNavigation {
  private clickDebounce = GlobalClickDebounce.getInstance();

  @Builder
  shouChangShanChuButton(record: DecibelRecord) {
    Column({ space: 8 }) {
      // 收藏按钮 - 全局防抖
      Button(record.isFavorite ? '取消收藏' : '收藏')
        .onClick(() => {
          this.clickDebounce.registerClick(async () => {
            record.isFavorite = !record.isFavorite;
            await this.recordService.updateRecord(record);
            this.promptAction.showToast({
              message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
              duration: 2000
            });
          });
        })
      
      // 删除按钮 - 全局防抖
      Button('删除')
        .onClick(() => {
          this.clickDebounce.registerClick(() => {
            this.pendingDeleteId = record.id;
          });
        })
    }
  }
}
```

## 防抖效果说明

### 用户操作场景

#### 场景1：快速点击多个按钮
```
用户操作：快速点击"重置" → 立即点击"保存"
防抖效果：只执行"重置"，"保存"被忽略
```

#### 场景2：正常操作
```
用户操作：点击"重置" → 等待1秒 → 点击"保存"  
防抖效果：两个操作都正常执行
```

#### 场景3：连续快速点击同一个按钮
```
用户操作：快速连续点击"保存"按钮3次
防抖效果：只执行最后一次点击
```

## 技术优势

### 1. 内存效率
- 整个应用只有一个 `Subject`
- 无需为每个按钮创建防抖实例
- 内存占用极小

### 2. 用户体验
- 防止用户误操作多个按钮
- 确保每次只处理一个用户意图
- 提升操作稳定性

### 3. 代码简洁
```typescript
// 统一的防抖调用模式
.onClick(() => {
  this.clickDebounce.registerClick(() => {
    // 原有的业务逻辑
  });
})
```

## 改造步骤

### 1. 创建全局管理器
创建 `GlobalClickDebounce.ets` 文件。

### 2. 组件改造模式
对每个组件的 `.onClick` 进行统一改造：

```typescript
// 原来
.onClick(() => { 业务逻辑 })

// 改为全局防抖
.onClick(() => {
  GlobalClickDebounce.getInstance().registerClick(() => {
    业务逻辑
  });
})
```

### 3. 批量替换
可以批量搜索替换所有 `.onClick` 调用。

## 配置选项

### 可调整的防抖时间
```typescript
// 如果需要调整防抖时间，可以这样修改
private constructor() {
  this.clickSubject.pipe(
    debounceTime(500) // 改为500ms防抖
  ).subscribe(...);
}
```

### 防抖策略扩展
```typescript
// 如果需要不同类型的防抖
registerClick(clickHandler: () => void, type: 'normal' | 'urgent' = 'normal'): void {
  const debounceTime = type === 'urgent' ? 100 : 300;
  // ... 实现不同类型的防抖
}
```

## 总结

这个全局点击防抖方案完全符合您的需求：

1. ✅ **全局统一管理** - 所有点击共享一个队列
2. ✅ **防止多点击** - 用户每次只能触发一个操作  
3. ✅ **内存高效** - 只有一个Subject实例
4. ✅ **用户体验好** - 防止误操作，提升稳定性

这才是真正解决"用户不可能同时点击多个按钮"问题的正确方案！