package nebula;

import nebula.Events;
import nebula.Engine;
import nebula.Color;
import nebula.Interfaces.LifecycleEvents;
import nebula.Scene;
import nebula.Util.Log;
import nebula.Math.Vector;
import nebula.Collision.CollisionType;
import nebula.EntityComponentSystem.Entity;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.Graphics.GraphicsComponent;
import nebula.Graphics.Rectangle;
import nebula.Collision.ColliderComponent;
import nebula.Collision.Colliders.Shape;
import nebula.Util.Watch;
import nebula.Collision.Index;
import nebula.Graphics.Circle;
import nebula.Input.PointerEvent;
import nebula.Input.WheelEvent;
import nebula.Input.PointerComponent;
import nebula.Actions.ActionsComponent;
import nebula.Math.CoordPlane;
import nebula.EventEmitter;
import nebula.EntityComponentSystem;
import nebula.EntityComponentSystem.Entity;

/**
 * Type guard for checking if something is an Actor
 * @param x
 */
function isActor(x: Any) {
  return Std.isTypeOf(x, Actor);
}

/**
 * Actor constructor options
 */
typedef ActorArgs = TColliderArgs & {
  /**
   * Optionally set the name of the actor, default is 'anonymous'
   */
  var name: Null<String>;
  /**
   * Optionally set the x position of the actor, default is 0
   */
  var x: Null<Int>;
  /**
   * Optionally set the y position of the actor, default is 0
   */
  var y: Null<Int>;
  /**
   * Optionally set the (x, y) position of the actor as a vector, default is (0, 0)
   */
  var pos: Null<Vector>;
  /**
   * Optionally set the coordinate plane of the actor, default is {@apilink CoordPlane.World} meaning actor is subject to camera positioning
   */
  var coordPlane: Null<CoordPlane>;
  /**
   * Optionally set the velocity of the actor in pixels/sec
   */
  var vel: Null<Vector>;
  /**
   * Optionally set the acceleration of the actor in pixels/sec^2
   */
  var acc: Null<Vector>;
  /**
   * Optionally se the rotation in radians (180 degrees = Math.PI radians)
   */
  var rotation: Null<Float>;
  /**
   * Optionally set the angular velocity of the actor in radians/sec (180 degrees = Math.PI radians)
   */
  var angularVelocity: Null<Float>;
  /**
   * Optionally set the scale of the actor's transform
   */
  var scale: Null<Vector>;
  /**
   * Optionally set the z index of the actor, default is 0
   */
  var z: Null<Int>;
  /**
   * Optionally set the color of an actor, only used if no graphics are present
   * If a width/height or a radius was set a default graphic will be added
   */
  var color: Null<Color>;
  /**
   * Optionally set the color of an actor, only used if no graphics are present
   * If a width/height or a radius was set a default graphic will be added
   */
  var opacity: Null<Float>;
  /**
   * Optionally set the visibility of the actor
   */
  var visible: Null<Bool>;
  /**
   * Optionally set the anchor for graphics in the actor
   */
  var anchor: Null<Vector>;
  /**
   * Optionally set the anchor for graphics in the actor
   */
  var offset: Null<Vector>;
  /**
   * Optionally set the collision type
   */
  var collisionType: Null<CollisionType>;
  /**
   * Optionally supply a {@apilink CollisionGroup}
   */
  var collisionGroup: Null<CollisionGroup>;
  /**
   * Optionally silence excalibur warning warnings
   */
  var silenceWarnings: Null<Bool>;
};

typedef TColliderArgs = {
  /**
   * Optionally supply a collider for an actor, if supplied ignores any supplied width/height
   *
   * No default graphigc is created in this case
   */
  collider: Null<Collider>,
  width: Null<Int>,
  height: Null<Int>,
  radius: Null<Int>,
  color: Null<Color>
};

