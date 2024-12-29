# 分贝检测应用

一个基于 HarmonyOS 的分贝检测应用，可以实时检测环境噪音分贝值。

## 功能特性

- 实时分贝值检测和显示
- 检测过程中自动记录最小值、平均值和最大值
- 支持位置信息记录
- 历史记录查看和管理
- 点击分贝面板可查看当前检测的详细数据
- 检测结束后自动显示详情弹窗
- 支持收藏重要记录

## 更新日志

### 2024-01-20
- 新增：点击分贝面板可随时查看当前检测的详细数据
- 优化：停止检测时保留数据，方便随时查看统计信息
- 优化：详情弹窗支持空数据提示

### 2024-01-19
- 新增：历史记录收藏功能
- 新增：检测结束后显示详情弹窗
- 优化：UI界面交互体验

## 技术特性

- **开发语言**：ArkTS
- **目标平台**：HarmonyOS
- **最低API版本**：API 9
- **权限要求**：
  - 麦克风权限 (MICROPHONE)

## 项目结构

```
entry/src/main/
├── ets/                    # 源代码目录
│   ├── components/        # UI组件
│   │   ├── ControlButton  # 控制按钮组件
│   │   ├── DBDisplay      # 分贝显示组件
│   │   ├── HeaderTitle    # 标题组件
│   │   ├── PermissionError# 权限错误提示组件
│   │   └── StatisticsView # 统计数据显示组件
│   ├── pages/            # 页面
│   │   └── Index         # 主页面
│   └── services/         # 服务
│       ├── AudioService   # 音频处理服务
│       └── PermissionService # 权限管理服务
└── resources/            # 资源文件
```

## 安装使用

1. 克隆项目到本地
2. 使用 DevEco Studio 打开项目
3. 运行到设备或模拟器上
4. 首次运行时需要授予麦克风权限

## 开发环境要求

- DevEco Studio 3.1.0 Beta2 或更高版本
- HarmonyOS SDK API 9 或更高版本
- 支持 HarmonyOS 的设备或模拟器

## 贡献指南

欢迎提交问题和改进建议。如果您想贡献代码：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 许可证

[MIT License](LICENSE)
