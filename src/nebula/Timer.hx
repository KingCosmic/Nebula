package nebula;

import nebula.Scene;
import nebula.Util.Log;
import nebula.Math.Random;

interface TimerOptions {
  /**
   * If true the timer repeats every interval infinitely
   */
  var repeats: Null<Bool>;
  /**
   * If a number is specified then it will only repeat a number of times
   */
  var numberOfRepeats: Null<Int>;
  /**
   * @deprecated use action: () => void, will be removed in v1.0
   */
  var fcn: Null<() -> Void>;
  /**
   * Action to perform every time the timer fires
   */
  var action: Null<() -> Void>;
  /**
   * Interval in milliseconds for the timer to fire
   */
  var interval: Int;
  /**
   * Optionally specify a random range of milliseconds for the timer to fire
   */
  var randomRange: Null<Array<Int>>;
  /**
   * Optionally provide a random instance to use for random behavior, otherwise a new random will be created seeded from the current time.
   */
  var random: Null<ex.Random>;
}

/**
 * The Excalibur timer hooks into the internal timer and fires callbacks,
 * after a certain interval, optionally repeating.
 */
class Timer {
  private var _logger = Logger.getInstance();
  private static var _MAX_ID: Int = 0;
  public var id: Int = 0;

  private var _elapsedTime: Float = 0;
  private var _totalTimeAlive: Float = 0;

  private var _running = false;

  private var _numberOfTicks: Int = 0;
  private var _callbacks: Array<() -> Void>;

  public var interval: Int = 10;
  public var repeats: Bool = false;
  public var maxNumberOfRepeats: Int = -1;
  public var randomRange: Array<Int> = [0, 0];
  public var random: Random;
  private var _baseInterval = 10;
  private var _generateRandomInterval = () -> {
    return this._baseInterval + this.random.integer(this.randomRange[0], this.randomRange[1]);
  };

  private var _complete = false;
  public var complete(get, never): Bool;
  function get_complete() {
    return this._complete;
  }

  public var scene: Null<Scene> = null;

  public function new(options: TimerOptions) {
    final fcn = options.action ?? options.fcn;
    final interval = options.interval;
    final repeats = options.repeats;
    final numberOfRepeats = options.numberOfRepeats;
    final randomRange = options.randomRange;
    final random = options.random;

    if (!!numberOfRepeats && numberOfRepeats >= 0) {
      this.maxNumberOfRepeats = numberOfRepeats;
      if (!repeats) {
        throw new Error('repeats must be set to true if numberOfRepeats is set');
      }
    }

    this.id = Timer._MAX_ID++;
    this._callbacks = [];
    this._baseInterval = this.interval = interval;
    if (!!randomRange) {
      if (randomRange[0] > randomRange[1]) {
        throw new Error('min value must be lower than max value for range');
      }
      //We use the instance of ex.Random to generate the range
      this.random = random ?? new Random();
      this.randomRange = randomRange;

      this.interval = this._generateRandomInterval();
      this.on(() -> {
        this.interval = this._generateRandomInterval();
      });
    }
    this.repeats = repeats || this.repeats;
    if (fcn) {
      this.on(fcn);
    }
  }

  /**
   * Adds a new callback to be fired after the interval is complete
   * @param action The callback to be added to the callback list, to be fired after the interval is complete.
   */
  public function on(action: () -> Void) {
    this._callbacks.push(action);
  }

  /**
   * Removes a callback from the callback list to be fired after the interval is complete.
   * @param action The callback to be removed from the callback list, to be fired after the interval is complete.
   */
  public function off(action: () -> Void) {
    final index = this._callbacks.indexOf(action);
    this._callbacks.splice(index, 1);
  }
  /**
   * Updates the timer after a certain number of milliseconds have elapsed. This is used internally by the engine.
   * @param elapsed  Number of elapsed milliseconds since the last update.
   */
  public function update(elapsed: Float) {
    if (this._running) {
      this._totalTimeAlive += elapsed;
      this._elapsedTime += elapsed;

      if (this.maxNumberOfRepeats > -1 && this._numberOfTicks >= this.maxNumberOfRepeats) {
        this._complete = true;
        this._running = false;
        this._elapsedTime = 0;
      }

      if (!this.complete && this._elapsedTime >= this.interval) {
        this._callbacks.forEach((c) => {
          c.call(this);
        });
        this._numberOfTicks++;
        if (this.repeats) {
          this._elapsedTime = 0;
        } else {
          this._complete = true;
          this._running = false;
          this._elapsedTime = 0;
        }
      }
    }
  }

  /**
   * Resets the timer so that it can be reused, and optionally reconfigure the timers interval.
   *
   * Warning** you may need to call `timer.start()` again if the timer had completed
   * @param newInterval If specified, sets a new non-negative interval in milliseconds to refire the callback
   * @param newNumberOfRepeats If specified, sets a new non-negative upper limit to the number of time this timer executes
   */
  public function reset(?newInterval: Int, ?newNumberOfRepeats: Int) {
    if (!!newInterval && newInterval >= 0) {
      this._baseInterval = this.interval = newInterval;
    }

    if (!!this.maxNumberOfRepeats && this.maxNumberOfRepeats >= 0) {
      this.maxNumberOfRepeats = newNumberOfRepeats;
      if (!this.repeats) {
        throw new Error('repeats must be set to true if numberOfRepeats is set');
      }
    }

    this._complete = false;
    this._elapsedTime = 0;
    this._numberOfTicks = 0;
  }

  public var timesRepeated(get, never): Int;
  function get_timesRepeated(): Int {
    return this._numberOfTicks;
  }

  public function getTimeRunning(): Int {
    return this._totalTimeAlive;
  }

  /**
   * @returns milliseconds until the next action callback, if complete will return 0
   */
  public var timeToNextAction(get, never): Int;
  function get_timeToNextAction() {
    if (this.complete) {
      return 0;
    }
    return this.interval - this._elapsedTime;
  }

  /**
   * @returns milliseconds elapsed toward the next action
   */
  public var timeElapsedTowardNextAction(get, never): Int;
  function get_timeElapsedTowardNextAction() {
    return this._elapsedTime;
  }

  public var isRunning(get, never): Bool;
  function get_isRunning() {
    return this._running;
  }

  /**
   * Pauses the timer, time will no longer increment towards the next call
   */
  public function pause(): Timer {
    this._running = false;
    return this;
  }

  /**
   * Resumes the timer, time will now increment towards the next call.
   */
  public function resume(): Timer {
    this._running = true;
    return this;
  }

  /**
   * Starts the timer, if the timer was complete it will restart the timer and reset the elapsed time counter
   */
  public function start(): Timer {
    if (!this.scene) {
      this._logger.warn('Cannot start a timer not part of a scene, timer wont start until added');
    }

    this._running = true;
    if (this.complete) {
      this._complete = false;
      this._elapsedTime = 0;
      this._numberOfTicks = 0;
    }

    return this;
  }

  /**
   * Stops the timer and resets the elapsed time counter towards the next action invocation
   */
  public function stop(): Timer {
    this._running = false;
    this._elapsedTime = 0;
    this._numberOfTicks = 0;
    return this;
  }

  /**
   * Cancels the timer, preventing any further executions.
   */
  public function cancel() {
    this.pause();
    if (this.scene) {
      this.scene.cancelTimer(this);
    }
  }
}
