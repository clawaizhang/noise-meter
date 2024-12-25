// Business Components
import { DecibelMeter } from './src/main/ets/components/business/DecibelMeter';
import { StatisticsView } from './src/main/ets/components/business/StatisticsView';
import type { StatisticsDataPoint } from './src/main/ets/components/business/StatisticsView';
import { LocationDisplay, type LocationStyle } from './src/main/ets/components/business/LocationDisplay';

// Services
import { AudioService } from './src/main/ets/services/AudioService';
import { DecibelService } from './src/main/ets/services/DecibelService';

/**
 * 噪音检测库接口
 */
export class NoiseDetectionLibClass {
  DecibelMeter = DecibelMeter;
  StatisticsView = StatisticsView;
  LocationDisplay = LocationDisplay;
  AudioService = AudioService;
  DecibelService = DecibelService;
}

const NoiseDetectionLib = new NoiseDetectionLibClass();

export default NoiseDetectionLib;
export {
  DecibelMeter,
  StatisticsView,
  LocationDisplay,
  AudioService,
  DecibelService
};
export type { StatisticsDataPoint, LocationStyle };