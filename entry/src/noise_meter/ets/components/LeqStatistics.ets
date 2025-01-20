import { LocationService } from '../../../library/ets/services/LocationService';
import { DecibelService } from '../services/DecibelService';

import { BasicStats, HealthStats, SpatialStats } from '../types/NoiseStats';

@ComponentV2
export struct LeqStatistics {
  @Local private basicStats: BasicStats = {
    leq: 0,
    lmax: 0,
    lmin: 0,
    l10: 0,
    l50: 0,
    l90: 0
  };

  @Local private healthStats: HealthStats = {
    dailyDose: 0,
    weeklyAvg: 0,
    peakEvents: 0
  };

  @Local private spatialStats: SpatialStats = {
    hotSpots: [],
    movementPath: []
  };

  build() {
    Column() {
      // 头部摘要
      HeaderSummary({ basicStats: this.basicStats, healthStats: this.healthStats })
      
      Row() {
        // 主区域
        Column() {
          LineChart({ data: this.basicStats })
          HealthIndicators({ stats: this.healthStats })
        }
        .layoutWeight(2)
        
        // 侧边栏
        Column() {
          NoiseLevelPieChart({ stats: this.basicStats })
          PeakEvents({ events: this.healthStats.peakEvents })
        }
        .layoutWeight(1)
      }
      
      // 底部面板
      HeatMap({ data: this.spatialStats })
    }
    .onAppear(() => {
      this.loadData();
    })
  }

  private loadData() {
    // 加载基础声学参数
    DecibelService.getBasicStats().then(stats => {
      this.basicStats = stats;
    });

    // 加载健康暴露指标
    DecibelService.getHealthStats().then(stats => {
      this.healthStats = stats;
    });

    // 加载时空分布特征
    LocationService.getSpatialStats().then(stats => {
      this.spatialStats = stats;
    });
  }
}

// 头部摘要组件
@ComponentV2
struct HeaderSummary {
  @Param @Require basicStats: BasicStats;
  @Param @Require healthStats: HealthStats;

  build() {
    Row() {
      Text(`今日Leq: ${this.basicStats.leq.toFixed(1)}dB(A)`)
        .fontSize(16)
      Text(`超标次数: ${this.healthStats.peakEvents}`)
        .fontSize(16)
        .margin({ left: 16 })
    }
    .padding(16)
    .backgroundColor('#F5F5F5')
  }
}

// 折线图组件
@ComponentV2
struct LineChart {
  @Param @Require data: BasicStats;

  build() {
    Line()
      // .data([
      //   this.data.l10,
      //   this.data.l50,
      //   this.data.l90
      // ])
      .width('90%')
      .height(200)
      .margin({ top: 16 })
  }
}

// 健康指标组件
@ComponentV2
struct HealthIndicators {
  @Param @Require stats: HealthStats;

  build() {
    Column() {
      Text(`日暴露剂量: ${this.stats.dailyDose.toFixed(1)}%`)
      Text(`周平均暴露: ${this.stats.weeklyAvg.toFixed(1)}dB`)
    }
    .padding(16)
  }
}

// 噪音等级饼图组件
@ComponentV2
struct NoiseLevelPieChart {
  @Param @Require stats: BasicStats;

  build() {
    // TODO: 实现饼图
    Text('噪音等级饼图')
      .padding(16)
  }
}

// 峰值事件组件
@ComponentV2
struct PeakEvents {
  @Param @Require events: number;

  build() {
    Text(`峰值事件: ${this.events}`)
      .padding(16)
  }
}

// 热力图组件
@ComponentV2
struct HeatMap {
  @Param @Require data: SpatialStats;

  build() {
    // TODO: 实现热力图
    Text('地理热力图')
      .padding(16)
  }
}