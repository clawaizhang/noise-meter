/**
 * 位置状态枚举
 */
export enum LocationState {
  /**
   * 已关闭
   */
  DISABLED,

  /**
   * 服务未开启
   */
  SERVICE_DISABLED,

  /**
   * 缺少权限
   */
  NO_PERMISSION,

  /**
   * 已开启
   */
  ENABLED,

  /**
   * 定位中
   */
  LOCATING,

  /**
   * 定位失败
   */
  FAILED
} 