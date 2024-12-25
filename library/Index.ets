// Base Components
import { HeaderTitle } from './src/main/ets/components/base/HeaderTitle';

// Business Components
import { DecibelMeter } from './src/main/ets/components/business/DecibelMeter';
import { StatisticsView } from './src/main/ets/components/business/StatisticsView';
import type { StatisticsDataPoint } from './src/main/ets/components/business/StatisticsView';
import { LocationDisplay } from './src/main/ets/components/business/LocationDisplay';

// Services
import { AudioService } from './src/main/ets/services/AudioService';

const NoiseDetectionLib = {
  HeaderTitle,
  DecibelMeter,
  StatisticsView,
  LocationDisplay,
  AudioService
};

export default NoiseDetectionLib;
export {
  HeaderTitle,
  DecibelMeter,
  StatisticsView,
  LocationDisplay,
  AudioService
};
export type { StatisticsDataPoint };