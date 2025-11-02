import { NoiseStandard } from '../models/NoiseStandard';

export enum NoiseStandardType {
  TYPE_0,
  TYPE_1,
  TYPE_2,
  TYPE_3,
  TYPE_4A,
  TYPE_4B
}

export const NoiseStandards: NoiseStandard[] = [
  new NoiseStandard(
    NoiseStandardType.TYPE_0,
    '0类声环境功能区',
    50,
    40,
    '康复疗养区等特别需要安静的区域'
  ),
  new NoiseStandard(
    NoiseStandardType.TYPE_1,
    '1类声环境功能区',
    55,
    45,
    '居民住宅、医疗卫生、文化教育、科研设计、行政办公区域'
  ),
  new NoiseStandard(
    NoiseStandardType.TYPE_2,
    '2类声环境功能区',
    60,
    50,
    '商业金融、集市贸易或居住、商业、工业混杂区域'
  ),
  new NoiseStandard(
    NoiseStandardType.TYPE_3,
    '3类声环境功能区',
    65,
    55,
    '工业生产、仓储物流区域'
  ),
  new NoiseStandard(
    NoiseStandardType.TYPE_4A,
    '4a类声环境功能区',
    70,
    55,
    '高速公路、一级公路、二级公路、城市快速路等交通干线两侧区域'
  ),
  new NoiseStandard(
    NoiseStandardType.TYPE_4B,
    '4b类声环境功能区',
    70,
    60,
    '铁路干线两侧区域'
  )
];