typedef TActorEvents = EntityEvents & {
  collisionstart: CollisionStartEvent,
  collisionend: CollisionEndEvent,
  precollision: PreCollisionEvent,
  postcollision: PostCollisionEvent,
  kill: KillEvent,
  prekill: PreKillEvent,
  postkill: PostKillEvent,
  predraw: PreDrawEvent,
  postdraw: PostDrawEvent,
  pretransformdraw: PreDrawEvent,
  posttransformdraw: PostDrawEvent,
  predebugdraw: PreDebugDrawEvent,
  postdebugdraw: PostDebugDrawEvent,
  pointerup: PointerEvent,
  pointerdown: PointerEvent,
  pointerenter: PointerEvent,
  pointerleave: PointerEvent,
  pointermove: PointerEvent,
  pointercancel: PointerEvent,
  pointerwheel: WheelEvent,
  pointerdragstart: PointerEvent,
  pointerdragend: PointerEvent,
  pointerdragenter: PointerEvent,
  pointerdragleave: PointerEvent,
  pointerdragmove: PointerEvent,
  enterviewport: EnterViewPortEvent,
  exitviewport: ExitViewPortEvent,
  actionstart: ActionStartEvent,
  actioncomplete: ActionCompleteEvent,
};

var ActorEvents = {
  CollisionStart: 'collisionstart',
  CollisionEnd: 'collisionend',
  PreCollision: 'precollision',
  PostCollision: 'postcollision',
  Kill: 'kill',
  PreKill: 'prekill',
  PostKill: 'postkill',
  PreDraw: 'predraw',
  PostDraw: 'postdraw',
  PreTransformDraw: 'pretransformdraw',
  PostTransformDraw: 'posttransformdraw',
  PreDebugDraw: 'predebugdraw',
  PostDebugDraw: 'postdebugdraw',
  PointerUp: 'pointerup',
  PointerDown: 'pointerdown',
  PointerEnter: 'pointerenter',
  PointerLeave: 'pointerleave',
  PointerMove: 'pointermove',
  PointerCancel: 'pointercancel',
  Wheel: 'pointerwheel',
  PointerDrag: 'pointerdragstart',
  PointerDragEnd: 'pointerdragend',
  PointerDragEnter: 'pointerdragenter',
  PointerDragLeave: 'pointerdragleave',
  PointerDragMove: 'pointerdragmove',
  EnterViewPort: 'enterviewport',
  ExitViewPort: 'exitviewport',
  ActionStart: 'actionstart',
  ActionComplete: 'actioncomplete'
};

/**
 * The most important primitive in Excalibur is an `Actor`. Anything that
 * can move on the screen, collide with another `Actor`, respond to events,
 * or interact with the current scene, must be an actor. An `Actor` **must**
 * be part of a {@apilink Scene} for it to be drawn to the screen.
 */
class Actor extends Entity implements Eventable implements PointerEvents implements CanInitialize implements CanUpdate implements CanBeKilled {
  public var events = new EventEmitter<TActorEvents>();
  // #region Properties

  /**
   * Set defaults for all Actors
   */
  public static var defaults = {
    anchor: Vector.Half
  };

  /**
   * The physics body the is associated with this actor. The body is the container for all physical properties, like position, velocity,
   * acceleration, mass, inertia, etc.
   */
  public var body: BodyComponent;

  /**
   * Access the Actor's built in {@apilink TransformComponent}
   */
  public var transform: TransformComponent;

  /**
   * Access the Actor's built in {@apilink MotionComponent}
   */
  public var motion: MotionComponent;

  /**
   * Access to the Actor's built in {@apilink GraphicsComponent}
   */
  public var graphics: GraphicsComponent;

  /**
   * Access to the Actor's built in {@apilink ColliderComponent}
   */
  public var collider: ColliderComponent;

  /**
   * Access to the Actor's built in {@apilink PointerComponent} config
   */
  public var pointer: PointerComponent;

  /**
   * Useful for quickly scripting actor behavior, like moving to a place, patrolling back and forth, blinking, etc.
   *
   *  Access to the Actor's built in {@apilink ActionsComponent} which forwards to the
   * {@apilink ActionContext | `Action context`} of the actor.
   */
  public var actions: ActionsComponent;
  private var _silenceWarnings: Bool;

  /**
   * Gets the position vector of the actor in pixels
   */
  public var pos(get, set): Vector;
  function get_pos(): Vector {
    return this.transform.pos;
  }

