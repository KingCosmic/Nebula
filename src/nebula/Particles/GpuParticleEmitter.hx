package nebula.Particles;

import nebula.Engine;
import nebula.Actor;

import nebula.Particles.EmitterType;
import nebula.Particles.Particles;
import nebula.Particles.GpuParticleRenderer;
import nebula.Particles
import nebula.Graphics.GraphicsComponent;

import nebula.Math.Radnom;
import nebula.Math.Vector;
import nebula.Math.Util

import nebula.Graphics.Context.ExcaliburGraphicsContextWebGL;
import nebula.Graphics.Context.ParticleRenderer.ParticleRenderer;

class GpuParticleEmitter extends Actor {
  public particle: GpuParticleConfig = {
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

  public graphics = new GraphicsComponent();
  public renderer: GpuParticleRenderer;
  public isEmitting: Bool = false;
  public emitRate: Int = 1;
  public emitterType: EmitterType = EmitterType.Rectangle;
  public radius: Int = 0;
  public readonly maxParticles: Int = 2000;
  random: Random;

  public get pos() {
    return this.transform.pos;
  }

  public set pos(pos: Vector) {
    this.transform.pos = pos;
  }

  public get z() {
    return this.transform.z;
  }

  public set z(z: Int) {
    this.transform.z = z;
  }

  public function new(config: ParticleEmitterArgs & { maxParticles?: Int; particle?: GpuParticleConfig }) {
    super({ name: `GpuParticleEmitter`, width: config.width, height: config.height }); // somewhat goofy way of doing width/height
    this.addComponent(this.graphics, true);
    (this.graphics.onPostDraw as any) = this.draw.bind(this);

    final { particle, maxParticles, x, y, z, pos, isEmitting, emitRate, emitterType, radius, random } = { ...config };

    this.maxParticles = clamp(maxParticles ?? this.maxParticles, 0, GpuParticleRenderer.GPU_MAX_PARTICLES);

    this.pos = pos ?? vec(x ?? 0, y ?? 0);

    this.z = z ?? 0;

    this.isEmitting = isEmitting ?? this.isEmitting;

    this.emitRate = emitRate ?? this.emitRate;

    this.emitterType = emitterType ?? this.emitterType;

    this.radius = radius ?? this.radius;

    this.particle = { ...this.particle, ...particle };

    this.random = random ?? new Random();

    this.renderer = new GpuParticleRenderer(this, this.random, this.particle);
  }

  public _initialize(engine: Engine): Void {
    super._initialize(engine);
    final context = engine.graphicsContext as ExcaliburGraphicsContextWebGL;
    this.renderer.initialize(context.__gl, context);
  }

  private _particlesToEmit = 0;
  public update(engine: Engine, elapsed: Int): Void {
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

  public emitParticles(particleCount: Int) {
    if (particleCount <= 0) {
      return;
    }
    this.renderer.emitParticles(particleCount | 0); // coerce to integer
  }

  public clearParticles() {
    this.renderer.clearParticles();
  }

  draw(ctx: ExcaliburGraphicsContextWebGL, elapsed: Int) {
    ctx.draw<ParticleRenderer>('ex.particle', this.renderer, elapsed);
  }
}
