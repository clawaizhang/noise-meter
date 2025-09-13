import { DesignConstants } from "../constants/DesignConstants"
import display from '@ohos.display';
import common from '@ohos.app.ability.common';
import prompt from '@ohos.prompt';

// 功能链接项接口
interface FunctionLinkItem {
  id: string;
  icon: Resource;
  label: Resource;
  uri: string; // 系统设置页面的URI
}

@ComponentV2
export struct FunctionLinksPanel {}