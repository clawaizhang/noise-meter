import { ImageSoundPlayerState } from "../components/decibel-meter/PressureSounds";

export class ImageSoundPlayingService {
  private static instance = new ImageSoundPlayingService();
  public imageSoundPlayingList: Array<ImageSoundPlayerState> = [] as Array<ImageSoundPlayerState>;

  static getInstance() {
    return ImageSoundPlayingService.instance;
  }
}