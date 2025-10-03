
// 功能链接项接口
interface FunctionLinkItem {
  id: string;
  icon: Resource;
  label: Resource;
  uri: string; // 系统设置页面的URI
}

@ComponentV2
export struct FunctionLinksPanel {}