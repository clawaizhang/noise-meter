import { AudioPlayerService } from '../../services/AudioPlayerService';
import hilog from '@ohos.hilog';
import resourceManager from '@ohos.resourceManager';
import { AudioPlayerGroupService } from '../../services/AudioPlayerGroupService';
import media from '@ohos.multimedia.media';
import { Debounce } from '../../utils/Debounce';

const TAG = 'AudioPlayer';
const DOMAIN = 0x0000;

@ComponentV2
export struct AudioPlayer {
  @Param @Require audioFilePath: string;
  @Param fileDescriptor: resourceManager.RawFileDescriptor | undefined = undefined;
  @Local playerState: media.AVPlayerState = 'idle';
  private audioPlayerService: AudioPlayerService = AudioPlayerGroupService.getPlayerInstance(this.audioFilePath);

  build() {
    Row() {
      if (this.playerState === 'playing' || this.playerState === 'paused') {
        Button() {
          Image($r('app.media.ic_stop'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.font_primary'))
        }
        .type(ButtonType.Normal)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .margin({ right: 8 })
        .onClick(async () => {
          Debounce.click(async () => {
            try {
              await this.audioPlayerService.stop();
            } catch (error) {
              hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s',
                error instanceof Error ? error.message : String(error));
            }
          })
        })
      }

      Button() {
        Row() {
          Image(this.playerState === 'playing' ? $r('app.media.ic_pause') :
            $r('app.media.ic_play'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.font_primary'))
            .margin({ right: 8 })
          Text(this.playerState === 'playing' ? '暂停播放' :
            this.playerState === 'paused' ? '继续播放' : '播放录音')
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .height(36)
      .padding({ left: 16, right: 16 })
      .onClick(async () => {
        Debounce.click(async () => {
          try {
            if (this.playerState === 'playing') {
              await this.audioPlayerService.pause();
            } else {
              if (this.playerState === 'paused') {
                await this.audioPlayerService.resume();
              } else {
                if (this.audioFilePath) {
                  await this.audioPlayerService.playAudioFile(this.audioFilePath);
                }
                if (this.fileDescriptor) {
                  await this.audioPlayerService.playAudioFileByFd(this.fileDescriptor);
                }
              }
            }
          } catch (error) {
            hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s',
              error instanceof Error ? error.message : String(error));
          }
        })
      })
    }
  }

  aboutToAppear() {
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.addOnStateChangeListener((state: media.AVPlayerState) => {
      this.playerState = state;
    });
  }

  aboutToDisappear(): void {
    if (this.playerState === 'playing' || this.playerState === 'paused') {
      this.audioPlayerService.stop();
    }
  }
}