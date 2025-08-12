import { DatabaseConstants } from "../constants/DatabaseConstants"
import { TableCreateSql } from "../constants/TableCreateSql"
import { DbConfig } from "../interfaces/DatabaseInterfaces"
import { app } from "./AppManager"

export class DbManager {
  public static getDbUpgradeConfigs(): DbConfig {
    if
    (app.noiseMeter
    ) {
      const
        dbConfig: DbConfig = {
          dbName: DatabaseConstants.NOISE_METER_DB,
          upgradeConfigs: [
            {
              version: 1,
              sqls: [TableCreateSql.DECIBEL_RECORDS]
            },
            {
              version: 2,
              sqls: [TableCreateSql.ADD_WEIGHTING_TYPES_COLUMN]
            },
            {
              version: 3,
              sqls: [TableCreateSql.ADD_COMMENT_COLUMN]
            }
          ]
        }
      return dbConfig;
    }
    if
    (app.deviceManager
    ) {
      const
        dbConfig: DbConfig = {
          dbName: DatabaseConstants.DEVICE_MANAGER_DB,
          upgradeConfigs: []
        }
      return dbConfig;
    }
    const
      dbConfig: DbConfig = {
        dbName: DatabaseConstants.DEVICE_MANAGER_DB,
        upgradeConfigs: []
      }
    return dbConfig;
  }
}