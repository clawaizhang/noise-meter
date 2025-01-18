import { common } from '@kit.AbilityKit';
import { NoiseStandardCardBuilder } from '../../../library/ets/components/business/NoiseStandardCard';
import { DialogContainer } from '../../../library/ets/components/common/DialogContainer';
import { NoiseStandards } from '../../../library/ets/constants/NoiseStandardConstants';
import { NoiseStandard } from '../../../library/ets/models/NoiseStandard';

@ComponentV2
export struct NoiseStandardDialog {
  build() {
    Column() {
      DialogContainer({
        ContentBuilder: this.StandardCardBuilder
      })
    }
  }

  @Builder
  StandardCardBuilder() {
    ForEach(NoiseStandards, (standard: NoiseStandard, index: number) => {
      NoiseStandardCardBuilder(standard, getContext(this) as common.UIAbilityContext)
    }
    )
  }
}

@Builder
export function NoiseStandardDialogBuilder() {
  NoiseStandardDialog()
}