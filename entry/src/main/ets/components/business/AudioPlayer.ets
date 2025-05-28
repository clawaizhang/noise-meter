import { PlayerState } from "../../services/AudioPlayerService"
import { AudioPlayerService } from "../../services/AudioPlayerService"
import hilog from '@ohos.hilog'
import { FileService } from "../../services/FileService";

const TAG = 'AudioPlayer';
const DOMAIN = 0x0000;

@ComponentV2
export struct AudioPlayer {
  @Param audioFilePath: string | null = null;
  @Local playerState: PlayerState = PlayerState.STATE_NOT_INIT;
  private context: Context = getContext(this)
  private fileService: FileService = new FileService(this.context)
  private audioPlayerService: AudioPlayerService = new AudioPlayerService(this.context, this.fileService);

  build() {
    Row() {
      if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
        Button() {
          Image($r('app.media.ic_stop'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.icon_inactive'))
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .margin({ right: 8 })
        .onClick(async () => {
          try {
            await this.audioPlayerService.stop();
          } catch (error) {
            hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s',
              error instanceof Error ? error.message : String(error));
          }
        })
      }

      Button() {
        Row() {
          Image(this.playerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') :
          $r('app.media.ic_play'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.icon_inactive'))
            .margin({ right: 8 })
          Text(this.playerState === PlayerState.STATE_PLAYING ? '暂停播放' :
            this.playerState === PlayerState.STATE_PAUSED ? '继续播放' : '播放录音')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.background_secondary'))
      .height(36)
      .padding({ left: 16, right: 16 })
      .onClick(async () => {
        try {
          if (this.playerState === PlayerState.STATE_PLAYING) {
            await this.audioPlayerService.pause();
          } else {
            if (this.playerState === PlayerState.STATE_PAUSED) {
              await this.audioPlayerService.resume();
            } else {
              if (this.audioFilePath) {
                await this.audioPlayerService.playAudioFile(this.audioFilePath);
              }
            }
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s',
            error instanceof Error ? error.message : String(error));
        }
      })
    }
  }

  aboutToAppear() {
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.setOnStateChangeListener((state: PlayerState) => {
      this.playerState = state;
    });
  }

  aboutToDisappear(): void {
    if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
      this.audioPlayerService.stop();
    }
  }
}