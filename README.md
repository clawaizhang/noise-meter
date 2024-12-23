# 噪音分贝仪

基于 HarmonyOS 的噪音分贝测量应用，使用 ArkTS 开发。

## 功能特点

- **实时分贝测量**：使用设备麦克风实时测量环境噪音分贝值
- **噪音等级显示**：根据分贝值自动判断当前环境噪音等级
  - 安静环境 (0-30dB)
  - 正常对话 (30-60dB)
  - 城市喧闹 (60-90dB)
  - 工业噪音 (90-100dB)
  - 危险噪音 (>100dB)
- **数据统计**：显示测量过程中的最小值、平均值和最大值
- **直观界面**：使用仪表盘样式展示当前分贝值，颜色随分贝值变化

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
