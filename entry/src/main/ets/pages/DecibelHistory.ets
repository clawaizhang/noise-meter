import { NoiseDecibelHistoryPage } from 'entry/NoiseDecibelHistoryPage'
import router from '@ohos.router'

@Entry
@Component
struct DecibelHistory {
  build() {
    Navigation() {
      NoiseDecibelHistoryPage()
    }
    .title('历史记录')
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(false)
  }
}