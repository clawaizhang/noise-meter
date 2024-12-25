// Base Components
import { HeaderTitle } from './src/main/ets/components/base/HeaderTitle';

// Business Components
import { DecibelMeter } from './src/main/ets/components/business/DecibelMeter';
import { StatisticsView } from './src/main/ets/components/business/StatisticsView';
import type { StatisticsDataPoint } from './src/main/ets/components/business/StatisticsView';
import { LocationDisplay, type LocationStyle } from './src/main/ets/components/business/LocationDisplay';

// Services
import { AudioService } from './src/main/ets/services/AudioService';

/**
 * 噪音检测库接口
 */
export class NoiseDetectionLibClass {
  HeaderTitle = HeaderTitle;
  DecibelMeter = DecibelMeter;
  StatisticsView = StatisticsView;
  LocationDisplay = LocationDisplay;
  AudioService = AudioService;
}

const NoiseDetectionLib = new NoiseDetectionLibClass();

export default NoiseDetectionLib;
export {
  HeaderTitle,
  DecibelMeter,
  StatisticsView,
  LocationDisplay,
  AudioService
};
export type { StatisticsDataPoint, LocationStyle };