package core.animations;

import core.textures.TextureManager;
import core.gameobjects.Sprite;
import core.structs.CustomMap;

using core.Constants;

/**
 * The Animation State Component.
 *
 * This component provides features to apply animations to Game Objects. It is responsible for
 * loading, queuing animations for later playback, mixing between animations and setting
 * the current animation frame to the Game Object that owns this component.
 *
 * This component lives as an instance within any Game Object that has it defined, such as Sprites.
 *
 * You can access its properties and methods via the `anims` property, i.e. `Sprite.anims`.
 *
 * As well as playing animations stored in the global Animation Manager, this component
 * can also create animations that are stored locally within it. See the `create` method
 * for more details.
 *
 * Prior to Phaser 3.50 this component was called just `Animation` and lived in the
 * `Phaser.GameObjects.Components` namespace. It was renamed to `AnimationState`
 * in 3.50 to help better identify its true purpose when browsing the documentation.
 */
class AnimationState {
  /**
   * The Game Object to which this animation component belongs.
   *
   * You can typically access this component from the Game Object
   * via the `this.anims` property.
   */
  public var parent:Sprite;

  // A reference to the global Animation Manager.
  public var animationManager:AnimationManager;

  // A reference to the Texture Manager.
  public var textureManager:TextureManager;

  /**
   * The Animations stored locally in this Animation component.
   *
   * Do not modify the contents of this Map directly, instead use the
   * `add`, `create` and `remove` methods of this class instead.
   */
  public var anims:CustomMap<Animation> = new CustomMap();

	// Is an animation currently playing or not?
  public var isPlaying:Bool = false;

  // Has the current animation started playing, or is it waiting for a delay to expire?
  public var hasStarted:Bool = false;

  /**
   * The current Animation loaded into this Animation component.
   *
   * Will be `null` if no animation is yet loaded.
   */
  public var currentAnim:Animation = null;

  /**
   * The current AnimationFrame being displayed by this Animation component.
   *
   * Will by `null` if no animation is yet loaded.
   */
  public var currentFrame:AnimationFrame = null;

  /**
   * The key, instance, or config of the next Animation to be loaded into this Animation component
   * when the current animation completes.
   *
   * Will be `null` if no animation has been queued.
   */
  public var nextAnim:Any = null;

  /**
   * A queue of Animations to be loaded into this Animation component when the current animation completes.
   *
   * Populate this queue via the `chain` method.
   */
  public var nextAnimsQueue:Array<Any> = [];

  /**
   * The Time Scale factor.
   *
   * You can adjust this value to modify the passage of time for the animation that is currently
   * playing. For example, setting it to 2 will make the animation play twice as fast. Or setting
   * it to 0.5 will slow the animation down.
   *
   * You can change this value at run-time, or set it via the `PlayAnimationConfig`.
   *
   * Prior to Phaser 3.50 this property was private and called `_timeScale`.
   */
  public var timeScale:Float = 1;

  /**
   * The frame rate of playback, of the current animation, in frames per second.
   *
   * This value is set when a new animation is loaded into this component and should
   * be treated as read-only, as changing it once playback has started will not alter
   * the animation. To change the frame rate, provide a new value in the `PlayAnimationConfig` object.
   */
  public var frameRate:Float = 0;

  /**
   * The duration of the current animation, in milliseconds.
   *
   * This value is set when a new animation is loaded into this component and should
   * be treated as read-only, as changing it once playback has started will not alter
   * the animation. To change the duration, provide a new value in the `PlayAnimationConfig` object.
   */
  public var duration:Float = 0;

  /**
   * The number of milliseconds per frame, not including frame specific modifiers that may be present in the
   * Animation data.
   *
   * This value is calculated when a new animation is loaded into this component and should
   * be treated as read-only. Changing it will not alter playback speed.
   */
  public var msPerFrame:Float = 0;

  // Skip frames if the time lags, or always advance anyways?
  public var skipMissedFrames:Bool = true;

