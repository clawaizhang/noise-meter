# 敏感信息清理说明

## 已完成的清理（当前工作区，不动 Git 历史）

以下改动已经完成，只需一次 `git commit` + `git push` 即可生效：

1. **build-profile.json5 脱敏**
   - 将所有签名证书路径、加密后的 `keyPassword`、`storePassword` 替换为占位符
   - 保留文件结构，方便 DevEco Studio 识别

2. **新增 build-profile.example.json5**
   - 提供模板，方便其他开发者或你自己在新环境中填写真实签名信息

3. **更新 .gitignore**
   - 忽略 `build-profile.json5`（真实签名配置）
   - 忽略 `error.log`、`.claude/`、`.cursorrules`、`.windsurfrules`
   - 忽略 `*.p12`、`*.p7b`、`*.cer`、`*.pem`、`*.jks`、`*.keystore`、`*.key`
   - 忽略 `.hvigor/outputs/` 等本地构建日志

4. **从 Git 索引移除错误跟踪的文件**
   - `error.log`
   - `.claude/settings.local.json`
   - `entry/.hvigor/outputs/build-logs/build.log`

## 提交命令

```bash
cd C:\Users\asus\DevEcoStudioProjects\zaoyinfenbeiyipro\noise-meter
git add build-profile.json5 build-profile.example.json5 .gitignore
git add error.log .claude/settings.local.json entry/.hvigor/outputs/build-logs/build.log
git commit -m "chore: 移除敏感签名配置和本地环境文件，避免泄露"
git push
```

## 仍然保留在 Git 历史中的敏感痕迹

由于**不清洗 Git 历史**，以下信息仍可在旧的 commit 中查看到：

- `build-profile.json5` 历史版本中的签名路径和加密密码
- 提交作者邮箱 `ko171@qq.com`
- `error.log` 的历史版本

这些信息的风险已经在 `SECURITY_CLEANUP.md` 编写前做过评估：

- 签名密码是 DevEco Studio 加密后的密文，单独无法直接伪造签名包
- 但绝对路径暴露了本地用户名 `asus` 和目录结构
- 邮箱暴露可能带来垃圾邮件、撞库、社工等风险

## 可选：彻底清洗 Git 历史

如果你将来希望彻底移除历史中的敏感信息，可以运行：

```powershell
.\scripts\cleanup-sensitive-history.ps1
```

运行后会：

- 备份整个仓库到 `../noise-meter-backup-YYYYMMDD-HHMMSS/`
- 使用 `git-filter-repo` 移除敏感文件的历史记录
- 将 `ko171@qq.com` 替换为 GitHub noreply 邮箱
- 保留所有 commit 的时间线、提交信息、代码改动
- **改变所有 commit 的 hash**，必须执行 `git push --force-with-lease origin main`

### 历史清洗脚本使用要求

1. 安装 `git-filter-repo`：

   ```bash
   pip install git-filter-repo
   ```

2. 运行脚本并按提示输入 `YES`：

   ```powershell
   .\scripts\cleanup-sensitive-history.ps1
   ```

3. 检查无误后 force push：

   ```bash
   git push --force-with-lease origin main
   ```

> ⚠️ **警告**：历史清洗会改变所有 commit hash，所有协作者都需要重新 clone 仓库。
