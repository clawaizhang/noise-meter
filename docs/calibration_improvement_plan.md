# 自动校准算法改进计划

## 问题分析

### 当前问题
1. **环境检测阈值不合理**：
   - 当前：EXCELLENT < 30dB, GOOD 30-40dB, FAIR 40-50dB, POOR > 50dB
   - 期望：更严格的环境检测标准，符合"非常非常安静"的要求

2. **校准算法逻辑缺失**：
   - 当前：只有环境检测UI，缺少实际的校准计算
   - 期望：在安静环境下自动将测量值调整到28dB

3. **参考声级不匹配**：
   - 当前：REFERENCE_LEVEL = 26dB
   - 期望：目标校准值应为28dB

### 现有校准算法
```typescript
private beginCalibration() {
  const calibrationDuration = CALIBRATION_CONFIG.AUTO_CALIBRATION_DURATION;
  this.calibrationProgress = 0;
  let totalDecibel = 0;
  let sampleCount = 0;

  // 开始校准
  const calibrationInterval = setInterval(() => {
    this.calibrationProgress += 1;
    totalDecibel += this.as.db;
    sampleCount += 1;

    if (this.calibrationProgress >= calibrationDuration) {
      clearInterval(calibrationInterval);
      this.finishCalibration(totalDecibel / sampleCount);
    }
  }, 1000);
}
```

## 改进方案

### 1. 环境检测阈值调整
```typescript
// 新的环境噪声阈值 (dB)
export const ENVIRONMENT_THRESHOLDS: EnvironmentThreshold = {
  EXCELLENT: 25,   // 优秀环境 < 25dB (非常非常安静)
  GOOD: 30,        // 良好环境 25-30dB
  FAIR: 35,        // 一般环境 30-35dB
  POOR: 35         // 差环境 > 35dB
};
```

### 2. 校准配置更新
```typescript
export const CALIBRATION_CONFIG: CaliConfig = {
  AUTO_CALIBRATION_DURATION: 8,      // 自动校准时长(秒)
  COUNTDOWN_DURATION: 3,             // 倒计时时长(秒)
  REFERENCE_LEVEL: 28,               // 参考声级(dB) - 更新为28dB
  TARGET_CALIBRATION_VALUE: 28,      // 新增：目标校准值
  MIN_CALIBRATION_VALUE: -30,        // 最小校准值
  MAX_CALIBRATION_VALUE: 30,         // 最大校准值
  PRESET_VALUES: [-20, -10, 0, 10, 20] // 预设校准点
};
```

### 3. 校准算法实现
```typescript
private finishCalibration(averageDecibel: number) {
  // 新的校准算法：在安静环境下将测量值调整到28dB
  if (this.environmentNoise < 25) {
    // 计算校准值 = 目标值(28dB) - 实际测量平均值
    const calibrationValue = 28 - averageDecibel;
    
    // 确保校准值在合理范围内
    const clampedValue = Math.max(
      CALIBRATION_CONFIG.MIN_CALIBRATION_VALUE,
      Math.min(CALIBRATION_CONFIG.MAX_CALIBRATION_VALUE, calibrationValue)
    );
    
    this.calibrationValue = clampedValue;
    this.isCalibrating = false;
    this.calibrationProgress = 100;
    
    // 保存校准值到设置
    this.saveCalibrationValue(clampedValue);
  } else {
    // 环境不理想，提示用户
    this.showEnvironmentWarning();
  }
}
```

### 4. 环境检测逻辑更新
```typescript
// 获取环境等级
private getEnvironmentLevel(): EnvironmentNoiseLevel {
  if (this.environmentNoise < 25) {
    return EnvironmentNoiseLevel.EXCELLENT;
  } else if (this.environmentNoise < 30) {
    return EnvironmentNoiseLevel.GOOD;
  } else if (this.environmentNoise < 35) {
    return EnvironmentNoiseLevel.FAIR;
  } else {
    return EnvironmentNoiseLevel.POOR;
  }
}

// 检查是否适合校准
private isSuitableForCalibration(): boolean {
  const level = this.getEnvironmentLevel();
  return level === EnvironmentNoiseLevel.EXCELLENT || level === EnvironmentNoiseLevel.GOOD;
}
```

## 实施步骤

1. **修改常量文件**：
   - 更新 `ENVIRONMENT_THRESHOLDS`
   - 更新 `CALIBRATION_CONFIG.REFERENCE_LEVEL`
   - 添加 `TARGET_CALIBRATION_VALUE`

2. **更新自动校准组件**：
   - 修改 `getEnvironmentLevel()` 方法
   - 修改 `isSuitableForCalibration()` 方法
   - 实现新的 `finishCalibration()` 算法

3. **更新校准状态指示器**：
   - 同步环境检测阈值

4. **测试验证**：
   - 在不同环境噪声水平下测试校准效果
   - 验证校准精度和用户体验

## 预期效果

- 在25dB以下的安静环境下，自动校准会将测量值准确调整到28dB
- 环境检测更加严格，确保校准精度
- 用户获得更准确的噪声测量结果