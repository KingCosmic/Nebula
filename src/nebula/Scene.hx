package nebula;

import nebula.ScreenElement;
import nebula.Events;
import nebula.util.Log;
import nebula.Timer;
import nebula.Engine;
import nebula.tilemap.TileMap;
import nebula.Camera;
import nebula.Actor;
import nebula.interfaces.LifecycleEvents;
import nebula.util.Util;
import nebula.Trigger;
import nebula.entitycomponentsystem.System;
import nebula.entitycomponentsystem.World;
import nebula.collision.MotionSystem;
import nebula.entitycomponentsystem.Entity;
import nebula.graphics.GraphicsSystem;
import nebula.debug.DebugSystem;
import nebula.input.PointerSystem;
import nebula.actions.ActionsSystem;
import nebula.tilemap.IsometricEntitySystem;
import nebula.graphics.OffscreenSystem;
import nebula.collision.PhysicsWorld;
import nebula.EventEmitter;
import nebula.Color;
import nebula.director.DefaultLoader;
import nebula.input.InputHost;
import nebula.input.PointerScope;
import nebula.collision.PhysicsConfig;

class PreLoadEvent {
  var loader: DefaultLoader;
}

typedef TSceneEvents = {
  initialize: InitializeEvent<Scene>,
  activate: ActivateEvent,
  deactivate: DeactivateEvent,
  preupdate: PreUpdateEvent<Scene>,
  postupdate: PostUpdateEvent<Scene>,
  predraw: PreDrawEvent,
  postdraw: PostDrawEvent,
  predebugdraw: PreDebugDrawEvent,
  postdebugdraw: PostDebugDrawEvent,
  preload: PreLoadEvent,
  transitionstart: Transition,
  transitionend: Transition,
};

final SceneEvents = {
  Initialize: 'initialize',
  Activate: 'activate',
  Deactivate: 'deactivate',
  PreUpdate: 'preupdate',
  PostUpdate: 'postupdate',
  PreDraw: 'predraw',
  PostDraw: 'postdraw',
  PreDebugDraw: 'predebugdraw',
  PostDebugDraw: 'postdebugdraw',
  PreLoad: 'preload',
  TransitionStart: 'transitionstart',
  TransitionEnd: 'transitionend'
};

/**
 * {@apilink Actor | `Actors`} are composed together into groupings called Scenes in
 * Excalibur. The metaphor models the same idea behind real world
 * actors in a scene. Only actors in scenes will be updated and drawn.
 *
 * Typical usages of a scene include: levels, menus, loading screens, etc.
 *
 * Scenes go through the following lifecycle
 * 1. onPreLoad - called once
 * 2. onInitialize - called once
 * 3. onActivate - called the first frame the scene is current
 * 4. onPreUpdate - called every update
 * 5. onPostUpdate - called every update
 * 6. onPreDraw - called every draw
 * 7. onPostDraw - called every draw
 * 8. onDeactivate - called teh first frame thescene is no longer current
 *
 */
class Scene implements CanInitialize implements CanActivate implements CanDeactivate implements CanUpdate implements CanDraw {
  private var _logger: Logger = Logger.getInstance();
  public var events = new EventEmitter<SceneEvents>();

  public static function isSceneConstructor(x: Any) {
    return !!x?.prototype && !!x?.prototype?.constructor?.name;
  }

  /**
   * Gets or sets the current camera for the scene
   */
  public var camera: Camera = new Camera();

  /**
   * Scene specific background color
   */
  public var backgroundColor: Null<Color>;

  /**
   * The ECS world for the scene
   */
  public var world: World = new World(this);

  /**
   * The Excalibur physics world for the scene. Used to interact
   * with colliders included in the scene.
   *
   * Can be used to perform scene ray casts, track colliders, broadphase, and narrowphase.
   */
  public var physics = new PhysicsWorld(getDefaultPhysicsConfig());

  /**
   * The actors in the current scene
   */
  public var actors(get, never): Array<Actor>;
  function get_actors(): Array<Actor> {
    return this.world.entityManager.entities.filter((e: Entity<Any>) -> {
      return e;
    });
  }

  /**
   * The entities in the current scene
   */
  public var entities(get, never): Array<Entity>;
  function get_entities(): Array<Entity> {
    return this.world.entityManager.entities;
  }

