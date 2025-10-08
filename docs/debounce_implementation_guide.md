# 防抖实现详细指南

## 防抖工具类代码实现

### DebounceUtils.ets 完整代码

```typescript
import { Subject, timer, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';

/**
 * 防抖工具类
 * 提供统一的防抖处理方案，支持RX JS防抖功能
 */
export class DebounceUtils {
  // 防抖时间配置
  private static readonly DEBOUNCE_CONFIG = {
    HIGH_FREQUENCY: 300,    // 高频操作：重置、保存、切换等
    NAVIGATION: 200,        // 导航操作：页面跳转、设置切换
    LIST_OPERATION: 150,    // 列表操作：收藏、删除、详情查看
    CONFIRMATION: 500       // 确认操作：对话框确认、重要操作
  };

  /**
   * 创建防抖函数
   * @param callback 回调函数
   * @param delay 延迟时间
   * @returns 防抖后的函数
   */
  static createDebounce<T>(callback: (value: T) => void, delay: number): (value: T) => void {
    let subscription: Subscription | null = null;
    const subject = new Subject<T>();

    const debouncedSubscription = subject.pipe(
      debounceTime(delay),
      distinctUntilChanged()
    ).subscribe(callback);

    return (value: T) => {
      if (subscription) {
        subscription.unsubscribe();
      }
      subject.next(value);
    };
  }

  /**
   * 创建带取消功能的防抖函数
   * @param callback 回调函数
   * @param delay 延迟时间
   * @returns 包含执行和取消方法的对象
   */
  static createDebounceWithCancel<T>(callback: (value: T) => void, delay: number): {
    execute: (value: T) => void;
    cancel: () => void;
  } {
    let subscription: Subscription | null = null;
    const subject = new Subject<T>();

    const debouncedSubscription = subject.pipe(
      debounceTime(delay),
      distinctUntilChanged()
    ).subscribe(callback);

    return {
      execute: (value: T) => {
        subject.next(value);
      },
      cancel: () => {
        if (subscription) {
          subscription.unsubscribe();
          subscription = null;
        }
      }
    };
  }

  /**
   * 获取防抖时间配置
   */
  static getDebounceConfig() {
    return this.DEBOUNCE_CONFIG;
  }

  /**
   * 清理所有防抖订阅
   */
  static cleanup() {
    // 在组件销毁时调用，确保资源释放
  }
}
```

## 组件改造示例

### 1. 操作按钮组件防抖改造

#### ActionPanel.ets 改造示例

```typescript
import { DebounceUtils } from '../../utils/DebounceUtils';

@ComponentV2
export struct ActionPanel {
  // ... 现有代码
  
  // 添加防抖函数
  @Local private debouncedReset: () => void;
  @Local private debouncedSave: () => void;
  @Local private debouncedTorch: () => void;

  aboutToAppear(): void {
    const config = DebounceUtils.getDebounceConfig();
    
    // 创建防抖函数
    this.debouncedReset = DebounceUtils.createDebounce(() => {
      this.onResetButtonClicked();
    }, config.HIGH_FREQUENCY);

    this.debouncedSave = DebounceUtils.createDebounce(() => {
      this.onSaveButtonClicked();
    }, config.HIGH_FREQUENCY);

    this.debouncedTorch = DebounceUtils.createDebounce(() => {
      this.toggleTorch();
    }, config.HIGH_FREQUENCY);
  }

  build() {
    // ... 现有代码
    
    // 修改onClick调用
    .onClick(() => {
      this.debouncedReset();
    })
    
    // ... 其他按钮类似修改
  }
}
```

#### ResetSaveButtonBuilder.ets 改造示例

```typescript
import { DebounceUtils } from '../utils/DebounceUtils';

@ComponentV2
export struct ResetSaveButton {
  // ... 现有代码
  
  @Local private debouncedReset: () => void;
  @Local private debouncedSave: () => void;

  aboutToAppear(): void {
    const config = DebounceUtils.getDebounceConfig();
    
    this.debouncedReset = DebounceUtils.createDebounce(async () => {
      const confirmed = await promptAction.showDialog({
        // ... 对话框配置
      });
      if (confirmed.index === 1) {
        this.onReset();
      }
    }, config.HIGH_FREQUENCY);

    this.debouncedSave = DebounceUtils.createDebounce(async () => {
      const confirmed = await promptAction.showDialog({
        // ... 对话框配置
      });
      if (confirmed.index === 1) {
        this.onSave();
      }
    }, config.HIGH_FREQUENCY);
  }

  build() {
    // ... 修改onClick调用
    .onClick(() => {
      this.debouncedReset();
    })
    
    // ... 其他按钮类似
  }
}
```

### 2. 列表组件防抖改造

#### DecibelHistoryNavigation.ets 改造示例

