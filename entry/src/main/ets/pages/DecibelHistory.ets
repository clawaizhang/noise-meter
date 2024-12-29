import { NoiseDecibelHistoryPage } from 'entry/NoiseDecibelHistoryPage'

@Entry
@Component
struct DecibelHistory {

  build() {
    Column(){
      NoiseDecibelHistoryPage()
    }
  }
}