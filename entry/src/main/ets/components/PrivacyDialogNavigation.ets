import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { noiseMeterNavStack } from '../../../noise_meter/ets/constant/ProviderConstant';
import { PromptAction } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

@ComponentV2
export struct PrivacyDialog {
  @Local countdown: number = 3;
  @Local agreeText:string = '同意并继续';
  private countdownTimer: number | null = null;
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private agreeCallback: () => void = async () => {
    // 同意隐私协议
    await this.preferenceService.setBoolean(PreferenceKeyConstants.PRIVACY_AGREED, true);
    this.navStack.pop();
  };
  private disagreeCallback: () => void = () => {
    // 拒绝隐私协议
    this.promptAction.showToast({ message: $r('app.string.privacy_disagree_message') });
    setTimeout(() => {
      // 退出应用
      getContext(this).getApplicationContext().killAllProcesses();
    }, 1000);
  };

  aboutToAppear(): void {
    this.startCountdown();
  }

  aboutToDisappear(): void {
    this.clearCountdown();
    if (!this.preferenceService.getBoolean(PreferenceKeyConstants.PRIVACY_AGREED, false)) {
      this.disagreeCallback();
    }
  }

  private startCountdown(): void {
    this.countdownTimer = setInterval(() => {
      if (this.countdown > 0) {
        this.countdown--;
      } else {
        this.clearCountdown();
      }
    }, 1000);
  }

  private clearCountdown(): void {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = null;
    }
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
          Web({
            src: 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1603946590609908800',
            controller: new webview.WebviewController()
          })
            .width('100%')
            .height('100%')
        }
        .height('80%')
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
          ;
          Button(this.countdown > 0 ? `${this.agreeText}(${this.countdown}s)` : $r('app.string.agree'),
            { type: ButtonType.Capsule })
            .width('40%')
            .height(40)
            .margin({ left: 16 })
            .enabled(this.countdown === 0)
            .onClick(async () => {
              if (this.countdown === 0) {
                await this.agreeCallback();
              }
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