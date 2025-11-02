# 瀑布图动态分辨率计算系统技术规范

## 问题分析

### 当前问题
1. **像素点大小固定**：在 `ConcurrentWaterfallProcessor.ets` 和 `DrawWaterfall.ets` 中，像素点大小被硬编码为 `rowSpacing`（当前为1像素）
2. **绘制函数写死**：绘制逻辑在多个地方重复，没有统一的动态计算机制
3. **分辨率不匹配**：像素点太小导致显示效果不佳

### 影响范围
- `ConcurrentWaterfallProcessor.ets` - 并行计算处理
- `DrawWaterfall.ets` - 主要绘制逻辑
- `WaterfallChartComponent.ets` - 组件集成

## 系统架构设计

### 核心组件

#### WaterfallResolutionManager
负责动态计算像素参数，根据Canvas尺寸自动调整显示效果。

```typescript
interface ResolutionConfig {
  minPixelSize: number;        // 最小像素大小 (2-4像素)
  maxPixelSize: number;        // 最大像素大小 (8-12像素)
  targetRows: number;          // 目标显示行数 (50-100行)
  enableGap: boolean;          // 是否启用行间间隙
  gapRatio: number;            // 间隙比例 (0.1-0.3)
  performanceMode: 'quality' | 'performance' | 'balanced';
}

interface ResolutionResult {
  pixelSize: number;           // 计算后的像素大小
  rowSpacing: number;          // 行间距
  maxDisplayRows: number;      // 最大显示行数
  actualRows: number;          // 实际显示行数
  gapSize: number;             // 间隙大小
}
```

### 计算策略

#### 1. 像素大小计算
```typescript
function calculatePixelSize(canvasHeight: number, config: ResolutionConfig): number {
  const baseSize = canvasHeight / config.targetRows;
  const clampedSize = Math.max(config.minPixelSize, Math.min(config.maxPixelSize, baseSize));
  return Math.round(clampedSize);
}
```

#### 2. 行间距计算
```typescript
function calculateRowSpacing(pixelSize: number, config: ResolutionConfig): number {
  if (config.enableGap) {
    return pixelSize + (pixelSize * config.gapRatio);
  }
  return pixelSize;
}
```

#### 3. 显示行数计算
```typescript
function calculateDisplayRows(canvasHeight: number, rowSpacing: number): number {
  return Math.floor(canvasHeight / rowSpacing);
}
```

## 实施计划

### 步骤1：创建WaterfallResolutionManager类
**文件**: `entry/src/main/ets/utils/WaterfallResolutionManager.ets`

```typescript
export class WaterfallResolutionManager {
  private config: ResolutionConfig;
  
  constructor(config?: Partial<ResolutionConfig>) {
    this.config = {
      minPixelSize: 2,
      maxPixelSize: 8,
      targetRows: 80,
      enableGap: false,
      gapRatio: 0.1,
      performanceMode: 'balanced',
      ...config
    };
  }
  
  calculateResolution(canvasWidth: number, canvasHeight: number): ResolutionResult {
    const pixelSize = this.calculatePixelSize(canvasHeight);
    const rowSpacing = this.calculateRowSpacing(pixelSize);
    const maxDisplayRows = this.calculateDisplayRows(canvasHeight, rowSpacing);
    
    return {
      pixelSize,
      rowSpacing,
      maxDisplayRows,
      actualRows: maxDisplayRows,
      gapSize: config.enableGap ? pixelSize * config.gapRatio : 0
    };
  }
  
  // 其他计算方法...
}
```

### 步骤2：修改ConcurrentWaterfallProcessor
**修改点**: 使用动态计算的 `rowSpacing` 参数

```typescript
// 在 concurrentProcessAllWaterfallFrames 函数中
const resolution = getCurrentResolution(); // 从外部传入
const maxRows = Math.floor(chartHeight / resolution.rowSpacing);
const rowsToProcess = Math.min(spectrumHistory.length, maxRows);

// 在计算Y坐标时
const y = chartHeight - (rowIndex * resolution.rowSpacing);
```

### 步骤3：修改DrawWaterfall
**修改点**: 使用动态计算的像素参数

```typescript
// 在 drawProcessedFrames 函数中
const resolution = getCurrentResolution();
const rectPixels = imageDataRenderer.createRectPixels(
  bin.x,
  frame.y,
  resolution.pixelSize,  // 使用动态像素大小
  resolution.pixelSize,  // 使用动态像素大小
  r, g, b, a
);
```

### 步骤4：更新WaterfallChartComponent
**修改点**: 集成分辨率管理器

```typescript
// 在组件中添加分辨率管理器
@Local private resolutionManager: WaterfallResolutionManager = new WaterfallResolutionManager();

// 在绘制函数中计算分辨率
private async drawWaterfallChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): Promise<void> {
  const resolution = this.resolutionManager.calculateResolution(canvasWidth, canvasHeight);
  // 将resolution参数传递给绘制函数
}
```

## 配置参数建议

### 默认配置
```typescript
const DefaultResolutionConfig: ResolutionConfig = {
  minPixelSize: 2,      // 最小2像素，确保可见性
  maxPixelSize: 8,      // 最大8像素，避免过度放大
  targetRows: 80,       // 目标80行，平衡显示效果和性能
  enableGap: false,     // 默认不启用间隙
  gapRatio: 0.1,        // 10%间隙比例
  performanceMode: 'balanced'
};
```

### 性能模式配置
```typescript
const PerformanceConfigs = {
  quality: {
    minPixelSize: 3,
    maxPixelSize: 12,
    targetRows: 60,
    enableGap: true,
    gapRatio: 0.15
  },
  performance: {
    minPixelSize: 1,
    maxPixelSize: 4,
    targetRows: 100,
    enableGap: false,
    gapRatio: 0
  },
  balanced: {
    minPixelSize: 2,
    maxPixelSize: 8,
    targetRows: 80,
    enableGap: false,
    gapRatio: 0.1
  }
};
```

## 预期效果

### 改进前
- 像素大小：固定1像素
- 显示效果：像素点太小，难以看清
- 适应性：无法根据Canvas尺寸调整

### 改进后
- 像素大小：动态计算（2-8像素）
- 显示效果：清晰可见，大小适中
- 适应性：自动根据Canvas尺寸优化显示

## 测试计划

### 测试场景
1. **小尺寸Canvas** (200x100像素)
2. **中等尺寸Canvas** (400x200像素) 
3. **大尺寸Canvas** (800x400像素)
4. **超大尺寸Canvas** (1200x600像素)

### 验证指标
- 像素大小是否在合理范围内
- 显示行数是否合适
- 性能是否可接受
- 视觉效果是否改善

## 风险评估

### 技术风险
- 性能影响：动态计算可能增加CPU开销
- 兼容性问题：需要确保与现有代码兼容

### 缓解措施
- 添加缓存机制，避免重复计算
- 提供性能监控和调试信息
- 保持向后兼容的默认参数