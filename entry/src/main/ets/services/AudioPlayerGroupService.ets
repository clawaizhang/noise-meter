import { AudioPlayerService, endState, PlayerState } from "./AudioPlayerService";

export class AudioPlayerGroupService {
  private static players: Map<string, AudioPlayerService> = new Map();

  private constructor() {
  }

  static isPlaying(){
    let isPlaying = false;
    for (let valuesElement of AudioPlayerGroupService.players.values()) {
      if (valuesElement.isPlaying()) {
        isPlaying = true;
      }
    }
    return isPlaying;
  }

  static getPlayerInstance(id: string): AudioPlayerService {
    if (AudioPlayerGroupService.players.has(id)) {
      return AudioPlayerGroupService.players.get(id) as AudioPlayerService;
    } else {
      let newPlayer = new AudioPlayerService(id);
      newPlayer.addOnStateChangeListener((state: PlayerState) => {
        if (endState.includes(state)) {
          AudioPlayerGroupService.players.delete(newPlayer.id);
        }
      })
      AudioPlayerGroupService.players.set(id, newPlayer);
      return newPlayer;
    }
  }
}