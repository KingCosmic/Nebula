package nebula;

import nebula.Engine;
import nebula.Screen;
import nebula.util.EasingFunctions;
import nebula.math.Vector;
import nebula.Actor;
import nebula.util.Util;
import nebula.interfaces.LifecycleEvents;
import nebula.Events;
import nebula.collision.BoundingBox;
import nebula.util.Log;
import nebula.graphics.context.ExcaliburGraphicsContext;
import nebula.math.AffineMatrix;
import nebula.EventEmitter;
import nebula.graphics.Graphic;
import nebula.math.Util;
import nebula.math.WatchVector;

/**
 * Interface that describes a custom camera strategy for tracking targets
 */
interface CameraStrategy<T> {
  /**
   * Target of the camera strategy that will be passed to the action
   */
  var target: T;

  /**
   * Camera strategies perform an action to calculate a new focus returned out of the strategy
   * @param target The target object to apply this camera strategy (if any)
   * @param camera The current camera implementation in excalibur running the game
   * @param engine The current engine running the game
   * @param elapsed The elapsed time in milliseconds since the last frame
   */
  function action(target: T, camera: Camera, engine: Engine, elapsed: Int): Vector;
}

/**
 * Container to house convenience strategy methods
 * @internal
 */
class StrategyContainer {
  public function new(camera: Camera) {}

  /**
   * Creates and adds the {@apilink LockCameraToActorStrategy} on the current camera.
   * @param actor The actor to lock the camera to
   */
  public function lockToActor(actor: Actor) {
    this.camera.addStrategy(new LockCameraToActorStrategy(actor));
  }

  /**
   * Creates and adds the {@apilink LockCameraToActorAxisStrategy} on the current camera
   * @param actor The actor to lock the camera to
   * @param axis The axis to follow the actor on
   */
  public function lockToActorAxis(actor: Actor, axis: Axis) {
    this.camera.addStrategy(new LockCameraToActorAxisStrategy(actor, axis));
  }

  /**
   * Creates and adds the {@apilink ElasticToActorStrategy} on the current camera
   * If cameraElasticity < cameraFriction < 1.0, the behavior will be a dampened spring that will slowly end at the target without bouncing
   * If cameraFriction < cameraElasticity < 1.0, the behavior will be an oscillating spring that will over
   * correct and bounce around the target
   * @param actor Target actor to elastically follow
   * @param cameraElasticity [0 - 1.0] The higher the elasticity the more force that will drive the camera towards the target
   * @param cameraFriction [0 - 1.0] The higher the friction the more that the camera will resist motion towards the target
   */
  public function elasticToActor(actor: Actor, cameraElasticity: Float, cameraFriction: Float) {
    this.camera.addStrategy(new ElasticToActorStrategy(actor, cameraElasticity, cameraFriction));
  }

  /**
   * Creates and adds the {@apilink RadiusAroundActorStrategy} on the current camera
   * @param actor Target actor to follow when it is "radius" pixels away
   * @param radius Number of pixels away before the camera will follow
   */
  public function radiusAroundActor(actor: Actor, radius: Int) {
    this.camera.addStrategy(new RadiusAroundActorStrategy(actor, radius));
  }

  /**
   * Creates and adds the {@apilink LimitCameraBoundsStrategy} on the current camera
   * @param box The bounding box to limit the camera to.
   */
  public function limitCameraBounds(box: BoundingBox) {
    this.camera.addStrategy(new LimitCameraBoundsStrategy(box));
  }
}

/**
 * Camera axis enum
 */
enum Axis {
  X;
  Y;
}

/**
 * Lock a camera to the exact x/y position of an actor.
 */
class LockCameraToActorStrategy implements CameraStrategy<Actor> {
  public function new(target: Actor) {}
  public function action(target: Actor, camera: Camera, engine: Engine, elapsed: Float) {
    final center = target.center;
    return center;
  };
}

/**
 * Lock a camera to a specific axis around an actor.
 */
class LockCameraToActorAxisStrategy implements CameraStrategy<Actor> {
  public function new(
    target: Actor,
    axis: Axis
  ) {}
  public function action(target: Actor, cam: Camera, _eng: Engine, elapsed: Float) {
    var center = target.center;
    var currentFocus = cam.getFocus();
    if (this.axis == Axis.X) {
      return new Vector(center.x, currentFocus.y);
    } else {
      return new Vector(currentFocus.x, center.y);
    }
  };
}

