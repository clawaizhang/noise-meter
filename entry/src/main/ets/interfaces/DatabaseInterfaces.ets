/**
 * 数据库版本升级配置
 */
export interface DatabaseUpgradeConfig {
  /**
   * 目标版本号
   */
  version: number;

  /**
   * 该版本需要执行的SQL语句数组
   */
  sqls: string[];
}

export interface DbConfig {
  dbName: string;
  upgradeConfigs: DatabaseUpgradeConfig[];
}