  /**
   * The delay before starting playback of the current animation, in milliseconds.
   *
   * This value is set when a new animation is loaded into this component and should
   * be treated as read-only, as changing it once playback has started will not alter
   * the animation. To change the delay, provide a new value in the `PlayAnimationConfig` object.
   *
   * Prior to Phaser 3.50 this property was private and called `_delay`.
   */
  public var delay:Float = 0;

  /**
   * The number of times to repeat playback of the current animation.
   *
   * If -1, it means the animation will repeat forever.
   *
   * This value is set when a new animation is loaded into this component and should
   * be treated as read-only, as changing it once playback has started will not alter
   * the animation. To change the number of repeats, provide a new value in the `PlayAnimationConfig` object.
   *
   * Prior to Phaser 3.50 this property was private and called `_repeat`.
   */
  public var repeat:Int = 0;

  /**
   * The number of milliseconds to wait before starting the repeat playback of the current animation.
   *
   * This value is set when a new animation is loaded into this component, but can also be modified
   * at run-time.
   *
   * You can change the repeat delay by providing a new value in the `PlayAnimationConfig` object.
   *
   * Prior to Phaser 3.50 this property was private and called `_repeatDelay`.
   */
  public var repeatDelay:Float = 0;

  /**
   * Should the current animation yoyo? An animation that yoyos will play in reverse, from the end
   * to the start, before then repeating or completing. An animation that does not yoyo will just
   * play from the start to the end.
   *
   * This value is set when a new animation is loaded into this component, but can also be modified
   * at run-time.
   *
   * You can change the yoyo by providing a new value in the `PlayAnimationConfig` object.
   *
   * Prior to Phaser 3.50 this property was private and called `_yoyo`.
   */
  public var yoyo:Bool = false;

  /**
   * Should the GameObject's `visible` property be set to `true` when the animation starts to play?
   *
   * This will happen _after_ any delay that may have been set.
   *
   * This value is set when a new animation is loaded into this component, but can also be modified
   * at run-time, assuming the animation is currently delayed.
   */
  public var showOnStart:Bool = false;

  /**
   * Should the GameObject's `visible` property be set to `false` when the animation completes?
   *
   * This value is set when a new animation is loaded into this component, but can also be modified
   * at run-time, assuming the animation is still actively playing.
   */
  public var hideOnComplete:Bool = false;

  // Is the playhead moving forwards (`true`) or in reverse (`false`) ?
  public var forward:Bool = true;

  /**
   * An internal trigger that tells the component if it should plays the animation
   * in reverse mode ('true') or not ('false'). This is used because `forward` can
   * be changed by the `yoyo` feature.
   *
   * Prior to Phaser 3.50 this property was private and called `_reverse`.
   */
  public var inReverse:Bool = false;

  /**
   * Internal time overflow accumulator.
   *
   * This has the `delta` time added to it as part of the `update` step.
   */
  public var accumulator:Float = 0;

  /**
   * The time point at which the next animation frame will change.
   *
   * This value is compared against the `accumulator` as part of the `update` step.
   */
  public var nextTick:Float = 0;

  /**
   * A counter keeping track of how much delay time, in milliseconds, is left before playback begins.
   *
   * This is set via the `playAfterDelay` method, although it can be modified at run-time
   * if required, as long as the animation has not already started playing.
   */
  public var delayCounter:Float = 0;

  /**
   * A counter that keeps track of how many repeats are left to run.
   *
   * This value is set when a new animation is loaded into this component, but can also be modified
   * at run-time.
   */
  public var repeatCounter:Int = 0;

  // An internal flag keeping track of pending repeats.
  public var pendingRepeat:Bool = false;

  // Is the Animation paused?
  public var _paused:Bool = false;

  // Was the animation previously playing before being paused?
  public var _wasPlaying:Bool = false;

  /**
   * Internal property tracking if this Animation is waiting to stop.
   *
   * 0 = No
   * 1 = Waiting for ms to pass
   * 2 = Waiting for repeat
   * 3 = Waiting for specific frame
   */
  public var _pendingStop:Int = 0;