/**
 * Using [Hook's law](https://en.wikipedia.org/wiki/Hooke's_law), elastically move the camera towards the target actor.
 */
class ElasticToActorStrategy implements CameraStrategy<Actor> {
  /**
   * If cameraElasticity < cameraFriction < 1.0, the behavior will be a dampened spring that will slowly end at the target without bouncing
   * If cameraFriction < cameraElasticity < 1.0, the behavior will be an oscillating spring that will over
   * correct and bounce around the target
   * @param target Target actor to elastically follow
   * @param cameraElasticity [0 - 1.0] The higher the elasticity the more force that will drive the camera towards the target
   * @param cameraFriction [0 - 1.0] The higher the friction the more that the camera will resist motion towards the target
   */
  public function new(
    target: Actor,
    cameraElasticity: Float,
    cameraFriction: Float
  ) {}
  public function action(target: Actor, cam: Camera, _eng: Engine, elapsed: Float) {
    var position = target.center;
    var focus = cam.getFocus();
    var cameraVel = cam.vel.clone();

    // Calculate the stretch vector, using the spring equation
    // F = kX
    // https://en.wikipedia.org/wiki/Hooke's_law
    // Apply to the current camera velocity
    var stretch = position.sub(focus).scale(this.cameraElasticity); // stretch is X
    cameraVel = cameraVel.add(stretch);

    // Calculate the friction (-1 to apply a force in the opposition of motion)
    // Apply to the current camera velocity
    var friction = cameraVel.scale(-1).scale(this.cameraFriction);
    cameraVel = cameraVel.add(friction);

    // Update position by velocity deltas
    focus = focus.add(cameraVel);

    return focus;
  };
}

class RadiusAroundActorStrategy implements CameraStrategy<Actor> {
  /**
   *
   * @param target Target actor to follow when it is "radius" pixels away
   * @param radius Number of pixels away before the camera will follow
   */
  public function new(
    target: Actor,
    radius: Int
  ) {}
  public function action(target: Actor, cam: Camera, _eng: Engine, elapsed: Int) {
    var position = target.center;
    var focus = cam.getFocus();

    var direction = position.sub(focus);
    var distance = direction.magnitude;
    if (distance >= this.radius) {
      var offset = distance - this.radius;
      return focus.add(direction.normalize().scale(offset));
    }
    return focus;
  };
}

/**
 * Prevent a camera from going beyond the given camera dimensions.
 */
class LimitCameraBoundsStrategy implements CameraStrategy<BoundingBox> {
  /**
   * Useful for limiting the camera to a {@apilink TileMap}'s dimensions, or a specific area inside the map.
   *
   * Note that this strategy does not perform any movement by itself.
   * It only sets the camera position to within the given bounds when the camera has gone beyond them.
   * Thus, it is a good idea to combine it with other camera strategies and set this strategy as the last one.
   *
   * Make sure that the camera bounds are at least as large as the viewport size.
   * @param target The bounding box to limit the camera to
   */

  var boundSizeChecked: Bool = false; // Check and warn only once

  public function new(target: BoundingBox) {}

  public function action(target: BoundingBox, cam: Camera, _eng: Engine, elapsed: Float) {
    var focus = cam.getFocus();

    if (!this.boundSizeChecked) {
      if (target.bottom - target.top < _eng.drawHeight || target.right - target.left < _eng.drawWidth) {
        Logger.getInstance().warn('Camera bounds should not be smaller than the engine viewport');
      }
      this.boundSizeChecked = true;
    }

    var focusX = focus.x;
    var focusY = focus.y;
    if (focus.x < target.left + _eng.halfDrawWidth) {
      focusX = target.left + _eng.halfDrawWidth;
    } else if (focus.x > target.right - _eng.halfDrawWidth) {
      focusX = target.right - _eng.halfDrawWidth;
    }

    if (focus.y < target.top + _eng.halfDrawHeight) {
      focusY = target.top + _eng.halfDrawHeight;
    } else if (focus.y > target.bottom - _eng.halfDrawHeight) {
      focusY = target.bottom - _eng.halfDrawHeight;
    }

    return vec(focusX, focusY);
  };
}

typedef TCameraEvents = {
  preupdate: PreUpdateEvent<Camera>,
  postupdate: PostUpdateEvent<Camera>,
  initialize: InitializeEvent,
};

var CameraEvents = {
  Initialize: 'initialize',
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate'
};

