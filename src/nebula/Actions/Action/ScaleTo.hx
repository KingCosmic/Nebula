package nebula.actions.action;

import nebula.math.Vector;

import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.actions.Action;

interface ScaleToOptions {
  /**
   * Absolute scale to change to
   */
  var scale: Vector;
  /**
   * Duration to take in milliseconds
   */
  var duration: Int;
}

function isScaleToOptions(x: Any) {
  return (Std.isOfType(x.scale, Vector) && Std.isOfType(x.duration, Int));
}

class ScaleToWithOptions implements Action {
  var id = nextActionId();
  private var _durationMs: Float;
  private var _tx: TransformComponent;
  private var _started: Bool = false;
  private var _currentMs: Float;
  private var _stopped: Bool = false;
  private var _motion: MotionComponent;
  private var _endScale: Vector = vec(1, 1);
  private var _startScale: Vector = vec(1, 1);
  public function new(
    entity: Entity,
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
  function update(elapsed: Int) {
    if (!this._started) {
      this._startScale = this._tx.scale;
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

class ScaleTo implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  public var x: Float;
  public var y: Float;
  private var _startX: Float;
  private var _startY: Float;
  private var _endX: Float;
  private var _endY: Float;
  private var _speedX: Float;
  private var _speedY: Float;
  private var _distanceX: Float;
  private var _distanceY: Float;
  private var _started = false;
  private var _stopped = false;
  public function new(entity: Entity, scaleX: Float, scaleY: Float, speedX: Float, speedY: Float) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._endX = scaleX;
    this._endY = scaleY;
    this._speedX = speedX;
    this._speedY = speedY;
  }

  public function update(elapsed: Int) {
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

  public function isComplete(): Bool {
    return (
      this._stopped ||
      (Math.abs(this._tx.scale.x - this._startX) >= this._distanceX - 0.01 &&
        Math.abs(this._tx.scale.y - this._startY) >= this._distanceY - 0.01)
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
