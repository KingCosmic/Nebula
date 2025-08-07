package nebula.util;

interface FpsSamplerOptions {
  /**
   * Specify the sampling period in milliseconds (default 100)
   */
  var samplePeriod: Null<Int>;
  /**
   * Specify the initial FPS
   */
  var initialFps: Int;

  /**
   * Specify the function used to return the current time (in milliseconds)
   */
  function nowFn(): Int;
}

class FpsSampler {
  private var _fps: Float;
  private var _samplePeriod: Int = 100;
  private var _currentFrameTime: Int = 0;
  private var _frames: Int = 0;
  private var _previousSampleTime: Int = 0;
  private var _beginFrameTime: Int = 0;
  private var _nowFn: () -> Int;

  public function new(options: FpsSamplerOptions) {
    this._fps = options.initialFps;
    this._samplePeriod = options.samplePeriod ?? this._samplePeriod;
    this._currentFrameTime = 1000 / options.initialFps;
    this._nowFn = options.nowFn;
    this._previousSampleTime = this._nowFn();
  }

  /**
   * Start of code block to sample FPS for
   */
  function start() {
    this._beginFrameTime = this._nowFn();
  }

  /**
   * End of code block to sample FPS for
   */
  function end() {
    this._frames++;
    final time = this._nowFn();

    this._currentFrameTime = time - this._beginFrameTime;

    if (time >= this._previousSampleTime + this._samplePeriod) {
      this._fps = (this._frames * 1000) / (time - this._previousSampleTime);
      this._previousSampleTime = time;
      this._frames = 0;
    }
  }

  /**
   * Return the currently sampled fps over the last sample period, by default every 100ms
   */
  public var fps(get, never): Float;
  function get_fps() {
    return this._fps;
  }

  /**
   * Return the instantaneous fps, this can be less useful because it will fluctuate given the current frames time
   */
  public var instant(get, never): Float;
  function get_instant() {
    return 1000 / this._currentFrameTime;
  }
}
