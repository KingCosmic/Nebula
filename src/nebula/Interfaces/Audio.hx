package nebula.Interfaces;

/**
 * Represents an audio control implementation
 */
interface Audio {
  /**
   * Whether the audio should loop (repeat forever)
   */
  var loop: Bool;
  /**
   * The volume (between 0 and 1)
   */
  var volume: Float;

  /**
   * Set the playbackRate, default is 1.0 at normal speed.
   * For example 2.0 is double speed, and 0.5 is half speed.
   */
  var playbackRate: Float;

  /**
   * Whether or not any audio is playing
   */
  function isPlaying(): Bool;

  /**
   * Returns if the audio is paused
   */
  function isPaused(): Bool;

  /**
   * Returns if the audio is stopped
   */
  function isStopped(): Bool;

  /**
   * Will play the sound or resume if paused
   */
  function play(): Promise<Any>;

  /**
   * Seek to a position (in seconds) in the audio
   * @param position
   */
  function seek(position: Int): Void;

  /**
   * Return the duration of the sound
   */
  function getTotalPlaybackDuration(): Float;

  /**
   * Return the current playback time of the playing track in seconds from the start
   */
  function getPlaybackPosition(): Float;

  /**
   * Pause the sound
   */
  function pause(): Void;

  /**
   * Stop playing the sound and reset
   */
  function stop(): Void;
}
