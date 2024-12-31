import { getTitleName } from 'entry/MainPageInfo'
import { getPageName } from 'entry/MainPageInfo'

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
    }
    .title(getTitleName())
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
    .onAppear(() => {
      // this.navStack.pop()
      this.navStack.replacePath(new NavPathInfo(getPageName(), undefined, () => {
      }, true), true)
    })
  }
}