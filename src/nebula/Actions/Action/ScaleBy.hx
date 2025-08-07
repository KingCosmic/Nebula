package nebula.actions.action;

import nebula.math.Vector;

import nebula.entitycomponentsystem.Entity;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;

import nebula.actions.Action;

interface ScaleByOptions {
  /**
   * Absolute scale to change to
   */
  var scaleOffset: Vector;
  /**
   * Duration to take in milliseconds
   */
  var duration: Int;
}

function isScaleByOptions(x: Any) {
  return (Std.isOfType(x.scaleOffset, Vector) && Std.isOfType(x.duration, Int));
}

class ScaleByWithOptions implements Action {
  var id = nextActionId();
  private var _durationMs: Float;
  private var _tx: TransformComponent;
  private var _started: Bool = false;
  private var _currentMs: Float;
  private var _stopped: Bool = false;
  private var _motion: MotionComponent;
  private var _endScale: Vector = vec(1, 1);
  private var _scaleOffset: Vector = vec(0, 0);
  private var _startScale: Vector = vec(1, 1);
  public function new(
    entity: Entity,
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
  function update(elapsed: Int) {
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
    var sx = newScale.sub(currentScale).scale(seconds == 0 ? 0 : 1 / seconds);
    this._motion.scaleFactor = sx;

    if (this.isComplete()) {
      this._tx.scale = this._endScale;
      this._motion.angularVelocity = 0;
    }
  }
  public function isComplete(): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public function stop() {
    this._motion.scaleFactor = Vector.Zero;
    this._stopped = true;
    this._currentMs = 0;
  }

  public function reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class ScaleBy implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  public var x: Float;
  public var y: Float;
  private var _startScale: Vector;
  private var _endScale: Vector;
  private var _offset: Vector;
  private var _distanceX: Float;
  private var _distanceY: Float;
  private var _directionX: Float;
  private var _directionY: Float;
  private var _started = false;
  private var _stopped = false;
  private var _speedX: Float;
  private var _speedY: Float;
  public function new(entity: Entity, scaleOffsetX: Float, scaleOffsetY: Float, speed: Float) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._offset = new Vector(scaleOffsetX, scaleOffsetY);
    this._speedX = this._speedY = speed;
  }

  public function update(elapsed: Int) {
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

  public function isComplete(): Bool {
    return (
      this._stopped ||
      (Math.abs(this._tx.scale.x - this._startScale.x) >= this._distanceX - 0.01 &&
        Math.abs(this._tx.scale.y - this._startScale.y) >= this._distanceY - 0.01)
    );
  }

  public function stop() {
    this._motion.scaleFactor.x = 0;
    this._motion.scaleFactor.y = 0;
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
  }
}
