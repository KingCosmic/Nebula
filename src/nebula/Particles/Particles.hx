package nebula.particles;

import nebula.Engine;
import nebula.Color;

import nebula.math.Vector;
import nebula.math.Random;
import nebula.math.Util;

import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.collision.BoundingBox;

import nebula.graphics.GraphicsComponent;
import nebula.graphics.Graphic;

import nebula.particles.EmitterType;
import nebula.particles.ParticleEmitter;

import nebula.collision.integrator.EulerIntegrator;

/**
 * CPU Particle is used in a {@apilink ParticleEmitter}
 */
class Particle extends Entity {
  public static var DefaultConfig: ParticleConfig = {
    beginColor: Color.White,
    endColor: Color.White,
    life: 300,
    fade: false,
    size: 5,
    graphic: undefined,
    startSize: undefined,
    endSize: undefined
  };

  public var focus: Null<Vector>;
  public var focusAccel: Null<Float>;
  public var beginColor: Color = Color.White;
  public var endColor: Color = Color.White;

  // Life is counted in ms
  public var life: Int = 300;
  public var fade: Bool = false;

  // Color transitions
  private var _rRate: Int = 1;
  private var _gRate: Int = 1;
  private var _bRate: Int = 1;
  private var _aRate: Int = 0;
  private var _currentColor: Color = Color.White;

  public var size: Int = 5;
  public var graphic: Null<Graphic>;

  public var startSize: Null<Int>;
  public var endSize: Null<Int>;
  public var sizeRate: Int = 0;

  public var visible = true;
  public var isOffscreen = false;

  public var transform: TransformComponent;
  public var motion: MotionComponent;
  public var graphics: GraphicsComponent;
  public var particleTransform = ParticleTransform.Global;

  public var name = 'Particle#${this.id}';

  public function new(options: ParticleConfig) {
    super({ silenceWarnings: true });
    this.addComponent((this.transform = new TransformComponent()));
    this.addComponent((this.motion = new MotionComponent()));
    this.addComponent((this.graphics = new GraphicsComponent()));
    this.configure(options);
  }

  private var _emitter: Null<ParticleEmitter>;
  function registerEmitter(emitter: ParticleEmitter) {
    this._emitter = emitter;
    if (this.particleTransform == ParticleTransform.Global) {
      final globalPos = this._emitter.transform.globalPos;
      this.transform.pos = this.transform.pos.add(globalPos);
      this.motion.vel = this.motion.vel.rotate(this._emitter.transform.globalRotation);
    }
  }

  function configure(options: ParticleConfig) {
    this.particleTransform = options.transform ?? this.particleTransform;
    this.life = options.life ?? this.life;
    this.fade = options.fade ?? this.fade;
    this.size = options.size ?? this.size;
    this.endColor = options.endColor ?? this.endColor.clone();
    this.beginColor = options.beginColor ?? this.beginColor.clone();
    this._currentColor = this.beginColor.clone();

    this.graphic = options.graphic;
    this.graphics.opacity = options.opacity ?? this.graphics.opacity;
    this.transform.pos = options.pos ?? this.transform.pos;
    this.transform.rotation = options.rotation ?? 0;
    this.transform.scale = vec(1, 1);

    this.motion.vel = options.vel ?? this.motion.vel;
    this.motion.angularVelocity = options.angularVelocity ?? 0;
    this.motion.acc = options.acc ?? this.motion.acc;

    this._rRate = (this.endColor.r - this.beginColor.r) / this.life;
    this._gRate = (this.endColor.g - this.beginColor.g) / this.life;
    this._bRate = (this.endColor.b - this.beginColor.b) / this.life;
    this._aRate = this.graphics.opacity / this.life;

    this.startSize = options.startSize ?? 0;
    this.endSize = options.endSize ?? 0;

    if (this.endSize > 0 && this.startSize > 0) {
      this.sizeRate = (this.endSize - this.startSize) / this.life;
      this.size = this.startSize;
    }
    if (this.graphic) {
      this.graphics.use(this.graphic);
      this.graphics.onPostDraw = undefined;
    } else {
      this.graphics.localBounds = BoundingBox.fromDimension(this.size, this.size, Vector.Half);
      this.graphics.onPostDraw = (ctx) => {
        ctx.save();
        ctx.debug.drawPoint(vec(0, 0), { color: this._currentColor, size: this.size });
        ctx.restore();
      };
    }
  }

  public override function kill() {
    if (this._emitter?.isActive) {
      this._emitter.removeParticle(this);
    } else {
      super.kill();
    }
  }

