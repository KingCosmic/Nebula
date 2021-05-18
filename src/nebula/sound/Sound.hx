package nebula.sound;

import kha.audio1.AudioChannel;
import kha.audio1.Audio;

class Sound extends EventEmitter {
  /**
   * Asset key for the sound.
   */
  public var key:String = '';

  /**
   * the current channel this Sound is referencing.
   */
  public var channel:AudioChannel;

  /**
   * Flag indicating if this sound is currently paused.
   */
  public var paused:Bool = false;

  /**
   * Flag indicating if this sound is looping.
   */
  public var loop:Bool = false;

  /**
   * A property that holds the value of the sounds actualy playback rate,
   * after its rate and detune values has been combined with global rate and detune values.
   */
  public var totalRate:Float = 1;

  /**
   * A value representing the duration, in seconds.
   */
  public var duration:Float = 0;

  public function new(_key:String, ?_loop:Bool = false) {
    super();

    key = _key;
    loop = _loop;
    
    // start our audio and set our channel.
    channel = Audio.play(SoundManager.audio.get(key), loop);
  }

  /**
   * pause our sound.
   */
  public function pause() {
    // if we're already paused just return.
    if (paused) return;

    // pause our sound.
    channel.pause();

    // update our flag.
    paused = true;
  }

  public function resume() {
		// if we're already playing just return.
		if (!paused) return;

		// resume our sound.
		channel.play();

		// update our flag.
		paused = false;
  }

  public function stop() {
    if (!paused) return false;

    paused = true;

    return true;
  }

  public function calculateRate() {
    // TODO:
  }

  /**
   * null all our references so we can be gc'd
   */
  public function destroy() {
    key = null;
    channel = null;
  }
}