  // Internal property used by _pendingStop.
  public var _pendingStopValue:Dynamic;

  public function new(_parent:Sprite) {
    parent = _parent;
    animationManager = parent.scene.sys.anims;
    textureManager = animationManager.textureManager;

    animationManager.on('REMOVE_ANIMATION', globalRemove);
  }

  /**
   * Sets an animation, or an array of animations, to be played in the future, after the current one completes or stops.
   *
   * The current animation must enter a 'completed' state for this to happen, i.e. finish all of its repeats, delays, etc,
   * or have one of the `stop` methods called.
   *
   * An animation set to repeat forever will never enter a completed state unless stopped.
   *
   * You can chain a new animation at any point, including before the current one starts playing, during it, or when it ends (via its `animationcomplete` event).
   *
   * Chained animations are specific to a Game Object, meaning different Game Objects can have different chained animations without impacting the global animation they're playing.
   *
   * Call this method with no arguments to reset all currently chained animations.
   */
  public function chain(?key:Array<Any>) {
    // if no key was provided, stop chaining.
    if (key == null) {
      nextAnimsQueue = [];
      nextAnim = null;

      return parent;
    }

    for (anim in key) {
      // if we don't have a next anim, make it this one.
      if (nextAnim == null) {
        nextAnim = anim;
      } else {
        // otherwise just add it to the queue.
        nextAnimsQueue.push(anim);
      }
    }

    return parent;
  }

  /**
   * Returns the key of the animation currently loaded into this component.
   *
   * Prior to Phaser 3.50 this method was called `getCurrentKey`.
   */
  public function getName() {
    return (currentAnim != null) ? currentAnim.key : '';
  }

  /**
   * Returns the key of the animation frame currently displayed by this component.
   */
  public function getFrameName() {
    return (currentFrame != null) ? currentFrame.textureFrame : '';
  }

  /**
   * Internal method used to load an animation into this component.
   */
  public function load(key:Dynamic) {
    // stop the anim so we can load.
    if (isPlaying) stop();

    var animKey = Std.isOfType(key, String) ? key : key.key;

		// Get the animation, first from the local map and, if not found, from the Animation Manager
    var anim = exists(animKey) ? get(animKey) : animationManager.get(animKey);

    if (anim == null) {
      trace('Missing Animation: ' + animKey);

      return parent;
    }

    currentAnim = anim;

    // And now override the animation values, if set in the config.
    var totalFrames = anim.getTotalFrames();

    var frameRate:Float = (key.frameRate != null) ? key.frameRate : anim.frameRate;
    var duration:Float = (key.duration != null) ? key.duration : anim.duration;

    anim.calculateDuration(this, totalFrames, duration, frameRate);

    delay = (key.delay != null) ? key.delay : anim.delay;
    repeat = (key.repeat != null) ? key.repeat : anim.repeat;
    repeatDelay = (key.repeatDelay != null) ? key.repeatDelay : anim.repeatDelay;
    yoyo = key.yoyo || anim.yoyo;
    showOnStart = key.showOnStart || anim.showOnStart;
    hideOnComplete = key.hideOnComplete || anim.hideOnComplete;
    skipMissedFrames = key.skipMissedFrames || anim.skipMissedFrames;

    timeScale = (key.timeScale != null) ? key.timeScale : timeScale;

    var startFrame:Int = (key.startFrame != null) ? key.startFrame : 0;

    if (startFrame > anim.getTotalFrames()) startFrame = 0;

    var frame = anim.frames[startFrame];

    if (startFrame == 0 && !forward) {
      frame = anim.getLastFrame();
    }

    currentFrame = frame;

    return parent;
  }

  /**
   * Pause the current animation and set the `isPlaying` property to `false`.
   * You can optionally pause it at a specific frame.
   */
  public function pause(?atFrame:AnimationFrame) {
    if (!_paused) {
      _paused = true;
      _wasPlaying = isPlaying;
      isPlaying = false;
    }

    if (atFrame != null)
      setCurrentFrame(atFrame);

    return parent;
  }

