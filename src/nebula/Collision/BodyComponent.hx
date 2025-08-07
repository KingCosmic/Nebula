package nebula.collision;

import nebula.math.Vector;
import nebula.collision.CollisionType;
import nebula.interfaces.Clonable;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.Component;

import nebula.collision.group.CollisionGroup;

import nebula.Id;
import nebula.math.Util;
import nebula.collision.ColliderComponent;
import nebula.math.Transform;

import nebula.EventEmitter;

import nebula.collision.PhysicsConfig;

import nebula.util.Required;

interface BodyComponentOptions {
  var type: Null<CollisionType>;
  var group: Null<CollisionGroup>;
  var useGravity: Null<Bool>;
  var config: Null<Pick<PhysicsConfig, 'bodies'>>;
}

enum DegreeOfFreedom {
  Rotation;
  X;
  Y;
}

/**
 * Body describes all the physical properties pos, vel, acc, rotation, angular velocity for the purpose of
 * of physics simulation.
 */
class BodyComponent extends Component implements Clonable<BodyComponent> {
  public var dependencies = [TransformComponent, MotionComponent];
  public static var _ID = 0;
  public var id: String = createId('body', BodyComponent._ID++);
  public var events = new EventEmitter();

  public var oldTransform = new Transform();

  /**
   * Indicates whether the old transform has been captured at least once for interpolation
   * @internal
   */
  public var __oldTransformCaptured: Bool = false;

  /**
   * Enable or disabled the fixed update interpolation, by default interpolation is on.
   */
  public var enableFixedUpdateInterpolate = true;

  private var _bodyConfig: DeepRequired<Pick<PhysicsConfig, 'bodies'>>;
  private static var _DEFAULT_CONFIG: DeepRequired<Pick<PhysicsConfig, 'bodies'>> = getDefaultPhysicsConfig().bodies;
  public var wakeThreshold: Float;

  public function new(?options: BodyComponentOptions) {
    super();
    if (options) {
      this.collisionType = options.type ?? this.collisionType;
      this.group = options.group ?? this.group;
      this.useGravity = options.useGravity ?? this.useGravity;
      this._bodyConfig = Oject.spreadWith(
        getDefaultPhysicsConfig().bodies,
        options.config
      );
    } else {
      this._bodyConfig = Oject.spreadWith(
        getDefaultPhysicsConfig().bodies,
        {}
      );
    }
    this.updatePhysicsConfig(this._bodyConfig);
    this._mass = BodyComponent._DEFAULT_CONFIG.defaultMass;
  }

  public var matrix(get, never): Matrix;
  function get_matrix() {
    return this.transform.get().matrix;
  }

  /**
   * Called by excalibur to update physics config defaults if they change
   * @param config
   */
  public function updatePhysicsConfig(config: DeepRequired<Pick<PhysicsConfig, 'bodies'>>) {
    this._bodyConfig = Oject.spreadWith(
      getDefaultPhysicsConfig().bodies,
      config
    );
    this.canSleep = this._bodyConfig.canSleepByDefault;
    this.sleepMotion = this._bodyConfig.sleepEpsilon * 5;
    this.wakeThreshold = this._bodyConfig.wakeThreshold;
  }
  /**
   * Called by excalibur to update defaults
   * @param config
   */
  public static function updateDefaultPhysicsConfig(config: DeepRequired<Pick<PhysicsConfig, 'bodies'>>) {
    BodyComponent._DEFAULT_CONFIG = config;
  }

  /**
   * Collision type for the rigidbody physics simulation, by default {@apilink CollisionType.PreventCollision}
   */
  public var collisionType: CollisionType = CollisionType.PreventCollision;

  /**
   * The collision group for the body's colliders, by default body colliders collide with everything
   */
  public var group: CollisionGroup = CollisionGroup.All;

  /**
   * The amount of mass the body has
   */
  private var _mass: Float;
  public var mass(get, set): Float;
  function get_mass(): Float {
    return this._mass;
  }
  function set_mass(newMass: Float) {
    this._mass = newMass;
    this._cachedInertia = undefined;
    this._cachedInverseInertia = undefined;
  }

