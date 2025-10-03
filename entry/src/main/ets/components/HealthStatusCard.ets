import { DeviceHealthInfo, ScoreHealth } from '../types/DeviceHealthInfo'
import { LengthUnit } from '@kit.ArkUI'
import { DeviceHealthService } from '../services/DeviceHealthService'
import { MetricItem } from './common/MetricItem'
import { DesignConstants } from '../constants/DesignConstants'
import { calculateMemoryUsage, calculateStorageUsage, MemoryUtils } from '../utils/MemoryUtils'
import { navigationStack } from '../constants/ProviderConstant'

// 健康卡片状态枚举
enum HealthCardState {
  LOADING,    // 加载中
  SUCCESS,    // 加载成功
  ERROR,      // 错误状态
  EMPTY       // 空状态
}

// 定义导航参数接口
interface HealthDetailDialogParams {
  metricType: string;
  healthInfo: DeviceHealthInfo;
}

@ComponentV2
export struct HealthStatusCard {}