package nebula.Actions.Action;

import nebula.Math.Vector;

import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math;

import nebula.Actions.Action;

interface ScaleToOptions {
  /**
   * Absolute scale to change to
   */
  scale: Vector;
  /**
   * Duration to take in milliseconds
   */
  duration: Float;
}

function isScaleToOptions(x: any): x is ScaleToOptions {
  return typeof x.scale === 'object' && typeof x.duration === 'number';
}

class ScaleToWithOptions implements Action {
  id = nextActionId();
  private _durationMs: Float;
  private _tx: TransformComponent;
  private _started: Bool = false;
  private _currentMs: Float;
  private _stopped: Bool = false;
  private _motion: MotionComponent;
  private _endScale: Vector = vec(1, 1);
  private _startScale: Vector = vec(1, 1);
  public function new(
    public entity: Entity,
    options: ScaleToOptions
  ) {
    this._endScale = options.scale;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only ScaleTo on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._currentMs = this._durationMs;
  }
  update(elapsed: Float) {
    if (!this._started) {
      this._startScale = this._tx.scale;
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

class ScaleTo implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  public x!: Float;
  public y!: Float;
  private _startX!: Float;
  private _startY!: Float;
  private _endX: Float;
  private _endY: Float;
  private _speedX: Float;
  private _speedY: Float;
  private _distanceX!: Float;
  private _distanceY!: Float;
  private _started = false;
  private _stopped = false;
  public function new(entity: Entity, scaleX: Float, scaleY: Float, speedX: Float, speedY: Float) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._endX = scaleX;
    this._endY = scaleY;
    this._speedX = speedX;
    this._speedY = speedY;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._startX = this._tx.scale.x;
      this._startY = this._tx.scale.y;
      this._distanceX = Math.abs(this._endX - this._startX);
      this._distanceY = Math.abs(this._endY - this._startY);
    }

    if (!(Math.abs(this._tx.scale.x - this._startX) >= this._distanceX)) {
      var directionX = this._endY < this._startY ? -1 : 1;
      this._motion.scaleFactor.x = this._speedX * directionX;
    } else {
      this._motion.scaleFactor.x = 0;
    }

    if (!(Math.abs(this._tx.scale.y - this._startY) >= this._distanceY)) {
      var directionY = this._endY < this._startY ? -1 : 1;
      this._motion.scaleFactor.y = this._speedY * directionY;
    } else {
      this._motion.scaleFactor.y = 0;
    }

    if (this.isComplete()) {
      this._tx.scale = vec(this._endX, this._endY);
      this._motion.scaleFactor.x = 0;
      this._motion.scaleFactor.y = 0;
    }
  }

  public isComplete(): Bool {
    return (
      this._stopped ||
      (Math.abs(this._tx.scale.x - this._startX) >= this._distanceX - 0.01 &&
        Math.abs(this._tx.scale.y - this._startY) >= this._distanceY - 0.01)
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
