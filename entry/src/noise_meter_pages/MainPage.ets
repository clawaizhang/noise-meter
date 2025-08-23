import { DatabaseConstants } from "../main/ets/constants/DatabaseConstants";
import { TableCreateSql } from "../main/ets/constants/TableCreateSql";
import { DbConfig } from "../main/ets/interfaces/DatabaseInterfaces";
import { MainNoiseMeter } from "../main/ets/pages/noisemeter/NoiseMeterNavigation";

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
    }
  ]
}