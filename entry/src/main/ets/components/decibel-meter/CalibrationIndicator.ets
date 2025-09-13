import { WeightingType } from "../../constants/WeightingConstants";

interface CalibrationConfig {
  gain: number;
  weightingType: WeightingType;
}

@Builder
export function CalibrationIndicator(config: CalibrationConfig) {

}