/**
 * Cameras
 *
 * {@apilink Camera} is the base class for all Excalibur cameras. Cameras are used
 * to move around your game and set focus. They are used to determine
 * what is "off screen" and can be used to scale the game.
 *
 */
class Camera implements CanUpdate implements CanInitialize {
  public var events = new EventEmitter<TCameraEvents>();
  public var transform: AffineMatrix = AffineMatrix.identity();
  public var inverse: AffineMatrix = AffineMatrix.identity();

  private var _follow: Actor;

  private var _cameraStrategies: Array<CameraStrategy<Any>> = [];

  public var strategy: StrategyContainer = new StrategyContainer(this);

  /**
   * Get or set current zoom of the camera, defaults to 1
   */
  private var _z = 1;
  public var zoom(get, set): Float;
  function get_zoom(): Float {
    return this._z;
  }
  function set_zoom(val: Float) {
    this._z = val;
    if (this._engine) {
      this._halfWidth = this._engine.halfDrawWidth;
      this._halfHeight = this._engine.halfDrawHeight;
    }
  }
  /**
   * Get or set rate of change in zoom, defaults to 0
   */
  public var dz: Float = 0;
  /**
   * Get or set zoom acceleration
   */
  public var az: Float = 0;

  /**
   * Current rotation of the camera
   */
  public var rotation: Float = 0;

  private var _angularVelocity: Float = 0;

  /**
   * Get or set the camera's angular velocity
   */
  public var angularVelocity(get, set): Float;
  function get_angularVelocity(): Float {
    return this._angularVelocity;
  }
  function set_angularVelocity(value: Float) {
    this._angularVelocity = value;
  }

  private var _posChanged = false;
  private var _pos: Vector = new WatchVector(Vector.Zero, () -> {
    this._posChanged = true;
  });
  /**
   * Get or set the camera's position
   */
  public var pos(get, set): Vector;
  function get_pos(): Vector {
    return this._pos;
  }
  function set_pos(vec: Vector) {
    this._posChanged = true;
    this._pos = new WatchVector(vec, () -> {
      this._posChanged = true;
    });
  }

  /**
   * Has the position changed since the last update
   */
  public function hasChanged(): Bool {
    return this._posChanged;
  }
  /**
   * Interpolated camera position if more draws are running than updates
   *
   * Enabled when `Engine.fixedUpdateFps` is enabled, in all other cases this will be the same as pos
   */
  public var drawPos: Vector = this.pos.clone();

  private var _oldPos = this.pos.clone();

  /**
   * Get or set the camera's velocity
   */
  public var vel: Vector = Vector.Zero;

  /**
   * Get or set the camera's acceleration
   */
  public var acc: Vector = Vector.Zero;

  private var _cameraMoving: Bool = false;
  private var _currentLerpTime: Float = 0;
  private var _lerpDuration: Float = 1000; // 1 second
  private var _lerpStart: Vector = null;
  private var _lerpEnd: Vector = null;
  private var _lerpResolve: (value: Vector) -> Void;
  private var _lerpPromise: Promise<Vector>;

  //camera effects
  private var _isShaking: Bool = false;
  private var _shakeMagnitudeX: Float = 0;
  private var _shakeMagnitudeY: Float = 0;
  private var _shakeDuration: Float = 0;
  private var _elapsedShakeTime: Float = 0;
  private var _xShake: Float = 0;
  private var _yShake: Float = 0;

  private var _isZooming: Bool = false;
  private var _zoomStart: Float = 1;
  private var _zoomEnd: Float = 1;
  private var _currentZoomTime: Float = 0;
  private var _zoomDuration: Float = 0;

  private var _zoomResolve: (val: Bool) -> Void;
  private var _zoomPromise: Promise<Bool>;
  private var _zoomEasing: EasingFunction = EasingFunctions.EaseInOutCubic;
  private var _easing: EasingFunction = EasingFunctions.EaseInOutCubic;

  private var _halfWidth: Float = 0;
  private var _halfHeight: Float = 0;

  /**
   * Get the camera's x position
   */
  public var x(get, set): Int;
  function get_x() {
    return this.pos.x;
  }

  /**
   * Set the camera's x position (cannot be set when following an {@apilink Actor} or when moving)
   */
  function set_x(value: Float) {
    if (!this._follow && !this._cameraMoving) {
      this.pos = vec(value, this.pos.y);
    }
  }

