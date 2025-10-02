# 自动校准改进实施指南

## 需要修改的文件

### 1. 修改常量文件
**文件：** `entry/src/main/ets/constants/CalibrationConstants.ets`

**修改内容：**
```typescript
// 环境噪声阈值 (dB) - 更新为更严格的标准
export const ENVIRONMENT_THRESHOLDS: EnvironmentThreshold = {
  EXCELLENT: 25,   // 优秀环境 < 25dB (非常非常安静)
  GOOD: 30,        // 良好环境 25-30dB
  FAIR: 35,        // 一般环境 30-35dB
  POOR: 35         // 差环境 > 35dB
};

// 校准配置 - 更新参考声级
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

### 2. 修改自动校准组件
**文件：** `entry/src/main/ets/components/calibration/ImprovedAutoCalibration.ets`

**修改内容：**
```typescript
// 更新环境检测逻辑
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

// 更新环境建议文本
private getEnvironmentAdvice(): string {
  const level = this.getEnvironmentLevel();
  switch (level) {
    case EnvironmentNoiseLevel.EXCELLENT:
      return '环境非常适合校准（非常安静）';
    case EnvironmentNoiseLevel.GOOD:
      return '环境适合校准';
    case EnvironmentNoiseLevel.FAIR:
      return '环境一般，建议寻找更安静的地方（<30dB）';
    default:
      return '环境嘈杂，不适合校准（>35dB）';
  }
}

// 实现新的校准完成逻辑
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
    
    // 显示校准成功提示
    this.showCalibrationSuccess(clampedValue);
  } else {
    // 环境不理想，提示用户
    this.showEnvironmentWarning();
    this.isCalibrating = false;
    this.calibrationProgress = 0;
  }
}

// 环境警告提示
private showEnvironmentWarning() {
  promptAction.showDialog({
    title: '环境不理想',
    message: `当前环境噪声${this.environmentNoise.toFixed(1)}dB较高，建议在25dB以下的安静环境中进行校准以获得最佳精度。`,
    buttons: [{ text: '确定' }]
  });
}

// 校准成功提示
private showCalibrationSuccess(calibrationValue: number) {
  promptAction.showDialog({
    title: '校准完成',
    message: `自动校准已完成！\n校准值：${calibrationValue.toFixed(1)}dB\n测量值已调整到28dB基准。`,
    buttons: [{ text: '确定' }]
  });
}
```

### 3. 修改校准状态指示器
**文件：** `entry/src/main/ets/components/calibration/CalibrationStatusIndicator.ets`

**修改内容：**
```typescript
// 同步更新环境检测逻辑
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
```

## 实施步骤

### 第一步：修改常量定义
1. 打开 `CalibrationConstants.ets`
2. 更新 `ENVIRONMENT_THRESHOLDS` 常量
3. 更新 `CALIBRATION_CONFIG.REFERENCE_LEVEL` 为28
4. 添加 `TARGET_CALIBRATION_VALUE` 字段

### 第二步：更新自动校准组件
1. 打开 `ImprovedAutoCalibration.ets`
2. 修改 `getEnvironmentLevel()` 方法
3. 更新 `getEnvironmentAdvice()` 方法
4. 实现新的 `finishCalibration()` 算法
5. 添加环境警告和成功提示方法

### 第三步：同步其他组件
1. 打开 `CalibrationStatusIndicator.ets`
2. 同步更新环境检测逻辑

### 第四步：测试验证
1. 在25dB以下的安静环境中测试自动校准
2. 验证校准后测量值是否显示为28dB
3. 在不同环境噪声水平下测试环境检测提示

## 预期行为

### 环境检测行为
- **<25dB**：显示"环境非常适合校准（非常安静）"
- **25-30dB**：显示"环境适合校准"
- **30-35dB**：显示"环境一般，建议寻找更安静的地方"
- **>35dB**：显示"环境嘈杂，不适合校准"

### 校准行为
- 只有在25dB以下的安静环境中才会执行自动校准
- 校准算法：`校准值 = 28 - 实际测量平均值`
- 校准完成后，测量值将显示为28dB基准
- 在校准过程中会显示进度和倒计时

## 注意事项

1. **环境检测精度**：确保环境噪声测量准确，建议使用多采样平均
2. **校准值范围**：校准值会被限制在-30dB到30dB之间
3. **用户提示**：提供清晰的校准状态和环境要求提示
4. **错误处理**：在校准失败或环境不理想时提供明确的错误信息