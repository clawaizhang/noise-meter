import { DecibelMeter } from '../components/DecibelMeter'

@Entry
@Component
struct Index {

  build() {
   Column(){
     DecibelMeter()
   }
  }
}