```typescript
import { DebounceUtils } from '../../utils/DebounceUtils';

@ComponentV2
export struct DecibelHistoryNavigation {
  // ... 现有代码
  
  @Local private debouncedShowDetails: (record: DecibelRecord) => void;
  @Local private debouncedToggleFavorite: (record: DecibelRecord) => void;

  aboutToAppear(): void {
    const config = DebounceUtils.getDebounceConfig();
    
    this.debouncedShowDetails = DebounceUtils.createDebounce((record: DecibelRecord) => {
      this.showNoiseDetails(record);
    }, config.LIST_OPERATION);

    this.debouncedToggleFavorite = DebounceUtils.createDebounce(async (record: DecibelRecord) => {
      record.isFavorite = !record.isFavorite;
      await this.recordService.updateRecord(record);
      // ... 提示信息
    }, config.LIST_OPERATION);
  }

  @Builder
  shouChangShanChuButton(record: DecibelRecord) {
    // ... 修改onClick调用
    .onClick(() => {
      this.debouncedToggleFavorite(record);
    })
    
    // ... 其他列表操作类似
  }
}
```

### 3. 设置组件防抖改造

#### SettingsNavigation.ets 改造示例

```typescript
import { DebounceUtils } from '../../utils/DebounceUtils';

@ComponentV2
export struct SettingsNavigation {
  // ... 现有代码
  
  @Local private debouncedOpenTimeWeighting: () => void;
  @Local private debouncedOpenFrequencyWeighting: () => void;

  aboutToAppear(): void {
    const config = DebounceUtils.getDebounceConfig();
    
    this.debouncedOpenTimeWeighting = DebounceUtils.createDebounce(() => {
      this.openTimeWeightingDialog();
    }, config.NAVIGATION);

    this.debouncedOpenFrequencyWeighting = DebounceUtils.createDebounce(() => {
      this.openFrequencyWeightingDialog();
    }, config.NAVIGATION);
  }

  build() {
    // ... 修改onClick调用
    .onClick(() => {
      this.debouncedOpenTimeWeighting();
    })
    
    // ... 其他设置项类似
  }
}
```

### 4. 对话框组件防抖改造

#### MembershipAgreementDialog.ets 改造示例

```typescript
import { DebounceUtils } from '../../utils/DebounceUtils';

@ComponentV2
export struct MembershipAgreementDialog {
  // ... 现有代码
  
  @Local private debouncedAgree: () => void;
  @Local private debouncedCancel: () => void;

  aboutToAppear(): void {
    const config = DebounceUtils.getDebounceConfig();
    
    this.debouncedAgree = DebounceUtils.createDebounce(() => {
      this.onAgree();
    }, config.CONFIRMATION);

    this.debouncedCancel = DebounceUtils.createDebounce(() => {
      this.onCancel();
    }, config.CONFIRMATION);
  }

  build() {
    // ... 修改onClick调用
    .onClick(() => {
      this.debouncedAgree();
    })
    
    // ... 取消按钮类似
  }
}
```

## 防抖配置优化建议

### 1. 环境自适应防抖
```typescript
// 根据设备性能调整防抖时间
static getAdaptiveDebounceTime(baseTime: number): number {
  const performance = window.performance;
  if (performance && performance.memory) {
    const usedMemory = performance.memory.usedJSHeapSize;
    const totalMemory = performance.memory.totalJSHeapSize;
    const memoryUsage = usedMemory / totalMemory;
    
    // 内存使用率高时增加防抖时间
    if (memoryUsage > 0.8) {
      return baseTime * 1.5;
    }
  }
  return baseTime;
}
```

### 2. 用户行为分析
```typescript
// 根据用户点击频率调整防抖
static getUserAdaptiveDebounce(userId: string, baseTime: number): number {
  const userBehavior = this.getUserBehavior(userId);
  if (userBehavior.fastClickRate > 0.7) {
    return baseTime * 1.2; // 频繁点击用户增加防抖
  }
  return baseTime;
}
```

## 测试方案

### 1. 单元测试
```typescript
// DebounceUtils.test.ets
describe('DebounceUtils', () => {
  it('should debounce function calls', (done) => {
    let callCount = 0;
    const debouncedFn = DebounceUtils.createDebounce(() => {
      callCount++;
    }, 100);

    // 快速调用多次
    debouncedFn();
    debouncedFn();
    debouncedFn();

    setTimeout(() => {
      expect(callCount).toBe(1);
      done();
    }, 150);
  });
});
```

### 2. 集成测试
- 测试按钮点击防抖效果
- 验证列表操作防抖
- 检查对话框确认防抖

## 性能监控

### 1. 防抖效果统计
```typescript
class DebounceMonitor {
  private static clickStats = new Map<string, number>();
  
  static recordClick(component: string) {
    const count = this.clickStats.get(component) || 0;
    this.clickStats.set(component, count + 1);
  }
  
  static getStats() {
    return this.clickStats;
  }
}
```

### 2. 性能影响分析
- 内存使用变化
- CPU使用率
- 响应时间改善

## 部署策略

### 1. 渐进式部署
1. 先部署工具类和测试
2. 分批改造组件
3. 监控性能影响
4. 全量部署

### 2. 回滚方案
- 保留原有代码注释
- 提供配置开关
- 快速回滚机制

## 总结

本指南提供了完整的防抖实现方案，包括工具类设计、组件改造示例、测试方案和部署策略。通过统一的防抖处理，可以显著提升应用的用户体验和性能表现。