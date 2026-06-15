# 敏感信息清理说明

## 已完成的清理

### 1. 当前工作区清理

以下改动已经通过 commit 推送到 GitHub：

1. **build-profile.json5 脱敏**
   - 将所有签名证书路径、加密后的 `keyPassword`、`storePassword` 替换为占位符
   - 保留文件结构，方便 DevEco Studio 识别

2. **新增 build-profile.example.json5**
   - 提供模板，方便其他开发者或你自己在新环境中填写真实签名信息

3. **更新 .gitignore**
   - 忽略 `build-profile.json5`（真实签名配置）
   - 忽略 `error.log`、`.claude/`、`.cursorrules`、`.windsurfrules`
   - 忽略 `*.p12`、`*.p7b`、`*.cer`、`*.pem`、`*jks`、`*keystore`、`*key`
   - 忽略 `.hvigor/outputs/` 等本地构建日志

4. **从 Git 索引移除错误跟踪的文件**
   - `error.log`
   - `.claude/settings.local.json`
   - `entry/.hvigor/outputs/build-logs/build.log`

### 2. Git 历史清洗

已使用 `git-filter-repo` 对历史进行重写，并强制推送到 `origin/main`：

- 从历史中移除了 `build-profile.json5`、`error.log`、`.claude/settings.local.json`、`.hvigor/build.log`、`.cursorrules`、`.windsurfrules`
- 将历史提交中的个人邮箱替换为 GitHub noreply 邮箱
- 所有 commit 的时间线、提交信息、代码改动均保留
- commit hash 已改变

## 本地开发注意事项

### 签名配置

克隆仓库后，复制 `build-profile.example.json5` 为 `build-profile.json5`，并填入你自己的 HarmonyOS 签名信息：

```bash
cp build-profile.example.json5 build-profile.json5
```

真实的 `build-profile.json5` 已被 `.gitignore` 忽略，不会被误提交。

### 历史清洗脚本

`scripts/cleanup-sensitive-history.ps1` 是一个通用模板脚本，用于将来需要再次清洗历史时使用。使用前需要编辑脚本，填入要替换的旧邮箱和新邮箱。

> ⚠️ **警告**：历史清洗会改变所有 commit hash，必须执行 `git push --force`。