  /**
   * Sets the position vector of the actor in pixels
   */
  function set_pos(thePos: Vector) {
    this.transform.pos = thePos.clone();
  }

  /**
   * Gets the position vector of the actor from the last frame
   */
  public var oldPos(get, set): Vector;
  function get_oldPos(): Vector {
    return this.body.oldPos;
  }
  /**
   * Sets the position vector of the actor in the last frame
   */
  function set_oldPos(thePos: Vector) {
    this.body.oldPos.setTo(thePos.x, thePos.y);
  }

  /**
   * Gets the global position vector of the actor from the last frame
   */
  public var oldGlobalPos(get, never): Vector;
  function get_oldGlobalPos(): Vector {
    return this.body.oldGlobalPos;
  }

  /**
   * Gets the velocity vector of the actor in pixels/sec
   */
  public var vel(get, set): Vector;
  function get_vel(): Vector {
    return this.motion.vel;
  }

  /**
   * Sets the velocity vector of the actor in pixels/sec
   */
  function set_vel(theVel: Vector) {
    this.motion.vel = theVel.clone();
  }

  /**
   * Gets the velocity vector of the actor from the last frame
   */
  public var oldVel(get, set): Vector;
  function get_oldVel(): Vector {
    return this.body.oldVel;
  }

  /**
   * Sets the velocity vector of the actor from the last frame
   */
  function set_oldVel(theVel: Vector) {
    this.body.oldVel.setTo(theVel.x, theVel.y);
  }

  /**
   * Gets the acceleration vector of the actor in pixels/second/second. An acceleration pointing down such as (0, 100) may be
   * useful to simulate a gravitational effect.
   */
  public var acc(get, set): Vector;
  function get_acc(): Vector {
    return this.motion.acc;
  }

  /**
   * Sets the acceleration vector of teh actor in pixels/second/second
   */
  function set_acc(theAcc: Vector) {
    this.motion.acc = theAcc.clone();
  }

  /**
   * Sets the acceleration of the actor from the last frame. This does not include the global acc {@apilink Physics.acc}.
   */
  public var oldAcc(get, set): Vector;
  function set_oldAcc(theAcc: Vector) {
    this.body.oldAcc.setTo(theAcc.x, theAcc.y);
  }

  /**
   * Gets the acceleration of the actor from the last frame. This does not include the global acc {@apilink Physics.acc}.
   */
  function get_oldAcc(): Vector {
    return this.body.oldAcc;
  }

  /**
   * Gets the rotation of the actor in radians. 1 radian = 180/PI Degrees.
   */
  public var rotation(get, set): Float;
  function get_rotation(): Float {
    return this.transform.rotation;
  }

  /**
   * Sets the rotation of the actor in radians. 1 radian = 180/PI Degrees.
   */
  function set_rotation(theAngle: Float) {
    this.transform.rotation = theAngle;
  }

  /**
   * Gets the rotational velocity of the actor in radians/second
   */
  public var angularVelocity(get, set): Float;
  function get_angularVelocity(): Float {
    return this.motion.angularVelocity;
  }

  /**
   * Sets the rotational velocity of the actor in radians/sec
   */
  function set_angularVelocity(angularVelocity: Float) {
    this.motion.angularVelocity = angularVelocity;
  }

  public var scale(get, set): Vector;
  function get_scale(): Vector {
    return this.get(TransformComponent).scale;
  }

  function set_scale(scale: Vector) {
    this.get(TransformComponent).scale = scale;
  }

  private var _anchor: Vector = watch(Vector.Half, (v) -> this._handleAnchorChange(v));
  /**
   * The anchor to apply all actor related transformations like rotation,
   * translation, and scaling. By default the anchor is in the center of
   * the actor. By default it is set to the center of the actor (.5, .5)
   *
   * An anchor of (.5, .5) will ensure that drawings are centered.
   *
   * Use `anchor.setTo` to set the anchor to a different point using
   * values between 0 and 1. For example, anchoring to the top-left would be
   * `Actor.anchor.setTo(0, 0)` and top-right would be `Actor.anchor.setTo(0, 1)`.
   */
  public var anchor(get, set): Vector;
  function get_anchor(): Vector {
    return this._anchor;
  }

