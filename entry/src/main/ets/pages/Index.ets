import { MainPage } from 'entry/MainPageInfo'

@Builder
function IndexBuilder() {
  Index()
}

@Entry
@Component
struct Index {
  build() {
    Column() {
      MainPage()
    }
  }
}