  /**
   * The inverse mass (1/mass) of the body. If {@apilink CollisionType.Fixed} this is 0, meaning "infinite" mass
   */
  public var inverseMass(get, never): Float;
  function get_inverseMass(): Float {
    return this.collisionType == CollisionType.Fixed ? 0 : 1 / this.mass;
  }

  /**
   * Amount of "motion" the body has before sleeping. If below {@apilink Physics.sleepEpsilon} it goes to "sleep"
   */
  public var sleepMotion: Float;

  /**
   * Can this body sleep, by default bodies do not sleep
   */
  public var canSleep: Bool;

  private var _sleeping = false;
  /**
   * Whether this body is sleeping or not
   * @deprecated use isSleeping
   */
  public var sleeping(get, never): Bool;
  function get_sleeping(): Bool {
    return this.isSleeping;
  }

  /**
   * Whether this body is sleeping or not
   */
  public var isSleeping(get, set): Bool;
  function get_isSleeping(): Bool {
    return this._sleeping;
  }
  function set_isSleeping(sleeping: Bool) {
    this._sleeping = sleeping;
    if (!sleeping) {
      // Give it a kick to keep it from falling asleep immediately
      this.sleepMotion = this._bodyConfig.sleepEpsilon * 5;
    } else {
      this.vel = Vector.Zero;
      this.acc = Vector.Zero;
      this.angularVelocity = 0;
      this.sleepMotion = 0;
    }
  }

  /**
   * Set the sleep state of the body
   * @param sleeping
   * @deprecated use isSleeping
   */
  public function setSleeping(sleeping: Bool) {
    this.isSleeping = sleeping;
  }

  /**
   * Update body's {@apilink BodyComponent.sleepMotion} for the purpose of sleeping
   */
  public function updateMotion() {
    if (this._sleeping) {
      this.isSleeping = true;
    }
    var currentMotion = this.vel.magnitude * this.vel.magnitude + Math.abs(this.angularVelocity * this.angularVelocity);
    var bias = this._bodyConfig.sleepBias;
    this.sleepMotion = bias * this.sleepMotion + (1 - bias) * currentMotion;
    this.sleepMotion = clamp(this.sleepMotion, 0, 10 * this._bodyConfig.sleepEpsilon);
    if (this.canSleep && this.sleepMotion < this._bodyConfig.sleepEpsilon) {
      this.isSleeping = true;
    }
  }

  private var _cachedInertia: Float;
  /**
   * Get the moment of inertia from the {@apilink ColliderComponent}
   */
  public var inertia(get, never): Float;
  function get_inertia() {
    if (this._cachedInertia) {
      return this._cachedInertia;
    }

    // Inertia is a property of the geometry, so this is a little goofy but seems to be okay?
    var collider = this.owner.get(ColliderComponent);
    if (collider) {
      collider.colliderAdded.subscribe(() -> {
        this._cachedInertia = null;
      });
      collider.colliderRemoved.subscribe(() -> {
        this._cachedInertia = null;
      });
      var maybeCollider = collider.get();
      if (maybeCollider) {
        return (this._cachedInertia = maybeCollider.getInertia(this.mass));
      }
    }
    return 0.0;
  }

  private var _cachedInverseInertia: Float;
  /**
   * Get the inverse moment of inertial from the {@apilink ColliderComponent}. If {@apilink CollisionType.Fixed} this is 0, meaning "infinite" mass
   */
  public var inverseInertia(get, never): Float;
  function get_inverseInertia() {
    if (this._cachedInverseInertia) {
      return this._cachedInverseInertia;
    }
    return (this._cachedInverseInertia = this.collisionType == CollisionType.Fixed ? 0 : 1 / this.inertia);
  }

  /**
   * The also known as coefficient of restitution of this actor, represents the amount of energy preserved after collision or the
   * bounciness. If 1, it is 100% bouncy, 0 it completely absorbs.
   */
  public var bounciness: Float = 0.2;