  /**
   * Resumes playback of a paused animation and sets the `isPlaying` property to `true`.
   * You can optionally tell it to start playback from a specific frame.
   */
  public function resume(?fromFrame:AnimationFrame) {
    if (_paused) {
      _paused = false;
      isPlaying = _wasPlaying;
    }

    if (fromFrame != null) {
      setCurrentFrame(fromFrame);
    }

    return parent;
  }

  /**
   * Waits for the specified delay, in milliseconds, then starts playback of the given animation.
   *
   * If the animation _also_ has a delay value set in its config, it will be **added** to the delay given here.
   *
   * If an animation is already running and a new animation is given to this method, it will wait for
   * the given delay before starting the new animation.
   *
   * If no animation is currently running, the given one begins after the delay.
   *
   * Prior to Phaser 3.50 this method was called 'delayedPlay' and the parameters were in the reverse order.
   */
  public function playAfterDelay(key:Any, delay:Float) {
    if (!isPlaying) {
      delayCounter = delay;

      play(key, true);
    } else {
      // If we'vegot a nextAnim, move it to the queue
      if (nextAnim != null)
        nextAnimsQueue.unshift(nextAnim);

      nextAnim = key;

      _pendingStop = 1;
      _pendingStopValue = delay;
    }

    return parent;
  }

  /**
   * Waits for the current animation to complete the `repeatCount` number of repeat cycles, then starts playback
   * of the given animation.
   *
   * You can use this to ensure there are no harsh jumps between two sets of animations, i.e. going from an
   * idle animation to a walking animation, by making them blend smoothly into each other.
   *
   * If no animation is currently running, the given one will start immediately.
   */
  public function playAfterRepeat(key:Any, ?repeatCount:Int = 1) {
    if (!isPlaying) {
      play(key);
    } else {
      // If we've got a nextAnim, move it to the queue
      if (nextAnim != null) {
        nextAnimsQueue.unshift(nextAnim);
      }

      if (repeatCounter != -1 && repeatCount > repeatCounter) {
        repeatCount = repeatCounter;
      }

      nextAnim = key;

      _pendingStop = 2;
      _pendingStopValue = repeatCount;
    }

    return parent;
  }

  /**
   * Start playing the given animation on this Sprite.
   *
   * Animations in Phaser can either belong to the global Animation Manager, or specifically to this Sprite.
   *
   * The benefit of a global animation is that multiple Sprites can all play the same animation, without
   * having to duplicate the data. You can just create it once and then play it on any Sprite.
   *
   * The following code shows how to create a global repeating animation. The animation will be created
   * from all of the frames within the sprite sheet that was loaded with the key 'muybridge':
   *
   * ```javascript
   * var config = {
   *     key: 'run',
   *     frames: 'muybridge',
   *     frameRate: 15,
   *     repeat: -1
   * };
   *
   * //  This code should be run from within a Scene:
   * this.anims.create(config);
   * ```
   *
   * However, if you wish to create an animation that is unique to this Sprite, and this Sprite alone,
   * you can call the `Animation.create` method instead. It accepts the exact same parameters as when
   * creating a global animation, however the resulting data is kept locally in this Sprite.
   *
   * With the animation created, either globally or locally, you can now play it on this Sprite:
   *
   * ```javascript
   * this.add.sprite(x, y).play('run');
   * ```
   *
   * Alternatively, if you wish to run it at a different frame rate, for example, you can pass a config
   * object instead:
   *
   * ```javascript
   * this.add.sprite(x, y).play({ key: 'run', frameRate: 24 });
   * ```
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   *
   * If you need a Sprite to be able to play both local and global animations, make sure they don't
   * have conflicting keys.
   *
   * See the documentation for the `PlayAnimationConfig` config object for more details about this.
   *
   * Also, see the documentation in the Animation Manager for further details on creating animations.
   */
  public function play(key:Dynamic, ?ignoreIfPlaying:Bool = false) {
		// Must be either an Animation instance, or a PlayAnimationConfig object
    var animKey = Std.isOfType(key, String) ? key : key.key;

    if (ignoreIfPlaying && isPlaying && currentAnim.key == animKey) {
      return parent;
    }

    // Are we mixing?
    if (currentAnim != null && isPlaying) {
      var mix = animationManager.getMix(currentAnim.key, key);

      if (mix > 0) {
        return playAfterDelay(key, mix);
      }
    }

    forward = true;
    inReverse = false;

    _paused = false;
    _wasPlaying = true;

    return startAnimation(key);
  }

