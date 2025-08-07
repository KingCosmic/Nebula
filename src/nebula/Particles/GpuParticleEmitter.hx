package nebula.particles;

import nebula.Engine;
import nebula.Actor;

import nebula.particles.EmitterType;
import nebula.particles.Particles;
import nebula.particles.GpuParticleRenderer;
import nebula.graphics.GraphicsComponent;

import nebula.math.Random;
import nebula.math.Vector;
import nebula.math.Util;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;
import nebula.graphics.context.particlerenderer.ParticleRenderer;

class GpuParticleEmitter extends Actor {
  public var particle: GpuParticleConfig = {
    /**
     * Gets or sets the life of each particle in milliseconds
     */
    life: 2000,
    transform: ParticleTransform.Global,
    graphic: undefined,
    opacity: 1,
    angularVelocity: 0,
    focus: undefined,
    focusAccel: undefined,
    randomRotation: false
  };

  public var graphics = new GraphicsComponent();
  public var renderer: GpuParticleRenderer;
  public var isEmitting: Bool = false;
  public var emitRate: Int = 1;
  public var emitterType: EmitterType = EmitterType.Rectangle;
  public var radius: Int = 0;
  public var maxParticles: Int = 2000;
  var random: Random;

  public var pos(get, set): Vector;
  function get_pos() {
    return this.transform.pos;
  }
  function set_pos(pos: Vector) {
    this.transform.pos = pos;
  }

  public var z(get, set): Int;
  function get_z() {
    return this.transform.z;
  }
  function set_z(z: Int) {
    this.transform.z = z;
  }

  public function new(config: ParticleEmitterArgs & { maxParticles: Null<Int>, particle: Null<GpuParticleConfig> }) {
    super({ name: 'GpuParticleEmitter', width: config.width, height: config.height }); // somewhat goofy way of doing width/height
    this.addComponent(this.graphics, true);
    this.graphics.onPostDraw = this.draw.bind(this);

    final particle = config.particle,
          maxParticles = config.maxParticles,
          x = config.x,
          y = config.y,
          z = config.z,
          pos = config.pos,
          isEmitting = config.isEmitting,
          emitRate = config.emitRate,
          emitterType = config.emitterType,
          radius = config.radius,
          random = config.random;

    this.maxParticles = clamp(maxParticles ?? this.maxParticles, 0, GpuParticleRenderer.GPU_MAX_PARTICLES);

    this.pos = pos ?? vec(x ?? 0, y ?? 0);

    this.z = z ?? 0;

    this.isEmitting = isEmitting ?? this.isEmitting;

    this.emitRate = emitRate ?? this.emitRate;

    this.emitterType = emitterType ?? this.emitterType;

    this.radius = radius ?? this.radius;

    this.particle = Object.spreadWith(this.particle, particle);

    this.random = random ?? new Random();

    this.renderer = new GpuParticleRenderer(this, this.random, this.particle);
  }

  public function _initialize(engine: Engine): Void {
    super._initialize(engine);
    final context = engine.graphicsContext;
    this.renderer.initialize(context.__gl, context);
  }

  private var _particlesToEmit = 0;
  public function update(engine: Engine, elapsed: Int): Void {
    super.update(engine, elapsed);

    if (this.isEmitting) {
      this._particlesToEmit += this.emitRate * (elapsed / 1000);
      if (this._particlesToEmit > 1.0) {
        this.emitParticles(Math.floor(this._particlesToEmit));
        this._particlesToEmit = this._particlesToEmit - Math.floor(this._particlesToEmit);
      }
    }
    this.renderer.update(elapsed);
  }

  public function emitParticles(particleCount: Int) {
    if (particleCount <= 0) {
      return;
    }
    this.renderer.emitParticles(particleCount | 0); // coerce to integer
  }

  public function clearParticles() {
    this.renderer.clearParticles();
  }

  function draw(ctx: ExcaliburGraphicsContextWebGL, elapsed: Int) {
    ctx.draw('ex.particle', this.renderer, elapsed);
  }
}
