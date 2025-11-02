import { FunctionLinksPanel } from '../components/FunctionLinksPanel'
import { DesignConstants } from '../constants/DesignConstants'

@Entry
@ComponentV2
struct TestFunctionLinksPage {
  build() {
    Column() {
      // 页面标题
      Text($r('app.string.function_links_panel_title'))
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ 
          top: DesignConstants.SPACING_XL,
          bottom: DesignConstants.SPACING_LG 
        })
      
      // 功能链接面板组件
      FunctionLinksPanel()
        .width('90%')
        .margin({ bottom: DesignConstants.SPACING_LG })
      
      // 说明文本
      Text('点击功能按钮将尝试跳转到系统设置页面')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .width('80%')
        .margin({ top: DesignConstants.SPACING_LG })
    }


    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.background_primary'))
  }
}