import { NoiseDecibelHistory } from 'entry/NioseDecibelHistory'

@Entry
@Component
struct DecibelHistory {

  build() {
    Column(){
      NoiseDecibelHistory()
    }
  }
} 