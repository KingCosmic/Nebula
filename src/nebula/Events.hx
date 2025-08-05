package nebula;

import nebula.Scene;
import nebula.Math.Vector;
import nebula.Actor;
import nebula.Trigger;
import nebula.Debug;
import nebula.Engine;
import nebula.TileMap;
import nebula.Collision.Side;
import nebula.Collision.Detection.CollisionContact;
import nebula.Collision.Colliders.Collider;
import nebula.EntityComponentSystem.Entity;
import nebula.Interfaces.LifecycleEvents;
import nebula.Graphics;
import nebula.Input.Gamepad;
import nebula.Actions.Action;

enum EventTypes {
  Kill;
  PreKill;
  PostKill;

  PreDraw;
  PostDraw;

  PreDebugDraw;
  PostDebugDraw;

  PreUpdate;
  PostUpdate;

  PreFrame;
  PostFrame;

  PreCollision;
  CollisionStart;
  CollisionEnd;
  PostCollision;

  Initialize;
  Activate;
  Deactivate;

  ExitViewport;
  EnterViewport;

  ExitTrigger;
  EnterTrigger;

  Connect;
  Disconnect;
  Button;
  Axis;

  Visible;
  Hidden;
  Start;
  Stop;

  PointerUp;
  PointerDown;
  PointerMove;
  PointerEnter;
  PointerLeave;
  PointerCancel;
  PointerWheel;

  Up;
  Down;
  Move;
  Enter;
  Leave;
  Cancel;
  Wheel;

  Press;
  Release;
  Hold;

  PointerDragStart;
  PointerDragEnd;
  PointerDragEnter;
  PointerDragLeave;
  PointerDragMove;

  ActionStart;
  ActionComplete;

  Add;
  Remove;
}

/**
 * Base event type in Excalibur that all other event types derive from. Not all event types are thrown on all Excalibur game objects,
 * some events are unique to a type, others are not.
 *
 */
class GameEvent<T, U = T> {
  /**
   * Target object for this event.
   */
  public var target: T;

  /**
   * Other target object for this event
   */
  public var other: Null<U> = null;

  /**
   * If set to false, prevents event from propagating to other actors. If true it will be propagated
   * to all actors that apply.
   */
  public var bubbles(get, set): Bool;
  function get_bubbles(): Bool {
    return this._bubbles;
  }
  function set_bubbles(value: Bool) {
    this._bubbles = value;
  }

  private var _bubbles: Bool = true;
  /**
   * Prevents event from bubbling
   */
  public function stopPropagation() {
    this.bubbles = false;
  }
}

/**
 * The 'kill' event is emitted on actors when it is killed. The target is the actor that was killed.
 */
class KillEvent extends GameEvent<Entity> {
  public function new(self: Entity) {
    super();
    this.target = self;
  }
}

/**
 * The 'prekill' event is emitted directly before an actor is killed.
 */
class PreKillEvent extends GameEvent<Actor> {
  public function new(self: Actor) {
    super();
    this.target = self;
  }
}

/**
 * The 'postkill' event is emitted directly after the actor is killed.
 */
class PostKillEvent extends GameEvent<Actor> {
  public function new(self: Actor) {
    super();
    this.target = self;
  }
}

/**
 * The 'start' event is emitted on engine when has started and is ready for interaction.
 */
class GameStartEvent extends GameEvent<Engine> {
  public function new(self: Engine) {
    super();
    this.target = self;
  }
}

/**
 * The 'stop' event is emitted on engine when has been stopped and will no longer take input, update or draw.
 */
class GameStopEvent extends GameEvent<Engine> {
  public function new(self: Engine) {
    super();
    this.target = self;
  }
}

/**
 * The 'predraw' event is emitted on actors, scenes, and engine before drawing starts. Actors' predraw happens inside their graphics
 * transform so that all drawing takes place with the actor as the origin.
 *
 */
enum EitherOr4<A, B, C, D> {
  First(a: A);
  Second(b: B);
  Third(c: C);
  Fourth(d: D);
}
typedef EntitySceneEngineTileMap = EitherOr4<Entity, Scene, Engine, TileMap>;

class PreDrawEvent extends GameEvent<EntitySceneEngineTileMap> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    elapsed: Int,
    self: EntitySceneEngineTileMap
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'postdraw' event is emitted on actors, scenes, and engine after drawing finishes. Actors' postdraw happens inside their graphics
 * transform so that all drawing takes place with the actor as the origin.
 *
 */
