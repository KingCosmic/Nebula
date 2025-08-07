package nebula.util;

import nebula.util.Log;
import nebula.util.Fps;

enum ScheduleCallbackTiming {
  PreFrame;
  PostFrame;
  PreUpdate;
  PostUpdate;
  PreDraw;
  PostDraw;
}

interface ClockOptions {
  /**
   * Define the function you'd like the clock to tick when it is started
   */
  function tick(elapsed: Int): Any;
  /**
   * Optionally define the fatal exception handler, used if an error is thrown in tick
   */
  var onFatalException: Null<(e: Any) -> Any>;
  /**
   * Optionally limit the maximum FPS of the clock
   */
  var maxFps: Null<Int>;
}

/**
 * Abstract Clock is the base type of all Clocks
 *
 * It has a few opinions
 * 1. It manages the calculation of what "elapsed" time means and thus maximum fps
 * 2. The default timing api is implemented in now()
 *
 * To implement your own clock, extend Clock and override start/stop to start and stop the clock, then call update() with whatever
 * method is unique to your clock implementation.
 */
abstract class Clock {
  private var tick: (elapsed: Int) -> Any;
  private var _onFatalException: (e: Any) -> Any = () -> {
    /* default nothing */
  };
  private var _maxFps: Int = Infinity;
  private var _lastTime: Int = 0;
  public var fpsSampler: FpsSampler;
  private var _options: ClockOptions;
  private var _elapsed: Int = 1;
  private var _scheduledCbs: Array<{ id: Int, cb: (elapsed: Int) -> Any, scheduledTime: Int, timing: ScheduledCallbackTiming}> = [];
  private var _totalElapsed: Int = 0;
  private var _nextScheduleId: ScheduleId = 0;
  public function new(options: ClockOptions) {
    this._options = options;
    this.tick = options.tick;
    this._lastTime = this.now() ?? 0;
    this._maxFps = options.maxFps ?? this._maxFps;
    this._onFatalException = options.onFatalException ?? this._onFatalException;
    this.fpsSampler = new FpsSampler({
      initialFps: 60,
      nowFn: () -> this.now()
    });
  }

  /**
   * Get the elapsed time for the last completed frame
   */
  public function elapsed(): Int {
    return this._elapsed;
  }

  /**
   * Get the current time in milliseconds
   */
  public function now(): Int {
    return performance.now();
  }

  public function toTestClock() {
    var clockOptions = Object.spreadWith(this._options, { defaultUpdateMs: 16.6 });
    final testClock = new TestClock(clockOptions);
    return testClock;
  }

  public function toStandardClock() {
    var clockOptions = Object.spreadWith(this._options, {});
    final clock = new StandardClock(clockOptions);
    return clock;
  }

  public function setFatalExceptionHandler(handler: (e: Any) -> Any) {
    this._onFatalException = handler;
  }
  /**
   * Schedule a callback to fire given a timeout in milliseconds using the excalibur {@apilink Clock}
   *
   * This is useful to use over the built in browser `setTimeout` because callbacks will be tied to the
   * excalibur update clock, instead of browser time, this means that callbacks wont fire if the game is
   * stopped or paused.
   * @param cb callback to fire
   * @param timeoutMs Optionally specify a timeout in milliseconds from now, default is 0ms which means the next possible tick
   * @param timing Optionally specify a timeout in milliseconds from now, default is 0ms which means the next possible tick
   * @returns A unique identifier that can be used to clear the scheduled callback with {@apilink clearSchedule}
   */
  public function schedule(cb: (elapsed: Int) -> Any, timeoutMs: Int = 0, timing: ScheduledCallbackTiming = 'preframe'): Int {
    // Scheduled based on internal elapsed time
    final scheduledTime = this._totalElapsed + timeoutMs;
    final id = this._nextScheduleId++;
    this._scheduledCbs.push([id, cb, scheduledTime, timing]);
    return id;
  }

  /**
   * Clears a scheduled callback using the ID returned from {@apilink schedule}
   * @param id The ID of the scheduled callback to clear
   */
  public function clearSchedule(id: Int): Void {
    final index = this._scheduledCbs.findIndex((cb) -> cb.scheduleId == id);
    if (index != -1) {
      this._scheduledCbs.splice(index, 1);
    }
  }
  /**
   * Called internally to trigger scheduled callbacks in the clock
   * @param timing
   * @internal
   */
  public function __runScheduledCbs(timing: ScheduledCallbackTiming = 'preframe') {
    // walk backwards to delete items as we loop
    var index = this._scheduledCbs.length;
    while (index > 0) {
      index--;

      final cb = this._scheduledCbs[index];
      final callback = cb.callback,
            scheduledTime = cb.scheduledTime,
            callbackTiming = cb.callbackTiming;

      if (timing == callbackTiming && scheduledTime <= this._totalElapsed) {
        callback(this._elapsed);
        this._scheduledCbs.splice(i, 1);
      }
    }
  }

