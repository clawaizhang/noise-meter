import { DialogContainer } from '../../../library/ets/components/common/DialogContainer';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { noiseMeterNavStack } from '../../../noise_meter/ets/constant/ProviderConstant';
import { PromptAction } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';

@ComponentV2
export struct PrivacyDialog {
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private agreeCallback: () => void = () => {
    // 同意隐私协议
    this.preferenceService.setBoolean(PreferenceKeyConstants.PRIVACY_AGREED, true);
    let want: Want = {
      bundleName: 'yu.zhang.myapplication.noisemeter',
      abilityName: 'EntryAbility'
    }
    getContext(this).getApplicationContext().restartApp(want)
  };
  private disagreeCallback: () => void = () => {
    // 拒绝隐私协议
    this.promptAction.showToast({ message: $r('app.string.privacy_disagree_message') });
    setTimeout(() => {
      // 退出应用
      getContext(this).getApplicationContext().killAllProcesses();
    }, 1000);
  };

  aboutToDisappear(): void {
    this.disagreeCallback()
  }

  build() {
    NavDestination() {
      Column() {
        // 标题
        Text($r('app.string.privacy_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 16 })

        // 内容区域
        Scroll() {
          Text($r('app.string.privacy_content'))
            .fontSize(14)
            .textAlign(TextAlign.Start)
            .fontColor('#666666')
        }
        .height('60%')
        .width('100%')
        .margin({ bottom: 24 })

        // 按钮区域
        Row() {
          Button($r('app.string.disagree'), { type: ButtonType.Normal })
            .width('40%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .fontColor('#333333')
            .onClick(() => {
              this.disagreeCallback();
            })

          Button($r('app.string.agree'), { type: ButtonType.Capsule })
            .width('40%')
            .height(40)
            .margin({ left: 16 })
            .onClick(() => {
              this.agreeCallback();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .padding(24)
    }
    .backgroundColor('rgba(0,0,0,0.5)')
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
  }

}

// 对话框构建器
@Builder
export function PrivacyDialogBuilder() {
  PrivacyDialog()
}