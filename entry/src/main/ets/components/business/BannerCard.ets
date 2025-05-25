import { advertising, AutoAdComponent } from '@kit.AdsKit';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';

const TAG = '[BannerCard]';
const DOMAIN = 0x0000;

@ComponentV2
export struct BannerCard {
  @Param context: common.Context = getContext(this) as common.Context;
  @Param adId: string = '';
  @Param @Require onItemClick?: () => void;

  async checkAndRequestPermissions(): Promise<void> {
    try {
      const permissions: Array<Permissions> = [
        'ohos.permission.INTERNET' as Permissions,
        'ohos.permission.GET_BUNDLE_INFO' as Permissions,
        'ohos.permission.GET_NETWORK_INFO' as Permissions
      ];

      const atManager = abilityAccessCtrl.createAtManager();
      for (const permission of permissions) {
        try {
          const result = await atManager.checkAccessToken(this.context.applicationInfo.accessTokenId, permission);
          hilog.info(DOMAIN, TAG, `Permission ${permission} check result: ${result}`);

          if (result === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
            const requestResult = await atManager.requestPermissionsFromUser(this.context, [permission]);
            hilog.info(DOMAIN, TAG, `Permission ${permission} request result: ${JSON.stringify(requestResult)}`);
          }
        } catch (err) {
          hilog.error(DOMAIN, TAG, `Failed to handle permission ${permission}: ${JSON.stringify(err)}`);
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error checking permissions: ${JSON.stringify(err)}`);
    }
  }

  async aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'aboutToAppear start');
    hilog.info(DOMAIN, TAG, `adId: ${this.adId}`);
    await this.checkAndRequestPermissions();
  }

  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'aboutToDisappear');
  }

  build() {
    Row() {
      AutoAdComponent({
        adParam: {
          adId: this.adId,
          adType: 3,
          adWidth: 360,
          adHeight: 57
        },
        adOptions: {
          tagForChildProtection: 0,
          adContentClassification: 'W',
          nonPersonalizedAd: 0
        },
        displayOptions: {
          displayWidth: '360vp',
          displayHeight: '57vp',
          displayRadius: '24vp',
          backgroundColor: '#FFFFFF'
        },
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            switch (status) {
              case 'loaded':
                hilog.info(DOMAIN, TAG, 'Ad loaded successfully');
                break;
              case 'showed':
                hilog.info(DOMAIN, TAG, 'Ad showed');
                break;
              case 'clicked':
                hilog.info(DOMAIN, TAG, 'Ad clicked');
                if (this.onItemClick) {
                  this.onItemClick();
                }
                break;
              case 'closed':
                hilog.info(DOMAIN, TAG, 'Ad closed');
                break;
              case 'error':
                hilog.error(DOMAIN, TAG, `Ad error: ${data}`);
                hilog.error(DOMAIN, TAG, `adId: ${this.adId}`);
                hilog.error(DOMAIN, TAG, `error data: ${JSON.stringify(data)}`);
                hilog.error(DOMAIN, TAG, `error stack: ${new Error().stack}`);
                break;
            }
          }
        }
      })
        .height(57)
    }
    .width('100%')
    .height(57)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
  }
} 