import { MainPage } from 'entry/MainPage'

@Entry
@Component
struct Index {

  build() {
    Column(){
      MainPage()
    }
  }
}