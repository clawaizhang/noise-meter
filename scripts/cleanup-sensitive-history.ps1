#Requires -Version 5.1
<#
.SYNOPSIS
    清洗 noise-meter 仓库的 Git 历史，移除敏感文件和邮箱。

.DESCRIPTION
    本脚本会：
    1. 备份整个仓库到上级目录
    2. 使用 git-filter-repo 从历史中删除以下敏感文件：
       - build-profile.json5（清洗后会恢复当前占位符版本）
       - error.log
       - .claude/settings.local.json
       - entry/.hvigor/outputs/build-logs/build.log
       - .cursorrules
       - .windsurfrules
    3. 将历史提交中的 ko171@qq.com 替换为 GitHub noreply 邮箱

.WARNING
    运行此脚本后：
    - 所有 commit 的 hash 会改变
    - 必须执行 git push --force 才能同步到 GitHub
    - 如果其他人已经 fork 或 clone 了本仓库，他们的本地副本仍会保留旧历史
    - 所有协作者都需要重新 clone 或使用 force pull

    如果你非常看重现有的 commit hash / 提交记录时间线，建议不要运行本脚本。
    仅提交当前工作区的改动（build-profile.json5 占位符化 + .gitignore 更新）已经足够安全。
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backupDir = Join-Path (Split-Path -Parent $repoRoot) ("noise-meter-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$repoName = Split-Path -Leaf $repoRoot

function Test-GitFilterRepo {
    try {
        $null = Get-Command git-filter-repo -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "noise-meter Git 历史敏感信息清洗脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "本脚本会重写 Git 历史。" -ForegroundColor Yellow
Write-Host "运行后所有 commit hash 都会改变，必须 force push。" -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "请输入 'YES' 继续执行，或按 Ctrl+C 取消"
    if ($confirm -ne "YES") {
        Write-Host "已取消。" -ForegroundColor Green
        exit 0
    }
}

Set-Location $repoRoot

# 检查 git-filter-repo
if (-not (Test-GitFilterRepo)) {
    Write-Host "错误：未找到 git-filter-repo。" -ForegroundColor Red
    Write-Host "请先安装：" -ForegroundColor Red
    Write-Host "  pip install git-filter-repo" -ForegroundColor Yellow
    Write-Host "或参考：https://github.com/newren/git-filter-repo" -ForegroundColor Yellow
    exit 1
}

# 备份仓库
Write-Host "正在备份仓库到：$backupDir" -ForegroundColor Cyan
Copy-Item -Path $repoRoot -Destination $backupDir -Recurse -Force
Write-Host "备份完成。" -ForegroundColor Green

# 保存当前清理后的 build-profile.json5
$buildProfilePath = Join-Path $repoRoot "build-profile.json5"
$tempBuildProfile = Join-Path $env:TEMP "build-profile-cleaned.json5"
if (Test-Path $buildProfilePath) {
    Copy-Item -Path $buildProfilePath -Destination $tempBuildProfile -Force
    Write-Host "已保存当前清理后的 build-profile.json5 到临时目录。" -ForegroundColor Green
}

# 清洗敏感文件历史
Write-Host "正在从历史中移除敏感文件..." -ForegroundColor Cyan
$filesToRemove = @(
    "build-profile.json5",
    "error.log",
    ".claude/settings.local.json",
    "entry/.hvigor/outputs/build-logs/build.log",
    ".cursorrules",
    ".windsurfrules"
)

$args = @("--force")
foreach ($file in $filesToRemove) {
    $args += "--path"
    $args += $file
    $args += "--invert-paths"
}

& git-filter-repo @args

# 恢复清理后的 build-profile.json5
if (Test-Path $tempBuildProfile) {
    Copy-Item -Path $tempBuildProfile -Destination $buildProfilePath -Force
    Remove-Item -Path $tempBuildProfile -Force
    Write-Host "已恢复清理后的 build-profile.json5。" -ForegroundColor Green
}

# 清洗作者邮箱历史
Write-Host "正在替换历史提交中的邮箱..." -ForegroundColor Cyan
& git-filter-repo --email-callback `
    "return email if email != b'ko171@qq.com' else b'146507046+ZhangYuScott@users.noreply.github.com'" `--force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "历史清洗完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "接下来请手动执行：" -ForegroundColor Cyan
Write-Host "  git status" -ForegroundColor Yellow
Write-Host "  git log --oneline -5   # 检查提交记录是否还在" -ForegroundColor Yellow
Write-Host "  git remote add origin https://github.com/clawaizhang/noise-meter.git  # 如果 remote 丢失" -ForegroundColor Yellow
Write-Host "  git push --force-with-lease origin main" -ForegroundColor Yellow
Write-Host ""
Write-Host "如果出现问题，备份在：$backupDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "重要提醒：" -ForegroundColor Red
Write-Host "  1. 所有 commit hash 已改变" -ForegroundColor Red
Write-Host "  2. 必须 force push 到 GitHub" -ForegroundColor Red
Write-Host "  3. 其他 fork/clone 副本仍保留旧历史" -ForegroundColor Red
