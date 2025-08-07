package nebula.graphics;

import nebula.graphics.Graphic;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.graphics.SpriteSheet;

import nebula.util.Log;
import nebula.math.Util;

import nebula.EventEmitter;

interface HasTick {
  /**
   *
   * @param elapsed The amount of real world time in milliseconds that has elapsed that must be updated in the animation
   * @param idempotencyToken Optional idempotencyToken prevents a ticking animation from updating twice per frame
   */
  function tick(elapsed: Float, ?idempotencyToken: Int): Void;
}

enum AnimationDirection {
  /**
   * Animation is playing forwards
   */
  Forward;
  /**
   * Animation is playing backwards
   */
  Backward;
}

enum AnimationStrategy {
  /**
   * Animation ends without displaying anything
   */
  End;
  /**
   * Animation loops to the first frame after the last frame
   */
  Loop;
  /**
   * Animation plays to the last frame, then backwards to the first frame, then repeats
   */
  PingPong;
  /**
   * Animation ends stopping on the last frame
   */
  Freeze;
}

/**
 * Frame of animation
 */
interface Frame {
  /**
   * Optionally specify a graphic to show, no graphic shows an empty frame
   */
  var graphic: Null<Graphic>;
  /**
   * Optionally specify the number of ms the frame should be visible, overrides the animation duration (default 100 ms)
   */
  var duration: Null<Int>;
}

interface FrameEvent extends Frame {
  var frameIndex: Int;
}

/**
 * Animation options for building an animation via constructor.
 */
interface AnimationOptions {
  /**
   * List of frames in the order you wish to play them
   */
  var frames: Array<Frame>;
  /**
   * Optionally set a positive speed multiplier on the animation.
   *
   * By default 1, meaning 1x speed. If set to 2, it will play the animation twice as fast.
   */
  var speed: Null<Int>;
  /**
   * Optionally reverse the direction of play
   */
  var reverse: Null<Bool>;
  /**
   * Optionally specify a default frame duration in ms (Default is 100)
   */
  var frameDuration: Null<Int>;
  /**
   * Optionally specify a total duration of the animation in ms to calculate each frame's duration
   */
  var totalDuration: Null<Int>;
  /**
   * Optionally specify the {@apilink AnimationStrategy} for the Animation
   */
  var strategy: Null<AnimationStrategy>;
  /**
   * Optionally set arbitrary meta data for the animation
   */
  var data: Null<Record<String, Any>>;
}

typedef TAnimationEvents = {
  var frame: FrameEvent;
  var loop: Animation;
  var end: Animation;
};

final AnimationEvents = {
  Frame: 'frame',
  Loop: 'loop',
  End: 'end'
};

interface FromSpriteSheetOptions {
  /**
   * {@apilink SpriteSheet} to source the animation frames from
   */
  var priteSheet: SpriteSheet;
  /**
   * The list of (x, y) positions of sprites in the {@apilink SpriteSheet} of each frame, for example (0, 0)
   * is the the top left sprite, (0, 1) is the sprite directly below that, and so on.
   *
   * You may optionally specify a duration for the frame in milliseconds as well, this will override
   * the default duration.
   */
  var frameCoordinates: Array<{ x: Int, y: Int, duration: Null<Int>, options: Null<GetSpriteOptions> }>;
  /**
   * Optionally specify a default duration for frames in milliseconds
   * @deprecated use `durationPerFrame`
   */
  var durationPerFrameMs: Null<Int>;
  /**
   * Optionally specify a default duration for frames in milliseconds
   */
  var durationPerFrame: Null<Int>;
  /**
   * Optionally set a positive speed multiplier on the animation.
   *
   * By default 1, meaning 1x speed. If set to 2, it will play the animation twice as fast.
   */
  var speed: Null<Int>;
  /**
   * Optionally specify the animation strategy for this animation, by default animations loop {@apilink AnimationStrategy.Loop}
   */
  var strategy: Null<AnimationStrategy>;
  /**
   * Optionally specify the animation should be reversed
   */
  var reverse: Null<Bool>;
  /**
   * Optionally set arbitrary meta data for the animation
   */
  var data: Null<Record<String, Any>>;
}

/**
 * Create an Animation given a list of {@apilink Frame | `frames`} in {@apilink AnimationOptions}
 *
 * To create an Animation from a {@apilink SpriteSheet}, use {@apilink Animation.fromSpriteSheet}
 */