  /**
   * The triggers in the current scene
   */
  public var triggers(get, never): Array<Trigger>;
  function get_triggers(): Array<Trigger> {
    return this.world.entityManager.entities.filter((e: Entity<Any>) -> {
      return e;
    });
  }

  /**
   * The {@apilink TileMap}s in the scene, if any
   */
  public var tileMaps(get, never): Array<TileMap>;
  function get_tileMaps(): Array<TileMap> {
    return this.world.entityManager.entities.filter((e: Entity<Any>) -> {
      return e;
    });
  }

  /**
   * Access to the Excalibur engine
   */
  public var engine: Engine;

  /**
   * Access scene specific input, handlers on this only fire when this scene is active.
   */
  public var input: InputHost;

  private var _isInitialized: Bool = false;
  private var _timers: Array<Timer> = [];
  public var timers(get, never): Array<Timer>;
  function get_timers(): Array<Timer> {
    return this._timers;
  }
  private var _cancelQueue: Array<Timer> = [];

  public function new() {
    // Initialize systems

    // Update
    this.world.add(ActionsSystem);
    this.world.add(new MotionSystem(this.world, this.physics));
    this.world.add(new CollisionSystem(this.world, this.physics));
    this.world.add(PointerSystem);
    this.world.add(IsometricEntitySystem);
    // Draw
    this.world.add(OffscreenSystem);
    this.world.add(GraphicsSystem);
    this.world.add(DebugSystem);
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

  /**
   * Event hook to provide Scenes a way of loading scene specific resources.
   *
   * This is called before the Scene.onInitialize during scene transition. It will only ever fire once for a scene.
   * @param loader
   */
  public function onPreLoad(loader: DefaultLoader) {
    // will be overridden
  }

  /**
   * Event hook fired directly before transition, either "in" or "out" of the scene
   *
   * This overrides the Engine scene definition. However transitions specified in goToScene take highest precedence
   *
   * ```typescript
   * // Overrides all
   * Engine.goToScene('scene', { destinationIn: ..., sourceOut: ... });
   * ```
   *
   * This can be used to configure custom transitions for a scene dynamically
   */
  public function onTransition(direction: String): Null<Transition> {
    // will be overridden
    return null;
  }

  /**
   * This is called before the first update of the {@apilink Scene}. Initializes scene members like the camera. This method is meant to be
   * overridden. This is where initialization of child actors should take place.
   */
  public function onInitialize(engine: Engine): Void {
    // will be overridden
  }

  /**
   * This is called when the scene is made active and started. It is meant to be overridden,
   * this is where you should setup any DOM UI or event handlers needed for the scene.
   */
  public function onActivate(context: SceneActivationContext<TActivationData>): Void {
    // will be overridden
  }

  /**
   * This is called when the scene is made transitioned away from and stopped. It is meant to be overridden,
   * this is where you should cleanup any DOM UI or event handlers needed for the scene.
   * @returns Either data to pass to the next scene activation context as `previousSceneData` or nothing
   */
  public function onDeactivate(context: SceneActivationContext): Null<Any> {
    // will be overridden
  }

  /**
   * Safe to override onPreUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreUpdate` is called directly before a scene is updated.
   * @param engine reference to the engine
   * @param elapsed  Number of milliseconds elapsed since the last draw.
   */
  public function onPreUpdate(engine: Engine, elapsed: Int): Void {
    // will be overridden
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after a scene is updated.
   * @param engine reference to the engine
   * @param elapsed  Number of milliseconds elapsed since the last draw.
   */
  public function onPostUpdate(engine: Engine, elapsed: Int): Void {
    // will be overridden
  }

  /**
   * Safe to override onPreDraw lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreDraw` is called directly before a scene is drawn.
   *
   */
  public function onPreDraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void {
    // will be overridden
  }

  /**
   * Safe to override onPostDraw lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPostDraw` is called directly after a scene is drawn.
   *
   */
  public function onPostDraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void {
    // will be overridden
  }

  /**
   * Initializes actors in the scene
   */
  private function _initializeChildren() {
    for (child in this.entities) {
      child._initialize(this.engine);
    }
  }

  /**
   * Gets whether or not the {@apilink Scene} has been initialized
   */
  public var isInitialized(get, never): Bool;
  function get_isInitialized(): Bool {
    return this._isInitialized;
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Initializes the scene before the first update, meant to be called by engine not by users of
   * Excalibur
   * @internal
   */
  public function _initialize(engine: Engine) {
    if (!this.isInitialized) {
      try {
        this.engine = engine;
        // PhysicsWorld config is watched so things will automagically update
        this.physics.config = this.engine.physics;
        this.input = new InputHost({
          global: engine.global,
          pointerTarget: engine.pointerScope == PointerScope.Canvas ? engine.canvas : document,
          grabWindowFocus: engine.grabWindowFocus,
          engine: engine
        });
        // Initialize camera first
        this.camera._initialize(engine);

        this.world.systemManager.initialize();

        // This order is important! we want to be sure any custom init that add actors
        // fire before the actor init
        this.onInitialize(engine).then(() -> {
          this._initializeChildren();

          this._logger.debug('Scene.onInitialize', this, engine);
          this.events.emit('initialize', new InitializeEvent(engine, this));
          this._isInitialized = true;
        });
      } catch (e) {
        this._logger.error('Error during scene initialization for scene ${engine.director?.getSceneName(this)}!');
        this._isInitialized = true;
        throw e;
      }
    }
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Activates the scene with the base behavior, then calls the overridable `onActivate` implementation.
   * @internal
   */
  public function _activate(context: SceneActivationContext<TActivationData>): Promise<Void> {
    try {
      this._logger.debug('Scene.onActivate', this);
      this.input.toggleEnabled(true);
      return this.onActivate(context);
    } catch (e) {
      this._logger.error('Error during scene activation for scene ${this.engine?.director?.getSceneName(this)}!');
      throw e;
    }
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Deactivates the scene with the base behavior, then calls the overridable `onDeactivate` implementation.
   * @internal
   */
  public function _deactivate(context: SceneActivationContext): Promise<Any> {
    this._logger.debug('Scene.onDeactivate', this);
    this.input.toggleEnabled(false);
    return this.onDeactivate(context);
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPreUpdate} lifecycle event
   * @internal
   */
  public function _preupdate(engine: Engine, elapsed: Int): Void {
    this.emit('preupdate', new PreUpdateEvent(engine, elapsed, this));
    this.onPreUpdate(engine, elapsed);
  }

  /**
   *  It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _preupdate handler for {@apilink onPostUpdate} lifecycle event
   * @internal
   */
  public function _postupdate(engine: Engine, elapsed: Int): Void {
    this.emit('postupdate', new PostUpdateEvent(engine, elapsed, this));
    this.onPostUpdate(engine, elapsed);
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _predraw handler for {@apilink onPreDraw} lifecycle event
   * @internal
   */
  public function _predraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void {
    this.emit('predraw', new PreDrawEvent(ctx, elapsed, this));
    this.onPreDraw(ctx, elapsed);
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _postdraw handler for {@apilink onPostDraw} lifecycle event
   * @internal
   */
  public function _postdraw(ctx: ExcaliburGraphicsContext, elapsed: Int): Void {
    this.emit('postdraw', new PostDrawEvent(ctx, elapsed, this));
    this.onPostDraw(ctx, elapsed);
  }

  /**
   * Updates all the actors and timers in the scene. Called by the {@apilink Engine}.
   * @param engine  Reference to the current Engine
   * @param elapsed  The number of milliseconds since the last update
   */
  public function update(engine: Engine, elapsed: Int) {
    if (!this.isInitialized) {
      this._logger.warnOnce('Scene update called before initialize for scene ${engine.director?.getSceneName(this)}!');
      return;
    }
    this._preupdate(engine, elapsed);

    // Remove timers in the cancel queue before updating them
    for (timer in this._cancelQueue) {
      this.removeTimer(timer);
    }
    this._cancelQueue = [];

    // Cycle through timers updating timers
    for (timer in this._timers) {
      timer.update(elapsed);
    }

    this.world.update(SystemType.Update, elapsed);

    // Camera last keeps renders smooth that are based on entity/actor
    if (this.camera) {
      this.camera.update(engine, elapsed);
    }

    this._collectActorStats(engine);

    this._postupdate(engine, elapsed);

    this.input.update();
  }

  /**
   * Draws all the actors in the Scene. Called by the {@apilink Engine}.
   * @param ctx    The current rendering context
   * @param elapsed  The number of milliseconds since the last draw
   */
  public function draw(ctx: ExcaliburGraphicsContext, elapsed: Int) {
    if (!this.isInitialized) {
      this._logger.warnOnce('Scene draw called before initialize!');
      return;
    }
    this._predraw(ctx, elapsed);

    this.world.update(SystemType.Draw, elapsed);

    if (this.engine?.isDebug) {
      this.debugDraw(ctx);
    }
    this._postdraw(ctx, elapsed);
  }

  /**
   * Draws all the actors' debug information in the Scene. Called by the {@apilink Engine}.
   * @param ctx  The current rendering context
   */
  /* istanbul ignore next */
  public function debugDraw(ctx: ExcaliburGraphicsContext) {
    this.emit('predebugdraw', new PreDebugDrawEvent(ctx, this));
    // pass
    this.emit('postdebugdraw', new PostDebugDrawEvent(ctx, this));
  }

  /**
   * Checks whether an actor is contained in this scene or not
   */
  public function contains(actor: Actor): Bool {
    return this.actors.indexOf(actor) > -1;
  }

  public function add(entity: Any): Void {
    this.emit('entityadded', { target: entity });
    if (Std.isTypeOf(entity, Timer)) {
      if (!Util.contains(this._timers, entity)) {
        this.addTimer(entity);
      }
      return;
    }
    this.world.add(entity);
    entity.scene = this;
  }

  /**
   * Removes an {@apilink Entity} (Actor, TileMap, Trigger, etc) or {@apilink Timer} from it's current scene
   * and adds it to this scene.
   *
   * Useful if you want to have an object be present in only 1 scene at a time.
   * @param entity
   */
  public function transfer(entity: Actor): Void {
    var scene: Scene;
    if (Std.isTypeOf(entity, Entity) && entity.scene && entity.scene != this) {
      scene = entity.scene;
      entity.scene.world.remove(entity, false);
    }
    if (Std.isTypeOf(entity, Timer) && entity.scene) {
      scene = entity.scene;
      entity.scene.removeTimer(entity);
    }

    scene?.emit('entityremoved', { target: entity });
    this.add(entity);
  }

  public function remove(entity: Any): Void {
    this.emit('entityremoved', { target: entity });
    if (Std.isTypeOf(entity, Entity)) {
      if (entity.isActive) {
        entity.kill();
      }
      this.world.remove(entity);
    }
    if (Std.isTypeOf(entity, Timer)) {
      this.removeTimer(entity);
    }
  }

  /**
   * Removes all entities and timers from the scene, optionally indicate whether deferred should or shouldn't be used.
   *
   * By default entities use deferred removal
   * @param deferred
   */
  public function clear(deferred: Bool = true): Void {
    var index = this.entities.length;
    while (index > 0) {
      index--;
      this.world.remove(this.entities[index], deferred);
    }
    index = this.timers.length;
    while (index > 0) {
      index--;
      this.removeTimer(this.timers[index]);
    }
  }

  /**
   * Adds a {@apilink Timer} to the scene
   * @param timer  The timer to add
   */
  public function addTimer(timer: Timer): Timer {
    this._timers.push(timer);
    timer.scene = this;
    return timer;
  }

  /**
   * Removes a {@apilink Timer} from the scene.
   * @warning Can be dangerous, use {@apilink cancelTimer} instead
   * @param timer  The timer to remove
   */
  public function removeTimer(timer: Timer): Timer {
    final i = this._timers.indexOf(timer);
    if (i != -1) {
      this._timers.splice(i, 1);
    }
    return timer;
  }

  /**
   * Cancels a {@apilink Timer}, removing it from the scene nicely
   * @param timer  The timer to cancel
   */
  public function cancelTimer(timer: Timer): Timer {
    this._cancelQueue.push(timer);
    return timer;
  }

  /**
   * Tests whether a {@apilink Timer} is active in the scene
   */
  public function isTimerActive(timer: Timer): Bool {
    return this._timers.indexOf(timer) > -1 && !timer.complete;
  }

  public function isCurrentScene(): Bool {
    if (this.engine) {
      return this.engine.currentScene == this;
    }
    return false;
  }

  private function _collectActorStats(engine: Engine) {
    final actors = this.actors;
    for (actor in actors) {
      if (Std.isOfType(actor, ScreenElement)) {
        engine.stats.currFrame.actors.ui++;
      }
      engine.stats.currFrame.actors.alive++;
      for (child in actor.children) {
        if (isScreenElement(child)) {
          // TODO not true
          engine.stats.currFrame.actors.ui++;
        } else {
          engine.stats.currFrame.actors.alive++;
        }
      }
    }
  }
}
