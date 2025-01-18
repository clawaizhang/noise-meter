import { NoiseStandardType } from "../constants/NoiseStandardConstants";

export class NoiseStandard {
  type: NoiseStandardType;
  typeName: string;
  dayLimit: number;
  nightLimit: number;
  description: string;

  constructor(
    type: NoiseStandardType,
    typeName: string,
    dayLimit: number,
    nightLimit: number,
    description: string
  ) {
    this.type = type;
    this.typeName = typeName;
    this.dayLimit = dayLimit;
    this.nightLimit = nightLimit;
    this.description = description;
  }
}