class Animation extends Graphic implements HasTick {
  private static var _LOGGER = Logger.getInstance();
  public var events = new EventEmitter<AnimationEvents>();
  public var frames: Array<Frame> = [];
  public var strategy: AnimationStrategy = AnimationStrategy.Loop;
  public var frameDuration: Int = 100;
  public var data: Map<String, Any>;

  private var _idempotencyToken = -1;

  private var _firstTick = true;
  private var _currentFrame = 0;
  private var _timeLeftInFrame = 0;
  private var _pingPongDirection = 1;
  private var _done = false;
  private var _playing = true;
  private var _speed = 1;
  private var _wasResetDuringFrameCalc: Bool = false;

  public function new(options: GraphicOptions & AnimationOptions) {
    super(options);
    this.frames = options.frames;
    this.speed = options.speed ?? this.speed;
    this.strategy = options.strategy ?? this.strategy;
    this.frameDuration = options.totalDuration ? options.totalDuration / this.frames.length : (options.frameDuration ?? this.frameDuration);
    this.data = options.data ? new Map(Object.entries(options.data)) : new Map<String, Any>();
    if (options.reverse) {
      this.reverse();
    }
    this.goToFrame(0);
  }

  public function clone(): Animation {
    var config = Object.spreadwith(
      {
        frames: this.frames.map((f) -> f),
        frameDuration: this.frameDuration,
        speed: this.speed,
        reverse: this._reversed,
        strategy: this.strategy,
      },
      this.cloneGraphicOptions()
    );

    return new Animation(config);
  }

  override function get_width(): Int {
    final maybeFrame = this.currentFrame;
    if (maybeFrame && maybeFrame.graphic) {
      return Math.abs(maybeFrame.graphic.width * this.scale.x);
    }
    return 0;
  }

  override function get_height(): Int {
    final maybeFrame = this.currentFrame;
    if (maybeFrame && maybeFrame.graphic) {
      return Math.abs(maybeFrame.graphic.height * this.scale.y);
    }
    return 0;
  }

  /**
   * Create an Animation from a {@apilink SpriteSheet}, a list of indices into the sprite sheet, a duration per frame
   * and optional {@apilink AnimationStrategy}
   *
   * Example:
   * ```typescript
   * const spriteSheet = SpriteSheet.fromImageSource({...});
   *
   * const anim = Animation.fromSpriteSheet(spriteSheet, range(0, 5), 200, AnimationStrategy.Loop);
   * ```
   * @param spriteSheet ex.SpriteSheet
   * @param spriteSheetIndex 0 based index from left to right, top down (row major order) of the ex.SpriteSheet
   * @param durationPerFrame duration per frame in milliseconds
   * @param strategy Optional strategy, default AnimationStrategy.Loop
   */
  public static function fromSpriteSheet(
    spriteSheet: SpriteSheet,
    spriteSheetIndex: Array<Int>,
    durationPerFrame: Int,
    strategy: AnimationStrategy = AnimationStrategy.Loop,
    ?data: Record<String, Any>
  ): Animation {
    final maxIndex = spriteSheet.sprites.length - 1;
    final invalidIndices = spriteSheetIndex.filter((index) => index < 0 || index > maxIndex);
    if (invalidIndices.length) {
      Animation._LOGGER.warn(
        'Indices into SpriteSheet were provided that don\'t exist: ${invalidIndices.join(',')} no frame will be shown'
      );
    }
    return new Animation({
      frames: spriteSheet.sprites
        .filter((_, index) -> spriteSheetIndex.indexOf(index) > -1)
        .map((f) => ({
          graphic: f,
          duration: durationPerFrame
        })),
      strategy: strategy,
      data: data
    });
  }