  /**
   * Start playing the given animation on this Sprite, in reverse.
   *
   * Animations in Phaser can either belong to the global Animation Manager, or specifically to this Sprite.
   *
   * The benefit of a global animation is that multiple Sprites can all play the same animation, without
   * having to duplicate the data. You can just create it once and then play it on any Sprite.
   *
   * The following code shows how to create a global repeating animation. The animation will be created
   * from all of the frames within the sprite sheet that was loaded with the key 'muybridge':
   *
   * ```javascript
   * var config = {
   *     key: 'run',
   *     frames: 'muybridge',
   *     frameRate: 15,
   *     repeat: -1
   * };
   *
   * //  This code should be run from within a Scene:
   * this.anims.create(config);
   * ```
   *
   * However, if you wish to create an animation that is unique to this Sprite, and this Sprite alone,
   * you can call the `Animation.create` method instead. It accepts the exact same parameters as when
   * creating a global animation, however the resulting data is kept locally in this Sprite.
   *
   * With the animation created, either globally or locally, you can now play it on this Sprite:
   *
   * ```javascript
   * this.add.sprite(x, y).playReverse('run');
   * ```
   *
   * Alternatively, if you wish to run it at a different frame rate, for example, you can pass a config
   * object instead:
   *
   * ```javascript
   * this.add.sprite(x, y).playReverse({ key: 'run', frameRate: 24 });
   * ```
   *
   * When playing an animation on a Sprite it will first check to see if it can find a matching key
   * locally within the Sprite. If it can, it will play the local animation. If not, it will then
   * search the global Animation Manager and look for it there.
   *
   * If you need a Sprite to be able to play both local and global animations, make sure they don't
   * have conflicting keys.
   *
   * See the documentation for the `PlayAnimationConfig` config object for more details about this.
   *
   * Also, see the documentation in the Animation Manager for further details on creating animations.
   */
  public function playReverse(key:Dynamic, ?ignoreIfPlaying:Bool = false) {

		// Must be either an Animation instance, or a PlayAnimationConfig object
    var animKey = Std.isOfType(key, String) ? key : key.key;

    if (ignoreIfPlaying && isPlaying && currentAnim.key == animKey) {
      return parent;
    }

    forward = false;
    inReverse = true;

    _paused = false;
    _wasPlaying = true;

    return startAnimation(key);
  }

  /**
   * Load the animation based on the key and set-up all of the internal values
   * needed for playback to start. If there is no delay, it will also fire the start events.
   */
  public function startAnimation(key:Any) {
    load(key);

    if (currentAnim == null) {
      return parent;
    }

    // Should give us 9,007,199,254,740,991 safe repeats
    repeatCounter = (repeat == -1) ? Ints.MAX : repeat;

    currentAnim.getFirstTick(this);

    isPlaying = true;
    pendingRepeat = false;
    hasStarted = false;

    _pendingStop = 0;
    _pendingStopValue = 0;
    _paused = false;

    // Add any delay the animation itself may have had as well
    if (delayCounter == 0) {
      handleStart();
    }

    return parent;
  }

  /**
   * Handles the start of an animation playback.
   */
  public function handleStart() {
    if (showOnStart)
      parent.setVisible(true);

    setCurrentFrame(currentFrame);

    hasStarted = true;

    emitEvents('ANIMATION_STARTED');
  }