  function set_anchor(vec: Vector) {
    this._anchor = watch(vec, (v) => this._handleAnchorChange(v));
    this._handleAnchorChange(vec);
  }

  private function _handleAnchorChange(v: Vector) {
    if (this.graphics) {
      this.graphics.anchor = v;
    }
  }

  private var _offset: Vector = watch(Vector.Zero, (v) -> this._handleOffsetChange(v));
  /**
   * The offset in pixels to apply to all actor graphics
   *
   * Default offset of (0, 0)
   */
  public var offset(get, set): Vector;
  function get_offset(): Vector {
    return this._offset;
  }
  function set_offset(vec: Vector) {
    this._offset = watch(vec, (v) -> this._handleOffsetChange(v));
    this._handleOffsetChange(vec);
  }

  private function _handleOffsetChange(v: Vector) {
    if (this.graphics) {
      this.graphics.offset = v;
    }
  }

  /**
   * Indicates whether the actor is physically in the viewport
   */
  public var isOffScreen(get, never): Bool;
  function get_isOffScreen(): Bool {
    return this.hasTag('ex.offscreen');
  }

  /**
   * Convenience reference to the global logger
   */
  public var logger: Logger = Logger.getInstance();

  /**
   * Draggable helper
   */
  private var _draggable: Bool = false;
  private var _dragging: Bool = false;

  private function _pointerDragStartHandler() {
    this._dragging = true;
  };

  private function _pointerDragEndHandler() {
    this._dragging = false;
  };

  private function _pointerDragMoveHandler(pe: PointerEvent) {
    if (this._dragging) {
      this.pos = pe.worldPos;
    }
  };

  private function _pointerDragLeaveHandler(pe: PointerEvent) {
    if (this._dragging) {
      this.pos = pe.worldPos;
    }
  };

  public var draggable(get, set): Bool;
  function get_draggable(): Bool {
    return this._draggable;
  }
  function set_draggable(isDraggable: Bool) {
    if (isDraggable) {
      if (isDraggable && !this._draggable) {
        this.events.on('pointerdragstart', this._pointerDragStartHandler);
        this.events.on('pointerdragend', this._pointerDragEndHandler);
        this.events.on('pointerdragmove', this._pointerDragMoveHandler);
        this.events.on('pointerdragleave', this._pointerDragLeaveHandler);
      } else if (!isDraggable && this._draggable) {
        this.events.off('pointerdragstart', this._pointerDragStartHandler);
        this.events.off('pointerdragend', this._pointerDragEndHandler);
        this.events.off('pointerdragmove', this._pointerDragMoveHandler);
        this.events.off('pointerdragleave', this._pointerDragLeaveHandler);
      }

      this._draggable = isDraggable;
    }
  }

  /**
   * Sets the color of the actor's current graphic
   */
  public var color(get, set): Color;
  function get_color(): Color {
    return this.graphics.color;
  }
  function set_color(v: Color) {
    this.graphics.color = v;
  }

  // #endregion