  /**
   * Get the camera's y position
   */
  public var y(get, set): Int;
  function get_y() {
    return this.pos.y;
  }

  /**
   * Set the camera's y position (cannot be set when following an {@apilink Actor} or when moving)
   */
  function set_y(value: Float) {
    if (!this._follow && !this._cameraMoving) {
      this.pos = vec(this.pos.x, value);
    }
  }

  /**
   * Get or set the camera's x velocity
   */
  public var dx(get, set): Float;
  function get_dx() {
    return this.vel.x;
  }

  function set_dx(value: Float) {
    this.vel = vec(value, this.vel.y);
  }

  /**
   * Get or set the camera's y velocity
   */
  public var dy(get, set): Float;
  function get_dy() {
    return this.vel.y;
  }

  function set_dy(value: Float) {
    this.vel = vec(this.vel.x, value);
  }

  /**
   * Get or set the camera's x acceleration
   */
  public var ax(get, set): Float;
  function get_ax() {
    return this.acc.x;
  }

  function set_ax(value: Float) {
    this.acc = vec(value, this.acc.y);
  }

  /**
   * Get or set the camera's y acceleration
   */
  public var ay(get, set): Float;
  function get_ay() {
    return this.acc.y;
  }

  function set_ay(value: Float) {
    this.acc = vec(this.acc.x, value);
  }

  /**
   * Returns the focal point of the camera, a new point giving the x and y position of the camera
   */
  public function getFocus() {
    return this.pos;
  }

  /**
   * This moves the camera focal point to the specified position using specified easing function. Cannot move when following an Actor.
   * @param pos The target position to move to
   * @param duration The duration in milliseconds the move should last
   * @param [easingFn] An optional easing function ({@apilink EasingFunctions.EaseInOutCubic} by default)
   * @returns A {@apilink Promise} that resolves when movement is finished, including if it's interrupted.
   *          The {@apilink Promise} value is the {@apilink Vector} of the target position. It will be rejected if a move cannot be made.
   */
  public function move(pos: Vector, duration: Float, easingFn: EasingFunction = EasingFunctions.EaseInOutCubic): Promise<Vector> {
    // cannot move when following an actor
    if (this._follow) {
      return Promise.reject(pos);
    }

    // resolve existing promise, if any
    if (this._lerpPromise && this._lerpResolve) {
      this._lerpResolve(pos);
    }

    this._lerpPromise = new Promise<Vector>((resolve) => {
      this._lerpResolve = resolve;
    });
    this._lerpStart = this.getFocus().clone();
    this._lerpDuration = duration;
    this._lerpEnd = pos;
    this._currentLerpTime = 0;
    this._cameraMoving = true;
    this._easing = easingFn;

    return this._lerpPromise;
  }

  /**
   * Sets the camera to shake at the specified magnitudes for the specified duration
   * @param magnitudeX  The x magnitude of the shake
   * @param magnitudeY  The y magnitude of the shake
   * @param duration    The duration of the shake in milliseconds
   */
  public function shake(magnitudeX: Float, magnitudeY: Float, duration: Float) {
    this._isShaking = true;
    this._shakeMagnitudeX = magnitudeX;
    this._shakeMagnitudeY = magnitudeY;
    this._shakeDuration = duration;
  }

  /**
   * Zooms the camera in or out by the specified scale over the specified duration.
   * If no duration is specified, it take effect immediately.
   * @param scale    The scale of the zoom
   * @param duration The duration of the zoom in milliseconds
   */
  public function zoomOverTime(scale: Float, duration: Float = 0, easingFn: EasingFunction = EasingFunctions.EaseInOutCubic): Promise<Bool> {
    this._zoomPromise = new Promise<Bool>((resolve) => {
      this._zoomResolve = resolve;
    });

    if (duration) {
      this._isZooming = true;
      this._zoomEasing = easingFn;
      this._currentZoomTime = 0;
      this._zoomDuration = duration;
      this._zoomStart = this.zoom;
      this._zoomEnd = scale;
    } else {
      this._isZooming = false;
      this.zoom = scale;
      return Promise.resolve(true);
    }

    return this._zoomPromise;
  }

  private var _viewport: BoundingBox = null;
  /**
   * Gets the bounding box of the viewport of this camera in world coordinates
   */
  public var viewport(get, never): BoundingBox;
  function get_viewport(): BoundingBox {
    if (this._viewport) {
      return this._viewport;
    }

    return new BoundingBox(0, 0, 0, 0);
  }

