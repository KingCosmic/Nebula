package nebula.particles;

import nebula.math.Util;

import nebula.graphics.context.ExcaliburGraphicsContextWebGL;

import nebula.particles.GpuParticleEmitter;
import nebula.particles.Particles;
import nebula.particles.EmitterType;

import nebula.util.Assert;

import nebula.math.Random;
import nebula.math.Vector;

import nebula.graphics.Sprite;

interface GpuParticleConfig extends ParticleConfig {
  /**
   * Only Sprite graphics are supported in GPU particles at the moment
   */
  var graphic: Null<Sprite>;
  /**
   * Set the maximum particles to use for this emitter
   */
  var maxParticles: Null<Int>;
}

/**
 * Container for the GPU Particle State contains the internal state needed for the GPU
 * to render particles and maintain state.
 */
class GpuParticleRenderer {
  static var GPU_MAX_PARTICLES: Int = 100_000;
  var emitter: GpuParticleEmitter;
  var emitRate: Int = 1;
  var particle: GpuParticleConfig;

  private var _initialized: Bool = false;
  private var _vaos: Array<WebGLVertexArrayObject> = [];
  private var _buffers: Array<WebGLBuffer> = [];
  private var _random: Random;

  private var _drawIndex = 0;
  private var _currentVao: WebGLVertexArrayObject;
  private var _currentBuffer: WebGLBuffer;

  private var _numInputFloats = 2 + 2 + 1 + 1 + 1;
  private var _particleData: Float32Array;
  private var _particleIndex = 0;
  private var _uploadIndex: Int = 0;

  private var _wrappedLife = 0;
  private var _wrappedParticles = 0;
  private var _particleLife = 0;

  public function new(emitter: GpuParticleEmitter, random: Random, options: GpuParticleConfig) {
    this.emitter = emitter;
    this.particle = options;
    this._particleData = new Float32Array(this.emitter.maxParticles * this._numInputFloats);
    this._random = random;
    this._particleLife = this.particle.life ?? 2000;
  }

  public var isInitialized(get, never): Bool;
  function get_isInitialized() {
    return this._initialized;
  }

  public var maxParticles(get, never): Int;
  function get_maxParticles(): Int {
    return this.emitter.maxParticles;
  }