  private function update(?overrideUpdateMs: Int): Void {
    try {
      this.fpsSampler.start();
      // Get the time to calculate time-elapsed
      final now = this.now();
      var elapsed = now - this._lastTime || 1; // first frame

      // Constrain fps
      final fpsInterval = 1000 / this._maxFps;

      // only run frame if enough time has elapsed
      if (elapsed >= fpsInterval) {
        var leftover = 0;
        if (fpsInterval != 0) {
          leftover = elapsed % fpsInterval;
          elapsed = elapsed - leftover; // shift elapsed to be "in phase" with the current loop fps
        }

        // Resolves issue #138 if the game has been paused, or blurred for
        // more than a 200 milliseconds, reset elapsed time to 1. This improves reliability
        // and provides more expected behavior when the engine comes back
        // into focus
        if (elapsed > 200) {
          elapsed = 1;
        }

        // tick the mainloop and run scheduled callbacks
        this._elapsed = overrideUpdateMs || elapsed;
        this._totalElapsed += this._elapsed;
        this.__runScheduledCbs('preframe');
        this.tick(overrideUpdateMs || elapsed);
        this.__runScheduledCbs('postframe');

        if (fpsInterval != 0) {
          this._lastTime = now - leftover;
        } else {
          this._lastTime = now;
        }
        this.fpsSampler.end();
      }
    } catch (e) {
      this._onFatalException(e);
      this.stop();
    }
  }

  /**
   * Returns if the clock is currently running
   */
  public abstract function isRunning(): Bool;

  /**
   * Start the clock, it will then periodically call the tick(elapsedMilliseconds) since the last tick
   */
  public abstract function start(): Void;

  /**
   * Stop the clock, tick() is no longer called
   */
  public abstract function stop(): Void;
}

/**
 * The {@apilink StandardClock} implements the requestAnimationFrame browser api to run the tick()
 */
class StandardClock extends Clock {
  private var _running = false;
  private var _requestId: Int;
  public function new(options: ClockOptions) {
    super(options);
  }

  public function isRunning(): Bool {
    return this._running;
  }

  public function start(): Void {
    if (this._running) {
      return;
    }
    this._running = true;
    final mainloop = () -> {
      // stop the loop
      if (!this._running) {
        return;
      }
      try {
        // request next loop
        this._requestId = window.requestAnimationFrame(mainloop);
        this.update();
      } catch (e) {
        window.cancelAnimationFrame(this._requestId);
        throw e;
      }
    };

    // begin the first frame
    mainloop();
  }

  public function stop(): Void {
    window.cancelAnimationFrame(this._requestId);
    this._running = false;
  }
}

interface TestClockOptions {
  /**
   * Specify the update milliseconds to use for each manual step()
   */
  var defaultUpdateMs: Int;
}

/**
 * The TestClock is meant for debugging interactions in excalibur that require precise timing to replicate or test
 */
class TestClock extends Clock {
  private var _logger = Logger.getInstance();
  private var _updateMs: Int;
  private var _running: Bool = false;
  private var _currentTime = 0;
  public function new(options: ClockOptions & TestClockOptions) {
    super(options);
    this._updateMs = options.defaultUpdateMs;
  }

  /**
   * Get the current time in milliseconds
   */
  public override function now() {
    return this._currentTime ?? 0;
  }

  public function isRunning(): Bool {
    return this._running;
  }
  public function start(): Void {
    this._running = true;
  }
  public function stop(): Void {
    this._running = false;
  }

  /**
   * Manually step the clock forward 1 tick, optionally specify an elapsed time in milliseconds
   * @param overrideUpdateMs
   */
  function step(?overrideUpdateMs: Int): Void {
    final time = overrideUpdateMs ?? this._updateMs;

    if (this._running) {
      // to be comparable to RAF this needs to be a full blown Task
      // For example, images cannot decode synchronously in a single step
      this.update(time);
      this._currentTime += time;
    } else {
      this._logger.warn('The clock is not running, no step will be performed');
    }
  }

  /**
   * Run a number of steps that tick the clock, optionally specify an elapsed time in milliseconds
   * @param numberOfSteps
   * @param overrideUpdateMs
   */
  function run(numberOfSteps: Int, ?overrideUpdateMs: Int): Void {
    for (i in 0...numberOfSteps) {
      this.step(overrideUpdateMs ?? this._updateMs);
    }
  }
}