  /**
   * Handles the repeat of an animation.
   */
  public function handleRepeat() {
    pendingRepeat = false;

    emitEvents('ANIMATION_REPEAT');
  }

  /**
   * Handles the stop of an animation playback.
   */
  public function handleStop() {
    _pendingStop = 0;

    isPlaying = false;

    emitEvents('ANIMATION_STOP');
  }

  /**
   * Handles the completion of an animation playback.
   */
  public function handleComplete() {
    _pendingStop = 0;

    isPlaying = false;

    if (hideOnComplete) {
      parent.setVisible(false);
    }

    emitEvents('ANIMATION_COMPLETE', 'ANIMATION_COMPLETE_');
  }

  /**
   * Fires the given animation event.
   */
  public function emitEvents(event:String, ?keyEvent:String) {
    var anim = currentAnim;
    var frame = currentFrame;

    var frameKey = frame.textureFrame;

    parent.emit(event, anim, frame, parent, frameKey);

    if (keyEvent != null)
      parent.emit(keyEvent + anim.key, anim, frame, parent, frameKey);
  }

  /**
   * Reverse the Animation that is already playing on the Game Object.
   */
  public function reverse() {
    if (isPlaying) {
      inReverse = !inReverse;

      forward = !forward;
    }

    return parent;
  }

  /**
   * Returns a value between 0 and 1 indicating how far this animation is through, ignoring repeats and yoyos.
   *
   * The value is based on the current frame and how far that is in the animation, it is not based on
   * the duration of the animation.
   */
  public function getProgress():Float {
    if (currentFrame == null) return 0;

    var p = currentFrame.progress;

    if (inReverse) p *= -1;

    return p;
  }

  /**
   * Takes a value between 0 and 1 and uses it to set how far this animation is through playback.
   *
   * Does not factor in repeats or yoyos, but does handle playing forwards or backwards.
   *
   * The value is based on the current frame and how far that is in the animation, it is not based on
   * the duration of the animation.
   */
  public function setProgress(value:Float) {
    if (!forward) {
      value = 1 - value;
    }

    setCurrentFrame(currentAnim.getFrameByProgress(value));

    return parent;
  }

  /**
   * Sets the number of times that the animation should repeat after its first play through.
   * For example, if repeat is 1, the animation will play a total of twice: the initial play plus 1 repeat.
   *
   * To repeat indefinitely, use -1.
   * The value should always be an integer.
   *
   * Calling this method only works if the animation is already running. Otherwise, any
   * value specified here will be overwritten when the next animation loads in. To avoid this,
   * use the `repeat` property of the `PlayAnimationConfig` object instead.
   */
  public function setRepeat(value:Int) {
    repeatCounter = (value == -1) ? Ints.MAX : value;

    return parent;
  }

  /**
   * Handle the removal of an animation from the Animation Manager.
   */
  public function globalRemove(key:String, ?animation:Animation) {
    if (animation == null) animation = currentAnim;

    if (isPlaying && animation.key == currentAnim.key) {
      stop();

      setCurrentFrame(currentAnim.frames[0]);
    }
  }

  /**
   * Restarts the current animation from its beginning.
   *
   * You can optionally reset the delay and repeat counters as well.
   *
   * Calling this will fire the `ANIMATION_RESTART` event immediately.
   *
   * If you `includeDelay` then it will also fire the `ANIMATION_START` event once
   * the delay has expired, otherwise, playback will just begin immediately.
   */
  public function restart(?includeDelay:Bool = false, ?resetRepeats:Bool = false) {
    if (currentAnim == null) return parent;

    if (resetRepeats) {
      repeatCounter = (repeat == -1) ? Ints.MAX : repeat;
    }

    currentAnim.getFirstTick(this);

    emitEvents('ANIMATION_RESTART');

    isPlaying = true;
    pendingRepeat = false;

    // Set this to `true` if there is no delay to include, so it skips the `hasStarted` check in `update`.
    hasStarted = !includeDelay;

    _pendingStop = 0;
    _pendingStopValue = 0;
    _paused = false;

    setCurrentFrame(currentAnim.frames[0]);

    return parent;
  }