  /**
   *
   * @param config
   */
  public function new(?config: ActorArgs) {
    super();

    var name = config.name,
        x = config.x,
        y = config.y,
        pos = config.pos,
        coordPlane = config.coordPlane,
        scale = config.scale,
        width = config.width,
        height = config.height,
        radius = config.radius,
        collider = config.collider,
        vel = config.vel,
        acc = config.acc,
        rotation = config.rotation,
        angularVelocity = config.angularVelocity,
        z = config.z,
        color = config.color,
        visible = config.visible,
        opacity = config.opacity,
        anchor = config.anchor,
        offset = config.offset,
        collisionType = config.collisionType,
        collisionGroup = config.collisionGroup,
        silenceWarnings = config.silenceWarnings;

    this.name = name ?? this.name;
    this.anchor = anchor ?? Actor.defaults.anchor.clone();
    this.offset = offset ?? Vector.Zero;
    this.transform = new TransformComponent();
    this.addComponent(this.transform);
    this.pos = pos ?? vec(x ?? 0, y ?? 0);
    this.rotation = rotation ?? 0;
    this.scale = scale ?? vec(1, 1);
    this.z = z ?? 0;
    this.transform.coordPlane = coordPlane ?? CoordPlane.World;
    this._silenceWarnings = silenceWarnings ?? false;

    this.pointer = new PointerComponent();
    this.addComponent(this.pointer);

    this.graphics = new GraphicsComponent({
      anchor: this.anchor,
      offset: this.offset,
      opacity: opacity
    });
    this.addComponent(this.graphics);

    this.motion = new MotionComponent();
    this.addComponent(this.motion);
    this.vel = vel ?? Vector.Zero;
    this.acc = acc ?? Vector.Zero;
    this.angularVelocity = angularVelocity ?? 0;

    this.actions = new ActionsComponent();
    this.addComponent(this.actions);

    this.body = new BodyComponent();
    this.addComponent(this.body);
    this.body.collisionType = collisionType ?? CollisionType.Passive;
    if (collisionGroup) {
      this.body.group = collisionGroup;
    }

    if (color) {
      this.color = color;
    }

    if (collider) {
      this.collider = new ColliderComponent(collider);
      this.addComponent(this.collider);
    } else if (radius) {
      this.collider = new ColliderComponent(Shape.Circle(radius));
      this.addComponent(this.collider);

      if (color) {
        this.graphics.add(
          new Circle({
            color: color,
            radius: radius
          })
        );
      }
    } else {
      if (width > 0 && height > 0) {
        this.collider = new ColliderComponent(Shape.Box(width, height, this.anchor));
        this.addComponent(this.collider);

        if (color && width && height) {
          this.graphics.add(
            new Rectangle({
              color: color,
              width: width,
              height: height
            })
          );
        }
      } else {
        this.collider = new ColliderComponent();
        this.addComponent(this.collider); // no collider
      }
    }

    this.graphics.isVisible = visible ?? true;
  }

  public function clone(): Actor {
    var clone = new Actor({
      silenceWarnings: this._silenceWarnings,
      color: this.color.clone(),
      anchor: this.anchor.clone(),
      offset: this.offset.clone()
    });
    clone.clearComponents();
    clone.processComponentRemoval();

    // Clone builtins, order is important, same as ctor
    clone.addComponent((clone.transform = this.transform.clone()), true);
    clone.addComponent((clone.pointer = this.pointer.clone()), true);
    clone.addComponent((clone.graphics = this.graphics.clone()), true);
    clone.addComponent((clone.motion = this.motion.clone()), true);
    clone.addComponent((clone.actions = this.actions.clone()), true);
    clone.addComponent((clone.body = this.body.clone()), true);
    if (this.collider.get()) {
      clone.addComponent((clone.collider = this.collider.clone()), true);
    }

    var builtInComponents: Array<Component> = [
      this.transform,
      this.pointer,
      this.graphics,
      this.motion,
      this.actions,
      this.body,
      this.collider
    ];

    // Clone non-builtin the current actors components
    var components = this.getComponents();
    for (c in components) {
      if (!builtInComponents.includes(c)) {
        clone.addComponent(c.clone(), true);
      }
    }
    return clone;
  }

  /**
   * `onInitialize` is called before the first update of the actor. This method is meant to be
   * overridden. This is where initialization of child actors should take place.
   *
   * Synonymous with the event handler `.on('initialize', (evt) => {...})`
   */
  public function onInitialize(engine: Engine): Void {
    // Override me
  }

  /**
   * Initializes this actor and all it's child actors, meant to be called by the Scene before first update not by users of Excalibur.
   *
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   * @internal
   */
  public function _initialize(engine: Engine) {
    super._initialize(engine);
    for (child in this.children) {
      child._initialize(engine);
    }
  }

  // #region Events
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

  // #endregion

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _prekill handler for {@apilink onPreKill} lifecycle event
   * @internal
   */
  public function _prekill(scene: Scene) {
    this.events.emit('prekill', new PreKillEvent(this));
    this.onPreKill(scene);
  }

