import { DatabaseConstants } from '../constants/DatabaseConstants';
import { TableCreateSql } from '../constants/TableCreateSql';
import { DbConfig } from '../interfaces/DatabaseInterfaces';
import { MainNoiseMeter } from './noisemeter/NoiseMeterNavigation';

@ComponentV2
export struct MainPage {
  build() {
    MainNoiseMeter()
  }
}

export const dbConfig: DbConfig = {
  dbName: DatabaseConstants.NOISE_METER_DB,
  upgradeConfigs: [
    {
      version: 1,
      sqls: [
        TableCreateSql.DECIBEL_RECORDS]
    }
    ,
    {
      version: 2,
      sqls: [
        TableCreateSql.ADD_WEIGHTING_TYPES_COLUMN]
    }
    ,
    {
      version: 3,
      sqls: [
        TableCreateSql.ADD_COMMENT_COLUMN]
    },
    {
      version: 4,
      sqls: [
        TableCreateSql.ADD_TIMESTAMP_INDEX]
    },
    {
      version: 5,
      sqls: [
        TableCreateSql.ALERT_HISTORY,
        TableCreateSql.ADD_ALERT_HISTORY_STARTTIME_INDEX,
        TableCreateSql.ADD_ALERT_HISTORY_SEVERITY_INDEX
      ]
    }
  ]
}