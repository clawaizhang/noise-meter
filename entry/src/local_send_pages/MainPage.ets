import { DatabaseConstants } from "../main/ets/constants/DatabaseConstants";
import { TableCreateSql } from "../main/ets/constants/TableCreateSql";
import { DbConfig } from "../main/ets/interfaces/DatabaseInterfaces";
import { MainLocalSend } from "../main/ets/pages/local_send/LocalSendNavigation";

@ComponentV2
export struct MainPage {
  build() {
    MainLocalSend()
  }
}

export const dbConfig: DbConfig = {
  dbName: DatabaseConstants.NOISE_METER_DB,
  upgradeConfigs: [

  ]
}