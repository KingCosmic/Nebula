package nebula;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System; 

// TODO: Simplify the hell out of this, then consider what needs to be moved to the renderer such as (frame count, fps counter)

class TimeStep {
  // A reference to the game instance
  public var game:Game;

  // A flag that is set once the TimeStep has started running and toggled when it stops.
  public var started:Bool = false;

  // ID that stores our Scheduler task id, (so we can stop it)
  public var updateID:Int;

  /**
   * A flag that is set once the TimeStep has started running and toggled when it stops.
   * The difference between this value and `started` is that `running` is toggled when
   * the TimeStep is sent to sleep, where-as `started` remains `true`, only changing if
   * the TimeStep is actually stopped, not just paused.
   */
  public var running:Bool = false;

  /**
   * The target fps rate for the Time Step to run at.
   *
   * Setting this value will not actually change the speed at which the browser runs, that is beyond
   * the control of Phaser. Instead, it allows you to determine performance issues and if the Time Step
   * is spiraling out of control.
   */
  public var targetFps:Int;

  /**
   * The targetFps value in ms.
   * Defaults to 16.66ms between frames (i.e. normal)
   */
	private var targetFpsMs:Float;

  /**
   * An exponential moving average of the frames per second.
   */
  public var actualFps:Float;

  /**
   * The time at which the next fps rate update will take place.
   * When an fps update happens, the `framesThisSecond` value is reset.
   */
  public var nextFpsUpdate:Float = 0;

  // The number of frames processed this second.
  public var framesThisSecond:Int = 0;

  // A callback to be inivoked each time the Time Step steps.
  public var callback:Float->Float->Void;

  // The time, calculated at the start of the current step, as smoothed by the delta value.
  public var time:Float = 0;

  // The time at which the game started running. This value is adjusted if the game is then paused and resumed.
  public var startTime:Float = 0;

  // The time, as returned by `performance.now` of the previous step.
  public var lastTime:Float = 0;

  /**
   * The current frame the game is on. This counter is incremented once every game step, regardless of how much
   * time has passed and is unaffected by delta smoothing
   */
  public var frame:Int = 0;

  /**
   * Is the browser currently considered in focus by the Page Visibility API?
   * This value is set in the `blur` method, which is called automatically by the Game instance.
   */
  public var inFocus:Bool = true;

  // The timestamp at which the game became paused, as determined by the Page Visibility API.
  private var pauseTime:Float = 0;

  /** 
   * The delta time, in ms, since the last game step.
   */
  public var delta:Float = 0;

  /**
   * The time, as returned by `performance.now` at the very start of the current step.
   * This can differ from the `time` value in that it isn't calculated based on the delta value.
   */
  public var now:Float = 0;
  
  public function new(game:Game, ?_targetFps:Int = 60) {
    this.game = game;

    this.targetFps = _targetFps;

    this.targetFpsMs = 1 / this.targetFps;
    this.actualFps = this.targetFps;
  }

  public function blur() {
    inFocus = false;
  }

  public function focus() {
    inFocus = true;
    resetDelta();
  }

  public function pause() {
		pauseTime = Scheduler.realTime();
  }

  public function resume() {
    resetDelta();

    startTime += time - pauseTime;
  }

  public function resetDelta() {
		var now = Scheduler.realTime();

    time = now;
    lastTime = now;
    nextFpsUpdate = now + 1;
    framesThisSecond = 0;

    delta = 0;
  }

  // Starts the Time Step running, if it is not already doing so.
  // Called automatcally by the Game Boot process.
  public function start(_callback:Float->Float->Void) {
    if (started) return this;

    started = true;
    running = true;

    resetDelta();

		startTime = Scheduler.realTime();

    callback = _callback;

    updateID = Scheduler.addTimeTask(step, 0, targetFpsMs);

    return this;
  }

  /**
   * The main step method. This is called each time the TimeTask updates.
   * It is responsible for calculating the delta values, frame totals, cool down history and more.
   * You generally should never call this method directly.
   */
	public function step() {
		// Because the timestamp passed in from raf represents the beginning of the main thread frame that we’re currently in,
		// not the actual time now, and as we want to compare this time value against Event timeStamps and the like, we need a
    // more accurate one:
    
		var currentTime = Scheduler.realTime();

    // update our now value
		now = currentTime;

    // calculate our delta
		var before = currentTime - lastTime;


    // TODO: unsure if this is needed.
    if (before < 0) {
      trace('fuck chrome');
      // Because, Chrome.
      before = 0;
    }

		// Set as the world delta value
    delta = before;

    // Real-World timer advance
    time += delta;

    // Update the estimate of the frame rate, `fps`. Every second, the number
    // of frames that occurred in that second are included in an exponential
    // moving average of all frames per second, with an alpha of 0.25. This
    // means that more recent seconds affect the estimated frame rate more than
    // older seconds.
    if (time > nextFpsUpdate) {
      // Compute the new exponential moving average withthe alpha of 0.25.
      actualFps = 0.25 * framesThisSecond + 0.75 * actualFps;

      // our next fps update is the next second.
      nextFpsUpdate = time + 1;

      // reset our frames this second.
      framesThisSecond = 0;
    }

    // increment our frames this second
    framesThisSecond++;

    // run our callback.
    callback(time, delta);

		// Shift time value over.
    lastTime = currentTime;

    // increment our total frame counter.
    frame++;
  }

  /**
	 * Sends the TimeStep to sleep, stopping TimeTask and toggling the `running` flag to false.
   * 
   * TODO: finish.
   */
  public function sleep() {
    if (running) {
      running = false;
    }
  }

  /**
   * Wakes-up the TimeStep, restarting the TimeTask and toggling the `running` flag to true.
   * The `seamless` argument controls if the wake-up should adjust the start time or not.
   */
  public function wake(seamless: Bool) {
    if (running) return;

    if (seamless) {
			startTime += -lastTime + (lastTime + Scheduler.realTime());
    }

		updateID = Scheduler.addTimeTask(step, 0, targetFpsMs);
    
    running = true;
  }

  /**
	 * Gets the duration which the game has been running, in seconds.
   */
  public function getDuration() {
    return Math.round(Scheduler.realTime());
  }

  /**
	 * Gets the duration which the game has been running, in ms.
   */
  public function getDurationMS() {
    return Scheduler.realTime();
  }

  /**
	 * Stops the TimeStep running.
   */
  public function stop() {
    running = false;
    started = false;

    return this;
  }

  /**
	 * Destroys the TimeStep. This will stop Request Animation Frame, stop the step,
   * clear the callbacks and null any objects.
   */
  public function destroy() {
    stop();

    callback = (f1:Float, f2:Float) -> {};

    game = null;
  }
}