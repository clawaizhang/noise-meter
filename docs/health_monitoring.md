# 设备健康检测功能文档

## 功能概述
设备健康检测功能提供对设备各项健康指标的实时监控和综合评分，包括：
- 电池健康度(电量、温度、状态)
- 性能指标(CPU、内存、存储使用率)
- 网络质量(连接状态、信号强度、延迟) - 以环形进度条显示信号强度(0-4)
- 传感器状态 - 以环形进度条显示状态(正常/警告/错误)

系统每5秒自动更新健康数据，并计算综合健康评分(0-100分)。

## 数据结构

### DeviceHealthInfo
设备健康信息主结构，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| battery | BatteryInfo | 电池信息 |
| performance | PerformanceInfo | 性能信息 |
| network | NetworkInfo | 网络信息 |
| sensors | SensorInfo | 传感器状态 |
| score | number | 综合健康评分(0-100) |
| lastUpdated | string | 最后更新时间(ISO格式) |

### BatteryInfo
电池信息：

| 字段 | 类型 | 说明 |
|------|------|------|
| level | number | 当前电量百分比(0-100) |
| health | number | 电池健康度(0-100) |
| temperature | number | 电池温度(摄氏度) |
| status | string | 充电状态(charging/discharging/full/unknown) |

### PerformanceInfo
性能信息：

| 字段 | 类型 | 说明 |
|------|------|------|
| cpu | number | CPU使用率(0-100) |
| memory | SystemMemInfo | 内存信息 |
| storage | StorageInfo | 存储信息 |

### NetworkInfo
网络信息：

| 字段 | 类型 | 说明 |
|------|------|------|
| isConnected | boolean | 是否连接网络 |
| type | NetType | 网络类型(wifi/cellular/ethernet/none) |
| signalStrength | number | 信号强度(0-4) |
| downloadSpeed | number | 下载速度(kbps) |
| uploadSpeed | number | 上传速度(kbps) |
| latency | number | 网络延迟(ms) |

## API接口

### DeviceHealthService
健康检测服务主类，提供以下方法：

#### getInstance(): DeviceHealthService
获取服务单例

#### getHealthInfo(): DeviceHealthInfo
获取当前设备健康信息

#### updateHealthInfo(): Promise<void>
手动触发健康信息更新

#### registerUpdateListener(callback: (score: number) => void): void
注册健康评分变化监听器

## 使用示例

```typescript
// 获取健康服务实例
const healthService = DeviceHealthService.getInstance();

// 获取当前健康信息
const healthInfo = healthService.getHealthInfo();
console.log(`当前健康评分: ${healthInfo.score}`);
console.log(`网络信号强度: ${healthInfo.network.signalStrength}/4`);
console.log(`传感器状态: ${healthInfo.sensors.status}`);

// 监听健康评分变化
healthService.registerUpdateListener((score) => {
  console.log(`健康评分更新: ${score}`);
});

// 手动更新健康信息
await healthService.updateHealthInfo();
```

## 界面显示
健康状态卡片以环形进度条直观显示各项指标：
- 电池健康度
- CPU使用率
- 内存使用率
- 存储使用率
- 网络信号强度
- 传感器状态

## 健康评分算法
综合健康评分计算公式：

```
score = (batteryScore * 0.3) + 
        ((cpuScore * 0.6 + memoryScore * 0.4) * 0.4) + 
        (networkScore * 0.2) + 
        (sensorScore * 0.1)
```

其中：
- batteryScore: 电池健康度(0-100)
- cpuScore: 1 - (CPU使用率/100)
- memoryScore: 可用内存/总内存
- networkScore: (网络健康度*0.5 + 信号强度*0.3 + (1-丢包率)*0.2)
- sensorScore: 传感器正常为1，异常为0.5

评分等级：
- ≥80: 良好(绿色)
- 60-79: 警告(黄色)
- <60: 差(红色)