  /**
   * The current animation has completed. This dispatches the `ANIMATION_COMPLETE` event.
   *
   * This method is called by the Animation instance and should not usually be invoked directly.
   *
   * If no animation is loaded, no events will be dispatched.
   *
   * If another animation has been queued for playback, it will be started after the events fire.
   */
  public function complete() {
    _pendingStop = 0;

    isPlaying = false;

    if (currentAnim != null) {
      handleComplete();
    }

    if (nextAnim != null) {
      var key = nextAnim;

      nextAnim = (nextAnimsQueue.length > 0) ? nextAnimsQueue.shift() : null;
      
      play(key);
    }

    return parent;
  }

  /**
   * Immediately stops the current animation from playing and dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing.
   */
  public function stop():Sprite {
    _pendingStop = 0;

    isPlaying = false;

    if (currentAnim != null) handleStop();

    if (nextAnim != null) {
      var key = nextAnim;

      nextAnim = nextAnimsQueue.shift();

      play(key);
    }

    return parent;
  }

  /**
   * Stops the current animation from playing after the specified time delay, given in milliseconds.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   */
  public function stopAfterDelay(delay:Float) {
    _pendingStop = 1;
    _pendingStopValue = delay;

    return parent;
  }

  /**
   * Stops the current animation from playing when it next repeats.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   *
   * Prior to Phaser 3.50 this method was called `stopOnRepeat` and had no parameters.
   */
  public function stopAfterRepeat(?repeatCount:Int = 1) {
    if (repeatCounter != -1 && repeatCount > repeatCounter) {
      repeatCount = repeatCounter;
    }

    _pendingStop = 2;
    _pendingStopValue = repeatCount;

    return parent;
  }

  /**
   * Stops the current animation from playing when it next sets the given frame.
   * If this frame doesn't exist within the animation it will not stop it from playing.
   *
   * It then dispatches the `ANIMATION_STOP` event.
   *
   * If no animation is running, no events will be dispatched.
   *
   * If there is another animation in the queue (set via the `chain` method) then it will start playing,
   * when the current one stops.
   */
  public function stopOnFrame(frame:AnimationFrame) {
    _pendingStop = 3;
    _pendingStopValue = frame;

    return parent;
  }

  /**
   * Returns the total number of frames in this animation, or returns zero if no
   * animation has been loaded.
   */
  public function getTotalFrames() {
    return (currentAnim != null) ? currentAnim.getTotalFrames() : 0;
  }

  /**
   * The internal update loop for the AnimationState Component.
   *
   * This is called automatically by the `Sprite.preUpdate` method.
   */
  public function update(time:Float, delta:Float) {
    if (!isPlaying || currentAnim == null || currentAnim.paused) {
      return;
    }

    accumulator += delta * timeScale;

    if (_pendingStop == 1) {
      _pendingStopValue -= delta;

      if (_pendingStopValue <= 0) {
        stop();
        return;
      }
    }

    if (!hasStarted) {
			if (accumulator >= delayCounter) {
				accumulator -= delayCounter;

				handleStart();
			}
    } else if (accumulator >= nextTick) {
      // Process one frame advance as standard

      if (forward) {
        currentAnim.nextFrame(this);
      } else {
        currentAnim.previousFrame(this);
      }

      // And only do more if we're skipping frames and have time left
      if (isPlaying && _pendingStop == 0 && skipMissedFrames && accumulator > nextTick) {
        var safetyNet = 0;

        while (accumulator > nextTick && safetyNet < 60) {
          if (forward) {
            currentAnim.nextFrame(this);
          } else {
            currentAnim.previousFrame(this);
          }

          safetyNet++;
        }
      }
    }
  }

