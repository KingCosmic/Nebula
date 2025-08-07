package nebula.director;

import nebula.Engine;
import nebula.Scene;

import nebula.util.Future;

import nebula.math.CoordPlane;

import nebula.math.Vector;
import nebula.math.Util;
import nebula.util.EasingFunctions;
import nebula.util.Coroutine;
import nebula.util.Log;

import nebula.entitycomponentsystem.Entity;

interface TransitionOptions {
  /**
   * Transition duration in milliseconds
   */
  var duration: Float;

  /**
   * Optionally hides the loader during the transition
   *
   * If either the out or in transition have this set to true, then the loader will be hidden.
   *
   * Default false
   */
  var hideLoader: Null<Bool>;

  /**
   * Optionally blocks user input during a transition
   *
   * Default false
   */
  var blockInput: Null<Bool>;

  /**
   * Optionally specify a easing function, by default linear
   */
  var easing: Null<EasingFunction<Int>>;
  /**
   * Optionally specify a transition direction, by default 'out'
   *
   * * For 'in' direction transitions start at 1 and complete is at 0
   * * For 'out' direction transitions start at 0 and complete is at 1
   */
  var direction: Null<String>;
}

/**
 * Base Transition that can be extended to provide custom scene transitions in Excalibur.
 */
class Transition extends Entity {
  private var _logger: Logger = Logger.getInstance();
  var transform = new TransformComponent();
  var graphics = new GraphicsComponent();
  var hideLoader: Bool;
  var blockInput: Bool;
  var duration: Float;
  var easing: EasingFunction<Int>;
  var direction: String;
  private var _completeFuture = new Future<Void>();
  var _engine: Null<Engine>;
  private var _co: Null<Any>;

  // State needs to be reset between uses
  public var started = false;
  private var _currentDistance: Float = 0;
  private var _currentProgress: Float = 0;

  public var done = this._completeFuture.promise;

  /**
   * Returns a number between [0, 1] indicating what state the transition is in.
   *
   * * For 'out' direction transitions start at 0 and end at 1
   * * For 'in' direction transitions start at 1 and end at 0
   */
  public var progress(get, never): Float;
  function get_progress(): Float {
    return this._currentProgress;
  }

  public var complete(get, never): Float;
  function get_complete(): Bool {
    if (this.direction == 'out') {
      return this.progress >= 1;
    } else {
      return this.progress <= 0;
    }
  }

  public function new(options: TransitionOptions) {
    super();
    this.name = 'Transition#${this.id}';
    this.duration = options.duration;
    this.easing = options.easing ?? EasingFunctions.Linear;
    this.direction = options.direction ?? 'out';
    this.hideLoader = options.hideLoader ?? false;
    this.blockInput = options.blockInput ?? false;
    this.transform.coordPlane = CoordPlane.Screen;
    this.transform.pos = Vector.Zero;
    this.transform.z = Infinity; // Transitions sit on top of everything
    this.graphics.anchor = Vector.Zero;
    this.addComponent(this.transform);
    this.addComponent(this.graphics);

    if (this.direction == 'out') {
      this._currentProgress = 0;
    } else {
      this._currentProgress = 1;
    }
  }

  /**
   * Overridable lifecycle method, called before each update.
   *
   * **WARNING BE SURE** to call `super.updateTransition()` if overriding in your own custom implementation
   * @param engine
   * @param elapsed
   */
  public function updateTransition(engine: Engine, elapsed: Int) {
    if (this.complete) {
      return;
    }

    this._currentDistance += clamp(elapsed / this.duration, 0, 1);
    if (this._currentDistance >= 1) {
      this._currentDistance = 1;
    }

    if (this.direction == 'out') {
      this._currentProgress = clamp(this.easing(this._currentDistance, 0, 1, 1), 0, 1);
    } else {
      this._currentProgress = clamp(this.easing(this._currentDistance, 1, 0, 1), 0, 1);
    }
  }

  /**
   * Overridable lifecycle method, called right before the previous scene has deactivated.
   *
   * This gives incoming transition a chance to grab info from previous scene if desired
   * @param scene
   */
  function onPreviousSceneDeactivate(scene: Scene) {
    // override me
  }

  /**
   * Overridable lifecycle method, called once at the beginning of the transition
   *
   * `progress` is given between 0 and 1
   * @param progress
   */
  function onStart(progress: Float) {
    // override me
  }

  /**
   * Overridable lifecycle method, called every frame of the transition
   *
   * `progress` is given between 0 and 1
   * @param progress
   */
  function onUpdate(progress: Float) {
    // override me
  }

  /**
   * Overridable lifecycle method, called at the end of the transition,
   *
   * `progress` is given between 0 and 1
   * @param progress
   */
  function onEnd(progress: Float) {
    // override me
  }

  /**
   * Overridable lifecycle method, called when the transition is reset
   *
   * Use this to override and provide your own reset logic for internal state in custom transition implementations
   */
  function onReset() {
    // override me
  }

  /**
   * reset() is called by the engine to reset transitions
   */
  function reset() {
    this.started = false;
    this._completeFuture = new Future<Void>();
    this.done = this._completeFuture.promise;
    this._currentDistance = 0;
    if (this.direction == 'out') {
      this._currentProgress = 0;
    } else {
      this._currentProgress = 1;
    }
    this.onReset();
  }

  /**
   * @internal
   */
  function _addToTargetScene(engine: Engine, targetScene: Scene): CoroutineInstance {
    var currentScene = targetScene;
    if (this.started) {
      this._logger.warn('Attempted to add a transition ${this.name} that is already playing.');
    }

    if (currentScene.world.entityManager.getById(this.id)) {
      return this._co!;
    }
    this._engine = engine;
    currentScene.add(this);
    var self = this;
    this._co = coroutine(
      engine,
      function () {
        while (!self.complete) {
          var elapsed = yield; // per frame
          self.updateTransition(self._engine!, elapsed);
          self._execute();
        }
      },
      {
        autostart: false
      }
    );
    return this._co;
  }

  /**
   * Called internally by excalibur to swap scenes with transition
   * @internal
   */
  function _play() {
    if (this.started) {
      this.reset();
      this._logger.warn('Attempted to play a transition ${this.name} that is already playing, reset transition.');
    }

    if (!this._engine || !this._co) {
      this.reset();
      this._logger.warn('Attempted to play a transition ${this.name} that hasn\'t been added');
    }

    if (this._co) {
      this._co.start();
    }
  }

  /**
   * execute() is called by the engine every frame to update the Transition lifecycle onStart/onUpdate/onEnd
   * @internal
   */
  function _execute() {
    if (!this.isInitialized) {
      return;
    }

    if (!this.started) {
      this.started = true;
      this.onStart(this.progress);
    }

    this.onUpdate(this.progress);

    if (this.complete && !this._completeFuture.isCompleted) {
      this.onEnd(this.progress);
      this._completeFuture.resolve();
    }
  }
}
