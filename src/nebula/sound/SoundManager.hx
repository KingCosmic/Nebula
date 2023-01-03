package nebula.sound;

import kha.Sound as KhaSound;

/*
 * Our games SoundManager it holds loaded sounds aswell as sounds currently playing.
 */
class SoundManager {
  /*
	 * our EventEmitter.
   */
	static public var events:EventEmitter = new EventEmitter();

  /*
   * An map of all loaded sounds for this game.
   */
	static public var audio:Map<String, KhaSound> = new Map();

  /*
   * Array of all currently "active" sounds.
   */
  static public var sounds:Array<Sound> = [];

  /*
   * Global mute setting.
   */
  static public var mute:Bool = false;

  /*
   * Global volume setting.
   */
  static public var volume:Float = 1;

  /*
   * Flag indicating if sounds should be paused when game looses focus,
   * for instance when user switches to another tab/program/app.
   */
  static public var pauseOnBlur:Bool = true;

  /*
   * Property that actually holds the value of global playback rate.
   */
  static private var _rate:Float = 1;

	/*
	 * Global playback rate at which all the sounds will be played.
	 * Value of 1.0 plays the audio at full speed, 0.5 plays the audio at half speed
	 * and 2.0 doubles the audio's playback speed.
	 */
	static public var rate(get, set):Float;

	static function get_rate() {
    return _rate;
  }

	static function set_rate(value:Float) {
    // update our rate.
    _rate = value;
    
    // loop through our active sounds and update their rate.
    forEachActiveSound((sound:Sound, index:Int) -> sound.calculateRate());

    // emit an event stating the rate was changed.
    events.emit('GLOBAL_RATE', value);

    return _rate;
  }

  /**
   * Property that actually holds the value of global detune.
   */
  static private var _detune:Float = 0;

	/**
	 * Global detuning of all sounds in [cents](https://en.wikipedia.org/wiki/Cent_%28music%29).
	 * The range of the value is -1200 to 1200, but we recommend setting it to [50](https://en.wikipedia.org/wiki/50_Cent).
	 */
	static public var detune(get, set):Float;

	static function get_detune() {
    return _detune;
  }

	static function set_detune(value:Float) {
		// update our detune.
    _detune = value;

		// loop through our active sounds and update their rate.
		forEachActiveSound((sound:Sound, index:Int) -> sound.calculateRate());

		// emit an event stating the detune was changed.
    events.emit('GLOBAL_DETUNE', value);

    return _detune;
  }

	/**
	 * Adds a new sound into the sound manager.
	 */
	static public function add(key:String, loadedSound:KhaSound) {
    audio.set(key, loadedSound);
  }

	/**
	 * Gets the first sound in the manager matching the given key, if any.
	 */
  static public function get(key:String) {
		// return GetFirst(this.sounds, 'key', key);
  }

	/**
	 * Gets any sounds in the manager matching the given key.
	 */
	static function getAll(key:String) {
		return sounds.filter(sound -> sound.key == key);
	}

	/**
	 * Adds a new sound to the sound manager and plays it.
	 * The sound will be automatically removed (destroyed) once playback ends.
	 * This lets you play a new sound on the fly without the need to keep a reference to it.
	 */
  static public function play(key:String, ?loop:Bool):Null<Sound> {
    if (!audio.exists(key)) return null;

    var sound = new Sound(key, loop);

		sound.once('COMPLETE', sound.destroy, sound);

    return sound;
	}

	/**
	 * Removes a sound from the sound manager.
	 * The removed sound is destroyed before removal.
	 */
	static public function remove(sound:Sound) {
		var index = sounds.indexOf(sound);

    // if we dont have this sound just return.
    if (index == -1) return false;

    // destroy the sound.
    sound.destroy();
    
    // remove it from our array.
    sounds.splice(index, 1);

    // let them know it was removed.
    return true;
	}

	/**
	 * Removes all sounds from the manager, destroying the sounds.
	 */
	static public function removeAll() {
    // destroy all our sounds.
    for (i in 0...sounds.length) {
			sounds[i].destroy();
    }

    // reset our array.
    sounds = [];
	}

	/**
	 * Removes all sounds from the sound manager that have an asset key matching the given value.
	 * The removed sounds are destroyed before removal.
	 */
	static public function removeByKey(key:String) {
    // how many have we removed?
		var removed = 0;

    // loop backwards through our sounds.
    for (i in new ReverseIterator(sounds.length - 1, 0)) {
      // grab sound.
			var sound = sounds[i];

      // if the key's don't match just continue.
      if (sound.key != key) continue;

      // destroy the sound.
      sound.destroy();

      // remove it from our array.
      sounds.splice(i, 1);

      // update our removed var.
      removed++;
		}

    // return the amount removed.
		return removed;
	}

	/**
	 * Pauses all the sounds in the game.
	 */
	static public function pauseAll() {
    // loop through our active sounds and pause them.
		forEachActiveSound((sound:Sound, index:Int) -> sound.pause());

    // emit our event.
		events.emit('PAUSE_ALL');
	}

	/**
	 * Resumes all the sounds in the game.
	 */
	static public function resumeAll() {
    // resume all active sounds.
		forEachActiveSound((sound:Sound, index:Int) -> sound.resume());

    // emit our event.
    events.emit('RESUME_ALL');
	}

	/**
	 * Stops all the sounds in the game.
	 */
	static public function stopAll() {
    // loop through our sounds and stop them.
		forEachActiveSound((sound:Sound, index:Int) -> sound.stop());

    // emit our event.
		events.emit('STOP_ALL');
	}

	/**
	 * Stops any sounds matching the given key.
	 */
	static public function stopByKey(key:String) {
		var stopped = 0;

    for (i in 0...getAll(key).length) {
      if (sounds[i].stop()) {
        stopped++;
      }
    }

		return stopped;
	}

	/**
	 * Method used internally for iterating only over active sounds
   * and skipping sounds that are marked for removal.
	 */
	static public function forEachActiveSound(callback:Sound->Int->Void) {
    for (i in 0...sounds.length) {
      callback(sounds[i], i);
    }
	}

	/**
	 * Sets the global playback rate at which all the sounds will be played.
	 *
	 * For example, a value of 1.0 plays the audio at full speed, 0.5 plays the audio at half speed
	 * and 2.0 doubles the audios playback speed.
	 */
	static public function setRate(value:Float) {
		rate = value;
	}

	/**
	 * Sets the global detuning of all sounds in [cents](https://en.wikipedia.org/wiki/Cent_%28music%29).
	 * The range of the value is -1200 to 1200, but we recommend setting it to [50](https://en.wikipedia.org/wiki/50_Cent).
	 */
	static public function setDetune(value:Float) {
		detune = value;
	}
}