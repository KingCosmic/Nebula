package core;

import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

typedef TimeStepConfig = {
  min:Int,
  target:Int,
  smoothStep:Bool
} 

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

  // The minimum fps rate you want the Time Step to run at.
  public var minFps:Int;

  /**
   * The target fps rate for the Time Step to run at.
   *
   * Setting this value will not actually change the speed at which the browser runs, that is beyond
   * the control of Phaser. Instead, it allows you to determine performance issues and if the Time Step
   * is spiraling out of control.
   */
  public var targetFps:Int;

  /**
   * The minFps value in ms.
   * Defaults to 200ms between frames (i.e. super slow!)
   */
  private var _min:Float;

  /**
   * The targetFps value in ms.
   * Defaults to 16.66ms between frames (i.e. normal)
   */
  private var _target:Float;

  // An exponential moving average of the frames per second.
  public var actualFps:Float;

  /**
   * The time at which the next fps rate update will take place.
   * When an fps update happens, the `framesThisSecond` value is reset.
   */
  public var nextFpsUpdate:Float = 0;

  // The number of frames processed this second.
  public var framesThisSecond:Int = 0;

  // A callback to be inivoked each time the Time Step steps.
  public var callback:Float->Float->Framebuffer->Void;

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
  private var _pauseTime:Float = 0;

  // The delta time, in ms, since the last game step. This is a clamped and smoothed average value.
  public var delta:Float = 0;

  /**
   * The actual elapsed time in ms between one update and the next.
   * 
   * Unlike with `delta`, no smoothing, capping, or averaging is applied to this value.
   * So please be careful when using this value in math calculations.
   */
  public var rawDelta:Float = 0;

  /**
   * The time, as returned by `performance.now` at the very start of the current step.
   * This can differ from the `time` value in that it isn't calculated based on the delta value.
   */
  public var now:Float = 0;
  
  public function new(game:Game, config:TimeStepConfig) {
    this.game = game;

    this.minFps = config.min | 5;
    this.targetFps = config.target | 60;

    this._min = 1000 / this.minFps;
    this._target = 1000 / this.targetFps;
    this.actualFps = this.targetFps;
  }
  
  public function getTime() {
    
  }

  public function blur() {
    inFocus = false;
  }

  public function focus() {
    inFocus = true;
    resetDelta();
  }

  public function pause() {
		_pauseTime = Scheduler.realTime();
  }

  public function resume() {
    resetDelta();

    startTime += time - _pauseTime;
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
  public function start(_callback:Float->Float->Framebuffer->Void) {
    if (started) return this;

    started = true;
    running = true;

    resetDelta();

		startTime = Scheduler.realTime();

    callback = _callback;

		System.notifyOnFrames(step);
    
    return this;
  }

  /**
   * The main step method. This is called each time the browser updates, either by Request Animation Frame,
   * or by Set Timeout. It is responsible for calculating the delta values, frame totals, cool down history and more.
   * You generally should never call this method directly.
   */
	public function step(frames:Array<Framebuffer>) {
		// Because the timestamp passed in from raf represents the beginning of the main thread frame that we’re currently in,
		// not the actual time now, and as we want to compare this time value against Event timeStamps and the like, we need a
    // more accurate one:
    
		var currentTime = Scheduler.realTime();

		now = currentTime;

		var before = currentTime - lastTime;

    if (before < 0) {
      // Because, Chrome.
      before = 0;
    }

    rawDelta = before;

    // Set as the world delta value
    delta = rawDelta;

    // Real-World timer advance
    time += rawDelta;

    // Update the estimate of the frame rate, `fps`. Every second, the number
    // of frames that occurred in that second are included in an exponential
    // moving average of all frames per second, with an alpha of 0.25. This
    // means that more recent seconds affect the estimated frame rate more than
    // older seconds.
    //
    // When a browser window is NOT minimized, but is covered up (i.e. you're using
    // another app which has spawned a window over the top of the browser), then it
    // will start to throttle the raf callback time. It waits for a while, and then
    // starts to drop the frame rate at 1 frame per second until it's down to just over 1fps.
    // So if the game was running at 60fps, and the player opens a new window, then
    // after 60 seconds (+ the 'buffer time') it'll be down to 1fps, so rafin'g at 1Hz.
    //
    // When they make the game visible again, the frame rate is increased at a rate of
    // approx. 8fps, back up to 60fps (or the max it can obtain)
    //
    // There is no easy way to determine if this drop in frame rate is because the
    // browser is throttling raf, or because the game is struggling with performance
    // because you're asking it to do too much on the device.

    if (time > nextFpsUpdate) {
      // Compute the new exponential moving average withthe alpha of 0.25.
      actualFps = 0.25 * framesThisSecond + 0.75 * actualFps;
      nextFpsUpdate = time + 1;
      framesThisSecond = 0;
    }

    framesThisSecond = framesThisSecond + 1;

    // Interpolation - how far between what is expected and where we are?
    // var interpolation = delta / _target;

    callback(time, delta, frames[0]);

		// Shift time value over.
    lastTime = currentTime;

    frame = frame + 1;
  }

  // Sends the TimeStep to sleep, stopping RAF and toggling the `running` flag to false.
  public function sleep() {
    if (running) {
      running = false;
    }
  }

  /**
   * Wakes-up the TimeStep, restarting Request Animation Frame (or SetTimeout) and toggling the `running` flag to true.
   * The `seamless` argument controls if the wake-up should adjust the start time or not.
   */
  public function wake(seamless: Bool) {
    if (running) return;

    if (seamless) {
			startTime += -lastTime + (lastTime + Scheduler.realTime());
    }

		System.notifyOnFrames(step);
    
    running = true;
  }

  // Gets the duration which the game has been running, in seconds.
  public function getDuration() {
    return Math.round(lastTime - startTime);
  }

  // Gets the duration which the game has been running, in ms.
  public function getDurationMS() {
    return Math.round(lastTime - startTime) * 100;
  }

  // Stops the TimeStep running.
  public function stop() {
    running = false;
    started = false;

    return this;
  }

  // Destroys the TimeStep. This will stop Request Animation Frame, stop the step, clear the callbacks and null
  // any objects.
  public function destroy() {
    stop();

    callback = (f1:Float, f2:Float, f3:Framebuffer) -> {};

    game = null;
  }
}