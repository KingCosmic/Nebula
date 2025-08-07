package nebula.actions.action;

import nebula.entitycomponentsystem.components.TransformComponent;
import nebula.entitycomponentsystem.components.MotionComponent;
import nebula.entitycomponentsystem.Entity;

import nebula.math.Util;

import nebula.actions.Action;

interface RotateByOptions {
  /**
   * Angle in radians to offset from the current and rotate
   */
  var angleRadiansOffset: Float;
  /**
   * Duration to take in milliseconds
   */
  var duration: Int;
  /**
   * Optionally provide type of rotation, default is RotationType.ShortestPath
   */
  var rotationType: Null<RotationType>;
}

/**
 *
 */
function isRotateByOptions(x: Any) {
  return (Std.isOfType(x.angleRadianOffset, Float) && Std.isOfType(x.duration, Int));
}

class RotateByWithOptions implements Action {
  var id = nextActionId();
  private var _durationMs: Float;
  private var _tx: TransformComponent;
  private var _started: Bool = false;
  private var _currentMs: Float;
  private var _stopped: Bool = false;
  private var _motion: MotionComponent;
  private var _offset: Float = 0;
  private var _startAngle: Float = 0;
  private var _rotationType: RotationType;
  private var _endAngle: Float = 0;
  public function new(
    entity: Entity,
    options: RotateByOptions
  ) {
    this._offset = options.angleRadiansOffset;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only RotateBy on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._rotationType = options.rotationType ?? RotationType.ShortestPath;
    this._currentMs = this._durationMs;
  }
  function update(elapsed: Int) {
    if (!this._started) {
      this._startAngle = this._tx.rotation;
      this._endAngle = canonicalizeAngle(this._startAngle + this._offset);
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    var newAngle = lerpAngle(this._startAngle, this._endAngle, this._rotationType, t);
    var currentAngle = this._tx.rotation;
    var seconds = elapsed / 1000;
    var rx = seconds == 0 ? 0 : (newAngle - currentAngle) / seconds;
    this._motion.angularVelocity = rx;

    if (this.isComplete()) {
      this._tx.rotation = this._endAngle;
      this._motion.angularVelocity = 0;
    }
  }
  public function isComplete(): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public function stop() {
    this._motion.angularVelocity = 0;
    this._stopped = true;
    this._currentMs = 0;
  }

  public function reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class RotateBy implements Action {
  var id = nextActionId();
  private var _tx: TransformComponent;
  private var _motion: MotionComponent;
  public var x: Float;
  public var y: Float;
  private var _start: Float;
  private var _end: Float;
  private var _speed: Float;
  private var _offset: Float;

  private var _rotationType: RotationType;
  private var _direction: Float;
  private var _distance: Float;
  private var _shortDistance: Float;
  private var _longDistance: Float;
  private var _shortestPathIsPositive: Bool;
  private var _currentNonCannonAngle: Float;
  private var _started = false;
  private var _stopped = false;
  public function new(entity: Entity, angleRadiansOffset: Float, speed: Float, ?rotationType: RotationType) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._speed = speed;
    this._offset = angleRadiansOffset;
    this._rotationType = rotationType || RotationType.ShortestPath;
  }

  public function update(elapsed: Int) {
    if (!this._started) {
      this._started = true;
      this._start = this._tx.rotation;
      this._currentNonCannonAngle = this._tx.rotation;
      this._end = this._start + this._offset;

      var distance1 = Math.abs(this._end - this._start);
      var distance2 = TwoPI - distance1;
      if (distance1 > distance2) {
        this._shortDistance = distance2;
        this._longDistance = distance1;
      } else {
        this._shortDistance = distance1;
        this._longDistance = distance2;
      }

      this._shortestPathIsPositive = (this._start - this._end + TwoPI) % TwoPI >= Math.PI;

      switch (this._rotationType) {
        case RotationType.ShortestPath:
          this._distance = this._shortDistance;
          if (this._shortestPathIsPositive) {
            this._direction = 1;
          } else {
            this._direction = -1;
          }
          break;
        case RotationType.LongestPath:
          this._distance = this._longDistance;
          if (this._shortestPathIsPositive) {
            this._direction = -1;
          } else {
            this._direction = 1;
          }
          break;
        case RotationType.Clockwise:
          this._direction = 1;
          if (this._shortDistance >= 0) {
            this._distance = this._shortDistance;
          } else {
            this._distance = this._longDistance;
          }
          break;
        case RotationType.CounterClockwise:
          this._direction = -1;
          if (this._shortDistance <= 0) {
            this._distance = this._shortDistance;
          } else {
            this._distance = this._longDistance;
          }
          break;
      }
    }

    this._motion.angularVelocity = this._direction * this._speed;
    this._currentNonCannonAngle += this._direction * this._speed * (elapsed / 1000);

    if (this.isComplete()) {
      this._tx.rotation = this._end;
      this._motion.angularVelocity = 0;
      this._stopped = true;
    }
  }

  public function isComplete(): Bool {
    var distanceTraveled = Math.abs(this._currentNonCannonAngle - this._start);
    return this._stopped || distanceTraveled >= Math.abs(this._distance);
  }

  public function stop() {
    this._motion.angularVelocity = 0;
    this._stopped = true;
  }

  public function reset() {
    this._started = false;
    this._stopped = false;
    this._start = null;
    this._currentNonCannonAngle = null;
    this._distance = null;
  }
}
