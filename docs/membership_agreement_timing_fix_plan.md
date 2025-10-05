# 会员协议弹出时机修复方案

## 问题分析

### 当前问题
1. **自动弹出问题**：在 [`Index.ets`](entry/src/main/ets/pages/Index.ets:250) 中，当用户使用APP达到1分钟时，会自动弹出会员协议，这干扰了用户体验
2. **重复弹出问题**：在多个地方（会员状态卡片、专业版升级页面）点击"免费体验"时，即使已经同意过协议，也会重复弹出

### 根本原因
- 使用完成时的自动弹出逻辑过于激进
- 缺少对用户已同意状态的检查
- 会员协议弹出时机设计不合理

## 解决方案

### 核心原则
**不主动弹出会员协议，只在用户明确点击时显示**

### 具体修改方案

#### 1. 移除自动弹出逻辑
在 [`Index.ets`](entry/src/main/ets/pages/Index.ets) 中：
- 移除 [`handleUsageCompletion()`](entry/src/main/ets/pages/Index.ets:242) 中的自动弹出会员协议逻辑
- 保留使用时长统计和奖励计算，但不主动弹出对话框

#### 2. 优化点击触发逻辑
在以下组件中添加已同意状态检查：

**在 [`MembershipStatusCard.ets`](entry/src/main/ets/components/membership/MembershipStatusCard.ets) 中：**
- 在 [`showMembershipAgreement()`](entry/src/main/ets/components/membership/MembershipStatusCard.ets:343) 方法中添加已同意检查
- 如果用户已同意协议，直接进入会员奖励流程，不重复弹出协议

**在 [`UpgradeContent.ets`](entry/src/main/ets/components/membership/UpgradeContent.ets) 中：**
- 在 [`handleFreeExperience()`](entry/src/main/ets/components/membership/UpgradeContent.ets:527) 方法中添加已同意检查
- 如果用户已同意协议，直接显示会员状态，不重复弹出协议

#### 3. 状态管理优化
- 使用 [`PreferenceKeys.has_agreed_membership_reward`](entry/src/main/ets/models/PreferenceKeys.ets:131) 作为唯一的状态标识
- 在所有需要弹出协议的地方都检查这个状态

## 修改步骤

### 第一步：修改 Index.ets
移除自动弹出会员协议的逻辑：

```typescript
// 在 handleUsageCompletion 方法中
private async handleUsageCompletion(): Promise<void> {
  const continuousUsageManager = ContinuousUsageManager.getInstance();
  const membershipRewardService = MembershipRewardService.getInstance();

  // 获取连续天数
  const consecutiveDays = continuousUsageManager.getConsecutiveDays();
  
  // 检查用户是否已同意会员奖励协议
  if (!this.pk.has_agreed_membership_reward) {
    // 用户未同意协议，不主动弹出，只记录日志
    console.info(`[使用完成] 连续${consecutiveDays}天，用户未同意会员奖励协议，等待用户主动点击`);
    return;
  }

  // 用户已同意协议，应用会员奖励
  membershipRewardService.applyMembershipReward(consecutiveDays);

  // 获取奖励信息
  const rewardDays = membershipRewardService.calculateRewardDays(consecutiveDays);
  const expiryDate = this.pk.member_ship.expiryDate;

  // 显示完成弹窗
  showRewardCompletionDialog(consecutiveDays, rewardDays, expiryDate);

  console.info(`[使用完成] 连续${consecutiveDays}天，获得${rewardDays}天会员`);
}
```

### 第二步：修改 MembershipStatusCard.ets
在点击"免费体验"时检查已同意状态：

```typescript
private showMembershipAgreement(): void {
  // 检查用户是否已同意协议
  if (this.pk.has_agreed_membership_reward) {
    // 用户已同意，直接进入会员奖励流程
    console.info('[会员管理] 用户已同意协议，直接进入会员奖励');
    this.updateMembershipData();
    return;
  }
  
  // 用户未同意，显示协议对话框
  let props: MembershipAgreementDialogProps = {
    onAgree: () => {
      this.handleAgreementAgree();
      dialog.dismiss();
    },
    onCancel: () => {
      this.handleAgreementCancel();
      dialog.dismiss();
    }
  };
  const dialog = DialogHub.getSheet()
    .setComponentTargetId('mainId')
    .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
    .setContent(wrapBuilder(MembershipAgreementDialogBuilder), props)
    .build();
  dialog.show();
}
```

### 第三步：修改 UpgradeContent.ets
在点击"免费体验"时检查已同意状态：

```typescript
private handleFreeExperience(): void {
  // 检查用户是否已同意协议
  if (this.pk.has_agreed_membership_reward) {
    // 用户已同意，直接进入会员奖励流程
    console.info('[会员管理] 用户已同意协议，直接进入会员奖励');
    this.handleAgreementAgree();
    return;
  }
  
  // 关闭当前升级对话框
  this.onLater();
  // 使用DialogHub显示会员协议对话框
  let props: MembershipAgreementDialogProps = {
    onAgree: () => {
      this.handleAgreementAgree();
      dialog.dismiss();
    },
    onCancel: () => {
      this.handleAgreementCancel();
      dialog.dismiss();
    }
  };
  const dialog = DialogHub.getSheet()
    .setComponentTargetId('mainId')
    .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
    .setContent(wrapBuilder(MembershipAgreementDialogBuilder), props)
    .build();
  dialog.show();
}
```

## 预期效果

### 修复后流程
1. **首次使用**：用户不会看到自动弹出的会员协议
2. **主动点击**：用户只有在会员状态卡片或专业版页面点击"免费体验"时才会看到协议
3. **避免重复**：用户同意协议后，再次点击"免费体验"不会重复弹出协议
4. **正常奖励**：使用时长统计和会员奖励计算正常进行，但不干扰用户

### 用户体验改善
- 不再有突兀的自动弹出对话框
- 用户完全控制何时查看和同意协议
- 避免重复同意带来的困扰
- 保持会员奖励功能的完整性

## 测试要点

1. 验证使用1分钟后不会自动弹出会员协议
2. 验证在会员状态卡片点击"免费体验"时：
   - 未同意时显示协议
   - 已同意时不重复显示
3. 验证在专业版页面点击"免费体验"时：
   - 未同意时显示协议
   - 已同意时不重复显示
4. 验证会员奖励计算正常进行
5. 验证使用完成弹窗正常显示

## 风险控制

- 保留原有的使用时长统计功能
- 保留会员奖励计算逻辑
- 只移除自动弹出行为，不影响核心功能
- 状态管理保持不变，确保数据一致性