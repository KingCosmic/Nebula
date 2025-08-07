package nebula.util;

import nebula.resources.sound.AudioContext;
import nebula.util.Log;

interface LegacyWebAudioSource {
  var playbackState: String;
  var PLAYING_STATE: AudioStates;
  var FINISHED_STATE: AudioStates;
}

enum AudioStates {
  Playing;
  Finished;
}

/**
 * Patch for detecting legacy web audio in browsers
 * @internal
 * @param source
 */
function isLegacyWebAudioSource(source: Any) {
  return !!source.playbackState;
}

class WebAudio {
  private static var _UNLOCKED: Bool = false;

  /**
   * Play an empty sound to unlock Safari WebAudio context. Call this function
   * right after a user interaction event.
   * @source https://paulbakaus.com/tutorials/html5/web-audio-on-ios/
   */
  static function unlock(): Promise<Bool> {
    final promise = new Promise<Bool>((resolve, reject) -> {
      if (WebAudio._UNLOCKED || !AudioContextFactory.create()) {
        return resolve(true);
      }
      final unlockTimeoutTimer = setTimeout(() -> {
        Logger.getInstance().warn('Excalibur was unable to unlock the audio context, audio probably will not play in this browser.');
        resolve(false);
      }, 200);

      final audioContext = AudioContextFactory.create();
      audioContext.resume().then(
        () -> {
          // create empty buffer and play it
          final buffer = audioContext.createBuffer(1, 1, 22050);
          final source = audioContext.createBufferSource();
          var ended = false;

          source.buffer = buffer;
          source.connect(audioContext.destination);
          source.onended = () -> (ended = true);

          source.start(0);

          // by checking the play state after some time, we know if we're really unlocked
          setTimeout(() -> {
            if (isLegacyWebAudioSource(source)) {
              if (source.playbackState == source.PLAYING_STATE || source.playbackState == source.FINISHED_STATE) {
                WebAudio._UNLOCKED = true;
              }
            } else {
              if (audioContext.currentTime > 0 || ended) {
                WebAudio._UNLOCKED = true;
              }
            }
          }, 0);

          clearTimeout(unlockTimeoutTimer);
          resolve(true);
        },
        () -> {
          reject();
        }
      );
    });

    return promise;
  }

  static function isUnlocked() {
    return this._UNLOCKED;
  }
}