  /**
   * Safe to override onPreKill lifecycle event handler. Synonymous with `.on('prekill', (evt) =>{...})`
   *
   * `onPreKill` is called directly before an actor is killed and removed from its current {@apilink Scene}.
   */
  public function onPreKill(scene: Scene) {
    // Override me
  }

  /**
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
   *
   * Internal _prekill handler for {@apilink onPostKill} lifecycle event
   * @internal
   */
  public function _postkill(scene: Scene) {
    this.events.emit('postkill', new PostKillEvent(this));
    this.onPostKill(scene);
  }

  /**
   * Safe to override onPostKill lifecycle event handler. Synonymous with `.on('postkill', (evt) => {...})`
   *
   * `onPostKill` is called directly after an actor is killed and remove from its current {@apilink Scene}.
   */
  public function onPostKill(scene: Scene) {
    // Override me
  }

  /**
   * If the current actor is a member of the scene, this will remove
   * it from the scene graph. It will no longer be drawn or updated.
   */
  public function kill() {
    if (this.scene) {
      this._prekill(this.scene);
      this.events.emit('kill', new KillEvent(this));
      super.kill();
      this._postkill(this.scene);
    } else {
      if (process.env.NODE_ENV == 'development') {
        this.logger.warn('Cannot kill actor named "${this.name}", it was never added to the Scene');
      }
    }
  }

  /**
   * If the current actor is killed, it will now not be killed.
   */
  public function unkill() {
    this.isActive = true;
  }

  /**
   * Indicates wether the actor has been killed.
   */
  public function isKilled(): Bool {
    return !this.isActive;
  }

  /**
   * Gets the z-index of an actor. The z-index determines the relative order an actor is drawn in.
   * Actors with a higher z-index are drawn on top of actors with a lower z-index
   */
  public var z(get, set): Float;
  function get_z(): Float {
    return this.get(TransformComponent).z;
  }

  /**
   * Sets the z-index of an actor and updates it in the drawing list for the scene.
   * The z-index determines the relative order an actor is drawn in.
   * Actors with a higher z-index are drawn on top of actors with a lower z-index
   * @param newZ new z-index to assign
   */
  function set_z(newZ: Float) {
    this.get(TransformComponent).z = newZ;
  }

  /**
   * Get the center point of an actor (global position)
   */
  public var center(get, never): Vector;
  function get_center(): Vector {
    var globalPos = this.getGlobalPos();
    return new Vector(
      globalPos.x + this.width / 2 - this.anchor.x * this.width,
      globalPos.y + this.height / 2 - this.anchor.y * this.height
    );
  }

  /**
   * Get the local center point of an actor
   */
  public var localCenter(get, never): Vector;
  function get_localCenter(): Vector {
    return new Vector(this.pos.x + this.width / 2 - this.anchor.x * this.width, this.pos.y + this.height / 2 - this.anchor.y * this.height);
  }

  public var width(get, never): Int;
  function get_width() {
    return this.collider.localBounds.width * this.getGlobalScale().x;
  }

  public var height(get, never): Int;
  function get_height() {
    return this.collider.localBounds.height * this.getGlobalScale().y;
  }

  /**
   * Gets this actor's rotation taking into account any parent relationships
   * @returns Rotation angle in radians
   * @deprecated Use {@apilink globalRotation} instead
   */
  public function getGlobalRotation(): Float {
    return this.get(TransformComponent).globalRotation;
  }

  /**
   * The actor's rotation (in radians) taking into account any parent relationships
   */
  public var globalRotation(get, never): Float;
  function get_globalRotation(): Float {
    return this.get(TransformComponent).globalRotation;
  }

  /**
   * Gets an actor's world position taking into account parent relationships, scaling, rotation, and translation
   * @returns Position in world coordinates
   * @deprecated Use {@apilink globalPos} instead
   */
  public function getGlobalPos(): Vector {
    return this.get(TransformComponent).globalPos;
  }

  /**
   * The actor's world position taking into account parent relationships, scaling, rotation, and translation
   */
  public var globalPos(get, never): Vector;
  function get_globalPos(): Vector {
    return this.get(TransformComponent).globalPos;
  }