class PostDrawEvent extends GameEvent<EntitySceneEngineTileMap> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    elapsed: Int,
    self: EntitySceneEngineTileMap
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'pretransformdraw' event is emitted on actors/entities before any graphics transforms have taken place.
 * Useful if you need to completely customize the draw or modify the transform before drawing in the draw step (for example needing
 * latest camera positions)
 *
 */
class PreTransformDrawEvent extends GameEvent<Entity> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    elapsed: Int,
    self: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'posttransformdraw' event is emitted on actors/entities after all graphics have been draw and transforms reset.
 * Useful if you need to completely custom the draw after everything is done.
 *
 */
class PostTransformDrawEvent extends GameEvent<Entity> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    elapsed: Int,
    self: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'predebugdraw' event is emitted on actors, scenes, and engine before debug drawing starts.
 */
typedef EntityActorSceneEngine = EitherOr4<Entity, Actor, Scene, Engine>;

class PreDebugDrawEvent extends GameEvent<EntityActorSceneEngine> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    self: EntityActorSceneEngine
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'postdebugdraw' event is emitted on actors, scenes, and engine after debug drawing starts.
 */
class PostDebugDrawEvent extends GameEvent<EntityActorSceneEngine> {
  public function new(
    ctx: ExcaliburGraphicsContext,
    self: EntityActorSceneEngine
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'preupdate' event is emitted on actors, scenes, camera, and engine before the update starts.
 */
typedef ActorSceneCameraEngine = EitherOr4<Actor, Scene, Camera, Engine>;

class PreUpdateEvent<ActorSceneCameraEngine> extends GameEvent<ActorSceneCameraEngine> {
  public function new(
    engine: Engine,
    elapsed: Int,
    self: ActorSceneCameraEngine
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'postupdate' event is emitted on actors, scenes, camera, and engine after the update ends.
 */
class PostUpdateEvent<ActorSceneCameraEngine> extends GameEvent<ActorSceneCameraEngine> {
  public function new(
    engine: Engine,
    elapsed: Int,
    self: ActorSceneCameraEngine
  ) {
    super();
    this.target = self;
  }
}

/**
 * The 'preframe' event is emitted on the engine, before the frame begins.
 */
class PreFrameEvent extends GameEvent<Engine> {
  public function new(
    engine: Engine,
    prevStats: FrameStats
  ) {
    super();
    this.target = engine;
  }
}

/**
 * The 'postframe' event is emitted on the engine, after a frame ends.
 */
class PostFrameEvent extends GameEvent<Engine> {
  public function new(
    engine: Engine,
    stats: FrameStats
  ) {
    super();
    this.target = engine;
  }
}

/**
 * Event received when a gamepad is connected to Excalibur. {@apilink Gamepads} receives this event.
 */
class GamepadConnectEvent extends GameEvent<Gamepad> {
  public function new(
    index: Int,
    gamepad: Gamepad
  ) {
    super();
    this.target = gamepad;
  }
}

/**
 * Event received when a gamepad is disconnected from Excalibur. {@apilink Gamepads} receives this event.
 */
class GamepadDisconnectEvent extends GameEvent<Gamepad> {
  public function new(
    index: Int,
    gamepad: Gamepad
  ) {
    super();
    this.target = gamepad;
  }
}

/**
 * Gamepad button event. See {@apilink Gamepads} for information on responding to controller input. {@apilink Gamepad} instances receive this event;
 */
class GamepadButtonEvent extends GameEvent<Gamepad> {
  /**
   * @param button  The Gamepad {@apilink Buttons} if not known by excalibur {@apilink Buttons.Unknown} is returned, use index to disambiguate.
   * @param index   The canonical index of the gamepad button from the system
   * @param value   A numeric value between 0 and 1
   * @param self    Reference to the gamepad
   */
  public function new(
    /**
     * The Gamepad {@apilink Buttons} if not known by excalibur {@apilink Buttons.Unknown} is returned, use index to disambiguate.
     */
    button: Buttons,
    /**
     * The canonical index of the gamepad button from the system
     */
    index: Int,
    /**
     * A numeric value between 0 and 1
     */
    value: Float,
    /**
     * Reference to the gamepad
     */
    self: Gamepad
  ) {
    super();
    this.target = self;
  }
}

/**
 * Gamepad axis event. See {@apilink Gamepads} for information on responding to controller input. {@apilink Gamepad} instances receive this event;
 */
class GamepadAxisEvent extends GameEvent<Gamepad> {
  /**
   * @param axis  The Gamepad axis
   * @param value A numeric value between -1 and 1
   * @param self Reference to the gamepad
   */
  public function new(
    /**
     * The Gamepad {@apilink Axis}
     */
    axis: Axes,
    /**
     * A numeric value between -1 and 1, 0 is the neutral axis position.
     */
    value: Float,
    /**
     * Reference to the gamepad
     */
    self: Gamepad
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event received by the {@apilink Engine} when the browser window is visible on a screen.
 */
class VisibleEvent extends GameEvent<Engine> {
  public function new(self: Engine) {
    super();
    this.target = self;
  }
}

/**
 * Event received by the {@apilink Engine} when the browser window is hidden from all screens.
 */
class HiddenEvent extends GameEvent<Engine> {
  public function new(self: Engine) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor | `actor`} when a collision will occur this frame if it resolves
 */
class PreCollisionEvent<Collider> extends GameEvent<Collider> {
  /**
   * @param self          The actor the event was thrown on
   * @param other         The actor that will collided with the current actor
   * @param side          The side that will be collided with the current actor
   * @param intersection  Intersection vector
   */
  public function new(
    self: T,
    other: T,
    side: Side,
    intersection: Vector,
    contact: CollisionContact
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor | `actor`} when a collision has been resolved (body reacted) this frame
 */
class PostCollisionEvent<Collider> extends GameEvent<Collider> {
  /**
   * @param self          The actor the event was thrown on
   * @param other         The actor that did collide with the current actor
   * @param side          The side that did collide with the current actor
   * @param intersection  Intersection vector
   */
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    intersection: Vector,
    contact: CollisionContact
  ) {
    super();
    this.target = self;
  }
}

class ContactStartEvent<Collider> {
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    contact: CollisionContact
  ) {}
}

class ContactEndEvent<Collider> {
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    lastContact: CollisionContact
  ) {}
}

class CollisionPreSolveEvent<Collider> {
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    intersection: Vector,
    contact: CollisionContact
  ) {}
}

class CollisionPostSolveEvent<Collider> {
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    intersection: Vector,
    contact: CollisionContact
  ) {}
}

/**
 * Event thrown the first time an {@apilink Actor | `actor`} collides with another, after an actor is in contact normal collision events are fired.
 */
class CollisionStartEvent<Collider> extends GameEvent<Collider> {
  /**
   *
   * @param self
   * @param other
   * @param side
   * @param contact
   */
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    contact: CollisionContact
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown when the {@apilink Actor | `actor`} is no longer colliding with another
 */
class CollisionEndEvent<Collider> extends GameEvent<Collider> {
  /**
   *
   */
  public function new(
    self: Collider,
    other: Collider,
    side: Side,
    lastContact: CollisionContact
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor}, {@apilink Scene}, and {@apilink Engine} only once before the first update call
 */
class InitializeEvent<Entity> extends GameEvent<Entity> {
  /**
   * @param engine  The reference to the current engine
   */
  public function new(
    engine: Engine,
    self: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on a {@apilink Scene} on activation
 */
class ActivateEvent extends GameEvent<Scene> {
  /**
   * @param context  The context for the scene activation
   */
  public function new(
    context: SceneActivationContext<Scene>,
    self: Scene
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on a {@apilink Scene} on deactivation
 */
class DeactivateEvent extends GameEvent<Scene> {
  /**
   * @param context  The context for the scene deactivation
   */
  public function new(
    context: SceneActivationContext,
    self: Scene
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor} when the graphics bounds completely leaves the screen.
 */
class ExitViewPortEvent extends GameEvent<Entity> {
  public function new(self: Entity) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor} when any part of the graphics bounds are on screen.
 */
class EnterViewPortEvent extends GameEvent<Entity> {
  public function new(self: Entity) {
    super();
    this.target = self;
  }
}

class EnterTriggerEvent extends GameEvent<Trigger> {
  public function new(
    self: Trigger,
    entity: Entity
  ) {
    super();
    this.target = self;
  }
}

class ExitTriggerEvent extends GameEvent<Trigger> {
  public function new(
    self: Trigger,
    entity: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor} when an action starts.
 */
class ActionStartEvent extends GameEvent<Entity> {
  public function new(
    action: Action,
    self: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an {@apilink Actor} when an action completes.
 */
class ActionCompleteEvent extends GameEvent<Entity> {
  public function new(
    action: Action,
    self: Entity
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an [[Actor]] when an Actor added to scene.
 */
class AddEvent<Actor> extends GameEvent<Actor> {
  public function new(
    engine: Engine,
    self: T
  ) {
    super();
    this.target = self;
  }
}

/**
 * Event thrown on an [[Actor]] when an Actor removed from scene.
 */
class RemoveEvent<Actor> extends GameEvent<Actor> {
  public function new(
    engine: Engine,
    self: T
  ) {
    super();
    this.target = self;
  }
}
