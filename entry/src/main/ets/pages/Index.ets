import { getTitleName, MainPage } from 'entry/MainPageInfo'

@Builder
function IndexBuilder() {
  Index()
}

@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.navStack) {
      MainPage()
    }
    .title(getTitleName())
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
  }
}