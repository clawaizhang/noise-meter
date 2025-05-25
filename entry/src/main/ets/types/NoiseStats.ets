export interface BasicStats {
  leq: number;
  lmax: number;
  lmin: number;
  lpeak?: number;
  l10: number;
  l50: number;
  l90: number;
}

export interface HealthStats {
  dailyDose: number;
  weeklyAvg: number;
  peakEvents: number;
}

export interface HotSpot {
  coord: string;
  value: number;
}

export interface MovementPoint {
  lat: number;
  lng: number;
}

export interface SpatialStats {
  hotSpots: Array<HotSpot>;
  movementPath: Array<MovementPoint>;
}