  /**
   * Create an {@apilink Animation} from a {@apilink SpriteSheet} given a list of coordinates
   *
   * Example:
   * ```typescript
   * const spriteSheet = SpriteSheet.fromImageSource({...});
   *
   * const anim = Animation.fromSpriteSheetCoordinates({
   *  spriteSheet,
   *  frameCoordinates: [
   *    {x: 0, y: 5, duration: 100, options { flipHorizontal: true }},
   *    {x: 1, y: 5, duration: 200},
   *    {x: 2, y: 5},
   *    {x: 3, y: 5}
   *  ],
   *  strategy: AnimationStrategy.PingPong
   * });
   * ```
   * @param options
   * @returns Animation
   */
  public static function fromSpriteSheetCoordinates(options: FromSpriteSheetOptions): Animation {
    final spriteSheet = options.spriteSheet,
          frameCoordinates = options.frameCoordinates,
          durationPerFrame = options.durationPerFrame,
          durationPerFrameMs = options.durationPerFrameMs,
          speed = options.speed,
          strategy = options.strategy,
          reverse = options.reverse,
          data = options.data;

    final defaultDuration = durationPerFrame ?? durationPerFrameMs ?? 100;
    final frames: Array<Frame> = [];
    for (coord in frameCoordinates) {
      final x = coord.x,
            y = coord.y,
            duration = coord.duration,
            options = coord.options;

      final sprite = spriteSheet.getSprite(x, y, options);
      if (sprite) {
        frames.push({
          graphic: sprite,
          duration: duration ?? defaultDuration
        });
      } else {
        Animation._LOGGER.warn(
          'Skipping frame! SpriteSheet does not have coordinate (${x}, ${y}), please check your SpriteSheet to confirm that sprite exists'
        );
      }
    }

    return new Animation({
      frames: frames,
      strategy: strategy,
      speed: speed,
      reverse: reverse,
      data: data
    });
  }

  /**
   * Current animation speed
   *
   * 1 meaning normal 1x speed.
   * 2 meaning 2x speed and so on.
   */
  public var speed(get, set): Int;
  function get_speed(): Int {
    return this._speed;
  }

  /**
   * Current animation speed
   *
   * 1 meaning normal 1x speed.
   * 2 meaning 2x speed and so on.
   */
  function set_speed(val: Int) {
    this._speed = clamp(Math.abs(val), 0, Infinity);
  }

  /**
   * Returns the current Frame of the animation
   *
   * Use {@apilink Animation.currentFrameIndex} to get the frame number and
   * {@apilink Animation.goToFrame} to set the current frame index
   */
  public var currentFrame(get, never): Null<Frame>;
  function get_currentFrame(): Null<Frame> {
    if (this._currentFrame >= 0 && this._currentFrame < this.frames.length) {
      return this.frames[this._currentFrame];
    }
    return null;
  }

  /**
   * Returns the current frame index of the animation
   *
   * Use {@apilink Animation.currentFrame} to grab the current {@apilink Frame} object
   */
  public var currentFrameIndex(get, never): Int;
  function get_currentFrameIndex(): Int {
    return this._currentFrame;
  }

  /**
   * Returns the amount of time in milliseconds left in the current frame
   */
  public var currentFrameTimeLeft(get, never): Int;
  function get_currentFrameTimeLeft(): Int {
    return this._timeLeftInFrame;
  }

  /**
   * Returns `true` if the animation is playing
   */
  public var isPlaying(get, never): Bool;
  function get_isPlaying(): Bool {
    return this._playing;
  }

  private var _reversed = false;

  public var isReversed(get, never): Bool;
  function get_isReversed() {
    return this._reversed;
  }

  /**
   * Reverses the play direction of the Animation, this preserves the current frame
   */
  public function reverse(): Void {
    // Don't mutate with the original frame list, create a copy
    this.frames = this.frames.slice().reverse();
    this._reversed = !this._reversed;
  }

  /**
   * Returns the current play direction of the animation
   */
  public var direction(get, never): AnimationDirection;
  function get_direction(): AnimationDirection {
    // Keep logically consistent with ping-pong direction
    // If ping-pong is forward = 1 and reversed is true then we are logically reversed
    final reversed = this._reversed && this._pingPongDirection == 1 ? true : false;
    return reversed ? AnimationDirection.Backward : AnimationDirection.Forward;
  }

  /**
   * Plays or resumes the animation from the current frame
   */
  public function play(): Void {
    this._playing = true;
  }

  /**
   * Pauses the animation on the current frame
   */
  public function pause(): Void {
    this._playing = false;
    this._firstTick = true; // firstTick must be set to emit the proper frame event
  }

  /**
   * Reset the animation back to the beginning, including if the animation were done
   */
  public function reset(): Void {
    this._wasResetDuringFrameCalc = true;
    this._done = false;
    this._firstTick = true;
    this._currentFrame = 0;
    this._timeLeftInFrame = this.frameDuration;
    final maybeFrame = this.frames[this._currentFrame];
    if (maybeFrame) {
      this._timeLeftInFrame = maybeFrame?.duration || this.frameDuration;
    }
  }