  function initialize(gl: WebGL2RenderingContext, context: ExcaliburGraphicsContextWebGL) {
    if (this._initialized) {
      return;
    }

    final numParticles = this.emitter.maxParticles;
    final numInputFloats = this._numInputFloats;
    final particleData = this._particleData;
    final bytesPerFloat = 4;

    final particleDataBuffer1 = gl.createBuffer()!;
    final vao1 = gl.createVertexArray()!;
    gl.bindVertexArray(vao1);
    gl.bindBuffer(gl.ARRAY_BUFFER, particleDataBuffer1);
    gl.bufferData(gl.ARRAY_BUFFER, numParticles * numInputFloats * bytesPerFloat, gl.DYNAMIC_DRAW);
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, particleData);
    var offset = 0;
    // position
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, numInputFloats * bytesPerFloat, 0);
    offset += bytesPerFloat * 2;
    // velocity
    gl.vertexAttribPointer(1, 2, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 2;
    // rotation
    gl.vertexAttribPointer(2, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;
    // angularVelocity
    gl.vertexAttribPointer(3, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;
    // life
    gl.vertexAttribPointer(4, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;

    // enable attributes
    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);
    gl.enableVertexAttribArray(3);
    gl.enableVertexAttribArray(4);

    this._vaos.push(vao1);
    this._buffers.push(particleDataBuffer1);
    // Clean up
    gl.bindVertexArray(null);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    final particleDataBuffer2 = gl.createBuffer()!;
    final vao2 = gl.createVertexArray()!;
    gl.bindVertexArray(vao2);
    gl.bindBuffer(gl.ARRAY_BUFFER, particleDataBuffer2);
    gl.bufferData(gl.ARRAY_BUFFER, numParticles * numInputFloats * bytesPerFloat, gl.DYNAMIC_DRAW);
    offset = 0;
    // position
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, numInputFloats * bytesPerFloat, 0);
    offset += bytesPerFloat * 2;
    // velocity
    gl.vertexAttribPointer(1, 2, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 2;
    // rotation
    gl.vertexAttribPointer(2, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;
    // angularVelocity
    gl.vertexAttribPointer(3, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;
    // life
    gl.vertexAttribPointer(4, 1, gl.FLOAT, false, numInputFloats * bytesPerFloat, offset);
    offset += bytesPerFloat * 1;

    // enable attributes
    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);
    gl.enableVertexAttribArray(2);
    gl.enableVertexAttribArray(3);
    gl.enableVertexAttribArray(4);

    this._vaos.push(vao2);
    this._buffers.push(particleDataBuffer2);

    // Clean up
    gl.bindVertexArray(null);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    this._currentVao = this._vaos[this._drawIndex % 2];
    this._currentBuffer = this._buffers[(this._drawIndex + 1) % 2];

    this._initialized = true;
  }

  private var _clearRequested = false;
  function clearParticles() {
    this._particleData.fill(0);
    this._clearRequested = true;
  }

  private var _emitted: Array<{ life: Float, index: Int }> = [];
  function emitParticles(particleCount: Int) {
    final startIndex = this._particleIndex;
    final maxSize = this.maxParticles * this._numInputFloats;
    final endIndex = particleCount * this._numInputFloats + startIndex;
    var countParticle = 0;
    var i = startIndex;
    while (i < endIndex) {
      var angle = this._random.floating(this.particle.minAngle || 0, this.particle.maxAngle || TwoPI);
      angle +=
        this.particle.transform == ParticleTransform.Local ? this.emitter.transform.rotation : this.emitter.transform.globalRotation;
      final speedX = this._random.floating(this.particle.minSpeed || 0, this.particle.maxSpeed || 0);
      final speedY = this._random.floating(this.particle.minSpeed || 0, this.particle.maxSpeed || 0);
      final dx = speedX * Math.cos(angle);
      final dy = speedY * Math.sin(angle);
      var ranX: Int = 0;
      var ranY: Int = 0;
      if (this.emitter.emitterType == EmitterType.Rectangle) {
        ranX = this._random.floating(-0.5, 0.5) * this.emitter.width;
        ranY = this._random.floating(-0.5, 0.5) * this.emitter.height;
      } else {
        final radius = this._random.floating(0, this.emitter.radius);
        ranX = radius * Math.cos(angle);
        ranY = radius * Math.sin(angle);
      }
      final tx = this.emitter.transform.apply(vec(ranX, ranY));
      final data = [
        this.particle.transform == ParticleTransform.Local ? ranX : tx.x,
        this.particle.transform == ParticleTransform.Local ? ranY : tx.y, // pos in world space
        dx,
        dy, // velocity
        this.particle.randomRotation ? randomInRange(0, TwoPI, this._random) : this.particle.rotation || 0, // rotation
        this.particle.angularVelocity || 0, // angular velocity
        this._particleLife // life
      ];

      countParticle++;
      this._particleData.set(data, i % this._particleData.length);
      i += this._numInputFloats;
    }

    if (endIndex >= maxSize) {
      this._wrappedParticles += (endIndex - maxSize) / this._numInputFloats;
      this._wrappedLife = this._particleLife;
    } else if (this._wrappedLife > 0) {
      this._wrappedParticles += particleCount;
    }

    this._particleIndex = endIndex % maxSize;
    this._emitted.push([this._particleLife, startIndex]);
  }

  private function _uploadEmitted(gl: WebGL2RenderingContext) {
    // upload index is the index of the previous upload
    // particle index is the current index of modification
    if (this._particleIndex != this._uploadIndex) {
      // Bind one buffer to ARRAY_BUFFER and the other to TFB
      gl.bindBuffer(gl.ARRAY_BUFFER, this._buffers[(this._drawIndex + 1) % 2]);
      if (this._particleIndex >= this._uploadIndex) {
        gl.bufferSubData(
          gl.ARRAY_BUFFER,
          this._uploadIndex * 4, // dst byte offset 4 bytes per float
          this._particleData,
          this._uploadIndex,
          this._particleIndex - this._uploadIndex
        );
      } else {
        // upload before the wrap
        // prettier-ignore
        gl.bufferSubData(
					gl.ARRAY_BUFFER,
					this._uploadIndex * 4,
					this._particleData,
					this._uploadIndex,
					this._particleData.length - this._uploadIndex
				);
        // upload after the wrap if there are any
        if (this._wrappedParticles) {
          // prettier-ignore
          gl.bufferSubData(
						gl.ARRAY_BUFFER,
						0,
						this._particleData,
						0,
						this._wrappedParticles * this._numInputFloats
					);
        }
        this._wrappedLife = this._particleLife;
      }
      gl.bindBuffer(gl.ARRAY_BUFFER, null);
    }
    this._uploadIndex = this._particleIndex % (this.maxParticles * this._numInputFloats);
  }

  function update(elapsed: Int) {
    this._particleLife = this.particle.life ?? this._particleLife;
    if (this._wrappedLife > 0) {
      this._wrappedLife -= elapsed;
    } else {
      this._wrappedLife = 0;
      this._wrappedParticles = 0;
    }
    if (!this._emitted.length) {
      return;
    }
    var i = this._emitted.length;
    while (i >= 0) {
      final particle = this._emitted[i];
      particle[0] -= elapsed;
      final life = particle[0];
      if (life <= 0) {
        this._emitted.splice(i, 1);
      }
      i--;
    }

    this._emitted.sort((a, b) -> a[0] - b[0]);
  }

  function draw(gl: WebGL2RenderingContext) {
    if (this._initialized) {
      // Emit
      if (this._clearRequested) {
        gl.bindBuffer(gl.ARRAY_BUFFER, this._buffers[(this._drawIndex + 1) % 2]);
        gl.bufferSubData(gl.ARRAY_BUFFER, 0, this._particleData);
        gl.bindBuffer(gl.ARRAY_BUFFER, null);
        this._clearRequested = false;
      } else {
        this._uploadEmitted(gl);
      }

      // Bind one buffer to ARRAY_BUFFER and the other to transform feedback buffer
      gl.bindVertexArray(this._currentVao);
      gl.bindBufferBase(gl.TRANSFORM_FEEDBACK_BUFFER, 0, this._currentBuffer);

      // Perform transform feedback (run the simulation) and the draw call all at once
      if (this._wrappedLife && this._emitted[0] && this._emitted[0][1] > 0) {
        final midpoint = this._emitted[0][1] / this._numInputFloats;
        // draw oldest first (maybe make configurable)
        assert('midpoint greater than 0, actual: ${midpoint}', () -> midpoint > 0);
        assert('midpoint is less than max, actual: ${midpoint}', () -> midpoint < this.maxParticles);
        gl.bindBufferRange(
          gl.TRANSFORM_FEEDBACK_BUFFER,
          0,
          this._currentBuffer,
          this._emitted[0][1] * 4,
          (this.maxParticles - midpoint) * this._numInputFloats * 4
        );
        gl.beginTransformFeedback(gl.POINTS);
        gl.drawArrays(gl.POINTS, midpoint, this.maxParticles - midpoint);
        gl.endTransformFeedback();

        // then draw newer particles
        gl.bindBufferRange(gl.TRANSFORM_FEEDBACK_BUFFER, 0, this._currentBuffer, 0, this._emitted[0][1] * 4);
        gl.beginTransformFeedback(gl.POINTS);
        gl.drawArrays(gl.POINTS, 0, midpoint);
        gl.endTransformFeedback();
      } else {
        gl.bindBufferRange(gl.TRANSFORM_FEEDBACK_BUFFER, 0, this._currentBuffer, 0, this._particleData.length * 4);
        gl.beginTransformFeedback(gl.POINTS);
        gl.drawArrays(gl.POINTS, 0, this.maxParticles);
        gl.endTransformFeedback();
      }

      // Clean up after ourselves to avoid errors.
      gl.bindVertexArray(null);
      gl.bindBufferBase(gl.TRANSFORM_FEEDBACK_BUFFER, 0, null);

      // flip flop buffers, one will be draw the other simulation
      this._currentVao = this._vaos[this._drawIndex % 2];
      this._currentBuffer = this._buffers[(this._drawIndex + 1) % 2];
      this._drawIndex = (this._drawIndex + 1) % 2;
    }
  }
}