  /**
   * The coefficient of friction on this actor.
   *
   * The {@apilink SolverStrategy.Arcade} does not support this property.
   *
   */
  public var friction: Float = 0.99;

  /**
   * Should use global gravity {@apilink Physics.gravity} in it's physics simulation, default is true
   */
  public var useGravity: Bool = true;

  /**
   * Degrees of freedom to limit
   *
   * Note: this only limits responses in the realistic solver, if velocity/angularVelocity is set the actor will still respond
   */
  public var limitDegreeOfFreedom: Array<DegreeOfFreedom> = [];

  /**
   * Returns if the owner is active
   * @deprecated use isActive
   */
  public var active(get, never): Bool;
  function get_active() {
    return !!this.owner?.isActive;
  }

  /**
   * Returns if the owner is active
   */
  public var isActive(get, never): Bool;
  function get_isActive() {
    return !!this.owner?.isActive;
  }

  /**
   * @deprecated Use globalPos
   */
  public var center(get, never): Vector;
  function get_center() {
    return this.globalPos;
  }

  public var transform: TransformComponent;
  public var motion: MotionComponent;

  override function onAdd(owner: Entity<Any>): Void {
    this.transform = this.owner?.get(TransformComponent);
    this.motion = this.owner?.get(MotionComponent);
  }

  public var pos(get, set): Vector;
  function get_pos(): Vector {
    return this.transform.pos;
  }
  function set_pos(val: Vector) {
    this.transform.pos = val;
  }

  /**
   * The (x, y) position of the actor this will be in the middle of the actor if the
   * {@apilink Actor.anchor} is set to (0.5, 0.5) which is default.
   * If you want the (x, y) position to be the top left of the actor specify an anchor of (0, 0).
   */
  public var globalPos(get, set): Vector;
  function get_globalPos(): Vector {
    return this.transform.globalPos;
  }
  function set_globalPos(val: Vector) {
    this.transform.globalPos = val;
  }

  private var _oldGlobalPos: Vector = Vector.Zero;

  /**
   * The position of the actor last frame (x, y) in pixels
   */
  public var oldPos(get, never): Vector;
  function get_oldPos(): Vector {
    return this.oldTransform.pos;
  }

  /**
   * The global position of the actor last frame (x, y) in pixels
   */
  public var oldGlobalPos(get, never): Vector;
  function get_oldGlobalPos(): Vector {
    return this._oldGlobalPos;
  }

  /**
   * The current velocity vector (vx, vy) of the actor in pixels/second
   */
  public var vel(get, set): Vector;
  function get_vel(): Vector {
    return this.motion.vel;
  }
  function set_vel(val: Vector) {
    this.motion.vel = val;
  }

  /**
   * The velocity of the actor last frame (vx, vy) in pixels/second
   */
  public var oldVel: Vector = new Vector(0, 0);

  /**
   * The current acceleration vector (ax, ay) of the actor in pixels/second/second. An acceleration pointing down such as (0, 100) may
   * be useful to simulate a gravitational effect.
   */
  public var acc(get, set): Vector;
  function get_acc(): Vector {
    return this.motion.acc;
  }
  function set_acc(val: Vector) {
    this.motion.acc = val;
  }

  /**
   * Gets/sets the acceleration of the actor from the last frame. This does not include the global acc {@apilink Physics.acc}.
   */
  public var oldAcc: Vector = Vector.Zero;

  /**
   * The current torque applied to the actor
   */
  public var torque(get, set): Float;
  function get_torque(): Float {
    return this.motion.torque;
  }
  function set_torque(val: Float) {
    this.motion.torque = val;
  }

  /**
   * Gets/sets the rotation of the body from the last frame.
   */
  public var oldRotation(get, never): Float;
  function get_oldRotation(): Float {
    return this.oldTransform.rotation;
  }

  /**
   * The rotation of the body in radians
   */
  public var rotation(get, set): Float;
  function get_rotation() {
    return this.transform.globalRotation;
  }
  function set_rotation(val: Float) {
    this.transform.globalRotation = val;
  }

