import { HeaderTitle } from '../components/HeaderTitle'
import { DBDisplay } from '../components/DBDisplay'
import { StatisticsView } from '../components/StatisticsView'
import { LocationDisplay } from '../components/LocationDisplay'

@Entry
@Component
struct Index {
  @State minDB: number = 100
  @State maxDB: number = 0
  @State avgDB: number = 0
  @State currentDB: number = 0

  private getDBColor(db: number): string {
    if (db < 30) return '#4CAF50'
    if (db < 60) return '#2196F3'
    if (db < 90) return '#FFC107'
    if (db < 100) return '#FF9800'
    return '#F44336'
  }

  build() {
    Column() {
      HeaderTitle()
      DBDisplay({ 
        minDB: $minDB,
        maxDB: $maxDB,
        avgDB: $avgDB,
        currentDB: $currentDB,
        getDBColor: this.getDBColor
      })
      StatisticsView({ 
        minDB: $minDB,
        maxDB: $maxDB,
        avgDB: $avgDB,
        getDBColor: this.getDBColor
      })
      LocationDisplay()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding(20)
  }
}