  public function update(engine: Engine, elapsed: Int) {
    this.life = this.life - elapsed;

    if (this.life < 0) {
      this.kill();
    }

    if (this.fade) {
      this.graphics.opacity = clamp(this._aRate * this.life, 0.0001, 1);
    }

    if (this.startSize && this.endSize && this.startSize > 0 && this.endSize > 0) {
      this.size = clamp(
        this.sizeRate * elapsed + this.size,
        Math.min(this.startSize, this.endSize),
        Math.max(this.startSize, this.endSize)
      );
    }

    this._currentColor.r = clamp(this._currentColor.r + this._rRate * elapsed, 0, 255);
    this._currentColor.g = clamp(this._currentColor.g + this._gRate * elapsed, 0, 255);
    this._currentColor.b = clamp(this._currentColor.b + this._bRate * elapsed, 0, 255);
    this._currentColor.a = this.graphics.opacity;

    var accel = this.motion.acc;
    if (this.focus) {
      accel = this.focus
        .sub(this.transform.pos)
        .normalize()
        .scale(this.focusAccel || 0)
        .scale(elapsed / 1000);
    }
    // Update transform and motion based on Euler linear algebra
    EulerIntegrator.integrate(this.transform, this.motion, accel, elapsed);
  }
}

interface ParticleConfig {
  /**
   * Optionally set the emitted particle transform style, {@apilink ParticleTransform.Global} is the default and emits particles as if
   * they were world space objects, useful for most effects.
   *
   * If set to {@apilink ParticleTransform.Local} particles are children of the emitter and move relative to the emitter
   * as they would in a parent/child actor relationship.
   */
  var transform: Null<ParticleTransform>;
  /**
   * Starting position of the particle
   */
  var pos: Null<Vector>;
  /**
   * Starting velocity of the particle
   */
  var vel: Null<Vector>;
  /**
   * Starting acceleration of the particle
   */
  var acc: Null<Vector>;
  /**
   * Starting angular velocity of the particle
   */
  var angularVelocity: Null<Float>;
  /**
   * Starting rotation of the particle
   */
  var rotation: Null<Float>;
  /**
   * Size of the particle in pixels
   */
  var size: Null<Int>;
  /**
   * Optionally set a graphic
   */
  var graphic: Null<Graphic>;
  /**
   * Totally life of the particle in milliseconds
   */
  var life: Null<Int>;
  /**
   * Starting opacity of the particle
   */
  var opacity: Null<Float>;
  /**
   * Should the particle fade out to fully transparent over their life
   */
  var fade: Null<Bool>;

  /**
   * Ending color of the particle over its life
   */
  var endColor: Null<Color>;
  /**
   * Beginning color of the particle over its life
   */
  var beginColor: Null<Color>;

  /**
   * Set the start size when you want to change particle size over their life
   */
  var startSize: Null<Int>;
  /**
   * Set the end size when you want to change particle size over their life
   */
  var endSize: Null<Int>;

  /**
   * Smallest possible starting size of the particle
   */
  var minSize: Null<Int>;
  /**
   * Largest possible starting size of the particle
   */
  var maxSize: Null<Int>;
  /**
   * Minimum magnitude of the particle starting speed
   */
  var minSpeed: Null<Int>;
  /**
   * Maximum magnitude of the particle starting speed
   */
  var maxSpeed: Null<Int>;
  /**
   * Minimum angle to use for the particles starting rotation
   */
  var minAngle: Null<Float>;
  /**
   * Maximum angle to use for the particles starting rotation
   */
  var maxAngle: Null<Float>;

  /**
   * Gets or sets the optional focus where all particles should accelerate towards
   *
   * If the particle transform is global the focus is in world space, otherwise it is relative to the emitter
   */
  var focus: Null<Vector>;
  /**
   * Gets or sets the optional acceleration for focusing particles if a focus has been specified
   */
  var focusAccel: Null<Float>;

  /**
   * Indicates whether particles should start with a random rotation
   */
  var randomRotation: Null<Bool>;
}

enum ParticleTransform {
  /**
   * {@apilink ParticleTransform.Global} is the default and emits particles as if
   * they were world space objects, useful for most effects.
   */
  Global;
  /**
   * {@apilink ParticleTransform.Local} particles are children of the emitter and move relative to the emitter
   * as they would in a parent/child actor relationship.
   */
  Local;
}

interface ParticleEmitterArgs {
  var particle: Null<ParticleConfig>;
  var x: Null<Int>;
  var y: Null<Int>;
  var z: Null<Int>;
  var pos: Null<Vector>;
  var width: Null<Int>;
  var height: Null<Int>;
  /**
   * Is emitting currently
   */
  var isEmitting: Null<Bool>;
  /**
   * Particles per second
   */
  var emitRate: Null<Int>;
  var focus: Null<Vector>;
  var focusAccel: Null<Float>;
  /**
   * Emitter shape
   */
  var emitterType: Null<EmitterType>;
  /**
   * Radius of the emitter if the emitter type is EmitterType.Circle
   */
  var radius: Null<Float>;
  var random: Null<Random>;
}
