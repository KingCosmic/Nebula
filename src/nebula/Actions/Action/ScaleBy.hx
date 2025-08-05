package nebula.Actions.Action;

import nebula.Math.Vector;
import nebula.Math;

import nebula.EntityComponentSystem.Entity;
import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;

import nebula.Actions.Action;

interface ScaleByOptions {
  /**
   * Absolute scale to change to
   */
  scaleOffset: Vector;
  /**
   * Duration to take in milliseconds
   */
  duration: Float;
}

function isScaleByOptions(x: any): x is ScaleByOptions {
  return typeof x.scaleOffset === 'object' && typeof x.duration === 'number';
}

class ScaleByWithOptions implements Action {
  id = nextActionId();
  private _durationMs: Float;
  private _tx: TransformComponent;
  private _started: Bool = false;
  private _currentMs: Float;
  private _stopped: Bool = false;
  private _motion: MotionComponent;
  private _endScale: Vector = vec(1, 1);
  private _scaleOffset: Vector = vec(0, 0);
  private _startScale: Vector = vec(1, 1);
  public function new(
    public entity: Entity,
    options: ScaleByOptions
  ) {
    this._scaleOffset = options.scaleOffset;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only ScaleBy on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._currentMs = this._durationMs;
  }
  update(elapsed: Float) {
    if (!this._started) {
      this._startScale = this._tx.scale;
      this._endScale = this._startScale.add(this._scaleOffset);
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    var newScale = lerpVector(this._startScale, this._endScale, t);
    var currentScale = this._tx.scale;
    var seconds = elapsed / 1000;
    var sx = newScale.sub(currentScale).scale(seconds === 0 ? 0 : 1 / seconds);
    this._motion.scaleFactor = sx;

    if (this.isComplete()) {
      this._tx.scale = this._endScale;
      this._motion.angularVelocity = 0;
    }
  }
  public isComplete(): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public stop() {
    this._motion.scaleFactor = Vector.Zero;
    this._stopped = true;
    this._currentMs = 0;
  }

  public reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class ScaleBy implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  public x!: Float;
  public y!: Float;
  private _startScale!: Vector;
  private _endScale!: Vector;
  private _offset: Vector;
  private _distanceX!: Float;
  private _distanceY!: Float;
  private _directionX!: Float;
  private _directionY!: Float;
  private _started = false;
  private _stopped = false;
  private _speedX: Float;
  private _speedY: Float;
  public function new(entity: Entity, scaleOffsetX: Float, scaleOffsetY: Float, speed: Float) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._offset = new Vector(scaleOffsetX, scaleOffsetY);
    this._speedX = this._speedY = speed;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._startScale = this._tx.scale.clone();
      this._endScale = this._startScale.add(this._offset);
      this._distanceX = Math.abs(this._endScale.x - this._startScale.x);
      this._distanceY = Math.abs(this._endScale.y - this._startScale.y);
      this._directionX = this._endScale.x < this._startScale.x ? -1 : 1;
      this._directionY = this._endScale.y < this._startScale.y ? -1 : 1;
    }

    this._motion.scaleFactor.x = this._speedX * this._directionX;
    this._motion.scaleFactor.y = this._speedY * this._directionY;

    if (this.isComplete()) {
      this._tx.scale = this._endScale;
      this._motion.scaleFactor.x = 0;
      this._motion.scaleFactor.y = 0;
    }
  }

  public isComplete(): Bool {
    return (
      this._stopped ||
      (Math.abs(this._tx.scale.x - this._startScale.x) >= this._distanceX - 0.01 &&
        Math.abs(this._tx.scale.y - this._startScale.y) >= this._distanceY - 0.01)
    );
  }

  public stop() {
    this._motion.scaleFactor.x = 0;
    this._motion.scaleFactor.y = 0;
    this._stopped = true;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
  }
}
