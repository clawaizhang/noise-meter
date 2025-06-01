# 颜色方案更新策略

## 1. 颜色定义扩展方案

```mermaid
graph TD
    A[现有颜色定义] --> B[分贝级别扩展]
    A --> C[阴影颜色扩展] 
    A --> D[系统颜色扩展]
    A --> E[按钮颜色扩展]
    
    B --> B1[decibel_very_quiet: #3EA665]
    B --> B2[decibel_quiet: #4CAF50]
    B --> B3[decibel_normal: #FFC107]
    B --> B4[decibel_noisy: #FF9800]
    B --> B5[decibel_very_noisy: #F44336]
    B --> B6[decibel_unbearable: #8B0000]
    
    C --> C1[shadow_light: #1A000000]
    C --> C2[shadow_medium: #33000000]
    C --> C3[shadow_dark: #4D000000]
    
    D --> D1[white: #FFFFFF]
    D --> D2[transparent_black_70: rgba(0,0,0,0.7)]
    D --> D3[transparent_white_90: rgba(255,255,255,0.9)]
    
    E --> E1[button_cancel: #666666]
    E --> E2[button_confirm: #2196F3]
    E --> E3[button_warning: #FF4444]
```

## 2. 颜色替换优先级

| 优先级 | 类别 | 处理方式 |
|--------|------|----------|
| 高 | 分贝级别颜色 | 立即替换为资源引用 |
| 高 | 按钮颜色 | 立即替换为资源引用 |
| 中 | 阴影颜色 | 下一版本替换 |
| 中 | 常用文本色 | 下一版本替换 |
| 低 | 一次性使用颜色 | 逐步替换 |

## 3. 颜色映射表(部分示例)

| 原颜色值 | 资源名称 | 使用场景 |
|----------|----------|----------|
| #3EA665 | $r('app.color.decibel_very_quiet') | 分贝级别颜色 |
| #4CAF50 | $r('app.color.decibel_quiet') | 分贝级别颜色 |
| #33000000 | $r('app.color.shadow_medium') | 卡片阴影 |
| #FFFFFF | $r('app.color.white') | 背景/文本色 |
| #666666 | $r('app.color.button_cancel') | 取消按钮 |

## 4. 代码修改规范

1. **禁止直接使用颜色值**
   - 所有颜色必须通过`$r('app.color.xxx')`引用
   - 例外：动态生成的颜色(如基于用户输入的渐变)

2. **强制使用资源引用**
   ```typescript
   // 错误示例
   .backgroundColor('#FFFFFF')
   
   // 正确示例
   .backgroundColor($r('app.color.white'))
   ```

3. **代码审查规则**
   - PR中检查是否有直接颜色值
   - ESLint规则检测颜色字面量

4. **迁移计划**
   - 第一阶段：高优先级颜色替换(1周)
   - 第二阶段：中优先级颜色替换(2周)
   - 第三阶段：低优先级颜色替换(后续迭代)