  /**
   * Returns `true` if the animation can end
   */
  public var canFinish(get, never): Bool;
  function get_canFinish(): Bool {
    switch (this.strategy) {
      case AnimationStrategy.End:
      case AnimationStrategy.Freeze: {
        return true;
      }
      default: {
        return false;
      }
    }
  }

  /**
   * Returns `true` if the animation is done, for looping type animations
   * `ex.AnimationStrategy.PingPong` and `ex.AnimationStrategy.Loop` this will always return `false`
   *
   * See the `ex.Animation.canFinish()` method to know if an animation type can end
   */
  public var done(get, never): Bool;
  function get_done(): Bool {
    return this._done;
  }

  /**
   * Jump the animation immediately to a specific frame if it exists
   *
   * Optionally specify an override for the duration of the frame, useful for
   * keeping multiple animations in sync with one another.
   * @param frameNumber
   * @param duration
   */
  public function goToFrame(frameNumber: Int, ?duration: Int) {
    this._currentFrame = frameNumber;
    this._timeLeftInFrame = duration ?? this.frameDuration;
    final maybeFrame = this.frames[this._currentFrame];
    if (maybeFrame && !this._done) {
      this._timeLeftInFrame = duration ?? (maybeFrame?.duration || this.frameDuration);
      this.events.emit('frame', Object.spreadWith(maybeFrame, { frameIndex: this.currentFrameIndex }));
    }
  }

  private function _nextFrame(): Int {
    this._wasResetDuringFrameCalc = false;
    final currentFrame = this._currentFrame;
    if (this._done) {
      return currentFrame;
    }
    var next = -1;

    switch (this.strategy) {
      case AnimationStrategy.Loop: {
        next = (currentFrame + 1) % this.frames.length;
        if (next == 0) {
          this.events.emit('loop', this);
        }
        break;
      }
      case AnimationStrategy.End: {
        next = currentFrame + 1;
        if (next >= this.frames.length) {
          this._done = true;
          this._currentFrame = this.frames.length;
          this.events.emit('end', this);
        }
        break;
      }
      case AnimationStrategy.Freeze: {
        next = clamp(currentFrame + 1, 0, this.frames.length - 1);
        if (currentFrame + 1 >= this.frames.length) {
          this._done = true;
          this.events.emit('end', this);
        }
        break;
      }
      case AnimationStrategy.PingPong: {
        if (currentFrame + this._pingPongDirection >= this.frames.length) {
          this._pingPongDirection = -1;
          this.events.emit('loop', this);
        }

        if (currentFrame + this._pingPongDirection < 0) {
          this._pingPongDirection = 1;
          this.events.emit('loop', this);
        }

        next = currentFrame + (this._pingPongDirection % this.frames.length);
        break;
      }
    }
    if (this._wasResetDuringFrameCalc) {
      // if reset during frame calculation discard the calc'd next and return the current frame.
      this._wasResetDuringFrameCalc = false;
      return this._currentFrame;
    }
    return next;
  }

  /**
   * Called internally by Excalibur to update the state of the animation potential update the current frame
   * @param elapsed Milliseconds elapsed
   * @param idempotencyToken Prevents double ticking in a frame by passing a unique token to the frame
   */
  public function tick(elapsed: Int, idempotencyToken: Int = 0): Void {
    if (this._idempotencyToken == idempotencyToken) {
      return;
    }
    this._idempotencyToken = idempotencyToken;
    if (!this._playing) {
      return;
    }

    // if it's the first frame emit frame event
    if (this._firstTick) {
      this._firstTick = false;
      this.events.emit('frame', Object.spreadWith(this.currentFrame, { frameIndex: this.currentFrameIndex }));
    }

    this._timeLeftInFrame -= elapsed * this._speed;
    if (this._timeLeftInFrame <= 0) {
      this.goToFrame(this._nextFrame());
    }
  }

  function _drawImage(ctx: ExcaliburGraphicsContext, x: Int, y: Int) {
    if (this.currentFrame && this.currentFrame.graphic) {
      this.currentFrame.graphic.draw(ctx, x, y);
    }
  }
}
