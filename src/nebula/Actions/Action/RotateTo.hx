package nebula.Actions.Action;

import nebula.Math;

import nebula.EntityComponentSystem.Components.TransformComponent;
import nebula.EntityComponentSystem.Components.MotionComponent;
import nebula.EntityComponentSystem.Entity;

import nebula.Math.Util;
import nebula.Math;

import nebula.Actions.Action;

interface RotateToOptions {
  /**
   * Absolute angle to rotate to in radians
   */
  angle: Float;
  /**
   * Duration to take in milliseconds
   */
  duration: Float;
  /**
   * Optionally provide type of rotation, default is RotationType.ShortestPath
   */
  rotationType?: RotationType;
}

/**
 *
 */
function isRotateToOptions(x: any): x is RotateToOptions {
  return typeof x.angle === 'number' && typeof x.duration === 'number';
}

class RotateToWithOptions implements Action {
  id = nextActionId();
  private _durationMs: Float;
  private _tx: TransformComponent;
  private _started: boolean = false;
  private _currentMs: Float;
  private _stopped: boolean = false;
  private _motion: MotionComponent;
  private _endAngle: Float = 0;
  private _startAngle: Float = 0;
  private _rotationType: RotationType;
  public function new(
    public entity: Entity,
    options: RotateToOptions
  ) {
    this._endAngle = options.angle;
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    if (!this._tx) {
      throw new Error('Entity ${entity.name} has no TransformComponent, can only RotateTo on Entities with TransformComponents.');
    }
    this._durationMs = options.duration;
    this._rotationType = options.rotationType ?? RotationType.ShortestPath;
    this._currentMs = this._durationMs;
  }
  update(elapsed: Float) {
    if (!this._started) {
      this._startAngle = this._tx.rotation;
      this._started = true;
    }
    this._currentMs -= elapsed;
    var t = clamp(remap(0, this._durationMs, 0, 1, this._durationMs - this._currentMs), 0, 1);
    var newAngle = lerpAngle(this._startAngle, this._endAngle, this._rotationType, t);
    var currentAngle = this._tx.rotation;

    var seconds = elapsed / 1000;
    var rx = seconds === 0 ? 0 : (newAngle - currentAngle) / seconds;
    this._motion.angularVelocity = rx;

    if (this.isComplete(this.entity)) {
      this._tx.rotation = this._endAngle;
      this._motion.angularVelocity = 0;
    }
  }
  public isComplete(entity: Entity): Bool {
    return this._stopped || this._currentMs < 0;
  }

  public stop() {
    this._motion.angularVelocity = 0;
    this._stopped = true;
    this._currentMs = 0;
  }

  public reset() {
    this._currentMs = this._durationMs;
    this._started = false;
    this._stopped = false;
  }
}

class RotateTo implements Action {
  id = nextActionId();
  private _tx: TransformComponent;
  private _motion: MotionComponent;
  public x!: Float;
  public y!: Float;
  private _start!: Float;
  private _end: Float;
  private _speed: Float;
  private _rotationType: RotationType;
  private _direction!: Float;
  private _distance!: Float;
  private _shortDistance!: Float;
  private _longDistance!: Float;
  private _shortestPathIsPositive!: Bool;
  private _currentNonCannonAngle!: Float;
  private _started = false;
  private _stopped = false;
  public function new(entity: Entity, angle: Float, speed: Float, rotationType?: RotationType) {
    this._tx = entity.get(TransformComponent);
    this._motion = entity.get(MotionComponent);
    this._end = angle;
    this._speed = speed;
    this._rotationType = rotationType || RotationType.ShortestPath;
  }

  public update(elapsed: Float) {
    if (!this._started) {
      this._started = true;
      this._start = this._tx.rotation;
      this._currentNonCannonAngle = this._tx.rotation;
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
          if (this._shortestPathIsPositive) {
            this._distance = this._shortDistance;
          } else {
            this._distance = this._longDistance;
          }
          break;
        case RotationType.CounterClockwise:
          this._direction = -1;
          if (!this._shortestPathIsPositive) {
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

  public isComplete(): Bool {
    const distanceTraveled = Math.abs(this._currentNonCannonAngle - this._start);
    return this._stopped || distanceTraveled >= Math.abs(this._distance);
  }

  public stop() {
    this._motion.angularVelocity = 0;
    this._stopped = true;
  }

  public reset() {
    this._started = false;
    this._stopped = false;
  }
}
