# 自动校准改进编码实施计划

## 总体目标

修复自动校准环境检测问题，优化用户体验，实现基于25dB基准的校准算法。

## 需要修改的文件清单

### 1. 常量定义文件
**文件：** `entry/src/main/ets/constants/CalibrationConstants.ets`

**修改内容：**
```typescript
// 环境噪声阈值 - 调整为更严格标准
export const ENVIRONMENT_THRESHOLDS: EnvironmentThreshold = {
  EXCELLENT: 25,   // 优秀环境 < 25dB (非常非常安静)
  GOOD: 30,        // 良好环境 25-30dB
  FAIR: 35,        // 一般环境 30-35dB
  POOR: 35         // 差环境 > 35dB
};

// 校准配置 - 更新参考声级为25dB
export const CALIBRATION_CONFIG: CaliConfig = {
  AUTO_CALIBRATION_DURATION: 8,      // 自动校准时长(秒)
  COUNTDOWN_DURATION: 3,             // 倒计时时长(秒)
  REFERENCE_LEVEL: 25,               // 参考声级(dB) - 更新为25dB
  TARGET_CALIBRATION_VALUE: 25,      // 目标校准值25dB
  MIN_CALIBRATION_VALUE: -30,        // 最小校准值
  MAX_CALIBRATION_VALUE: 30,         // 最大校准值
  PRESET_VALUES: [-20, -10, 0, 10, 20] // 预设校准点
};
```

### 2. 音频分析设置页面
**文件：** `entry/src/main/ets/pages/settings/AudioAnalysisSettingsNavigation.ets`

**修改内容：**
```typescript
// 修复环境噪声计算 - 使用实际数据而非硬编码
private startEnvironmentMonitoring() {
  setInterval(() => {
    // 使用实际测量数据计算环境噪声（背景噪声）
    const recentReadings = this.getRecentDecibelReadings(); // 需要实现此方法
    if (recentReadings.length > 0) {
      // 使用最小值作为环境噪声（背景噪声）
      this.environmentNoise = Math.min(...recentReadings);
    }
  }, 5000); // 每5秒更新一次
}

// 实现获取最近分贝读数的方法
private getRecentDecibelReadings(): number[] {
  // 返回最近一段时间的分贝读数
  // 可以从音频服务或历史记录中获取
  return []; // 需要具体实现
}
```

### 3. 自动校准组件
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

// 优化环境检测UI显示 - 隐藏具体数值
@Builder
private buildEnvironmentCheck() {
  Column({ space: DesignConstants.SPACING_SM }) {
    Text('校准环境检测')
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .alignSelf(ItemAlign.Start)

    if (this.environmentNoise < 25) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('sys.media.ic_ok')) // 成功图标
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor(CALIBRATION_COLORS.SUCCESS)
        Text('环境适合自动校准')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.SUCCESS)
      }
      Text('当前环境非常安静，可获得最佳精度')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    } else if (this.environmentNoise < 30) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('sys.media.ic_ok'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor(CALIBRATION_COLORS.SUCCESS)
        Text('环境适合自动校准')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.SUCCESS)
      }
      Text('当前环境适合自动校准')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    } else {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('sys.media.ic_warning')) // 警告图标
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor(CALIBRATION_COLORS.WARNING)
        Text('环境不适合自动校准')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(CALIBRATION_COLORS.WARNING)
      }
      Text('建议寻找更安静的环境进行校准')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
  }
  .width('100%')
  .padding(DesignConstants.SPACING_MD)
  .backgroundColor($r('sys.color.background_secondary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  .margin({ bottom: DesignConstants.SPACING_MD })
}

// 实现新的校准算法
private finishCalibration(averageDecibel: number) {
  // 新的校准算法：在安静环境下将测量值调整到25dB
  if (this.environmentNoise < 25) {
    // 计算校准值 = 目标值(25dB) - 实际测量平均值
    const calibrationValue = 25 - averageDecibel;
    
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
    promptAction.showDialog({
      title: '校准完成',
      message: `自动校准已完成！\n校准值：${clampedValue.toFixed(1)}dB\n测量值已调整到25dB基准。`,
      buttons: [{ text: '确定' }]
    });
  } else {
    // 环境不理想，提示用户
    promptAction.showDialog({
      title: '环境不理想',
      message: '当前环境噪声较高，建议在25dB以下的安静环境中进行校准以获得最佳精度。',
      buttons: [{ text: '确定' }]
    });
    this.isCalibrating = false;
    this.calibrationProgress = 0;
  }
}
```

### 4. 手动校准组件
**文件：** `entry/src/main/ets/components/calibration/EnhancedManualCalibration.ets`

**修改内容：**
- 确保不包含任何环境检测相关的UI元素
- 保持简洁的校准值调整界面

### 5. 校准状态指示器
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
1. 更新环境检测阈值
2. 更新参考声级为25dB

### 第二步：修复环境噪声计算
1. 移除硬编码的环境噪声模拟
2. 实现基于实际测量数据的计算

### 第三步：优化自动校准UI
1. 隐藏环境噪声具体数值
2. 提供简明的环境适合性评估
3. 实现新的校准算法

### 第四步：清理手动校准界面
1. 移除环境检测相关显示

### 第五步：同步其他组件
1. 更新校准状态指示器的环境检测逻辑

## 预期效果

### 自动校准界面
```
自动校准
────────────────
校准环境检测
✅ 环境适合自动校准
当前环境非常安静，可获得最佳精度
────────────────
[开始自动校准]
```

### 校准算法
- 在25dB以下的安静环境中执行自动校准
- 校准值 = 25 - 实际测量平均值
- 校准后测量值显示为25dB基准

## 测试要点

1. 在<25dB环境中验证自动校准精度
2. 测试环境检测提示的正确性
3. 验证校准值计算和范围限制
4. 确认手动校准界面无环境检测信息

这个实施计划将解决所有识别的问题，提供准确可靠的自动校准功能。