  /**
   * Sets the given Animation Frame as being the current frame
   * and applies it to the parent Game Object, adjusting size and origin as needed.
   */
  public function setCurrentFrame(animationFrame:AnimationFrame) {
    currentFrame = animationFrame;

    parent.texture = animationFrame.frame.texture;
    parent.frame = animationFrame.frame;

    if (parent.isCropped) {
      parent.frame.updateCropUvs(parent._crop, parent.flipX, parent.flipY);
    }

    parent.setSizeToFrame();

    if (parent._originComponent != null) {
      if (animationFrame.frame.customPivot) {
        parent.setOrigin(animationFrame.frame.pivotX, animationFrame.frame.pivotY);
      } else {
        parent.updateDisplayOrigin();
      }
    }

    if (isPlaying && hasStarted) {
      emitEvents('ANIMATION_UPDATE');

      if (_pendingStop == 3 && _pendingStopValue == animationFrame) {
        stop();
      }
    }
    
    return parent;
  }

  /**
   * Advances the animation to the next frame, regardless of the time or animation state.
   * If the animation is set to repeat, or yoyo, this will still take effect.
   *
   * Calling this does not change the direction of the animation. I.e. if it was currently
   * playing in reverse, calling this method doesn't then change the direction to forwards.
   */
  public function nextFrame() {
    if (currentAnim != null) {
      currentAnim.nextFrame(this);
    }

    return parent;
  }

  /**
   * Advances the animation to the previous frame, regardless of the time or animation state.
   * If the animation is set to repeat, or yoyo, this will still take effect.
   *
   * Calling this does not change the direction of the animation. I.e. if it was currently
   * playing in forwards, calling this method doesn't then change the direction to backwards.
   */
  public function previousFrame() {
    if (currentAnim != null) {
      currentAnim.previousFrame(this);
    }

    return parent;
  }

  /**
   * Get an Animation instance that has been created locally on this Sprite.
   *
   * See the `create` method for more details.
   */
  public function get(key:String) {
    return (anims != null) ? anims.get(key) : null;
  }

  /**
   * Checks to see if the given key is already used locally within the animations stored on this Sprite.
   */
  public function exists(key:String) {
    return (anims != null && anims.has(key));
  }

  /**
   * Creates a new Animation that is local specifically to this Sprite.
   *
   * When a Sprite owns an animation, it is kept out of the global Animation Manager, which means
   * you're free to use keys that may be already defined there. Unless you specifically need a Sprite
   * to have a unique animation, you should favor using global animations instead, as they allow for
   * the same animation to be used across multiple Sprites, saving on memory. However, if this Sprite
   * is the only one to use this animation, it's sensible to create it here.
   *
   * If an invalid key is given this method will return `false`.
   *
   * If you pass the key of an animation that already exists locally, that animation will be returned.
   *
   * A brand new animation is only created if the key is valid and not already in use by this Sprite.
   *
   * If you wish to re-use an existing key, call the `remove` method first, then this method.
   */
  public function create(config) {
    var key = config.key;

    var anim:Animation = null;

    if (key != '') {
      anim = get(key);

      if (anim == null) {
        anim = new Animation(this.animationManager, key, config);

        anims.set(key, anim);
      }
    }

    return anim;
  }

  /**
   * Removes a locally created Animation from this Sprite, based on the given key.
   *
   * Once an Animation has been removed, this Sprite cannot play it again without re-creating it.
   */
  public function remove(key:String) {
    var anim = get(key);

    if (currentAnim == anim) {
      stop();
    }

    anims.delete(key);

    return anim;
  }

  /**
   * Destroy this Animation component.
   *
   * Unregisters event listeners and cleans up its references.
   */
  public function destroy() {
    animationManager.removeListener('REMOVE_ANIMATION', globalRemove);

    anims.clear();

    animationManager = null;
    parent = null;
    nextAnim = null;
    nextAnimsQueue = [];

    currentAnim = null;
    currentFrame = null;
  }

  /**
   * `true` if the current animation is paused, otherwise `false`.
   */
  public var isPaused(get, null):Bool;

  function get_isPaused() {
    return _paused;
  }
}