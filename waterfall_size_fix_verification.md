# 瀑布图尺寸修复验证文档

## 问题描述
瀑布图尺寸没有和整个Canvas的尺寸相匹配，只占了下部1/4多一点点，导致显示区域过小。

## 修复方案
通过以下修改让瀑布图完全填满整个Canvas坐标方框：

### 1. 边距配置调整
- **修改前**: `{top: 20, right: 15, bottom: 40, left: 35}`
- **修改后**: `{top: 0, right: 0, bottom: 0, left: 0}`

### 2. 绘制区域计算优化
- **修改前**: `chartWidth = canvasWidth - margin.left - margin.right`
- **修改后**: `chartWidth = canvasWidth` (直接使用整个Canvas宽度)
- **修改前**: `chartHeight = canvasHeight - margin.top - margin.bottom`
- **修改后**: `chartHeight = canvasHeight` (直接使用整个Canvas高度)

### 3. 坐标轴位置调整
- 将坐标轴标签移到Canvas外部显示
- 频率轴标签显示在Canvas底部外部
- 时间轴标签显示在Canvas左侧外部

### 4. 网格绘制优化
- 网格线现在绘制在整个Canvas区域
- 水平网格线: 从0到chartHeight
- 垂直网格线: 从0到chartWidth

## 修改的文件

### 1. [`DrawWaterfall.ets`](entry/src/main/ets/components/decibel-meter/DrawWaterfall.ets)
- 修改默认边距配置 (第84-89行)
- 调整绘制区域计算逻辑 (第212-218行)
- 优化网格绘制函数 (第359-387行)
- 调整坐标轴绘制函数 (第789-827行)
- 修复直接绘制方法中的坐标计算 (第632行)
- 修复单行频谱数据绘制中的坐标计算 (第677行)
- 修复并行计算绘制中的坐标计算 (第452行)

### 2. [`WaterfallChartComponent.ets`](entry/src/main/ets/components/decibel-meter/WaterfallChartComponent.ets)
- 更新瀑布图特定的边距配置 (第40-52行)

### 3. [`BaseChartComponent.ets`](entry/src/main/ets/components/common/charts/BaseChartComponent.ets)
- 跳过瀑布图的网格绘制，避免重复绘制 (第116-120行)

## 预期效果

### 修复前
- 瀑布图只占据Canvas的约1/4空间
- 大量空白区域浪费
- 显示效果不佳

### 修复后
- 瀑布图完全填满整个Canvas坐标方框
- 充分利用显示空间
- 视觉效果更佳

## 验证方法

1. **视觉验证**:
   - 打开瀑布图界面
   - 观察瀑布图是否填满整个Canvas区域
   - 检查坐标轴标签是否显示在Canvas外部

2. **功能验证**:
   - 确保瀑布图数据正常显示
   - 验证网格线是否正确绘制
   - 检查坐标轴标签是否正确显示

3. **性能验证**:
   - 确保修改后性能没有明显下降
   - 验证并行计算功能正常工作

## 测试步骤

1. 启动应用
2. 进入全屏图表仪表盘
3. 切换到瀑布图模式
4. 观察瀑布图是否填满整个Canvas区域
5. 检查坐标轴标签是否显示在Canvas外部
6. 验证网格线是否正确绘制
7. 确认瀑布图数据正常显示

## 注意事项

- 坐标轴标签现在显示在Canvas外部，需要确保父容器有足够的空间显示这些标签
- 如果坐标轴标签被截断，可能需要调整父容器的padding或margin
- 网格线现在覆盖整个Canvas，如果不需要网格线可以关闭网格显示选项

## 回滚方案

如果修复出现问题，可以恢复以下配置：

1. 将边距配置改回原值: `{top: 20, right: 15, bottom: 40, left: 35}`
2. 恢复绘制区域计算: `canvasWidth - margin.left - margin.right`
3. 恢复坐标轴绘制位置到Canvas内部

## 总结

通过本次修复，瀑布图现在能够充分利用Canvas的显示空间，解决了尺寸不匹配的问题，提升了用户体验。