  /**
   * The scale vector of the actor
   */
  public var scale(get, set): Vector;
  function get_scale(): Vector {
    return this.transform.globalScale;
  }
  function set_scale(val: Vector) {
    this.transform.globalScale = val;
  }

  /**
   * The scale of the actor last frame
   */
  public var oldScale(get, never): Vector;
  function get_oldScale(): Vector {
    return this.oldTransform.scale;
  }

  /**
   * The scale rate of change of the actor in scale/second
   */
  public var scaleFactor(get, set): Vector;
  function get_scaleFactor(): Vector {
    return this.motion.scaleFactor;
  }
  function set_scaleFactor(scaleFactor: Vector) {
    this.motion.scaleFactor = scaleFactor;
  }

  /**
   * Get the angular velocity in radians/second
   */
  public var angularVelocity(get, set): Float;
  function get_angularVelocity(): Float {
    return this.motion.angularVelocity;
  }

  /**
   * Set the angular velocity in radians/second
   */
  function set_angularVelocity(value: Float) {
    this.motion.angularVelocity = value;
  }

  private var _impulseScratch = vec(0, 0);
  private var _distanceFromCenterScratch = vec(0, 0);
  /**
   * Apply a specific impulse to the body
   * @param point
   * @param impulse
   */
  public function applyImpulse(point: Vector, impulse: Vector) {
    if (this.collisionType != CollisionType.Active) {
      return; // only active objects participate in the simulation
    }

    var finalImpulse = impulse.scale(this.inverseMass, this._impulseScratch);
    if (this.limitDegreeOfFreedom.indexOf(DegreeOfFreedom.X) > -1) {
      finalImpulse.x = 0;
    }
    if (this.limitDegreeOfFreedom.indexOf(DegreeOfFreedom.Y) > -1) {
      finalImpulse.y = 0;
    }

    this.vel.addEqual(finalImpulse);

    if (!this.limitDegreeOfFreedom.includes(DegreeOfFreedom.Rotation)) {
      final distanceFromCenter = point.sub(this.globalPos, this._distanceFromCenterScratch);
      this.angularVelocity += this.inverseInertia * distanceFromCenter.cross(impulse);
    }
  }

  /**
   * Apply only linear impulse to the body
   * @param impulse
   */
  public function applyLinearImpulse(impulse: Vector) {
    if (this.collisionType != CollisionType.Active) {
      return; // only active objects participate in the simulation
    }

    var finalImpulse = impulse.scale(this.inverseMass);

    if (this.limitDegreeOfFreedom.includes(DegreeOfFreedom.X)) {
      finalImpulse.x = 0;
    }
    if (this.limitDegreeOfFreedom.includes(DegreeOfFreedom.Y)) {
      finalImpulse.y = 0;
    }

    this.vel = this.vel.add(finalImpulse);
  }

  /**
   * Apply only angular impulse to the body
   * @param point
   * @param impulse
   */
  public function applyAngularImpulse(point: Vector, impulse: Vector) {
    if (this.collisionType != CollisionType.Active) {
      return; // only active objects participate in the simulation
    }

    if (!this.limitDegreeOfFreedom.includes(DegreeOfFreedom.Rotation)) {
      var distanceFromCenter = point.sub(this.globalPos);
      this.angularVelocity += this.inverseInertia * distanceFromCenter.cross(impulse);
    }
  }

  /**
   * Sets the old versions of pos, vel, acc, and scale.
   */
  public function captureOldTransform() {
    // Capture old values before integration step updates them
    this.__oldTransformCaptured = true;
    var tx = this.transform.get();
    tx.clone(this.oldTransform);
    this.oldTransform.parent = tx.parent; // also grab parent
    this.oldVel.setTo(this.vel.x, this.vel.y);
    this.oldAcc.setTo(this.acc.x, this.acc.y);
    this.oldGlobalPos.setTo(this.globalPos.x, this.globalPos.y);
  }

  public function clone(): BodyComponent {
    var component = super.clone();
    return component;
  }
}