  /**
   * Gets the global scale of the Actor
   * @deprecated Use {@apilink globalScale} instead
   */
  public function getGlobalScale(): Vector {
    return this.get(TransformComponent).globalScale;
  }

  /**
   * The global scale of the Actor
   */
  public var globalScale(get, never): Vector;
  function get_globalScale(): Vector {
    return this.get(TransformComponent).globalScale;
  }

  /**
   * The global z-index of the actor
   */
  public var globalZ(get, never): Float;
  function get_globalZ(): Float {
    return this.get(TransformComponent).globalZ;
  }

  // #region Collision

  /**
   * Tests whether the x/y specified are contained in the actor
   * @param x  X coordinate to test (in world coordinates)
   * @param y  Y coordinate to test (in world coordinates)
   * @param recurse checks whether the x/y are contained in any child actors (if they exist).
   */
  public function contains(x: Float, y: Float, recurse: Bool = false): Bool {
    var point = vec(x, y);
    var collider = this.get(ColliderComponent);
    collider.update();
    var geom = collider.get();
    if (!geom) {
      return false;
    }
    var containment = geom.contains(point);

    if (recurse) {
      return (
        containment ||
        this.children.some((child: Actor) => {
          return child.contains(x, y, true);
        })
      );
    }

    return containment;
  }

  /**
   * Returns true if the two actor.collider's surfaces are less than or equal to the distance specified from each other
   * @param actor     Actor to test
   * @param distance  Distance in pixels to test
   */
  public function within(actor: Actor, distance: Float): Bool {
    var collider = this.get(ColliderComponent);
    var otherCollider = actor.get(ColliderComponent);
    var me = collider.get();
    var other = otherCollider.get();
    if (me && other) {
      return me.getClosestLineBetween(other).getLength() <= distance;
    }
    return false;
  }

  // #endregion

  // #region Update

  /**
   * Called by the Engine, updates the state of the actor
   * @internal
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function update(engine: Engine, elapsed: Int) {
    this._initialize(engine);
    this._add(engine);
    this._preupdate(engine, elapsed);
    this._postupdate(engine, elapsed);
    this._remove(engine);
  }

  /**
   * Safe to override onPreUpdate lifecycle event handler. Synonymous with `.on('preupdate', (evt) =>{...})`
   *
   * `onPreUpdate` is called directly before an actor is updated.
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPreUpdate(engine: Engine, elapsed: Int): Void {
    // Override me
  }

  /**
   * Safe to override onPostUpdate lifecycle event handler. Synonymous with `.on('postupdate', (evt) =>{...})`
   *
   * `onPostUpdate` is called directly after an actor is updated.
   * @param engine The reference to the current game engine
   * @param elapsed  The time elapsed since the last update in milliseconds
   */
  public function onPostUpdate(engine: Engine, elapsed: Int): Void {
    // Override me
  }

  /**
   * Fires before every collision resolution for a confirmed contact
   * @param self
   * @param other
   * @param side
   * @param contact
   */
  public function onPreCollisionResolve(self: Collider, other: Collider, side: Side, contact: CollisionContact) {
    // Override me
  }

  /**
   * Fires after every resolution for a confirmed contact.
   * @param self
   * @param other
   * @param side
   * @param contact
   */
  public function onPostCollisionResolve(self: Collider, other: Collider, side: Side, contact: CollisionContact) {
    // Override me
  }

  /**
   * Fires once when 2 entities with a ColliderComponent first start colliding or touching, if the Colliders stay in contact this
   * does not continue firing until they separate and re-collide.
   * @param self
   * @param other
   * @param side
   * @param contact
   */
  public function onCollisionStart(self: Collider, other: Collider, side: Side, contact: CollisionContact) {
    // Override me
  }

  /**
   * Fires once when 2 entities with a ColliderComponent separate after having been in contact.
   * @param self
   * @param other
   * @param side
   * @param lastContact
   */
  public function onCollisionEnd(self: Collider, other: Collider, side: Side, lastContact: CollisionContact) {
    // Override me
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
   * It is not recommended that internal excalibur methods be overridden, do so at your own risk.
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

  // endregion
}
