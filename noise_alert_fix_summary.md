# 噪音警报分贝值不一致问题修复总结

## 问题描述
用户反馈噪音警报触发时，实际触发分贝值较高（如超过55dB阈值），但通知中显示的分贝值较低（如47dB），导致显示不一致。

## 根本原因分析
1. **状态机上下文延迟更新**：警报触发时使用的分贝值是状态机上下文中的值，而不是触发警报时的实际值
2. **分贝值传递路径不一致**：状态机在处理噪音变化事件时更新了上下文，但警报触发时可能使用的是更新后的值
3. **防抖机制影响**：状态机的防抖机制可能导致警报触发时使用的分贝值不是实际触发阈值时的值

## 修复方案

### 1. 修改 AlertStateMachine.ets
- 添加 `alertTriggerDecibel` 字段记录警报触发时的实际分贝值
- 在 `calculateStateFromNoiseLevel` 方法中记录触发分贝值
- 添加 `AlertTriggerDecibel` 计算属性获取触发分贝值
- 在 `reset` 方法中重置触发分贝值记录

### 2. 修改 AlertsContent.ets
- 在 `updateAlertState` 方法中使用 `stateMachine.AlertTriggerDecibel` 而不是 `context.currentDecibel`
- 添加安全措施，当触发分贝值不可用时使用上下文值作为后备

### 3. 修改 AlertService.ets
- 在 `triggerAlert` 方法中添加详细的分贝值传递日志
- 记录实际分贝值、阈值和差值，便于问题追踪

## 修改的文件

1. **entry/src/main/ets/utils/AlertStateMachine.ets**
   - 添加 `alertTriggerDecibel` 字段
   - 修改 `calculateStateFromNoiseLevel` 方法
   - 添加 `AlertTriggerDecibel` 计算属性
   - 修改 `reset` 方法

2. **entry/src/main/ets/components/alerts/AlertsContent.ets**
   - 修改 `updateAlertState` 方法使用触发分贝值
   - 添加安全后备机制

3. **entry/src/main/ets/services/AlertService.ets**
   - 在 `triggerAlert` 方法中添加详细日志

## 预期效果
修复后，当用户设置阈值为55dB时：
- 实际噪音超过55dB时触发警报
- 通知中显示的分贝值将是实际的触发值（如56dB、57dB等）
- 不会出现触发时是56dB但通知显示47dB的不一致情况

## 验证方法
1. 设置阈值为55dB
2. 产生超过55dB的噪音
3. 检查通知中显示的分贝值是否与实际触发值一致
4. 查看日志确认分贝值传递正确

## 技术要点
- 使用状态机记录触发时的实际分贝值
- 确保分贝值传递路径一致
- 添加详细的调试日志便于问题追踪
- 提供安全后备机制确保系统稳定性