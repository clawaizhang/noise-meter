import { MainPage } from 'entry/MainPage'

@Builder
function IndexBuilder(name: string, param: Object) {
  Index()
}

@Entry
@Component
struct Index {
  build() {
    Navigation() {
      Column() {
        MainPage()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('噪音检测')
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
  }
}