  /**
   * Adds a new camera strategy to this camera
   * @param cameraStrategy Instance of an {@apilink CameraStrategy}
   */
  public function addStrategy<T>(cameraStrategy: CameraStrategy<T>) {
    this._cameraStrategies.push(cameraStrategy);
  }

  /**
   * Removes a camera strategy by reference
   * @param cameraStrategy Instance of an {@apilink CameraStrategy}
   */
  public function removeStrategy<T>(cameraStrategy: CameraStrategy<T>) {
    removeItemFromArray(cameraStrategy, this._cameraStrategies);
  }

  /**
   * Clears all camera strategies from the camera
   */
  public function clearAllStrategies() {
    this._cameraStrategies = [];
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPreUpdate} lifecycle event
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   * @internal
   */
  public function _preupdate(engine: Engine, elapsed: Int): Void {
    this.events.emit('preupdate', new PreUpdateEvent(engine, elapsed, this));
    this.onPreUpdate(engine, elapsed);
  }

  /**
   * Safe to override onPreUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreUpdate` is called directly before a scene is updated.
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPreUpdate(engine: Engine, elapsed: Int): Void {
    // Overridable
  }

  /**
   *  It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPostUpdate} lifecycle event
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   * @internal
   */
  public function _postupdate(engine: Engine, elapsed: Int): Void {
    this.events.emit('postupdate', new PostUpdateEvent(engine, elapsed, this));
    this.onPostUpdate(engine, elapsed);
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after a scene is updated.
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPostUpdate(engine: Engine, elapsed: Int): Void {
    // Overridable
  }

  private var _engine: Engine;
  private var _screen: Screen;
  private var _isInitialized = false;

  public var isInitialized(get, never): Bool;
  function get_isInitialized() {
    return this._isInitialized;
  }

  public function _initialize(engine: Engine) {
    if (!this.isInitialized) {
      this._engine = engine;
      this._screen = engine.screen;

      var currentRes = this._screen.contentArea;
      var center = vec(currentRes.width / 2, currentRes.height / 2);
      if (!this._engine.loadingComplete) {
        // If there was a loading screen, we peek the configured resolution
        var res = this._screen.peekResolution();
        if (res) {
          center = vec(res.width / 2, res.height / 2);
        }
      }
      this._halfWidth = center.x;
      this._halfHeight = center.y;

      // If the user has not set the camera pos, apply default center screen position
      if (!this._posChanged) {
        this.pos = center;
      }
      this.pos.clone(this.drawPos);
      // First frame bootstrap

      // Ensure camera tx is correct
      // Run update twice to ensure properties are init'd
      this.updateTransform(this.pos);

      // Run strategies for first frame
      this.runStrategies(engine, engine.clock.elapsed());

      // Setup the first frame viewport
      this.updateViewport();

      // It's important to update the camera after strategies
      // This prevents jitter
      this.updateTransform(this.pos);
      this.pos.clone(this._oldPos);

      this.onInitialize(engine);
      this.events.emit('initialize', new InitializeEvent(engine, this));
      this._isInitialized = true;
    }
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after a scene is updated.
   */
  public function onInitialize(engine: Engine) {
    // Overridable
  }

  public function emit(eventName: String, ?event: Any): Void {
    this.events.emit(eventName, event);
  }

  public function on(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.on(eventName, handler);
  }

  public function once(eventName: String, handler: Handler<Any>): Subscription {
    return this.events.once(eventName, handler);
  }

  public function off(eventName: String, ?handler: Handler<Any>): Void {
    this.events.off(eventName, handler);
  }

  public function runStrategies(engine: Engine, elapsed: Int) {
    for (s in this._cameraStrategies) {
      this.pos = s.action.call(s, s.target, this, engine, elapsed);
    }
  }

  public function updateViewport() {
    // recalculate viewport
    this._viewport = new BoundingBox(
      this.x - this._halfWidth,
      this.y - this._halfHeight,
      this.x + this._halfWidth,
      this.y + this._halfHeight
    );
  }

  public function update(engine: Engine, elapsed: Int) {
    this._initialize(engine);
    this._preupdate(engine, elapsed);
    this.pos.clone(this._oldPos);

    // Update placements based on linear algebra
    this.pos = this.pos.add(this.vel.scale(elapsed / 1000));
    this.zoom += (this.dz * elapsed) / 1000;

    this.vel = this.vel.add(this.acc.scale(elapsed / 1000));
    this.dz += (this.az * elapsed) / 1000;

    this.rotation += (this.angularVelocity * elapsed) / 1000;

    if (this._isZooming) {
      if (this._currentZoomTime < this._zoomDuration) {
        var zoomEasing = this._zoomEasing;
        var newZoom = zoomEasing(this._currentZoomTime, this._zoomStart, this._zoomEnd, this._zoomDuration);

        this.zoom = newZoom;
        this._currentZoomTime += elapsed;
      } else {
        this._isZooming = false;
        this.zoom = this._zoomEnd;
        this._currentZoomTime = 0;
        this._zoomResolve(true);
      }
    }

    if (this._cameraMoving) {
      if (this._currentLerpTime < this._lerpDuration) {
        var moveEasing = EasingFunctions.CreateVectorEasingFunction(this._easing);

        var lerpPoint = moveEasing(this._currentLerpTime, this._lerpStart, this._lerpEnd, this._lerpDuration);

        this.pos = lerpPoint;

        this._currentLerpTime += elapsed;
      } else {
        this.pos = this._lerpEnd;
        var end = this._lerpEnd.clone();

        this._lerpStart = null;
        this._lerpEnd = null;
        this._currentLerpTime = 0;
        this._cameraMoving = false;
        // Order matters here, resolve should be last so any chain promises have a clean slate
        this._lerpResolve(end);
      }
    }

    if (this._isDoneShaking()) {
      this._isShaking = false;
      this._elapsedShakeTime = 0;
      this._shakeMagnitudeX = 0;
      this._shakeMagnitudeY = 0;
      this._shakeDuration = 0;
      this._xShake = 0;
      this._yShake = 0;
    } else {
      this._elapsedShakeTime += elapsed;
      this._xShake = ((Math.random() * this._shakeMagnitudeX) | 0) + 1;
      this._yShake = ((Math.random() * this._shakeMagnitudeY) | 0) + 1;
    }

    this.runStrategies(engine, elapsed);

    this.updateViewport();

    // It's important to update the camera after strategies
    // This prevents jitter
    this.updateTransform(this.pos);
    this._postupdate(engine, elapsed);
    this._posChanged = false;
  }

  private var _snapPos = vec(0, 0);
  /**
   * Applies the relevant transformations to the game canvas to "move" or apply effects to the Camera
   * @param ctx Canvas context to apply transformations
   */
  public function draw(ctx: ExcaliburGraphicsContext): Void {
    // default to the current position
    this.pos.clone(this.drawPos);

    // interpolation if fixed update is on
    // must happen on the draw, because more draws are potentially happening than updates
    if (this._engine.fixedUpdateTimestep) {
      var blend = this._engine.currentFrameLagMs / this._engine.fixedUpdateTimestep;
      var interpolatedPos = this.pos.scale(blend).add(this._oldPos.scale(1.0 - blend));
      interpolatedPos.clone(this.drawPos);
      this.updateTransform(interpolatedPos);
    }
    // Snap camera to pixel
    if (ctx.snapToPixel) {
      var snapPos = this.drawPos.clone(this._snapPos);
      snapPos.x = ~~(snapPos.x + pixelSnapEpsilon * sign(snapPos.x));
      snapPos.y = ~~(snapPos.y + pixelSnapEpsilon * sign(snapPos.y));
      snapPos.clone(this.drawPos);
      this.updateTransform(snapPos);
    }
    ctx.multiply(this.transform);
  }

  public function updateTransform(pos: Vector) {
    // center the camera
    var newCanvasWidth = this._screen.resolution.width / this.zoom;
    var newCanvasHeight = this._screen.resolution.height / this.zoom;
    var cameraPos = vec(-pos.x + newCanvasWidth / 2 + this._xShake, -pos.y + newCanvasHeight / 2 + this._yShake);

    // Calculate camera transform
    this.transform.reset();

    this.transform.scale(this.zoom, this.zoom);

    // rotate about the focus
    this.transform.translate(newCanvasWidth / 2, newCanvasHeight / 2);
    this.transform.rotate(this.rotation);
    this.transform.translate(-newCanvasWidth / 2, -newCanvasHeight / 2);

    this.transform.translate(cameraPos.x, cameraPos.y);
    this.transform.inverse(this.inverse);
  }

  private function _isDoneShaking(): Bool {
    return !this._isShaking || this._elapsedShakeTime >= this._shakeDuration;
  }
}
